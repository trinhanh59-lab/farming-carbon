# Current non-root analysis

This module runs six selected GLMMs for C concentration and bulk-soil Δ¹⁴C. Annual fields cover 0–100 cm; orchards and hedgerows cover 0–75 cm. The unchanged input is `../../data/processed/sample_level_analysis_96_current.csv`: 36 annual, 24 orchard and 36 hedgerow observations. Deeper measurements remain in the full data and historical inputs.

`saved_results/` contains 18 omnibus tests, 64 fitted means, 44 pairwise contrasts, 28 figure-marker tests and six diagnostic summaries. All retained non-stock fields match the preceding tables. Cumulative-stock profile results and the exact previous driver are preserved under `historical_cumulative_profile_2026-10-20/`. Current stock inference and plotting summaries are in `../stock_endpoints_2026-10-20/`.

The formula remains `response ~ depth_cm * site_type + (1 | core)`. C concentration uses Gamma(log); Δ¹⁴C uses Gaussian(identity). Type III Wald tests, sum-to-zero contrasts and unadjusted emmeans follow-ups retain their selected settings. Gamma pairwise effects are ratios; Gaussian effects are differences. Model means and ±1SE intervals are on the response scale.

## Execution

Run from the repository root into a new output directory:

~~~sh
Rscript --vanilla analysis/nonroot_current/run_nonroot_analysis.R --run-analysis outputs_rerun/nonroot
Rscript --vanilla analysis/nonroot_current/run_nonroot_analysis.R --run-hedgerows75 outputs_rerun/hedgerow_nonroot
~~~

The first command fits all six current models. The bounded hedgerow command fits only C concentration and Δ¹⁴C. Both retain the selected 500-draw DHARMa diagnostics and save model objects, sample-linked residuals and session information. Supporting bulk density is run separately as described in `../hedgerow_0_75/README.md`. Output must be new and outside protected source/results folders; supplied results are not overwritten.

## Execution history

The 17 October isolated execution reproduced the then-current eight-model tables: 24 omnibus tests, 97 fitted means, 71 contrasts and 41 marker tests. Those counts describe the earlier five-interval hedgerow scope. `historical_before_hedgerow75_2026-10-19/` preserves the previous entrypoint and saved tables. The original July 30 analysis remains under `../selected_reference_2026-07-30/`.

The 19 October bounded execution completed the three restricted hedgerow fits with convergence code 0 and positive-definite Hessians. Diagnostic counts, seeds and p-values are supplied in `../hedgerow_0_75/nonroot_results/`. These checks describe fit behavior; they do not establish model validity or causal effects.

## Historical orchard 0–75 cm profile restoration, earlier 20 October

Historical command at the time of that run, not a current entrypoint:

~~~sh
Rscript --vanilla analysis/nonroot_current/run_nonroot_analysis.R --run-orchard-stock outputs_rerun/orchard_stock
~~~

The input contains 24 orchard observations from six cores, identical to the selected July stock inputs. The isolated 20 October execution and session record are in `orchard_stock_0_75_2026-10-20/`. The fitted depth-by-field pattern is supported (χ² = 15.57, p = 0.0014); the management term is not (p = 0.985), and no unadjusted within-depth contrast reaches p < 0.10. Figure 3c used response-scale fitted means ±1SE at that checkpoint. The current stock panels use observed means ±1SE. Successive cumulative depths share overlying increments, so numerical reproduction does not establish the adequacy of the model's covariance assumptions.
