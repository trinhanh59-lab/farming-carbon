"""Export the six fixed scientific figure assets used in the current paper/S1.

These are source assets, not a fresh analysis or an editable reconstruction.
"""
from pathlib import Path
import argparse
import shutil

HERE = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("output_dir", nargs="?", type=Path, default=HERE / "regenerated" / "publication_assets")
args = parser.parse_args()
out = args.output_dir.resolve()
if out.exists():
    raise SystemExit("Output already exists; choose a new directory.")
out.mkdir(parents=True)
for name in ("Figure_1.png", "Figure_2.png", "Figure_3.png", "Figure_4.png", "Figure_S1.png", "Figure_S2.png"):
    shutil.copyfile(HERE / "assets" / name, out / name)
print(out)
