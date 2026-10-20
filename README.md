# Farming Carbon: code and data

Code and data for *Soil Carbon Stocks and Radiocarbon Profiles in Three Agricultural Systems of California’s Central Valley*.

The current paper compares annual fields through 100 cm and orchards and hedgerows through 75 cm. Cumulative-stock inference uses Welch endpoint comparisons at 0–100 cm in annual fields, 0–75 cm in orchards, and 0–20 and 0–75 cm in hedgerows. All six hedgerow contrasts form one Holm family; their 95% Welch confidence intervals are unadjusted. The hedgerow C-concentration, cumulative-stock, radiocarbon and supporting bulk-density models were rerun on 19 October 2026 using the common four depth intervals. All 111 sample records and the historical analyses remain supplied. The current combined analysis input contains 96 records: 36 annual, 24 orchard and 36 hedgerow observations. The six deepest orchard and nine deepest hedgerow records remain in the full data table. The separate orchard covariance analysis is retained as a secondary archive and is excluded from the current manuscript and supplement. The repository contains the data and code used for this author-reviewed manuscript version.

## Start here

- [COVERAGE_MAP.md](COVERAGE_MAP.md) connects each paper figure, table and supplement item to its inputs, results and current code.
- [docs/ROOT_MODEL_CHECKS.md](docs/ROOT_MODEL_CHECKS.md) contains the detailed root-model sensitivity tables and residual diagnostics, formerly Table S3 and Figure S2 in the supplement.
- [data/Supplementary_Data.xlsx](data/Supplementary_Data.xlsx) contains the publication data, statistical tables, figure values and variable/source definitions. Its SHA-256 is `2f99d70b51f1859d6d3c72ed3d17e89bee715baa2671c906d809a95b6e9f339c`.
- [REPRODUCIBILITY.md](REPRODUCIBILITY.md) gives execution order, software setup and the verified-run status.
- [data/DATA_AVAILABILITY.md](data/DATA_AVAILABILITY.md) distinguishes original measurement records, corrected working spreadsheets and processed analysis inputs, including records that were not located.
- [CITATION.md](CITATION.md) identifies the associated unpublished manuscript without inventing a public DOI.

These commands check supplied files and saved arithmetic. They do not fit models or run simulations:

```sh
Rscript --vanilla scripts/check_repository.R
Rscript --vanilla scripts/check_saved_results.R
```

## Source qualifications

On 20 October 2026, the author confirmed retaining the 3.81 cm sampling diameter used in the calculations. The fitted cutting-tip dimension has not been independently verified. The author also approved retaining sample 108's 104.40 g field-moist bag mass as an estimate informed by neighboring B/C cores. Its original same-core measurement remains unverified. [DATA_AVAILABILITY.md](data/DATA_AVAILABILITY.md) and [CORRECTION_HISTORY.csv](data/CORRECTION_HISTORY.csv) preserve the source history.

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

The current root models use working dry masses with recorded zeros retained. The Gamma addition is made before volume normalization. Current perennial root analyses stop at 75 cm. Unadjusted contrasts and the separate annual six-test Holm sensitivity remain distinct. Each management category represents one field or margin, so these comparisons do not establish replicated management effects across independent fields.

The historical scientific archive is retained under `analysis/`. Its `selected_reference_2026-07-30/` folder preserves the earlier code/results and supports the unchanged C-concentration and Δ¹⁴C results. Current hedgerow results are under `analysis/hedgerow_0_75/`; the former five-interval hedgerow outputs remain identified as historical. Its older root-mass models, C:N analyses and orchard cumulative-stock interaction are not current paper results. Use the current entrypoints above. On 19 October, its README was labeled historical and one obsolete machine-specific input locator was replaced with the supplied relative path. The archive manifest and repository-wide checksums cover the saved files.

## Historical stock analyses

The earlier 20 October orchard Gamma(log)/core profile restoration reproduced the saved July results exactly. It has been superseded by the author-selected endpoint comparisons. The exact previous driver and complete saved CSVs are retained under `analysis/nonroot_current/historical_cumulative_profile_2026-10-20/`. The earlier orchard-only Welch record remains in `analysis/nonroot_current/historical_endpoint_2026-10-16/`; the current endpoint module reproduces that comparison alongside the other selected tests. The separate covariance/bootstrap workflow remains at `analysis/orchard_cumulative_correlation/run_new_reproduction.R` as a secondary archive, with its inputs, simulations and saved results.

## Preserved results and reruns

`outputs/` and `saved_results/` hold the identified reference results. The author-approved hedgerow depth revision updated current `analysis/nonroot_current/saved_results/` rows; the preceding files are preserved under its `historical_before_hedgerow75_2026-10-19/` folder. Other historical reference results remain unchanged. The portable perennial and orchard modules write to new output directories; other historical scripts should be executed only in a writable rerun copy, as described in REPRODUCIBILITY.md.

The orchard module includes all 999 original likelihood/fit classifications and the saved 20,000-dataset diagnostic. Original simulated response arrays and interactive checkpoint/RNG state were not retained. A new execution uses the recovered final method and is labeled a new reproduction. The secondary archive in `reproduction_2026-10-17/new_reproduction_all999_fit_audit.csv` records: 125 definite exceedances, 870 nonexceedances, three failed fits and one ambiguous comparison, with p-value bounds 0.126–0.130. The original classifications remain historical evidence.

The exact current S1 illustration and its caption are included. Its editable drawing source was not located. No diagram or missing observation was reconstructed by inference. See the figure README for the distinction between fixed publication assets, assembly and rendering from saved numerical results.

## Software

The tested package environment is recorded in `renv.lock`; original session/version records remain alongside each source analysis. Python figure dependencies are pinned in `reproducibility/python-requirements.txt`. Environment changes and numerical comparisons belong in the verified-run report, rather than changing the publication values to force agreement.

## License

Original project code is licensed under the [MIT License](LICENSE). Project data and numerical results are licensed under [CC BY 4.0](DATA_LICENSE). [LICENSING.md](LICENSING.md) defines the scope and attribution. Third-party software and Census boundary materials retain their own terms and source credits.
