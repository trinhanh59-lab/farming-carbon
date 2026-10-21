"""Figure 1: published approximate site vicinities in California Albers EPSG:3310.

Cartographic boundaries: U.S. Census Bureau, 2023, 1:500,000.
Use only for small-scale display; do not infer exact core coordinates.
Adapted from the reviewed V4 scientific map renderer. No statistical analysis.
"""
from pathlib import Path
import hashlib
import csv
import io
import stat
from zipfile import ZipFile
import json
import re
import sys

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
from matplotlib.path import Path as MplPath
from matplotlib.patches import PathPatch, Rectangle
import numpy as np
import shapefile
from shapely.geometry import shape, Point, box
from shapely.ops import transform, unary_union
from pyproj import Transformer, Geod

HERE = Path(__file__).resolve().parent
OUTPUT = Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else HERE.parent / "regenerated" / "map"
if OUTPUT.exists():
    raise SystemExit("Output already exists; choose a new directory.")
# Source ZIP handling only; the original boundary bytes and drawing remain unchanged.
BASEMAP_IDENTITIES = {'county': {'path': 'figures/map/basemap/cb_2023_us_county_500k.zip', 'bytes': 11630077, 'sha256': '99d6597b1fc7767deef62e01d28d8b5dcbd578e151855f7dc0d173cbf5bf0868', 'md5': '81d0b3b19d460b342c7354226ba4d567'}, 'state': {'path': 'figures/map/basemap/cb_2023_us_state_500k.zip', 'bytes': 3249332, 'sha256': '4a9b4f5cf993cd23738ac49b58fbb556f1f097fcf5e404a9dc10348dd41f7432', 'md5': '3ac2c59dd7708dc9960fdc10c039095b'}}

def safe_regular_zip_members(archive):
    entries = archive.infolist()
    names = [entry.filename for entry in entries]
    if len({name.casefold() for name in names}) != len(names):
        raise ValueError("Duplicate basemap archive member path.")
    for entry in entries:
        name = entry.filename
        mode = (entry.external_attr >> 16) & 0xFFFF
        if (not name or name.startswith("/") or re.match(r"^[A-Za-z]:", name)
                or "\\" in name or re.search(r"[\x00-\x1f\x7f]", name)
                or any(part in ("", ".", "..") for part in name.split("/"))
                or entry.is_dir() or stat.S_IFMT(mode) not in (0, stat.S_IFREG)):
            raise ValueError("Unsafe or nonregular basemap archive member.")
    return names


def verified_basemap_readers():
    wrapper = HERE / "basemap" / "Census_Basemaps_2023_500k.zip"
    payloads = {}
    if wrapper.is_file():
        with ZipFile(wrapper) as archive:
            names = safe_regular_zip_members(archive)
            expected_names = {record["path"] for record in BASEMAP_IDENTITIES.values()}
            if set(names) != expected_names | {"FILE_MANIFEST.csv"}:
                raise ValueError("Basemap wrapper must contain the two original ZIPs and manifest.")
            if archive.testzip() is not None:
                raise ValueError("Basemap wrapper CRC check failed.")
            manifest = list(csv.DictReader(io.StringIO(archive.read("FILE_MANIFEST.csv").decode("utf-8"))))
            if len(manifest) != 2 or {row["path"] for row in manifest} != expected_names:
                raise ValueError("Basemap manifest identities differ.")
            manifest_by_path = {row["path"]: row for row in manifest}
            for kind, record in BASEMAP_IDENTITIES.items():
                row = manifest_by_path[record["path"]]
                if (int(row["bytes"]) != record["bytes"] or row["sha256"] != record["sha256"]
                        or row["md5"] != record["md5"]):
                    raise ValueError("Basemap manifest differs from the recorded source identity.")
                payloads[kind] = archive.read(record["path"])
    else:
        for kind, record in BASEMAP_IDENTITIES.items():
            payloads[kind] = (HERE / "basemap" / Path(record["path"]).name).read_bytes()
    readers = {}
    for kind, raw in payloads.items():
        record = BASEMAP_IDENTITIES[kind]
        if (len(raw) != record["bytes"] or hashlib.sha256(raw).hexdigest() != record["sha256"]
                or hashlib.md5(raw).hexdigest() != record["md5"]):
            raise ValueError("Basemap source bytes differ from the recorded ZIP.")
        with ZipFile(io.BytesIO(raw)) as archive:
            names = safe_regular_zip_members(archive)
            if archive.testzip() is not None:
                raise ValueError("Original Census ZIP CRC check failed.")
            buffers = {}
            for suffix in ("shp", "shx", "dbf"):
                matches = [name for name in names if Path(name).suffix.lower() == "." + suffix]
                if len(matches) != 1 or Path(matches[0]).stem != Path(record["path"]).stem:
                    raise ValueError("Original Census ZIP lacks its expected shapefile components.")
                buffers[suffix] = io.BytesIO(archive.read(matches[0]))
            readers[kind] = shapefile.Reader(**buffers)
    return readers


BASEMAP_READERS = verified_basemap_readers()
OUTPUT.mkdir(parents=True)
SITES = [
    {"label": "Hedgerow", "lon": -122.001, "lat": 38.633, "color": "#D4A017"},
    {"label": "Annual", "lon": -119.857, "lat": 36.714, "color": "#7BA428"},
    {"label": "Peach", "lon": -119.624, "lat": 36.653, "color": "#C7522A"},
]
CV_NAMES = ["Tehama", "Glenn", "Butte", "Colusa", "Sutter", "Yolo", "Yuba",
            "Sacramento", "San Joaquin", "Stanislaus", "Merced", "Madera",
            "Fresno", "Kings", "Tulare", "Kern"]

boundary_transform = Transformer.from_crs(4269, 3310, always_xy=True)
site_transform = Transformer.from_crs(4326, 3310, always_xy=True)
inverse = Transformer.from_crs(3310, 4326, always_xy=True)
geod = Geod(ellps="GRS80")

def read_ca(kind):
    reader = BASEMAP_READERS[kind]
    return {r.record["NAME"]: transform(boundary_transform.transform, shape(r.shape.__geo_interface__))
            for r in reader.iterShapeRecords() if r.record["STATEFP"] == "06"}

ca = read_ca("state")["California"]
counties = read_ca("county")
assert len(counties) == 58
valley = unary_union([counties[name] for name in CV_NAMES])

def draw_geometry(ax, geometry, **kwargs):
    polygons = [geometry] if geometry.geom_type == "Polygon" else list(geometry.geoms)
    for polygon in polygons:
        vertices, codes = [], []
        for ring in [polygon.exterior, *polygon.interiors]:
            xy = np.asarray(ring.coords)
            vertices.extend(xy)
            codes.extend([MplPath.MOVETO] + [MplPath.LINETO] * (len(xy) - 2) + [MplPath.CLOSEPOLY])
        ax.add_patch(PathPatch(MplPath(vertices, codes), **kwargs))

plt.rcParams.update({"font.family": "DejaVu Sans", "font.size": 10,
                     "pdf.fonttype": 42, "svg.fonttype": "none"})
fig, ax = plt.subplots(figsize=(5.8, 7.2))
fig.subplots_adjust(left=.045, right=.975, top=.975, bottom=.035)
ax.set_aspect("equal")
ax.set_xlim(-480000, 585000)
ax.set_ylim(-650000, 480000)
ax.axis("off")

draw_geometry(ax, ca, facecolor="#FAF6EC", edgecolor="#3A3A3A", linewidth=1.05, zorder=1)
draw_geometry(ax, valley, facecolor="#E2D9C0", edgecolor="none", alpha=.65, zorder=2)
for name in ("Fresno", "Yolo"):
    draw_geometry(ax, counties[name], facecolor="#D6C99B", edgecolor="#7a6a3a",
                  linewidth=.65, alpha=.7, zorder=3)

def xy(lon, lat):
    return site_transform.transform(lon, lat)

# Marker centres are published approximate vicinity coordinates, not core locations.
# Preserve the approved layout and leader-line anchors.
label_positions = {"Hedgerow": (-360000, 95000), "Annual": (-250000, -130000),
                   "Peach": (295000, -70000)}
for site in SITES:
    x, y = xy(site["lon"], site["lat"])
    assert ca.covers(Point(x, y))
    back = inverse.transform(x, y)
    assert np.allclose(back, (site["lon"], site["lat"]), rtol=0, atol=1e-8)
    ax.annotate(site["label"], xy=(x, y), xytext=label_positions[site["label"]],
                ha="center", va="center", color=site["color"], fontsize=10.2,
                weight="bold", zorder=5,
                bbox=dict(boxstyle="round,pad=.27,rounding_size=.12", facecolor="white",
                          edgecolor=site["color"], linewidth=.8),
                arrowprops=dict(arrowstyle="-", color=site["color"], linewidth=.95,
                                shrinkA=3, shrinkB=3))
    ax.plot(x, y, marker="D", markersize=4.8, markerfacecolor="white",
            markeredgecolor=site["color"], markeredgewidth=1.25, zorder=6)

ax.text(*xy(-121.91, 39.105), "Yolo", ha="center", va="center", color="#6F6138",
        fontsize=9, style="italic", zorder=4)
ax.text(*xy(-119.58, 35.955), "Fresno", ha="center", va="center", color="#6F6138",
        fontsize=9, style="italic", zorder=4)
ax.text(*xy(-120.22, 38.1), "Central Valley", ha="center", va="center",
        color="#7a6a3a", fontsize=9, style="italic", rotation=-52, zorder=4)

# A single uncluttered north arrow, outside the state. Its direction follows true
# north at the arrow's position, including Albers meridian convergence.
arrow_base = (320000, 245000)
lon, lat = inverse.transform(*arrow_base)
north_x, north_y = xy(*geod.fwd(lon, lat, 0, 70000)[:2])
ax.annotate("", xy=(north_x, north_y), xytext=arrow_base,
            arrowprops=dict(arrowstyle="-|>", color="#333333", linewidth=1.25,
                            mutation_scale=13), zorder=5)
ax.text(north_x, north_y + 23000, "N", ha="center", va="bottom",
        fontsize=11, weight="bold", color="#333333")
assert not ca.intersects(box(285000, 230000, 355000, 365000))

# A conventional 0/100/200 km scale in Pacific whitespace. The displayed length
# is calibrated against an ellipsoidal geodesic between its projected endpoints.
scale_x, scale_y = -355000, -410000
scale_length = 200000.0
for _ in range(4):
    a = inverse.transform(scale_x, scale_y)
    b = inverse.transform(scale_x + scale_length, scale_y)
    distance = geod.inv(*a, *b)[2]
    scale_length *= 200000.0 / distance
scale_height = 7000
for i, color in enumerate(("#333333", "white")):
    ax.add_patch(Rectangle((scale_x + i * scale_length / 2, scale_y),
                          scale_length / 2, scale_height, facecolor=color,
                          edgecolor="#333333", linewidth=.8, zorder=5))
for i, label in enumerate(("0", "100", "200 km")):
    ax.text(scale_x + i * scale_length / 2, scale_y - 19000, label,
            ha="center", va="top", fontsize=8.5, color="#333333")
assert not ca.intersects(box(scale_x - 20000, scale_y - 45000,
                            scale_x + scale_length + 45000, scale_y + 16000))
end_a = inverse.transform(scale_x, scale_y)
end_b = inverse.transform(scale_x + scale_length, scale_y)
bar_km = geod.inv(*end_a, *end_b)[2] / 1000
assert abs(bar_km - 200) < .001

stem = OUTPUT / "Figure_1"
fig.savefig(stem.with_suffix(".png"), dpi=600, facecolor="white")
fig.savefig(stem.with_suffix(".pdf"), facecolor="white", metadata={"Title": "Farming Carbon Figure 1"})
fig.savefig(stem.with_suffix(".svg"), facecolor="white")
plt.close(fig)
print("Rendered current Figure 1 specifications in", OUTPUT)
