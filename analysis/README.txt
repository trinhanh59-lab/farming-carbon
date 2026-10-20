CURRENT LAYOUT, 20 OCTOBER 2026

Current paper modules, source inputs and required July bulk-density files remain in the analysis folders. Optional stock checkpoints, selected older mixed-model files and the orchard covariance workflow are preserved at their original relative paths in ../archive/Analysis_History_2026-10-20.zip. Its FILE_MANIFEST.csv records original file hashes. The separate ../archive/Supporting_Files_2026-10-20.zip preserves duplicate snapshots, recovered perennial source cells, optional plotters and the two historical hedgerow scope-comparison tables. Original paths in the dated text below may be members of either archive. Current annual validation reads the canonical input in corrected_annual_gamma_2026-10-16/input/. Paths in the dated description below may refer to those archive members; the repository root README and REPRODUCIBILITY.md give current commands.

HISTORICAL ARCHIVE README, 16 OCTOBER 2026

The description below records the original 84-file archive. It predates the
portable perennial, non-root and orchard workflows added on 17 October.
For current code, data-preparation instructions and coverage, use the repository
root README.md, REPRODUCIBILITY.md and COVERAGE_MAP.md. Historical root-mass and C:N models are not current paper results.
Current cumulative-stock inference uses the observed endpoint Welch module,
stock_endpoints_2026-10-20. Current nonroot_current fits only C concentration
and radiocarbon (six models). The prior cumulative-profile driver and entire
saved CSVs are retained under nonroot_current/historical_cumulative_profile_2026-10-20/.
The description below remains a dated record, not the current selection.

Farming Carbon analysis resources
16 October 2026

This archive contains the corrected annual-root Gamma analysis and its saved checks. Historical analyses support the non-root results. A separate source extract records the current orchard and hedgerow root-density tests. The scientific analyses remain provisional.

CONTENTS

corrected_annual_gamma_2026-10-16
The corrected 36-row annual input, model code, fitted objects and saved contrasts. Added masses are 0.000085, 0.00017 and 0.00034 g before division by sampled soil volume. The original branch uses 0.00017 g. Six cores and nine no-recovery zeros are retained.

corrected_annual_validation_2026-10-16
Residual simulations, whole-core deletion checks and Holm adjustment across six annual depths. General diagnostic tests did not reject, but simulations produced adjusted responses below the known constant/volume floor. Gamma results therefore remain exploratory supporting evidence. Deep ratios and some depth comparisons remain sensitive.

selected_reference_2026-07-30
Historical inputs, code and selected outputs for non-root responses. Root rows in these files predate the October corrections and must not be used for current root results. The restoration copy is retained because its labeling and root-display behavior differ from the later script. Both versions contributed to the recorded output lineage.

figure2_review
The corrected annual panel's saved plot values and rendering code. This code draws panel A from the corrected outputs. It does not reconstruct the combined manuscript figure or certify the other panels.

observed_profile_figures
Rendering code and exact source tables for perennial root-density profiles (60 increments) and orchard cumulative C-stock profiles (24 increments), displayed by core over 0-75 cm. These panels show observed values without fitted means or statistical tests. Root-density displays use no added mass.

current_perennial_source
Exact code-cell extracts and selected saved outputs from Farming Carbon - Root density Tweedie models - 2026-10-14.ipynb. The source trace identifies the notebook hash and zero-based cells. Saved tests and contrasts use B_shift_gamma with the full categorical interaction, covering 24 orchard observations and 36 hedgerow observations at 0-75 cm. The 60 corresponding source records are included. These extracts depend on earlier notebook objects; current perennial fitted objects and a complete standalone rerun are not supplied. Historical July root outputs are not substitutes.

PATHS AND EXECUTION

Extract the archive and work from a writable copy. Model scripts write into their outputs directories and can replace files there. Preserve the supplied results before a rerun.

For the corrected annual analysis, run run_gamma_sensitivity.R before run_gamma_checks.R. The validation script reads the saved annual fits and contrasts. Plot scripts read saved CSVs. The historical non-root scripts read their bundled data directory. Path references were adapted to this folder layout; scientific model formulas and settings were retained. Only syntax and input-path checks were performed after these adaptations. No model or simulation was rerun.

R session files record the software used for the saved results. Earlier outputs used emmeans 2.0.3; corrected annual outputs used emmeans 2.0.4. The PNG plot scripts that specify quartz require macOS. A different graphics device needs a separate layout check.

One field or margin represents each management category. The comparisons cannot separate management from field identity. Equal-depth log averages are not integrated profile root mass. The orchard correlated-depth carbon-stock analysis remains an external dependency; its final code and inference are not included here.

FILE_MANIFEST.json lists the files in this resource and their hashes. No submission, public posting or final author approval is established by this archive.
