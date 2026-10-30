# Root-model sensitivity and diagnostics

The history/support ZIPs named below are unchanged inner members of [History_and_Support_2026-10-21.zip](../archive/History_and_Support_2026-10-21.zip). Extract the outer container, then the relevant inner ZIP into a separate copy. The numerical tables and diagnostic image below remain directly visible. Six complete diagnostic source records are preserved in the separate [Diagnostic_Results_2026-10-21.zip](../archive/Diagnostic_Results_2026-10-21.zip), including the annual source residuals. Extract it into a separate repository copy, preserving folders, before inspecting the records or using the saved-residual renderer. The [figure guide](../figures/README.md#restore-the-saved-residual-renderer) gives the restoration steps.

Historical stock-profile, orchard covariance and superseded figure files are now stored at their original relative paths inside the [history ZIP](../archive/History_and_Support_2026-10-21.zip). The ZIP manifest records their original sizes and hashes. Current analysis drivers and publication figure assets remain outside the history archive.

These detailed checks accompany the root-density results in the paper. Current hedgerow summaries incorporate the two author-confirmed mass corrections and the checks completed on 27 October 2026. Annual and orchard checks are unchanged. Earlier tables and the annual diagnostic image remain available here, with their original Supplemental Table S3 and Figure S2 labels. The 30 October repository synchronization copies saved results; it does not run a new analysis.

## Details retained from Statistical analysis

The 19 October 2026 editorial revision condensed the manuscript's Statistical analysis section. The implementation details below preserve the methods used for the existing results.

Models were fitted separately for each system and response in R 4.6.0 and 4.6.1 using glmmTMB. Annual models covered 0–100 cm; orchard and hedgerow models covered 0–75 cm. Management, categorical depth interval and their interaction were fixed effects, with a core random intercept for repeated depth increments. Non-root models used sum-to-zero contrasts for Type III tests. For Gamma responses, variance increases with the square of the fitted mean; residual variance was not modeled separately by management category.

### Root fits and test targets

Root-density models used Gamma distributions and log links, fitted by maximum likelihood, with constant dispersion within each model and no separate zero-inflation component. Samples with no recovered roots were retained. The modeled response was 1000 × (root dry mass [g] + 0.00017 g) / sampled soil volume [cm³], with the added mass applied to every observation before conversion to mg and volume normalization.

Root fixed effects used asymptotic Wald χ² tests. Management tests compared fitted log-density means with equal weighting across depth intervals; depth tests used equal weighting across management categories. Interaction coefficients were tested jointly. Within-depth and depth-averaged pairwise effects were ratios of fitted means for the constant-adjusted response, with 95% Wald confidence intervals. Depth-averaged contrasts used equal weights on the log scale. Within-depth contrasts were exploratory, and root contrasts were unadjusted for multiple testing. Depth tests compared sampled intervals using root mass per unit sampled soil volume.

Added-mass sensitivity used half to double 0.00017 g for annual fields (0.000085, 0.000170 and 0.000340 g). Orchard and hedgerow checks used 0.1, 0.5, 1, 2 and 10 times 0.00017 g, spanning 0.000017–0.0017 g. Each system retained the same samples and model structure across its sensitivity fits. Numerical convergence was checked, and residual diagnostics used DHARMa 0.5.0. The sections below retain the saved diagnostic settings and results.

### Other responses and follow-up tests

Current C-concentration models use Gamma distributions and log links. Δ¹⁴C and supporting bulk density use Gaussian errors and identity links. Their non-root fixed effects use Type III Wald χ² tests from car. emmeans supplies response-scale model means/SEs, pairwise contrasts and within-depth hedgerow joint tests. Pairwise effects are ratios for Gamma models and differences for Gaussian models. Model-based follow-ups use asymptotic reference distributions and remain unadjusted.

Current cumulative-stock inference uses one overall Welch ANOVA per system, with one observed value per core at 0–100 cm in annual fields and 0–75 cm in orchards and hedgerows. The selected branch has no 0–20 cm hedgerow test, pairwise follow-up or stock Holm adjustment. [The overall-stock module](../analysis/stock_omnibus_2026-10-21/) contains the three tests. Stock panels show observed means ±1 SE, not model EMMs. Stocks remain fixed-depth quantities without equivalent-soil-mass adjustment.

Figure brackets mark unadjusted within-depth pairwise model comparisons for roots, C concentration and Δ¹⁴C. The current hedgerow C-concentration/Δ¹⁴C brackets identify pairs rather than the earlier joint tests; those joint results remain supplied. Only p < 0.05 is marked, using up to three stars. Each stock panel marks only its selected overall endpoint comparison, labeled overall ns. Each management category has one field or field-margin location; cores describe within-location variation rather than field-level replication.

The earlier 20 October orchard Gamma(log)/core profile restoration reproduced the selected July values exactly. That prior selection is historical. Its exact driver and complete saved CSVs are retained under `analysis/nonroot_current/historical_cumulative_profile_2026-10-20/`; the current endpoint module is separate. Numerical reproduction does not validate the earlier cumulative-depth covariance assumptions.

## Annual-field sensitivity

Supplemental Table S3. Sensitivity of annual-field root-density comparisons to the added mass and adjustment for six within-depth comparisons.

The Gamma models used a log link, a management × categorical-depth interaction and a core random intercept. The corrected annual dataset contained 36 observations from six cores, including nine samples with no roots recovered. The response was 1000 × (root dry mass + c) / sampled soil volume, with mass in g and volume in cm³. The added mass c was applied to every observation.

### A. Constant-adjusted polyculture/monoculture ratios and unadjusted Wald tests

| Quantity | c = 0.000085 g | c = 0.000170 g | c = 0.000340 g |
| --- | --- | --- | --- |
| Equal-depth ratio (95% CI) | 9.21 (3.64–23.29) | 7.25 (2.88–18.23) | 5.71 (2.34–13.94) |
| Equal-depth p | 2.76 × 10⁻⁶ | 2.55 × 10⁻⁵ | 1.30 × 10⁻⁴ |
| Management × depth p | 0.0221 | 0.1274 | 0.3640 |
| 40–50 cm ratio (95% CI) | 42.58 (9.65–187.85) | 21.23 (5.33–84.53) | 11.09 (3.13–39.22) |
| 50–100 cm ratio (95% CI) | 29.79 (6.75–131.42) | 15.01 (3.78–59.71) | 8.00 (2.27–28.25) |

### B. Holm-adjusted p-values for within-depth comparisons

| Depth (cm) | c = 0.000085 g | c = 0.000170 g | c = 0.000340 g |
| --- | --- | --- | --- |
| 0–10 | 0.2150 | 0.1716 | 0.1373 |
| 10–20 | 0.1935 | 0.1493 | 0.1093 |
| 20–30 | 0.0869 | 0.0628 | 0.0429 |
| 30–40 | 0.0064 | 0.0042 | 0.0031 |
| 40–50 | 4.36 × 10⁻⁶ | 8.79 × 10⁻⁵ | 0.0011 |
| 50–100 | 3.70 × 10⁻⁵ | 6.00 × 10⁻⁴ | 0.0049 |

Ratios describe the constant-adjusted response. The equal-depth ratio is the exponentiated mean of six log field contrasts, not an integrated root-mass ratio. Confidence intervals are pointwise, approximate 95% Wald intervals. Holm adjustment was applied to the six depth tests separately within each constant scenario; it excludes the equal-depth and interaction tests. One field represented each management category, so management and field identity cannot be separated.

### Annual core-deletion sensitivity

Removing each whole core in turn gave 18 fits across the three constants. Every equal-depth ratio and its lower 95% Wald limit remained above one. At c = 0.00017 g, ratios ranged from 4.90 to 11.02. Within-depth precision was less stable: at the same constant, the Holm-adjusted 50–100 cm p-value was 0.0509 after removing LAHE.3, and the 30–40 cm p-value was 0.1187 after removing LAHE.5. These checks assess influence and do not provide additional independent replication.

## Root-model diagnostics

For each of the three constants, 2,000 simulations were evaluated in each of two modes: conditional on fitted core effects and with newly simulated core effects. Uniformity p-values ranged from 0.238 to 0.756, dispersion p-values from 0.395 to 0.840, and outlier p-values were 1. These non-rejections do not establish model adequacy. The adjusted observations cannot fall below 1000c/volume, yet simulations averaged 3.38–3.56 values below that floor per 36 observations. Only 0.3–1.95% of simulated datasets had none below it. This predictive mismatch limits interpretation of the Gamma estimates; the simulation frequencies are not calibrated hypothesis tests.

The analyzed 0–75 cm orchard root dataset contained 24 observations from six cores, including four recorded zeros. Saved Gamma sensitivity checks used 0.1, 0.5, 1, 2 and 10 times 0.00017 g. The orchard equal-depth comparison remained nonsignificant (unadjusted p = 0.1153–0.1491). At 0.00017 g, 1,000 conditional simulations gave uniformity p = 0.0705, dispersion p = 0.512 and outlier p = 1. Simulations averaged 1.17 values below the added-response floor per 24 orchard observations.

The corrected hedgerow dataset contained 36 observations from nine cores, including three recorded zeros. Root density was higher under the 30-year than the 10-year hedgerow when depths were weighted equally on the log scale (unadjusted p < 0.001 at all five added-mass settings). The overall management test remained significant at all five settings. The management × depth interaction was significant at 0.1, 0.5, 1 and 2 times 0.00017 g, but not at 10 times (p = 0.168). At the 0.00017 g addition, tests based on 1,000 conditional simulations gave uniformity p = 0.7431, dispersion p = 0.654 and outlier p = 1. The simulations averaged 2.61 values below the added-response floor per 36 observations.

Whole-core deletion checks were limited to annual fields.

The below-floor predictions remain a mismatch with the added-response support; the diagnostic p-values do not establish model adequacy. Pre-correction hedgerow results are retained as dated history and must not replace these corrected results.

## Annual residual diagnostic figure

![Conditional residual diagnostics for the corrected annual Gamma model](../figures/assets/Figure_S2.png)

Supplemental Figure S2. Residual diagnostics for the corrected annual Gamma model with 0.00017 g added before volume normalization. Scaled residuals use 2,000 conditional DHARMa simulations with fitted core effects held fixed and no refitting. Panels show, from left to right, the uniform Q–Q plot, residuals against fitted adjusted density (mg cm⁻³; logarithmic axis), and residuals by depth (top row); residuals by field, by core, and ordered within-core profiles (bottom row). Blue and brown shades denote monoculture and polyculture cores; open circles mark zero recovered root mass. The Q–Q reference is the identity line; dashed horizontal reference lines mark 0.5. Joined profiles use ordered depth categories, not proportional depth spacing, and are not an autocorrelation test.

## Data, results and code

- Annual models and added-mass sensitivity: [corrected annual Gamma module](../analysis/corrected_annual_gamma_2026-10-16/). Its saved `field_contrasts.csv` and `omnibus_wald_tests.csv` supply table A above.
- Annual diagnostics, six-depth Holm adjustment and whole-core deletion: [annual validation module](../analysis/corrected_annual_validation_2026-10-16/). `Holm_six_depth_comparisons.csv` remains in the module. The complete `leave_one_core_out_contrasts.csv`, `residual_tests.csv`, `below_floor_prediction_check.csv` and `residuals_by_sample.csv` are preserved at their original paths in the diagnostic-results ZIP linked above.
- Corrected hedgerow checks: [27 October saved checks](../analysis/current_perennial_root/saved_results/hedgerow_checks/), including five added-mass settings, conditional residuals and diagnostic provenance.
- Perennial sensitivity and conditional diagnostics: [current perennial root module](../analysis/current_perennial_root/), with the corrected working input, current combined orchard/hedgerow results and diagnostic settings. Orchard results are unchanged; old hedgerow results remain labeled history.
- Diagnostic rendering from saved residuals: the [support archive](../archive/History_and_Support_2026-10-21.zip) retains `figures/render_saved_annual_diagnostics.R` at its original path. Restore the helper and diagnostic-results ZIP into the same separate repository copy before use. This optional renderer runs no model fits or simulations; the current diagnostic PNG and all numerical summaries remain visible here.
- The publication workbook retains the unadjusted Table S1 contrasts, observed perennial profiles and current figure values. [REPRODUCIBILITY.md](../REPRODUCIBILITY.md) describes execution and software versions.

### Additional archived detail

The [run-support archive](../archive/History_and_Support_2026-10-21.zip) preserves unused optimizer/simulation caches, per-sample floor-detail files, optional diagnostic graphics and the two larger recovered perennial diagnostic/sensitivity JSON containers. The tables and figure above remain visible; the six diagnostic records, including source residuals, are in the diagnostic-results ZIP. Other published summary CSVs remain directly available. Restore the archive into a separate repository copy when inspecting the additional records or using optional cached-object plotters.
