# Paper, supplement and code coverage

Historical stock-profile, orchard covariance and superseded figure files are now stored at their original relative paths inside the [history ZIP](archive/Analysis_History_2026-10-20.zip). The ZIP manifest records their original sizes and hashes. Current analyses and publication assets remain outside the archive. Duplicate snapshots and optional plotters are in the separate [support ZIP](archive/Supporting_Files_2026-10-20.zip); restore it into a separate repository copy before running those helpers.

This map follows the current 30-page local paper, with its supplement on pages 29–30. The separate supplement has 3 pages including its identifying cover. Annual comparisons cover 0–100 cm; orchard and hedgerow comparisons cover 0–75 cm. The 19 October rerun changes only the affected hedgerow models and dependent outputs. The 17 October verification remains a dated record of the preceding analyses. The current stock comparisons use observed core endpoints with Welch tests; all six hedgerow pairwise tests share one Holm adjustment. The earlier stock-profile selection is historical. The separate covariance/bootstrap workflow remains a secondary archive outside the paper and supplement.

| Artifact | Current source and code | Coverage and bounds |
| --- | --- | --- |
| Table 1 | Corrected annual and current perennial root outputs; six C-concentration/Δ¹⁴C models in `analysis/nonroot_current/run_nonroot_analysis.R`; `analysis/stock_endpoints_2026-10-20/run_stock_endpoints.R` | Panel A contains root-density tests and 18 non-root Wald rows. Panel B contains eight Welch endpoint contrasts and observed mean ±SD summaries from three cores per field or margin. Hedgerow p values use one Holm family of six; all 95% Welch intervals are unadjusted. |
| Figure 1 | `figures/map/render_figure1.py`, published approximate vicinity points and unchanged Census 2023 state/county ZIPs | Recovered V4 output matches the current figure's decoded pixels. The fresh portable map render matches the publication pixels. Census source metadata and acknowledgement requirements are retained. Markers are not core coordinates. |
| Figure 2 | `figures/render_profile_figures.R`; unchanged annual root-display values, 24 fitted C-concentration/Δ¹⁴C means and 12 observed stock-profile means | Panels a/b/d retain their previous values, markers and pixels. Panel c shows observed cumulative-stock means ±1 sample SE, with no significance markers; endpoint tests are in Table 1B. |
| Figure 3 | `figures/render_profile_figures.R`; 24 observed root increments, 16 fitted C-concentration/Δ¹⁴C means and eight observed stock-profile means | Panel a shows observed core profiles; panels b/d retain fitted EMM ±1SE and unadjusted pairwise markers. Panel c shows observed stock means ±1SE without markers. All panels cover 0–75 cm. |
| Figure 4 | `figures/render_profile_figures.R`; 36 observed root increments, 24 fitted C-concentration/Δ¹⁴C means and 12 observed stock-profile means | All panels cover 0–75 cm. Panel a remains observed; panels b/d retain fitted EMM ±1SE and eight unadjusted joint tests. Panel c shows observed stock means ±1SE with no former joint-test stars. |
| Figure S1 | `figures/assets/Figure_S1.png` and `Figure_S1_caption.txt` | Exact current scientific illustration and approved caption preserved. The editable drawing source was not located; no replacement diagram was inferred. This does not prevent execution of the analyses. |
| Repository root diagnostic figure (former Figure S2) | `docs/ROOT_MODEL_CHECKS.md`; [support ZIP](archive/Supporting_Files_2026-10-20.zip), original member `figures/render_saved_annual_diagnostics.R`; `analysis/corrected_annual_validation_2026-10-16/outputs/residuals_by_sample.csv` | Retained in the repository rather than the current supplement. Draws the original-constant, conditional residual subset from saved simulations. It runs no simulations or fits. The fixed PNG and its full caption are preserved. |
| Repository root sensitivity tables (former Table S3) | `docs/ROOT_MODEL_CHECKS.md`; annual Gamma `omnibus_wald_tests.csv`, `field_contrasts.csv` and validation `Holm_six_depth_comparisons.csv`; existing annual scripts | Both full tables and their qualifications are retained in the repository rather than the current supplement. Three added-mass branches and the separate six-depth Holm sensitivity are supplied. Current unadjusted Table S1 values are not replaced by adjusted values. The earlier isolated fits, simulations and all 18 whole-core deletion scenarios reproduced the frozen annual tables. |
| Secondary archived orchard profile analysis | [History ZIP](archive/Analysis_History_2026-10-20.zip), original members under `analysis/orchard_cumulative_correlation/`, with 999 classifications, retained simulated responses and the 20,000-dataset diagnostic | The secondary archive records the completed 17 October run: 125 exceedances, 870 nonexceedances, three failed fits and one ambiguous comparison; bounds 0.126–0.130 and Monte Carlo envelope 0.1052–0.1515. The original run (bounds 0.124–0.129) remains historical. Original interactive RNG/checkpoint objects were not recovered; the new response matrix and classifications are retained. |
| Workbook Table S1 | Current annual and perennial root contrasts; current C-concentration/Δ¹⁴C pairwise and joint-test outputs | 74 rows: 66 pairwise contrasts and eight non-root hedgerow joint tests. Stock endpoint tests are reported separately. Unavailable perennial root joint tests are not invented. |
| Workbook Table S2 | Current C-concentration tests and supporting bulk-density analyses; `analysis/hedgerow_0_75/run_bulk_density_hedgerow75.R` supplies the revised hedgerow tests | 18 supporting rows. Annual and orchard rows are unchanged; six hedgerow C-concentration/bulk-density test rows are refreshed. |
| Workbook Endpoint Welch | `analysis/stock_endpoints_2026-10-20/saved_results/` | Ten endpoint group summaries and eight signed Welch contrasts, including sample SD, n, unadjusted 95% CIs and clearly labeled raw/Holm p values. The workbook has ten worksheets; all 111 sample records are retained. |
| Workbook figure values | Corrected annual fitted root means, current non-root fitted outputs and `analysis/stock_endpoints_2026-10-20/saved_results/stock_profile_summary.csv` | 108 records: 12 annual root EMMs, 64 non-stock EMMs and 32 observed stock means ±1SE. Model EMMs/SEs and observed means/SEs are distinguished. The separate observed sheets retain 60 root and 24 orchard stock increments. |
| Workbook sample data | `scripts/prepare_analysis_data.R`; twelve working source workbooks; `data/processed/`; current annual/perennial inputs | The data-only reconstruction matches the historical 111/105-row tables before the 18 annual working-mass changes, then matches all current workbook sample columns and root-module inputs. The full measurements and cumulative-stock calculations remain unchanged. Current model input excludes six deepest orchard and nine deepest hedgerow records, leaving 96 observations; all excluded measurements remain supplied. |
| Workbook dictionary/provenance | Current workbook's Data dictionary and Provenance sheets; `data/source_measurements/SOURCE_FILES.csv` | Existing variable definitions and historical source records are retained; current hedgerow-run provenance is appended. All twelve direct-input workbooks are supplied with their recorded hashes. Six CAMS reports, one partial EA result worksheet and four field/history records are added. `data/DATA_AVAILABILITY.md` identifies unavailable original records. |

## Current entrypoints

From the repository root:

```sh
Rscript --vanilla scripts/prepare_analysis_data.R . outputs_rerun/data_preparation
Rscript --vanilla analysis/nonroot_current/run_nonroot_analysis.R --run-analysis [NEW_OUTPUT_DIR]
Rscript --vanilla analysis/stock_endpoints_2026-10-20/run_stock_endpoints.R --run-analysis [NEW_OUTPUT_DIR]
python figures/map/render_figure1.py [NEW_OUTPUT_DIR]
Rscript --vanilla figures/render_profile_figures.R [NEW_OUTPUT_DIR]
```

Brackets indicate optional arguments, not literal shell syntax. The non-root analysis defaults to its new `outputs_rerun/` folder. Figure commands default to separate `figures/regenerated/` subfolders and refuse existing output directories. The perennial module exposes `read_perennial_root_input()` for input checks and an explicit `run_perennial_root_workflow()` call for future fits, sensitivities and diagnostics. Companion-module usage and dependencies are documented with those modules.

The optional orchard workflow is stored in the [history archive](archive/Analysis_History_2026-10-20.zip). Restore its original paths into a separate repository copy before using the historical command:

```sh
Rscript --vanilla analysis/orchard_cumulative_correlation/run_new_reproduction.R NEW_OUTPUT_DIR
```

It is excluded from the current manuscript and supplement.

## Current endpoint checks

The endpoint module verifies 96 analysis records, 30 endpoint observations, ten groups of three cores, eight Welch contrasts and 32 observed profile summaries. All twelve direct-input source hashes and the supplied layer/cumulative-stock arithmetic match. No profile models were refitted for this endpoint selection. Numerical agreement does not establish independent field replication.

## Earlier verification history

The new R and Python scripts parse. Saved non-root values were checked against the current workbook, and the default profile assembly reproduces Figures 2–4 in decoded pixels. The unchanged current map asset matches its recovered V4 source output. The original 84-file archive remains a historical record; its root-mass outputs and original 100-cm orchard cumulative interaction are historical. That earlier 20 October profile selection is now historical. Current stock inference uses the selected Welch endpoints; the exact former driver and CSVs are retained under `analysis/nonroot_current/historical_cumulative_profile_2026-10-20/`.

The isolated selected-analysis execution on 17 October is complete. Annual and retained non-root numerical tables reproduce exactly, perennial values agree at reported precision, and the new orchard bootstrap is documented separately from the archived result. On 19 October, the data-only reconstruction checked the supplied measurement workbooks, and the author-approved hedgerow scope change reran three non-root models and the supporting bulk-density model on 36 observations. The 19 October revision did not rerun annual, orchard or root models. The later 20 October restoration reran only the existing orchard cumulative-stock profile model and reproduced its July outputs exactly. Checked dependencies are recorded in the dependency-closed `renv.lock` and Python requirements file. Font and graphics-device differences can change regenerated layouts. The exact static publication assets remain available for comparison. MIT for original project code and CC BY 4.0 for project data/results are included. The data and code are publicly available at https://github.com/trinhanh59-lab/farming-carbon. Third-party Census source conditions are retained.

## Archived run detail

The [run-support archive](archive/Run_Support_History_2026-10-21.zip) contains the dated hedgerow non-root checkpoint, extra bulk-density outputs, unused model caches, run logs and detailed diagnostic payloads. Current publication tables and figure inputs remain at the paths listed above. Restore archive members into a separate repository copy when inspecting those historical records.
