# Hedgerow analyses over 0–75 cm

The current hedgerow comparisons use four common intervals: 0–10, 10–20, 20–50 and 50–75 cm. All nine cores contribute each interval, giving 36 observations. The nine deeper measurements remain in the 111-row measurement table and historical 105-row analysis input. Their actual lower endpoints are 86, 88 or 100 cm; they are excluded from the current primary models rather than deleted.

`../../data/processed/sample_level_analysis_96_current.csv` combines these observations with the unchanged 36 annual and 24 orchard observations. `../../data/processed/sample_level_scope_111_current.csv` records historical and current inclusion for every measured sample. The annual and perennial root inputs remain unchanged.

## Models and saved results

`nonroot_results/` contains the three primary-response fits executed on 19 October 2026. The formula is `response ~ depth_cm * site_type + (1 | core)`. C concentration and cumulative C stock use Gamma(log); bulk-soil Δ14C uses Gaussian(identity). The optimizer retains `iter.max = 10000` and `eval.max = 10000`. Outputs include Type III Wald tests, response-scale means with SE, unadjusted pairwise contrasts and within-depth joint tests. Pairwise confidence intervals are 95%; plotted error bars are one SE. Gamma-model effects are ratios and Gaussian-model effects are differences. Figure symbols use the joint test within a depth.

`bulk_density_results/` contains the supporting Gaussian(identity) fit with the same interaction and core random intercept, retaining the selected default glmmTMB optimizer controls. It includes within-depth means, contrasts and joint tests, equal-depth group averages and contrasts, model status and the fitted object. `current_bulk_density/` combines updated hedgerow rows with byte-identical annual and orchard supporting rows from the selected reference. The reference files are unchanged.

`scope_comparison_omnibus.csv` compares the earlier five-interval and current four-interval tests. `scope_comparison_retained_means.csv` compares fitted means at shared intervals. These tables describe the scope change; they do not select another model.

All four fits returned convergence code 0 and positive-definite Hessians. Primary-model DHARMa diagnostics use 500 simulations, the selected pre-call seeds 7302038, 7302040 and 7302041, and the unchanged `simulateResiduals()` default `seed = 123`, `refit = FALSE`. The pre-call seed and the function's seed argument are distinct. The selected supporting bulk-density code used convergence and Hessian checks without DHARMa simulations, which is retained here. Session records give actual package versions.

The overall radiocarbon management test has p = 0.1289; the depth-by-management interaction has p = 0.0004002. Within-depth joint tests are supported at 0–10 and 50–75 cm. The unadjusted 10-year versus 30-year pair at 20–50 cm has p = 0.04864 despite an unsupported joint test at that depth. Both results are retained in the tables.

## Reproduce the bounded workflow

From the repository root, use separate new output directories:

```sh
Rscript --vanilla analysis/nonroot_current/run_nonroot_analysis.R --run-hedgerows75 outputs_rerun/hedgerow75/nonroot
Rscript --vanilla analysis/hedgerow_0_75/run_bulk_density_hedgerow75.R --run-analysis outputs_rerun/hedgerow75/bulk_density
```

These commands do not run root, annual or orchard models. Output paths are checked before fitting and must be new paths outside protected source, analysis, figure and reproducibility folders. No supplied result is overwritten.

The data-only entrypoint `../../scripts/prepare_analysis_data.R` reconstructs the working measurement tables and current scope from 12 source workbooks. It retains recorded corrections, checks the 96 selected rows and compares all 111 measurement records and current scope flags with the supplementary workbook. It does not fit models or create documents or workbooks. The 19 October checks are in `../../data/processed/preparation_validation_hedgerow75_2026-10-19.csv`.

`../../figures/render_hedgerow75_panels.R` draws Figure 4b–d from saved means and joint tests without fitting. Fixed current panels are in `../../figures/assets/current_panels/`; the assembly script retains the original root panel and legend pixels. The earlier Figure 4 is preserved with the historical non-root outputs.
