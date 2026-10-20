# Farming Carbon: code and data

Code and data for the author-reviewed version of *Soil Carbon Stocks and Radiocarbon Profiles in Three Agricultural Systems of California’s Central Valley*.

The paper compares annual fields to 100 cm and orchards and hedgerows to 75 cm. Welch endpoint comparisons test cumulative stocks at 0–100 cm in annual fields, 0–75 cm in orchards, and 0–20 and 0–75 cm in hedgerows. The six hedgerow contrasts form one Holm family; their 95% Welch confidence intervals are unadjusted.

All 111 sample records are included. The current analysis input has 96 records: 36 annual, 24 orchard and 36 hedgerow observations. The six deepest orchard and nine deepest hedgerow records remain in the full data table. Historical analyses are preserved. The separate orchard covariance analysis is a secondary archive and is not used in the current manuscript or supplement.

## Start here

- [COVERAGE_MAP.md](COVERAGE_MAP.md) links each paper figure, table and supplement item to its inputs, results and current code.
- [docs/ROOT_MODEL_CHECKS.md](docs/ROOT_MODEL_CHECKS.md) contains the detailed root-model sensitivity tables and residual diagnostics, formerly Table S3 and Figure S2 in the supplement.
- [data/Supplementary_Data.xlsx](data/Supplementary_Data.xlsx) contains the publication data, statistical tables, figure values and variable/source definitions. Its SHA-256 is `2f99d70b51f1859d6d3c72ed3d17e89bee715baa2671c906d809a95b6e9f339c`.
- [REPRODUCIBILITY.md](REPRODUCIBILITY.md) gives run order, software setup and rerun status.
- [data/DATA_AVAILABILITY.md](data/DATA_AVAILABILITY.md) describes the original measurement records, corrected working spreadsheets and processed inputs, including records that were not located.
- [CITATION.md](CITATION.md) identifies the unpublished manuscript; no public DOI is supplied.

These commands check supplied files and saved arithmetic. They do not fit models or run simulations:

```sh
Rscript --vanilla scripts/check_repository.R
Rscript --vanilla scripts/check_saved_results.R
```

## Source qualifications

On 20 October 2026, the author confirmed using the 3.81 cm sampling diameter in the calculations. The fitted cutting-tip dimension has not been independently verified. The author also approved sample 108's 104.40 g field-moist bag mass as an estimate based on neighboring B/C cores. The original same-core measurement remains unverified. [DATA_AVAILABILITY.md](data/DATA_AVAILABILITY.md) and [CORRECTION_HISTORY.csv](data/CORRECTION_HISTORY.csv) document this history.

## Current analyses

| Component | Current code |
| --- | --- |
| Measurement workbooks to the full 111-sample table and current 96-row analysis input | `scripts/prepare_analysis_data.R` |
| Corrected annual root density and three added-mass scenarios | `analysis/corrected_annual_gamma_2026-10-16/run_gamma_sensitivity.R` |
| Annual diagnostics, whole-core deletion and six-depth Holm sensitivity | `analysis/corrected_annual_validation_2026-10-16/run_gamma_checks.R` |
| Orchard and hedgerow root density, five added-mass scenarios and conditional diagnostics | `analysis/current_perennial_root/perennial_root_workflow.R` |
| Six selected non-root models for C concentration and Δ¹⁴C | `analysis/nonroot_current/run_nonroot_analysis.R` |
| Restricted hedgerow rerun and supporting bulk-density analysis | `analysis/nonroot_current/run_nonroot_analysis.R --run-hedgerows75`; `analysis/hedgerow_0_75/run_bulk_density_hedgerow75.R` |
| Observed stock endpoints and mean ±SE profiles | `analysis/stock_endpoints_2026-10-20/run_stock_endpoints.R` |
| Publication figure assets and scientific rendering/assembly code | `figures/` |

The current root models use working dry masses, including recorded zeros. The Gamma addition is made before volume normalization. Current perennial root analyses stop at 75 cm. Unadjusted contrasts and the annual six-test Holm sensitivity are reported separately. Each management category was sampled in one field or margin; the comparisons do not establish replicated management effects across independent fields.

The hedgerow C-concentration, cumulative-stock, radiocarbon and supporting bulk-density models were rerun on 19 October 2026 using four common depth intervals. Results from that rerun are in `analysis/hedgerow_0_75/`. The cumulative-stock profile models are historical; current stock inference uses the endpoint comparisons above. The former five-interval hedgerow outputs are also historical.

Earlier code and results are preserved under `analysis/`. Its `selected_reference_2026-07-30/` folder supports the unchanged C-concentration and Δ¹⁴C results. Older root-mass models, C:N analyses and the orchard cumulative-stock interaction are not current paper results. Use the current code listed above. On 19 October, the archive README was labeled historical and one obsolete machine-specific input path was replaced with the supplied relative path. The archive manifest and repository-wide checksums cover the saved files.

## Historical stock analyses

The orchard Gamma(log)/core profile restoration on 20 October reproduced the saved July results exactly. The selected endpoint comparisons supersede it. The previous driver and complete saved CSVs are in `analysis/nonroot_current/historical_cumulative_profile_2026-10-20/`. The earlier orchard-only Welch record is in `analysis/nonroot_current/historical_endpoint_2026-10-16/`; the current endpoint module reproduces that comparison alongside the other selected tests. The separate covariance/bootstrap workflow remains at `analysis/orchard_cumulative_correlation/run_new_reproduction.R` as a secondary archive, with its inputs, simulations and saved results.

## Preserved results and reruns

Saved reference results are in `outputs/` and `saved_results/`. The approved hedgerow depth revision updated current rows in `analysis/nonroot_current/saved_results/`; preceding files are under its `historical_before_hedgerow75_2026-10-19/` folder. Other historical reference results are unchanged. The portable perennial and orchard modules write to new output directories. Run other historical scripts in a writable rerun copy, as described in REPRODUCIBILITY.md.

The orchard module includes all 999 original likelihood/fit classifications and the saved 20,000-dataset diagnostic. Original simulated response arrays and interactive checkpoint/RNG state were not retained. Reruns use the recovered final method and are labeled new reproductions. The secondary archive in `reproduction_2026-10-17/new_reproduction_all999_fit_audit.csv` records 125 definite exceedances, 870 nonexceedances, three failed fits and one ambiguous comparison, giving p-value bounds of 0.126–0.130. The original classifications remain historical evidence.

The current S1 illustration and caption are included. Its editable drawing source was not located. No diagram or missing observation was reconstructed by inference. See the figure README for details on fixed publication assets, assembly and rendering from saved numerical results.

## Software

`renv.lock` records the tested package environment. Original session/version records remain with each source analysis. Python figure dependencies are pinned in `reproducibility/python-requirements.txt`. Record environment changes and numerical comparisons in the verified-run report. Do not change publication values to force agreement.

## License

Original project code is licensed under the [MIT License](LICENSE). Project data and numerical results are licensed under [CC BY 4.0](DATA_LICENSE). [LICENSING.md](LICENSING.md) defines the scope and attribution. Third-party software and Census boundary materials retain their own terms and source credits.
