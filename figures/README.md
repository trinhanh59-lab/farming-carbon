# Scientific figures

`assets/` contains the five PNGs used in the current manuscript and supplement, plus the annual root diagnostic PNG documented in [ROOT_MODEL_CHECKS.md](../docs/ROOT_MODEL_CHECKS.md). Figures 2–4 were redrawn from the saved publication values to use consistent Arial fonts at 6.5 × 6.1 inches (1950 × 1830 pixels, 300 dpi). Panels a/b/d retain their data, uncertainty, significance markers and pixels. Stock panels c now show observed core means ±1SE, with no significance markers; their endpoint tests are in Table 1B. Figure 1, the static sampling diagram and the root diagnostic image are unchanged. Current and historical image hashes are recorded in `FIGURE_ASSET_PROVENANCE.json`.

## Commands

Run from the repository root. Each command requires a new output directory and leaves supplied assets unchanged.

```sh
python figures/export_publication_assets.py
python figures/assemble_profile_figures.py
Rscript --vanilla figures/render_profile_figures.R
python figures/map/render_figure1.py
Rscript --vanilla figures/render_nonroot_panels.R
Rscript --vanilla figures/render_hedgerow75_panels.R
Rscript --vanilla figures/render_saved_annual_diagnostics.R
```

Defaults are separate subdirectories of `figures/regenerated/`. An explicit output directory may be supplied as the first argument. `assemble_profile_figures.py` exports the complete current Figures 2–4 unchanged. Its old `--panel-dir` option now reports an error because the legacy crops would restore inconsistent typography. The old crops remain under `assets/current_panels/` as source history.

`render_profile_figures.R` is the current saved-data renderer for complete Figures 2–4. It reads corrected annual-root display values, observed perennial-root profiles, current C-concentration/Δ¹⁴C EMMs/markers and the 32 observed stock-profile summaries in `analysis/stock_endpoints_2026-10-20/saved_results/stock_profile_summary.csv`. It writes plotting-data readbacks with each render. Axis labels use 9 pt Arial, ticks and legends use 8.5 pt, and panel letters use 11 pt. All panel frames and categorical depth intervals retain the existing layout. No models or statistical tests are run.

`render_nonroot_panels.R` separately draws all nine non-root panels: six C-concentration/Δ¹⁴C panels from 64 saved EMMs and three stock panels from 32 observed mean ±SE summaries. Only the C-concentration/Δ¹⁴C panels use the saved marker tests. It preserves the selected data and plotting rules; its separate-panel layout is not the current publication composite. Earlier root and observed-profile renderers remain under `analysis/figure2_review/` and `analysis/observed_profile_figures/` as source history. Their macOS Quartz device calls need a device/layout check on other platforms.

`render_saved_annual_diagnostics.R` draws the former Figure S2 from saved residuals, without simulations or model fitting. The existing annual analysis and diagnostic scripts supply the former Table S3's mass-sensitivity and Holm results. These detailed checks, both full tables and the figure caption are now in [ROOT_MODEL_CHECKS.md](../docs/ROOT_MODEL_CHECKS.md).

## Figure-specific limits

- Figure 1 uses the recovered current map specifications, approximate vicinity points and Census boundaries. A fresh execution of the recovered map code matches the publication's decoded pixels. See `map/THIRD_PARTY_MAP_SOURCES.md` for required source credit and use limits.
- Figures 2–4 combine corrected annual fitted root density, observed perennial root profiles, 32 observed stock means ±1SE and retained C-concentration/Δ¹⁴C fitted panels. Historical root-mass and orchard cumulative-stock GLMM panels must not replace these current displays.
- S1 is the exact current static scientific illustration and approved caption. Its editable drawing source was not found. No diagram was redrawn by inference.
- The former S2 fixed PNG remains byte-for-byte unchanged as the repository diagnostic image. It is no longer included in the current supplement. A new graphics device or font can change regenerated pixels without changing the saved residual values.

The 19 October hedgerow revision rendered Figure 4 panels b–d from the restricted model results. The later font revision redrew complete Figures 2–4 from those saved values and the other approved display sources. The preceding isolated analysis verification was completed on 17 October 2026. Code/data release and licensing choices remain separate from the manuscript license. Census source conditions remain attached to its boundary files.

The earlier 20 October orchard-stock restoration and its fitted panel are historical. The current endpoint revision replaces only panels 2c, 3c and 4c with observed means ±1SE; all a/b/d and legend pixels are preserved. The 32 means and SEs retain their source sample/core IDs. No old stock joint-test stars are used, and rendering fits no model or test.
