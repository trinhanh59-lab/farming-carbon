# Observed carbon-stock endpoints

The author selected two-sided, unpaired Welch comparisons of existing cumulative-stock totals: annual fields at 0–100 cm, orchards at 0–75 cm, and hedgerows at 0–20 and 0–75 cm. Each field contributes three core totals at each selected depth. No stock profile model is fitted.

Run from the repository root, writing to a new output directory:

~~~sh
Rscript --vanilla analysis/stock_endpoints_2026-10-20/run_stock_endpoints.R --run-analysis outputs_rerun/stock_endpoints
~~~

The script uses the existing 96-row analysis input. It checks sample identities, endpoint depths, core counts, the preserved layer/cumulative-stock arithmetic and the twelve direct-input source hashes. It does not change measurements or recalculate supplied stocks.

The six hedgerow pairwise p values form one Holm family across both depths. Annual and orchard p values are unadjusted. All reported 95% confidence intervals are unadjusted, pointwise intervals for first_group minus second_group. They are not simultaneous intervals corresponding to the Holm-adjusted p values.

`stock_profile_summary.csv` contains 32 observed means, sample SDs and SEs for the three stock-profile panels. Each SE is SD divided by the square root of three; the plotted mean ±1SE is descriptive and is not a confidence interval. Core/sample identifiers accompany each value. `endpoint_observations.csv` preserves the 30 records used in the eight comparisons.

Welch comparisons allow unequal variances. Independent core observations and approximate normality remain assumptions, with only three cores per field. These comparisons describe the sampled fields or field margins; one location represents each management category. Previous stock profile and endpoint analyses remain historical records elsewhere in the repository.
