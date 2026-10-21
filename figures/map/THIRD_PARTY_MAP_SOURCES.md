# Census map sources

Figure 1 boundaries are from the **U.S. Census Bureau, 2023 Cartographic Boundary Files, 1:500,000**, state and county layers. The original ZIPs and their embedded ISO metadata are retained unchanged.

- [2023 cartographic boundary files](https://www.census.gov/geographies/mapping-files/time-series/geo/cartographic-boundary.2023.html)
- [State ZIP](https://www2.census.gov/geo/tiger/GENZ2023/shp/cb_2023_us_state_500k.zip)
- [County ZIP](https://www2.census.gov/geo/tiger/GENZ2023/shp/cb_2023_us_county_500k.zip)

The official metadata permits use in a product or publication with acknowledgement of the U.S. Census Bureau. Retain that credit when reusing this map. The files are intended for small-scale display at 1:500,000 or smaller scales. They are not suitable for precise geographic relationships, geocoding or area/perimeter analysis.

No satellite or commercial basemap tiles are used. The project does not assign its own code or data license to these Census boundary files. Their source metadata and conditions remain applicable.

The script transforms boundary coordinates from NAD83 (EPSG:4269) and approximate WGS84 vicinity markers to California Albers (EPSG:3310). Markers summarize the published regional/farm vicinity; they are not sampled core coordinates. The displayed scale is calibrated geodesically. These choices reproduce the recovered scientific map rather than add location precision.

## Local source locations

[Census_Basemaps_2023_500k.zip](basemap/Census_Basemaps_2023_500k.zip) preserves both original ZIP byte streams, including embedded metadata, at the member paths below. Its manifest records sizes, SHA-256 and MD5.

| Original member path | Bytes | SHA-256 |
| --- | --- | --- |
| `figures/map/basemap/cb_2023_us_county_500k.zip` | 11630077 | `99d6597b1fc7767deef62e01d28d8b5dcbd578e151855f7dc0d173cbf5bf0868` |
| `figures/map/basemap/cb_2023_us_state_500k.zip` | 3249332 | `4a9b4f5cf993cd23738ac49b58fbb556f1f097fcf5e404a9dc10348dd41f7432` |

The renderer validates these recorded source identities and CRCs before drawing. Extract the wrapper into a separate repository copy to restore the original loose-map layout if needed. Source credits and geographic specifications above are unchanged.
