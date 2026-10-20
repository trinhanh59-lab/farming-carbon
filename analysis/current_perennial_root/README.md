# Perennial root-density analysis

This module contains the orchard and hedgerow root-density analysis reported in the manuscript and Supplemental Material S1. It uses 24 orchard observations from six cores and 36 hedgerow observations from nine cores, all from 0–75 cm. Each system contains four recorded zero-root observations. The annual-root analysis is separate.

## Files

- `perennial_root_workflow.R`: input checks, the current Gamma model, Wald tests and contrasts, mass-addition sensitivity, conditional residual diagnostics and scientific residual plots.
- `input/perennial_root_input.csv`: the 60 modeled observations, including system, field, core, depth, working root mass and sampled volume.
- `input/perennial_notebook_input.json`: the previously archived mass, volume and observed-density readback, preserved without changes.
- `saved_results/`: frozen results recovered from the original saved notebook. These are supplied evidence, not results from executing the portable script.
- `provenance/`: source hashes, the selected analysis and recorded software versions.

`root_weight` is the working dry mass in g. `root_weight_raw` preserves the earlier subtraction for provenance. In sample `143_MAS2_3_A2`, the working mass is the previously corrected 0.0086 g; the raw subtraction was −1.4427 g. The model uses the working value, with no new correction or clipping.

## Model and interpretation

The response is `1000 * (root_weight + 0.00017) / volume_cm3`, in mg/cm³. The addition is made to every mass before volume normalization. The model uses Gamma errors with a log link, a full categorical management-by-depth interaction, a core random intercept, constant dispersion and no separate zero-inflation component. It is fitted by maximum likelihood. Both nlminb and BFGS are checked using the original controls and numerical-agreement thresholds.

The functions retain the original mass-scale Gamma starting fit and its exact depth-specific conversion to the density scale. This starting calculation does not choose among scientific models. The reported model remains the full density-scale Gamma model (`B_shift_gamma`). The original notebook's title and older cells mention Tweedie models; those historical analyses are not the selected analysis in this module.

Management comparisons average fitted log means equally across the four intervals. Depth comparisons average equally across management categories. Pairwise effects are ratios for the constant-adjusted response, with 95% Wald intervals and unadjusted p-values. They are not ratios of integrated profile root mass or replicated management effects across independent fields. Within-depth comparisons are exploratory.

The five mass additions are 0.1, 0.5, 1, 2 and 10 times 0.00017 g. They are sensitivity checks, not detection limits or values selected to obtain significance. Conditional DHARMa diagnostics use 1,000 simulations without refitting, with seeds 20261116 for orchards and 20261117 for hedgerows. Values simulated below the observation-specific added-response floor are counted without clipping. Non-rejection of the residual tests does not establish model adequacy; the saved results include this support mismatch.

## Use

Sourcing the script defines functions only. It does not install packages, fit models, simulate residuals or write results.

The saved runtime used R 4.6.1, glmmTMB 1.1.15.2, emmeans 2.0.4, DHARMa 0.5.0 and jsonlite 2.0.0. Package installation is a separate user step. The diagnostic function requires the recorded glmmTMB and DHARMa versions because its conditional-simulation verification inspects glmmTMB's internal simulation code.

From the repository root, inspect the input without fitting:

```r
module_dir <- "analysis/current_perennial_root"
source(file.path(module_dir, "perennial_root_workflow.R"))
input <- read_perennial_root_input(file.path(module_dir, "input", "perennial_root_input.csv"))
vapply(input, function(x) nrow(x$data), integer(1))
```

An explicit future rerun can use:

```r
result <- run_perennial_root_workflow(
  module_dir = module_dir,
  output_dir = "outputs_rerun/current_perennial_root",
  sensitivity = TRUE,
  diagnostics = TRUE
)
```

Before any fitting, the workflow normalizes the output path and requires a new or empty directory outside this module. Paths into the module, including its inputs, saved results and provenance, are rejected, including aliases through existing symlinks. The destination is checked again immediately before writing. A future rerun writes separate summaries, fitted objects, residual simulation objects, residual plots and session information to `outputs_rerun/` or another chosen directory. The supplied `saved_results/` files remain unchanged. Do not compare new p-values as literal byte-for-byte outputs across software or optimizer changes.

## Recovery status

The recovered notebook cell extracts and duplicate readbacks are preserved at their original `analysis/current_perennial_source/` paths in the [support archive](../../archive/Supporting_Files_2026-10-20.zip). The current portable code, inputs and saved results remain in this module.

The portable code was recovered and checked against the saved notebook and paper/S1. An isolated execution on 17 October 2026 then completed the selected fits, all five mass-addition scenarios and conditional diagnostics. Numerical changes were below the precision reported in the paper; diagnostic p-values and floor counts reproduced. The supplied reference results remain unchanged. See the repository verification report for the measured differences and checked environment.

The original fitted model objects and full 1,000-draw simulation matrices were not retained in the source archive. The isolated execution produced new fitted and simulation objects separately. The supplied results retain model-status summaries, tests, contrasts, per-observation residuals and below-floor probabilities. The exact methods and seeds are present for a future rerun. These missing historical objects are not missing analysis specifications.
