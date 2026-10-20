"""Export the current complete profile figures without refitting or recomposition.

Use render_profile_figures.R to redraw them from saved publication values.
Legacy panel crops are retained as source history, not current assembly inputs.
"""
from pathlib import Path
import argparse
import shutil

HERE = Path(__file__).resolve().parent
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("output_dir", nargs="?", type=Path, default=HERE / "regenerated" / "profiles")
parser.add_argument("--panel-dir", type=Path, help="Legacy option; individual panel crops cannot reproduce the current unified fonts.")
args = parser.parse_args()
if args.panel_dir is not None:
    parser.error("Legacy --panel-dir assembly is incompatible with the current full figures. Use render_profile_figures.R to redraw saved values.")
out = args.output_dir.resolve()
if out.exists():
    raise SystemExit("Output already exists; choose a new directory.")
out.mkdir(parents=True)
for number in (2, 3, 4):
    shutil.copyfile(HERE / "assets" / f"Figure_{number}.png", out / f"Figure_{number}.png")
print(out)
