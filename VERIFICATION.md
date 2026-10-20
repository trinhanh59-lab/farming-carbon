# Numerical reproduction check

Historical stock-profile, orchard covariance and superseded figure files are now stored at their original relative paths inside the [history ZIP](archive/Analysis_History_2026-10-20.zip). The ZIP manifest records their original sizes and hashes. Current analyses and publication assets remain outside the archive. Duplicate snapshots and optional plotters are in the separate [support ZIP](archive/Supporting_Files_2026-10-20.zip); restore it into a separate repository copy before running those helpers.

## Current endpoint selection, 20 October

The current non-root GLMMs cover C concentration and Δ¹⁴C only: six models, with 18 omnibus tests, 64 fitted means, 44 pairwise contrasts, 28 figure-marker tests and six diagnostic summaries. Those non-stock output fields are unchanged.

Cumulative stocks use the author-selected Welch endpoints: annual fields at 0–100 cm, orchards at 0–75 cm, and hedgerows at 0–20 and 0–75 cm. All six hedgerow contrasts share one Holm family; the reported 95% Welch intervals are unadjusted. Independent arithmetic checks agree with all eight tests. The 30 endpoint records, ten three-core groups and 32 observed stock means/SEs match the supplied inputs; all twelve direct-source hashes and existing stock calculations are preserved. No profile model was refitted for this selection.

The previous profile driver and complete CSVs remain under `analysis/nonroot_current/historical_cumulative_profile_2026-10-20/`. The workbook retains all 111 samples and now has ten sheets, including Endpoint Welch. Figure values distinguish 12 annual root EMMs, 64 non-stock EMMs and 32 observed stock means. Stock panels contain no old joint-test stars.

The endpoint `saved_results/source_sha256.csv` records the code used for the selected run. Current `reproducibility/FILE_CHECKSUMS.csv` records the cleanup versions. The data-preparation code changed only its optional-history cross-check; the calculated inputs and saved scientific results are unchanged.

## Author confirmations, 20 October

The author approved retaining the 3.81 cm sampling diameter and sample 108's 104.40 g neighboring-core estimate. The actual fitted cutting-tip dimension and original same-core mass have not been independently verified. Numerical checks establish agreement with these retained inputs; they do not verify their original measurements. No input value, code, analysis result or figure changed with this documentation update.

## Dated verification history

Hedgerow scope revision, 19 October 2026: annual fields are compared through 100 cm and orchards and hedgerows through 75 cm. Three hedgerow primary-response models and the supporting bulk-density model were rerun using 36 observations across nine cores. Their dependent paper, workbook and figure outputs are updated. Annual, orchard and root model results remain unchanged. All 111 measured records and the earlier five-interval hedgerow results remain supplied. The earlier 17 October numerical verification below is historical where superseded by this targeted revision. The separate orchard covariance/bootstrap analysis remains excluded from the current paper and supplement.

The selected analyses were executed in isolated local copies on 17 October 2026. That numerical synchronization updated the manuscript and former Table S4. The separate orchard covariance/bootstrap analysis was removed from the paper and supplement on 19 October 2026 and remains in the secondary archive. Measurements, workbook, figures and other reported results are unchanged.

| Component | Result |
| --- | --- |
| Annual roots, sensitivity, diagnostics, Holm and whole-core deletion | All 21 compared CSV files and Figure 2 display/significance CSVs reproduced byte for byte. |
| Orchard and hedgerow roots | Results agree at the paper's reported precision. The largest baseline confidence-limit difference was 6.01 × 10⁻⁷. Diagnostic p-values and below-floor counts reproduced. |
| Previous eight non-root models and endpoint Welch comparison, 17 October | All compared Wald, fitted-value, pairwise and marker rows reproduce exactly. Welch agrees at the precision saved in the reference. |
| Historical orchard cumulative-stock profile model, earlier 20 October | All three Wald rows, eight fitted means, four unadjusted ratios and diagnostic values reproduce the selected July values exactly. The 24 current orchard input rows match July. Only this model was rerun. |
| Three supporting bulk-density models | Nine Wald rows, 25 contrasts and three diagnostic rows reproduce exactly. |
| Scientific figures | Fresh map, profile assembly and S2 pixels match. Six fixed assets export exactly; eight separate non-root panels also render without clipping or data loss. |
| Orchard profile bootstrap | Observed LR and the 524/20,000 diagnostic count agree. The new bootstrap classifications differ, as detailed below. |

## Orchard comparison

The secondary orchard archive records the new execution: 125 definite exceedances, 870 nonexceedances, three failed fits and one ambiguous comparison among 999 datasets, giving p-value bounds of **0.126–0.130**. The conservative 95% Monte Carlo envelope is **0.1052–0.1515**; this is separate from the numerical p-value bounds. Infinite-shape selections number 671 for the full model and 682 for the null. The historical run had 123, 871, four and one, with bounds **0.124–0.129**. Both retain the same non-rejection conclusion. Both runs remain archived and are excluded from the current paper and supplement.

At index 516, a higher-likelihood finite OU full fit replaces a limiting-distribution fit and crosses the observed LR threshold. At index 911, the new RI full fit passes the unchanged numerical gates near a previously recorded but unvalidated higher likelihood; the row becomes usable. Nineteen rows change selected family or classification, with only these two changing failure/tail accounting. Boundary counts are retained separately for each run.

The original simulated arrays and interactive checkpoint state were not saved. Platform and numerical search history also differ, so identical original responses and optimizer history cannot be proved. The new run's simulated response matrix, observation order, fit classifications and comparison tables are retained under `analysis/orchard_cumulative_correlation/reproduction_2026-10-17/`. They are labeled simulated analysis records, distinct from field measurements. This run is retained as a secondary archived analysis.

## Environment and scope

The checked environment uses R 4.6.1, glmmTMB 1.1.15.2, emmeans 2.0.4, DHARMa 0.5.0 and Matrix 1.7-6. The annual archive recorded Matrix 1.7-5. The original non-root analysis used R 4.6.0 and earlier glmmTMB/emmeans versions. The orchard source used Linux/OpenBLAS; the new execution used macOS/R BLAS. Recorded original sessions remain alongside the frozen results; `renv.lock` and the Python requirements file record the checked environment.

The exact S1 illustration and approved caption are included, although its editable drawing source was not located. Numerical reproduction does not resolve the Gamma support mismatch, covariance-model concerns or the study's field-replication limits. The paper and supplement retain the concise root-model qualifications; [ROOT_MODEL_CHECKS.md](docs/ROOT_MODEL_CHECKS.md) preserves the full sensitivity tables, diagnostic figure and supporting notes formerly presented as S3 and S2.

MIT covers original project code, and CC BY 4.0 covers project data/results. Machine-readable comparisons are in `reproducibility/verification_summary.json`.

## Historical orchard stock selection, earlier 20 October

The author restored the existing July Gamma(log) cumulative-stock model over 0–75 cm, with depth-by-field fixed effects and a core random intercept. At that earlier checkpoint, the tables and Figure 3c used the profile model. It is now superseded by the selected endpoints. The earlier orchard-only endpoint record is preserved; its test is reproduced within the current all-system endpoint module. The isolated execution, settings, sample-linked residuals and session information are in `analysis/nonroot_current/orchard_stock_0_75_2026-10-20/`. Other model results and all measurements are unchanged. Reproduction does not validate the cumulative-depth covariance assumptions.
