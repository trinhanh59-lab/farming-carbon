# Reproducing the selected analyses

Optional historical analyses are preserved in the [history archive](archive/Analysis_History_2026-10-20.zip), with [restoration instructions](archive/README.md). Paths in the historical sections below are original archive-member paths. Current fitting and figure commands use the files retained in the main folders. The separate [support ZIP](archive/Supporting_Files_2026-10-20.zip) holds duplicate snapshots and optional plotters; restore it into a separate repository copy before using those helpers.

Use R 4.6.1 and the package versions in `renv.lock` for the checked environment. The original non-root records used R 4.6.0 and earlier glmmTMB/emmeans versions; those original records are preserved. An isolated rerun checks agreement with the supplied tables rather than assuming different software versions give identical results.

Restore R packages with `renv::restore(lockfile = "renv.lock", library = "PATH_TO_LOCAL_R_LIBRARY")`, then point `R_LIBS_USER` to that library when invoking Rscript. Install renv from CRAN first if needed. `scripts/check_repository.R` reports missing package names without installing them.

For Python figures, create a separate Python environment and install `reproducibility/python-requirements.txt`. The checked Python version is recorded in `reproducibility/PYTHON_ENVIRONMENT.txt`. Census boundary archives are bundled, so the map renderer does not download map data.

## Safe checks

Run from the repository root:

```sh
Rscript --vanilla scripts/check_repository.R
Rscript --vanilla scripts/check_saved_results.R
```

The first checks file integrity and parses R syntax without evaluating the source. The second checks current saved annual inputs, volume/density arithmetic, contrasts, Holm adjustment, Figure 2A display values and perennial inputs/floor counts. It does not load the optional orchard history by default. Use `Rscript --vanilla scripts/check_saved_results.R --archive` to include the saved historical orchard checks from the ZIP. These checks do not refit or validate a model; historical S4 labels refer to the 17 October record, not a table in the current PDF.

## Execution order

Start by reconstructing the current analysis inputs without fitting a model:

```sh
Rscript --vanilla scripts/prepare_analysis_data.R . outputs_rerun/data_preparation
```

The script reads the twelve working measurement spreadsheets in `data/source_measurements/`, preserves source root masses and applies the recorded working-mass corrections. It retains the author-confirmed 3.81 cm sampling diameter and the author-approved 104.40 g neighboring-core estimate for sample 108. These confirmations do not establish an independently measured cutting-tip dimension or the original same-core mass. It writes CSV files into a new directory and checks the rebuilt tables against the historical non-root inputs, current root inputs and publication workbook. It does not create Word or Excel files. See `data/DATA_AVAILABILITY.md` for the limits of the original records and `data/processed/` for the supplied current tables. Historical analysis inputs remain available at their existing paths.

1. Copy the repository to a writable rerun directory. Preserve the supplied `outputs/` folders before running historical scripts, because those scripts write there.
2. Run the annual Gamma script, then its validation script:

```sh
Rscript --vanilla analysis/corrected_annual_gamma_2026-10-16/run_gamma_sensitivity.R
Rscript --vanilla analysis/corrected_annual_validation_2026-10-16/run_gamma_checks.R
```

3. Source the perennial module in R and call its explicit workflow. See its README for input-only checking and output protections:

```r
module_dir <- "analysis/current_perennial_root"
source(file.path(module_dir, "perennial_root_workflow.R"))
run_perennial_root_workflow(module_dir, output_dir = "outputs_rerun/perennial")
```

4. Run the six selected C-concentration and Δ¹⁴C models into a new directory:

```sh
Rscript --vanilla analysis/nonroot_current/run_nonroot_analysis.R --run-analysis outputs_rerun/nonroot
```

5. Run the selected cumulative-stock endpoints into a new directory:

~~~sh
Rscript --vanilla analysis/stock_endpoints_2026-10-20/run_stock_endpoints.R --run-analysis outputs_rerun/stock_endpoints
~~~

The endpoint module uses one observed total per core at the selected depths. It runs eight two-sided Welch tests, adjusts all six hedgerow p values together by Holm, and saves unadjusted pointwise 95% intervals. It also saves 32 observed stock means ±1SE for plotting. It fits no profile models.

6. Use `figures/README.md` for publication-asset export, profile assembly, map reconstruction and saved-result plotting. Figure rendering/assembly does not itself refit the statistical models.


### Historical hedgerow 0–75 cm revision, 19 October

The current combined analysis input is `data/processed/sample_level_analysis_96_current.csv`. It preserves the annual 0–100 cm and orchard 0–75 cm observations and restricts hedgerows to the same four intervals through 75 cm. Full 111-record data and historical 105-row inputs remain supplied. The data-preparation entrypoint rebuilds these inputs without fitting models.

The current bounded non-root command fits only the two retained hedgerow responses, C concentration and Δ¹⁴C. Cumulative stocks use the endpoint module; the following bulk-density command remains separate:

```sh
Rscript --vanilla analysis/nonroot_current/run_nonroot_analysis.R --run-hedgerows75 outputs_rerun/hedgerow_nonroot
Rscript --vanilla analysis/hedgerow_0_75/run_bulk_density_hedgerow75.R --run-analysis outputs_rerun/hedgerow_bulk_density
```

The 19 October run fitted three hedgerow primary-response models and the supporting bulk-density model, with the existing model specifications. Its CSV results, fitted objects, diagnostics and session records are under `analysis/hedgerow_0_75/`. Other current output rows remain unchanged. Earlier five-interval hedgerow outputs remain labeled historical.

### Optional secondary archive

The separate orchard covariance/bootstrap workflow is excluded from the current paper and supplement. It is distinct from the current Welch endpoint comparisons. To reproduce that secondary archived analysis, first restore its original paths into a separate repository copy as described in `archive/README.md`, then use a new output directory:

```sh
Rscript --vanilla analysis/orchard_cumulative_correlation/run_new_reproduction.R outputs_rerun/orchard
```

This runs the observed fits, 20,000-dataset full-model diagnostic, 999 null-dataset refits and final boundary/tail audit. Its README explains why a fresh execution is a new method reproduction rather than recovery of the original interactive execution history. It retains failed and ambiguous outcomes.


## Earlier verification history

The 19 October 2026 editorial revision condensed Statistical analysis, moved Table 1 into Results and the bulk-density findings into the supplement, and preserved implementation details in [ROOT_MODEL_CHECKS.md](docs/ROOT_MODEL_CHECKS.md); no models or numerical results changed.

The author-approved hedgerow depth revision was executed on 19 October 2026 as described above. The preceding selected-analysis rerun completed on 17 October 2026. The annual and retained non-root tables reproduced exactly, and perennial results agreed at reported precision. The orchard observed LR and 20,000-dataset smoothness count agreed; its new bootstrap bounds are 0.126–0.130. This run is retained in the secondary archive and is excluded from the current manuscript and supplement. The original bounds of 0.124–0.129 remain labeled historical. See VERIFICATION.md and reproducibility/verification_summary.json for the comparisons. Numerical reproduction does not establish model adequacy or remove the paper's scientific limits.

The source measurements, correction provenance and recorded zero handling are unchanged. The 19 October revision removed the separate orchard covariance/bootstrap analysis and S4. An earlier 20 October revision restored the July Gamma(log) cumulative-stock profile model. That selection has now been superseded by the endpoint comparisons; its exact driver and complete saved CSVs remain in `analysis/nonroot_current/historical_cumulative_profile_2026-10-20/`. The later hedgerow 0–75 cm revision updates the affected models, Figure 4, tables, workbook and dependent text. That hedgerow revision preserved annual, orchard and root results. The later orchard-stock restoration is recorded below. The supplement revision changed organization and repeated front matter only. A subsequent language review made seven wording, grammar and spacing edits; no analyses were rerun and no numerical results changed. The detailed root-model checks are now documented in [ROOT_MODEL_CHECKS.md](docs/ROOT_MODEL_CHECKS.md), including the full former Table S3 and Figure S2; their code, saved results and image bytes are unchanged. The 17 October verification record retains its original checkpoint hashes, with the current document hashes recorded separately. The repository is https://github.com/trinhanh59-lab/farming-carbon. This execution history describes numerical checks; repository access and posting of the manuscript are separate distribution steps.

The earlier 19 October data-preparation check added source coverage and deterministic import checks. The subsequent hedgerow revision separately records its four targeted fits; it does not extend the unchanged models’ 17 October verification. The R lockfile now includes required transitive dependencies and the spreadsheet-reading packages used by the data-preparation script. Original package-author and software-license information is retained.

### Historical orchard stock profile restoration, earlier 20 October

Before selecting the current endpoint tests, the author selected the existing July Gamma(log) orchard cumulative-stock model through 75 cm. The current 24 orchard observations match the July stock inputs exactly. Only this model was rerun, reproducing all saved omnibus, fitted-value, unadjusted contrast and diagnostic numbers exactly.

The following is the historical command at the time of that run, not a current entrypoint:

~~~sh
Rscript --vanilla analysis/nonroot_current/run_nonroot_analysis.R --run-orchard-stock outputs_rerun/orchard_stock
~~~

The execution record is in `analysis/nonroot_current/orchard_stock_0_75_2026-10-20/`. Other current models and all measurements were preserved. The previous endpoint Welch result remains under `analysis/nonroot_current/historical_endpoint_2026-10-16/`; the separate covariance/bootstrap analysis remains a secondary archive.

## Current endpoint verification, 20 October

The current endpoint module and saved results are under `analysis/stock_endpoints_2026-10-20/`. All 30 endpoint records, ten three-core groups, eight Welch results and 32 observed profile summaries were verified in isolation. The existing orchard p value of 0.381241 was reproduced. All source measurements and non-stock model outputs are unchanged. Current `nonroot_current/saved_results/` contains 18 omnibus rows, 64 EMMs, 44 pairwise rows, 28 marker tests and six diagnostic summaries. The previous cumulative-profile driver and complete CSVs are preserved as dated history.
