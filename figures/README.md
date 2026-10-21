# Scientific figures

`assets/` contains the five PNGs used in the current manuscript and supplement, plus the annual root diagnostic PNG documented in [ROOT_MODEL_CHECKS.md](../docs/ROOT_MODEL_CHECKS.md). Figures 2–4 were redrawn from the saved publication values to use consistent Arial fonts at 6.5 × 6.1 inches (1950 × 1830 pixels, 300 dpi). Panels a/b/d retain their data, uncertainty, significance markers and pixels. Stock panels c now show observed core means ±1SE, with no significance markers; their endpoint tests are in Table 1B. Figure 1, the static sampling diagram and the root diagnostic image are unchanged. Current and historical image hashes are recorded in `FIGURE_ASSET_PROVENANCE.json`.

## Commands

Run from the repository root, using a new output directory:

```sh
Rscript --vanilla figures/render_profile_figures.R [NEW_OUTPUT_DIR]
python figures/map/render_figure1.py [NEW_OUTPUT_DIR]
```

Brackets indicate an optional argument, not literal shell syntax. Defaults are separate subdirectories of `figures/regenerated/`. Both commands leave supplied assets unchanged.

`render_profile_figures.R` redraws complete Figures 2–4 from corrected annual-root display values, observed perennial-root profiles, current C-concentration/Δ¹⁴C EMMs/markers and 32 observed stock means ±1SE. It writes plotting-data readbacks and runs no models or statistical tests. Arial axes use 9 pt, ticks and legends 8.5 pt, and panel letters 11 pt. The required annual fit-to-display helper remains at `analysis/figure2_review/render_corrected_figure2a.R`.

The [support archive](../archive/Supporting_Files_2026-10-20.zip) preserves alternate panel renderers, copy-only asset exporters and optional annual diagnostic plotters at their original paths. Restore it into a separate repository copy before using these helpers. In particular, `figures/render_saved_annual_diagnostics.R` redraws the former Figure S2 from saved residuals without fitting or simulation. Its fixed PNG, underlying residuals and detailed checks remain active in [ROOT_MODEL_CHECKS.md](../docs/ROOT_MODEL_CHECKS.md).

The older panel crops and superseded hedgerow helper remain in the separate [analysis history](../archive/Analysis_History_2026-10-20.zip). They are not current rendering inputs.

## Figure-specific limits

- Figure 1 uses the recovered current map specifications, approximate vicinity points and Census boundaries. A fresh execution of the recovered map code matches the publication's decoded pixels. See `map/THIRD_PARTY_MAP_SOURCES.md` for required source credit and use limits.
- Figures 2–4 combine corrected annual fitted root density, observed perennial root profiles, 32 observed stock means ±1SE and retained C-concentration/Δ¹⁴C fitted panels. Historical root-mass and orchard cumulative-stock GLMM panels must not replace these current displays.
- S1 is the exact current static scientific illustration and approved caption. Its editable drawing source was not found. No diagram was redrawn by inference.
- The former S2 fixed PNG remains byte-for-byte unchanged as the repository diagnostic image. It is no longer included in the current supplement. A new graphics device or font can change regenerated pixels without changing the saved residual values.

The 19 October hedgerow revision rendered Figure 4 panels b–d from the restricted model results. The later font revision redrew complete Figures 2–4 from those saved values and the other approved display sources. The preceding isolated analysis verification was completed on 17 October 2026. Code/data release and licensing choices remain separate from the manuscript license. Census source conditions remain attached to its boundary files.

The earlier 20 October orchard-stock restoration and its fitted panel are historical. The current endpoint revision replaces only panels 2c, 3c and 4c with observed means ±1SE; all a/b/d and legend pixels are preserved. The 32 means and SEs retain their source sample/core IDs. No old stock joint-test stars are used, and rendering fits no model or test.

## Optional cached-object plots

Some diagnostic helpers in `Supporting_Files_2026-10-20.zip` use objects now stored in [Run_Support_History_2026-10-21.zip](../archive/Run_Support_History_2026-10-21.zip). Restore both support archives into the same separate copy before using those saved objects. Current Figures 1–4 and the fixed S1/S2 assets do not read the run-support ZIP.
