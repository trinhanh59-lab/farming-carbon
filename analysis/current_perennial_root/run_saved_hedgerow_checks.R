# Repeat the author-selected checks from the supplied corrected hedgerow fit.
# Sourcing defines this function only. No model is fitted or simulated on source.

run_saved_hedgerow_checks <- function(module_dir, output_dir,
                                     sensitivity = TRUE, diagnostics = TRUE) {
  module <- normalizePath(module_dir, winslash = "/", mustWork = TRUE)
  source(file.path(module, "perennial_root_workflow.R"), local = TRUE)
  output <- validate_perennial_output_dir(module, output_dir)
  perennial_require_packages(diagnostics = diagnostics)
  saved <- readRDS(file.path(module, "saved_results", "hedgerow_fit_corrected.rds"))
  d <- saved$data
  stopifnot(nrow(d) == 36L, nlevels(d$core) == 9L,
            sum(d$root_weight == 0) == 3L,
            all(table(d$site_type, d$depth_factor) == 3L),
            isTRUE(saved$current$regular))
  expected <- read.csv(file.path(module, "input", "perennial_root_input.csv"),
                       stringsAsFactors = FALSE)
  expected <- expected[match(d$sample_code, expected$sample_code), , drop = FALSE]
  stopifnot(!anyNA(expected$sample_code), identical(d$sample_code, expected$sample_code),
            max(abs(d$root_weight - expected$root_weight)) < 1e-12,
            max(abs(d$root_weight_raw - expected$root_weight_raw)) < 1e-12,
            max(abs(d$volume_cm3 - expected$volume_cm3)) < 1e-10,
            d$root_weight[d$sample_code == "187_HRDY1_2_A1"] == 0.1952,
            d$root_weight[d$sample_code == "208_HRDY2_3_A2"] == 0.0199)
  current <- list(hedgerows = saved)
  # The 1x fit is reused; the sensitivity function fits only the other additions.
  # Residual simulations use the fitted core effects and refit = FALSE.
  sensitivity_result <- if (sensitivity) run_perennial_constant_sensitivity(current) else NULL
  diagnostic_result <- if (diagnostics) run_perennial_gamma_diagnostics(current) else NULL
  write_perennial_rerun(current, sensitivity_result, diagnostic_result, output)
  invisible(list(current = current, sensitivity = sensitivity_result,
                 diagnostics = diagnostic_result))
}
