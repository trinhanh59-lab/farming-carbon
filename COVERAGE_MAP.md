# Paper, supplement and code coverage

All four named history/support ZIPs below are members of [History_and_Support_2026-10-21.zip](archive/History_and_Support_2026-10-21.zip). Restore the outer container and then the needed inner ZIP into a separate copy. Current module instructions are consolidated in [REPRODUCIBILITY.md](REPRODUCIBILITY.md); the four original READMEs are also preserved in the container.

Historical stock-profile, orchard covariance and superseded figure files are now stored at their original relative paths inside the [history ZIP](archive/History_and_Support_2026-10-21.zip). The ZIP manifest records their original sizes and hashes. Current analyses and publication assets remain outside the archive. Duplicate snapshots and optional plotters are in the separate [support ZIP](archive/History_and_Support_2026-10-21.zip); restore it into a separate repository copy before running those helpers.

This map describes the numerical sources synchronized on 30 October 2026. Annual comparisons cover 0–100 cm; orchard and hedgerow comparisons cover 0–75 cm. Current root results include the two author-confirmed hedgerow mass corrections. Stock inference uses one overall Welch ANOVA per system, based on one cumulative total per core. The earlier 0–20 cm hedgerow comparisons, pairwise stock tests and stock Holm adjustment are historical. Dated verification records describe their own earlier branches, not the corrected current results. This repository update does not establish that the separate online supplement or Google Sheet has been edited.

| Artifact | Current source and code | Coverage and bounds |
| --- | --- | --- |
| Former Table 1 (historical) | Earlier root/non-root Wald summaries and `analysis/stock_endpoints_2026-10-20/` | The manuscript table was removed. Current root tests and three overall stock tests are supplied in the workbook and the selected modules; old endpoint contrasts remain as history. |
| Figure 1 | `figures/map/render_figure1.py`, published approximate vicinity points and unchanged Census 2023 state/county ZIPs | Recovered V4 output matches the current figure's decoded pixels. The fresh portable map render matches the publication pixels. Census source metadata and acknowledgement requirements are retained. Markers are not core coordinates. |
| Figure 2 | `figures/render_profile_figures.R`; `figures/profile_data/annual_means1se.csv` and `annual_brackets.csv` | 48 means: 36 response-scale fitted root/C-concentration/Δ¹⁴C means and 12 observed cumulative-stock means, all ±1 SE. Five unadjusted within-depth pairwise brackets and one overall 0–100 cm stock ns marker. Both groups share each depth-row center. |
| Figure 3 | `figures/render_profile_figures.R`; `figures/profile_data/orchard_means1se.csv` and `orchard_brackets.csv` | 32 means: 24 fitted root/C-concentration/Δ¹⁴C means and eight observed stock means, all ±1 SE. Four unadjusted within-depth pairwise brackets and one overall 0–75 cm stock ns marker. Both groups share each depth-row center. Individual-core root profiles remain supplied as data, not drawn. |
| Figure 4 | `figures/render_profile_figures.R`; `figures/profile_data/hedgerow_means1se.csv` and `hedgerow_brackets.csv` | 48 means: 36 fitted root/C-concentration/Δ¹⁴C means and 12 observed stock means, all ±1 SE, through 75 cm. Sixteen unadjusted within-depth pairwise brackets and one overall stock ns marker comparing all three margins. Approved vertical group offsets aid readability. Both root-mass corrections are included. |
| Figure S1 | `figures/assets/Figure_S1.png` and `Figure_S1_caption.txt` | Exact current scientific illustration and approved caption preserved. The editable drawing source was not located; no replacement diagram was inferred. This does not prevent execution of the analyses. |
| Repository root diagnostic figure (former Figure S2) | `docs/ROOT_MODEL_CHECKS.md`; [support ZIP](archive/History_and_Support_2026-10-21.zip), original member `figures/render_saved_annual_diagnostics.R`; [diagnostic-results ZIP](archive/Diagnostic_Results_2026-10-21.zip), member `analysis/corrected_annual_validation_2026-10-16/outputs/residuals_by_sample.csv` | Retained in the repository with its dated Figure S2 label. Draws the original-constant, conditional residual subset from saved simulations. It runs no simulations or fits. The fixed PNG and its full caption are preserved. |
| Repository root sensitivity tables (former Table S3) | `docs/ROOT_MODEL_CHECKS.md`; annual Gamma `omnibus_wald_tests.csv`, `field_contrasts.csv` and validation `Holm_six_depth_comparisons.csv`; existing annual scripts | Both full tables and their qualifications are retained in the repository with their dated Table S3 label. Three added-mass branches and the separate six-depth Holm sensitivity are supplied. Current unadjusted Table S1 values are not replaced by adjusted values. The earlier isolated fits, simulations and all 18 whole-core deletion scenarios reproduced the frozen annual tables. |
| Secondary archived orchard profile analysis | [History ZIP](archive/History_and_Support_2026-10-21.zip), original members under `analysis/orchard_cumulative_correlation/`, with 999 classifications, retained simulated responses and the 20,000-dataset diagnostic | The secondary archive records the completed 17 October run: 125 exceedances, 870 nonexceedances, three failed fits and one ambiguous comparison; bounds 0.126–0.130 and Monte Carlo envelope 0.1052–0.1515. The original run (bounds 0.124–0.129) remains historical. Original interactive RNG/checkpoint objects were not recovered; the new response matrix and classifications are retained. |
| Workbook Table S1 | Current annual/perennial root contrasts and retained C-concentration/Δ¹⁴C outputs | 74 rows: 66 pairwise contrasts and eight retained non-root hedgerow joint tests. Only matching significant pairwise tests support current figure stars: five annual, four orchard and 16 hedgerow. Joint tests and legacy symbols are distinguished from current figure flags. |
| Workbook Table S2 | Current C-concentration tests and supporting bulk-density analyses; `analysis/hedgerow_0_75/run_bulk_density_hedgerow75.R` supplies the revised hedgerow tests | 18 supporting rows. Annual and orchard rows are unchanged; six hedgerow C-concentration/bulk-density test rows are refreshed. |
| Workbook Stock overall tests | `analysis/stock_omnibus_2026-10-21/saved_results/` | Three overall Welch ANOVAs, seven group summaries and 21 observed core totals. Annual 0–100 cm p = 0.0935645; orchard 0–75 cm p = 0.3812410; hedgerow 0–75 cm p = 0.4507432. The complete earlier endpoint table is retained in History Endpoint Welch. |
| Workbook figure values | Approved readbacks in `figures/profile_data/` | 128 current plotted means: 96 fitted root/C-concentration/Δ¹⁴C means and 32 observed stock means. Display bounds are mean ±1 saved response-scale SE. Root display means have the density equivalent of the added mass subtracted; shifted-response model fields and 95% contrast intervals remain separately labeled. Raw profiles remain supplied and are not drawn in the current figures. |
| Workbook Root model results/checks | `analysis/current_perennial_root/saved_results/` and its `hedgerow_checks/` folder | Corrected hedgerow Wald tests, three equal-depth contrasts and the five-setting sensitivity/conditional-diagnostic checks. Corrections documents the two working-mass changes; History root contrasts retains the original 12 within-depth rows. |
| Workbook sample data | `scripts/prepare_analysis_data.R`; twelve working source workbooks; `data/processed/`; annual/perennial inputs | All 111 records and imported raw masses are retained. Working corrections include the 18 annual changes and hedgerow samples 187 = 0.1952 g and 208 = 0.0199 g. Current model input excludes six deepest orchard and nine deepest hedgerow records, leaving 96 observations. Non-root measurements and supplied stock totals are unchanged. |
| Workbook dictionary/provenance | Workbook definitions, correction/history records and `data/source_measurements/SOURCE_FILES.csv` | Current mean types, figure flags and test scope are explicit. Original workbooks and imported root masses remain preserved; the two author-confirmed hedgerow corrections are dated 27 October 2026. The weighing record was not independently inspected. Historical results retain their original labels and values. |

## Current entrypoints

From the repository root:

```sh
Rscript --vanilla scripts/prepare_analysis_data.R . outputs_rerun/data_preparation
Rscript --vanilla analysis/nonroot_current/run_nonroot_analysis.R --run-analysis [NEW_OUTPUT_DIR]
Rscript --vanilla analysis/stock_omnibus_2026-10-21/run_stock_omnibus.R --run-analysis [NEW_OUTPUT_DIR]
python figures/map/render_figure1.py [NEW_OUTPUT_DIR]
Rscript --vanilla figures/render_profile_figures.R [NEW_OUTPUT_DIR]
```

Brackets indicate optional arguments, not literal shell syntax. The non-root analysis defaults to its new `outputs_rerun/` folder. Figure commands default to separate `figures/regenerated/` subfolders and refuse existing output directories. The perennial module exposes `read_perennial_root_input()` for input checks and an explicit `run_perennial_root_workflow()` call for future fits, sensitivities and diagnostics. Companion-module usage and dependencies are consolidated in REPRODUCIBILITY.md.

The optional orchard workflow is stored in the [history archive](archive/History_and_Support_2026-10-21.zip). Restore its original paths into a separate repository copy before using the historical command:

```sh
Rscript --vanilla analysis/orchard_cumulative_correlation/run_new_reproduction.R NEW_OUTPUT_DIR
```

This dated secondary workflow is not the selected overall stock test.

## Current endpoint checks

The selected stock module contains 21 core totals, seven groups of three cores and three overall Welch ANOVAs. The earlier endpoint module retains 30 observations, ten groups, eight pairwise contrasts and 32 observed profile summaries as a dated branch. No stock-profile model was refitted for the current selection. Supplied layer/cumulative-stock arithmetic is unchanged. Numerical agreement does not establish independent field replication.

## Earlier verification history

The dated 17–21 October checks describe the preceding repository state. The 30 October synchronization replaces the affected hedgerow root inputs/results, selects three overall stock comparisons and publishes the approved mean ±1 SE Figures 2–4. Earlier root results and pairwise/Holm stock tests are retained as history. Current C-concentration and Δ¹⁴C estimates remain unchanged; hedgerow figure brackets now identify their actual pairwise tests rather than the earlier joint markers. The current map asset is unchanged. The former stock-profile driver and CSVs remain under `analysis/nonroot_current/historical_cumulative_profile_2026-10-20/`.

The isolated selected-analysis execution on 17 October is complete. Annual and retained non-root numerical tables reproduce exactly, perennial values agree at reported precision, and the new orchard bootstrap is documented separately from the archived result. On 19 October, the data-only reconstruction checked the supplied measurement workbooks, and the author-approved hedgerow scope change reran three non-root models and the supporting bulk-density model on 36 observations. The 19 October revision did not rerun annual, orchard or root models. The later 20 October restoration reran only the existing orchard cumulative-stock profile model and reproduced its July outputs exactly. Checked dependencies are recorded in the dependency-closed `renv.lock` and Python requirements file. Font and graphics-device differences can change regenerated layouts. The exact static publication assets remain available for comparison. MIT for original project code and CC BY 4.0 for project data/results are included. The data and code are publicly available at https://github.com/trinhanh59-lab/farming-carbon. Third-party Census source conditions are retained.

## Archived run detail

The [run-support archive](archive/History_and_Support_2026-10-21.zip) contains the dated hedgerow non-root checkpoint, extra bulk-density outputs, unused model caches, run logs and detailed diagnostic payloads. Current publication tables and figure inputs remain at the paths listed above. Restore archive members into a separate repository copy when inspecting those historical records.

## Additional archived records

The [additional support ZIP](archive/History_and_Support_2026-10-21.zip) contains the duplicate CSV coverage map, old analysis README/hash list, dated verification audit, earlier Figure 2 review provenance, intermediate 105-row table, preparation-check snapshots, Sheets/notebook input readbacks and three July bulk-density outputs. Their original paths are retained inside the ZIP. The current map above, repository-wide checksum list and current result/input files remain active. Current annual/orchard bulk-density rows are retained in `analysis/hedgerow_0_75/current_bulk_density/`; current hedgerow support uses 0–75 cm. The active full 111-row table preserves every record in the archived intermediate 105-row table.

## Current source workbook container

All 23 original source workbooks are in [data/Original_Source_Workbooks.zip](data/Original_Source_Workbooks.zip) at their original full relative paths, with an integrity manifest. `data/source_measurements/SOURCE_FILES.csv` maps every original path/hash to its ZIP member. Preparation and endpoint source checks open verified temporary members automatically; current CSV inputs, published outputs and 13 script paths remain active. Recorded workbook identities and the frozen selected-run source-hash table are unchanged.

## Bundled method records and basemaps

The five original method/environment records are preserved in `reproducibility/Method_and_Environment_Records.zip` inside the [history/support container](archive/History_and_Support_2026-10-21.zip). Their essential context is retained in [REPRODUCIBILITY.md](REPRODUCIBILITY.md#method-records-and-map-sources). The two original Census ZIPs are preserved in [Census_Basemaps_2023_500k.zip](figures/map/basemap/Census_Basemaps_2023_500k.zip); [map credits](figures/map/THIRD_PARTY_MAP_SOURCES.md) identify each original source. All seven retain their original full relative paths as members, with byte sizes and SHA-256/MD5 manifests.

## Diagnostic source records

[Diagnostic_Results_2026-10-21.zip](archive/Diagnostic_Results_2026-10-21.zip) preserves six complete dated records at their original paths, with a six-row integrity manifest: four annual validation CSVs, the pre-correction perennial selected-status JSON and hedgerow bulk-density diagnostics. Its bytes are unchanged. Corrected hedgerow root checks are in `analysis/current_perennial_root/saved_results/hedgerow_checks/`. [Root checks](docs/ROOT_MODEL_CHECKS.md) identify current and historical summaries. The [figure guide](figures/README.md#restore-the-saved-residual-renderer) explains restoration for the unchanged annual diagnostic image.