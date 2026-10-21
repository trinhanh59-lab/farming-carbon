# Reproducing the selected analyses

Use a writable repository copy and new output directories. Preserve the supplied results before rerunning scripts that write into their own `outputs/` folders. The [history and support container](archive/History_and_Support_2026-10-21.zip) preserves the four original history ZIPs, module READMEs and method/environment ZIP without changing their bytes. Current analyses use the inputs and results retained in the main folders.

## Environment and saved-file checks

Use R 4.6.1 and the package versions in `renv.lock`. Restore them with `renv::restore(lockfile = "renv.lock", library = "PATH_TO_LOCAL_R_LIBRARY")`, then point `R_LIBS_USER` to that library when invoking Rscript. Install renv from CRAN first if needed. Original non-root records used R 4.6.0 and earlier glmmTMB/emmeans versions; those records remain archived. The perennial diagnostic code requires the recorded glmmTMB 1.1.15.2 and DHARMa 0.5.0 versions because it checks internal conditional-simulation behavior.

For Python figures, use a separate environment and install `reproducibility/python-requirements.txt`. The checked interpreter is Python 3.12.14 on darwin. Bundled Census boundaries allow the map renderer to work without downloading map data. The recorded import/distribution versions are:

| Import | Distribution | Version |
| --- | --- | --- |
| PIL | Pillow | 13.0.0 |
| matplotlib | matplotlib | 3.11.2 |
| numpy | numpy | 2.5.4 |
| pyproj | pyproj | 3.8.0 |
| shapefile | pyshp | 3.1.6 |
| shapely | shapely | 2.2.0 |

From the repository root:

```sh
Rscript --vanilla scripts/check_repository.R
Rscript --vanilla scripts/check_saved_results.R
```

The first checks file integrity, installed package names and R syntax without evaluating analysis code. The second checks current inputs, stock/volume/density arithmetic, saved contrasts, Holm adjustment and figure mappings without fitting models. Add `--archive` to check the historical orchard evidence inside the container:

```sh
Rscript --vanilla scripts/check_saved_results.R --archive
```

This extracts only the outer manifest and the original analysis-history ZIP to a temporary directory, checks that ZIP's size/MD5/SHA-256, then runs its unchanged historical checks. An explicit restored old ZIP also works: `Rscript --vanilla scripts/check_saved_results.R --archive PATH_TO_OLD_ZIP`. Ordinary checks do not read the optional container. The optional route accepts the current nine-payload container and the preceding eight-payload version; explicit restored history ZIPs remain supported.

## Prepare the inputs and annual-root results

```sh
Rscript --vanilla scripts/prepare_analysis_data.R . outputs_rerun/data_preparation
```

Preparation opens `data/Original_Source_Workbooks.zip` automatically, verifies its 23 members against the manifest and `SOURCE_FILES.csv`, and extracts them only to a temporary directory. It reads twelve working measurement spreadsheets and preserves their original root masses separately from recorded working-mass corrections. It rebuilds the full 111-record table, current 96-row input and inclusion flags, and compares them with the publication workbook. The retained diameter is the author-confirmed 3.81 cm. Sample 108 uses the author-approved 104.40 g neighboring-core estimate; neither confirmation independently verifies the original cutting-tip measurement or same-core mass. See [DATA_AVAILABILITY.md](data/DATA_AVAILABILITY.md) for source records, corrections and missing laboratory exports. Preparation creates CSVs and checks, not Word or Excel files.

Run the annual model before its validation script, which reads the selected saved fits and contrasts:

```sh
Rscript --vanilla analysis/corrected_annual_gamma_2026-10-16/run_gamma_sensitivity.R
Rscript --vanilla analysis/corrected_annual_validation_2026-10-16/run_gamma_checks.R
```

The annual selected-fit RDS remains active so validation can also run without a preceding new fit. Older preparation summaries, duplicate 105-row/current-input readbacks and verification narratives are preserved in the nested support archives. Their original paths identify archived snapshots, not additional measurements or current runtime inputs.

## Perennial root density

`analysis/current_perennial_root/` contains 24 orchard observations from six cores and 36 hedgerow observations from nine cores, all through 75 cm. Each system has four no-root-recovery observations. The active input is `input/perennial_root_input.csv`; notebook readbacks and original source cells remain archived. The source trace retains their hashes and locations. The recorded perennial environment is R 4.6.1 (2026-06-24), glmmTMB 1.1.15.2, emmeans 2.0.4, DHARMa 0.5.0 and jsonlite 2.0.0. Its original `source_cells_zero_based` values are `[0, 1, 30]`.

The response is `1000 * (root_weight + 0.00017) / volume_cm3`, in mg/cm³. The full management-by-depth model uses Gamma(log), a core random intercept, constant dispersion and no zero-inflation component. It is fitted by maximum likelihood. The original mass-scale starting fit and depth-specific conversion to density are retained; nlminb and BFGS use the original controls/agreement thresholds. The selected model is `B_shift_gamma`, not the older Tweedie alternatives named in the source notebook.

Sourcing defines functions without fitting or writing. To check inputs:

```r
module_dir <- "analysis/current_perennial_root"
source(file.path(module_dir, "perennial_root_workflow.R"))
input <- read_perennial_root_input(file.path(module_dir, "input", "perennial_root_input.csv"))
vapply(input, function(x) nrow(x$data), integer(1))
```

To rerun the selected workflow:

```r
result <- run_perennial_root_workflow(
  module_dir = module_dir,
  output_dir = "outputs_rerun/perennial",
  sensitivity = TRUE,
  diagnostics = TRUE
)
```

Output must be a new or empty directory outside the module, including aliases through symlinks. The path is checked before fitting and again before writing; supplied inputs/results/provenance are protected. `root_weight_raw` preserves the earlier subtraction, while `root_weight` is the working g mass. Sample `143_MAS2_3_A2` retains the corrected 0.0086 g working value and −1.4427 g raw subtraction, without a new correction or clipping.

Management/depth comparisons average fitted log means equally across intervals/groups. Pairwise effects are ratios of the constant-adjusted response with unadjusted p values and 95% Wald intervals, not integrated root-mass ratios. Five mass additions use 0.1, 0.5, 1, 2 and 10 times 0.00017 g. Conditional DHARMa diagnostics use 1,000 draws without refitting, with seeds 20261116 and 20261117 for orchard and hedgerow. Below-floor predictions are counted without clipping; these checks do not establish model adequacy. [ROOT_MODEL_CHECKS.md](docs/ROOT_MODEL_CHECKS.md) retains the detailed tables and figure. Original fitted objects/full simulation matrices were not retained; reruns produce new objects separately, while the supplied results remain the reference.

## C concentration and radiocarbon

`analysis/nonroot_current/` runs six models on the 96-row input: annual fields through 100 cm, orchards and hedgerows through 75 cm. The formula is `response ~ depth_cm * site_type + (1 | core)`. C concentration uses Gamma(log), and Δ¹⁴C uses Gaussian(identity). Type III Wald tests, sum-to-zero contrasts and unadjusted emmeans follow-ups retain the selected settings. Gamma effects are ratios, Gaussian effects are differences, and plotted model means ±1SE are on the response scale.

```sh
Rscript --vanilla analysis/nonroot_current/run_nonroot_analysis.R --run-analysis outputs_rerun/nonroot
Rscript --vanilla analysis/nonroot_current/run_nonroot_analysis.R --run-hedgerows75 outputs_rerun/hedgerow_nonroot
```

The first fits all six models; the second fits only the two current hedgerow responses. Both retain 500-draw DHARMa checks and save model objects, sample-linked residuals and session information. Output must be new and outside protected source/results folders. Current saved results contain 18 omnibus rows, 64 fitted means, 44 pairwise contrasts, 28 marker tests and six diagnostic summaries. Stock inference is separate below; earlier profile-model commands/results remain historical archive records.

## Hedgerow scope and supporting bulk density

All nine hedgerow cores contribute the common 0–10, 10–20, 20–50 and 50–75 cm intervals, giving 36 observations. The nine deeper measurements, with actual bottoms of 86, 88 or 100 cm, remain in the full 111-record table and historical input. Current/historical inclusion is explicit in `data/processed/sample_level_scope_111_current.csv`.

The bounded non-root command above and the supporting bulk-density command use separate new output directories:

```sh
Rscript --vanilla analysis/hedgerow_0_75/run_bulk_density_hedgerow75.R --run-analysis outputs_rerun/hedgerow_bulk_density
```

Bulk density uses Gaussian(identity) with the same depth-by-group interaction and core random intercept, retaining selected default optimizer controls. It uses convergence/Hessian checks without DHARMa simulations. `analysis/hedgerow_0_75/current_bulk_density/` combines current 0–75 cm hedgerow rows with unchanged annual/orchard support rows. The two equal-depth group summaries remain in `bulk_density_results/`; the other dated checkpoint outputs are archived. These bounded commands do not refit annual, orchard or root models.

The retained July bulk-density driver is `analysis/selected_reference_2026-07-30/code/run_bulk_density_aidee_wald.R`. It creates its `outputs/` folder when needed. Use a separate repository copy: it reproduces the original annual/orchard rows and the older 100 cm hedgerow reference, which must not replace current hedgerow results. The earlier three-response hedgerow checkpoint included a cumulative-stock profile fit; that is historical, not the current stock method.

## Observed carbon-stock endpoints

The current endpoint module uses one observed total per core: annual 0–100 cm, orchard 0–75 cm and hedgerow 0–20/0–75 cm, with three cores per group. These author-selected comparisons fit no stock-profile or sensitivity model:

```sh
Rscript --vanilla analysis/stock_endpoints_2026-10-20/run_stock_endpoints.R --run-analysis outputs_rerun/stock_endpoints
```

The script checks identities, endpoint depths, core counts, twelve source hashes and preserved layer/cumulative-stock arithmetic without changing measurements or supplied stocks. It saves 30 endpoint records, ten three-core group summaries and eight two-sided unpaired Welch comparisons. Differences are first group minus second group, in t C ha⁻¹. All six hedgerow p values share one Holm family; annual/orchard values are unadjusted. Every 95% interval is an unadjusted pointwise interval, not a simultaneous Holm interval.

`stock_profile_summary.csv` supplies 32 observed means, sample SDs and SEs with source core/sample identifiers. SE is SD/√3; plotted mean ±1SE is descriptive, not a fitted mean or confidence interval. Welch allows unequal variances; independence and approximate normality remain assumptions with three cores per field. One location represents each management category, so these comparisons describe sampled fields/margins rather than replicated field-level management effects. Selecting these endpoints changed no raw measurement, supplied stock calculation, source file, profile model or other analysis. New reruns continue to write `METHOD_SCOPE.txt` in their output directory.

## Figures and archived records

Use [figures/README.md](figures/README.md) for the map and profile renderers. The [diagnostic-results ZIP](archive/Diagnostic_Results_2026-10-21.zip) preserves four annual validation CSVs, the perennial selected-status JSON and current hedgerow bulk-density diagnostics at their original paths. Extract it into a separate repository copy before using the archived saved-residual renderer. [ROOT_MODEL_CHECKS.md](docs/ROOT_MODEL_CHECKS.md) retains the numerical summaries, and the [figure guide](figures/README.md#restore-the-saved-residual-renderer) gives the restoration commands. New annual/perennial/bulk-density runs still write their original diagnostic filenames. Rendering uses supplied tables without fitting models. The five publication images and root diagnostic image remain active; S1's editable drawing source was not located, so its exact image/caption are preserved.

[archive/README.md](archive/README.md) identifies the four inner ZIPs, 187 original records and original module guides. Restore the outer container and then the needed inner ZIP into a separate copy before using optional helpers. The separate orchard covariance/bootstrap workflow remains historical and excluded from the current paper/supplement. Current `reproducibility/PUBLICATION_TARGETS.json` identifies selected results and nested locations; `FILE_CHECKSUMS.csv` is the active integrity list. Dated hashes/source versions remain labeled history. Numerical reproduction checks agreement with supplied results; it does not recover missing original measurements or establish model validity.

## Original source workbook packaging

[Original_Source_Workbooks.zip](data/Original_Source_Workbooks.zip) contains the 23 complete source workbooks at their original `data/source_measurements/...` paths, plus a 23-row integrity manifest. Their bytes and original SHA-256 values are unchanged. This is current input data; the separate history/support container remains optional.

Preparation and endpoint source checks validate paths, regular files, sizes, SHA-256 and MD5 before using temporary extracted files. Temporary sources are cleaned on exit. Preparation still accepts an explicit loose source directory as its third `RAW_DIR` argument; both scripts also support the original restored directory layout when the source ZIP is absent. For manual inspection, extract the ZIP into a new directory, preserving folders. The loose source directory is then `NEW_DIRECTORY/data/source_measurements/`.

Saved source tables retain original semantic filenames and workbook hashes. A new endpoint run records the current preparation/endpoint code hashes, which differ only because of source-access packaging. The supplied `saved_results/source_sha256.csv` remains the dated selected-run record; current code identities are in `FILE_CHECKSUMS.csv`.

## Method records and map sources

The [history/support container](archive/History_and_Support_2026-10-21.zip) includes `reproducibility/Method_and_Environment_Records.zip`, which preserves five original method/environment records at their original paths, plus a size/SHA-256/MD5 manifest. The current instructions above retain their software and endpoint scope; the original files remain available for inspection.

The July 30 selected reference records `analysis/selected_reference_2026-07-30/data/sample_level_analysis_105.csv` as its input, with 105 rows and 21 cores. Sample 142 has Δ¹⁴C = −11.5; sample 143 has Δ¹⁴C = 13.2 and root weight 0.0086 g. That reference contains zero orchard 75–100 cm rows, uses a 0.00017 g root offset, records the pairwise adjustment as `none (Fisher LSD)`, and restricts orchards to 0–75 cm. These are dated reference settings; current sample scope and selected analyses are described above.

[Census_Basemaps_2023_500k.zip](figures/map/basemap/Census_Basemaps_2023_500k.zip) holds the original state and county ZIPs at their original `figures/map/basemap/...` paths, plus an integrity manifest. The map renderer verifies their recorded sizes/hashes and ZIP contents before creating its output directory, then reads shapefile components in memory. If the wrapper is absent, it also accepts the original two loose ZIPs in `figures/map/basemap/`. [Census credits and use limits](figures/map/THIRD_PARTY_MAP_SOURCES.md) still apply.

To inspect the method records, extract the history/support container into a separate directory, then extract its `reproducibility/Method_and_Environment_Records.zip` there. For Census sources, extract their wrapper into a separate directory. Preserve folders in either case. These bundles change access to existing records, not the measurements, statistical methods or map specifications.
