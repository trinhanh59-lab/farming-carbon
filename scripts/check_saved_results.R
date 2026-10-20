#!/usr/bin/env Rscript
# Verify preserved annual inputs, contrasts, Holm adjustment and Figure 2A values.
# This checks saved arithmetic and display mappings without fitting any model.
a <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
stopifnot(length(a) == 1L)
repo <- normalizePath(file.path(dirname(sub("^--file=", "", a)), ".."), mustWork = TRUE)
read_table <- function(relative) read.csv(file.path(repo, relative), stringsAsFactors = FALSE, check.names = FALSE)
d <- read_table("analysis/corrected_annual_gamma_2026-10-16/input/annual_corrected_root_profiles.csv")
stopifnot(nrow(d) == 36L, !anyDuplicated(d$sample_code), length(unique(d$core)) == 6L,
          sum(d$root_mass_current_g == 0) == 9L,
          abs(d$root_mass_current_g[d$sample_id == 54] - 0.0074) < 1e-12,
          max(abs(d$volume_cm3 - pi * 1.905^2 * (d$depth_bottom_cm-d$depth_top_cm))) < 1e-9,
          max(abs(d$root_density_mg_cm3 - 1000*d$root_mass_current_g/d$volume_cm3)) < 1e-12)
contrasts <- read_table("analysis/corrected_annual_gamma_2026-10-16/outputs/field_contrasts.csv")
stopifnot(nrow(contrasts) == 21L, all(table(contrasts$constant) == 7L),
          max(abs(exp(contrasts$log_poly_over_mono)-contrasts$poly_over_mono)) < 1e-8)
holm <- read_table("analysis/corrected_annual_validation_2026-10-16/outputs/Holm_six_depth_comparisons.csv")
for (constant in c("half", "original", "double")) {
  rows <- holm$constant == constant
  stopifnot(sum(rows) == 6L,
            max(abs(p.adjust(holm$p_unadjusted[rows], method = "holm")-holm$p_Holm_six_depths[rows])) < 1e-12)
}
# The plotted annual root means subtract the added density after Gamma fitting.
# Their SEs remain model-based; the plot is not a raw-density mean display.
fig <- read_table("analysis/figure2_review/figure2a_display_values.csv")
stopifnot(nrow(fig) == 12L, all(fig$constant == "original"),
          max(abs(fig$added_density_mg_cm3 - 1000*0.00017/fig$volume_cm3)) < 1e-12,
          max(abs(fig$display_mean - (fig$response-fig$added_density_mg_cm3))) < 1e-10,
          max(abs(fig$display_lower_one_SE - (fig$display_mean-fig$SE))) < 1e-10,
          max(abs(fig$display_upper_one_SE - (fig$display_mean+fig$SE))) < 1e-10)
cat("Preserved annual data, contrasts, six-test Holm families and Figure 2A mappings: PASS\n")
# The perennial input helper only reads and validates data when called here.
perennial <- new.env(parent = globalenv())
source(file.path(repo, "analysis/current_perennial_root/perennial_root_workflow.R"), local = perennial)
input <- perennial$read_perennial_root_input(file.path(repo, "analysis/current_perennial_root/input/perennial_root_input.csv"))
stopifnot(nrow(input$orchards$data) == 24L, nrow(input$hedgerows$data) == 36L)
diag <- read_table("analysis/current_perennial_root/saved_results/conditional_diagnostics.csv")
residual <- read_table("analysis/current_perennial_root/saved_results/conditional_residuals.csv")
stopifnot(nrow(diag) == 2L, nrow(residual) == 60L, all(diag$simulations == 1000L),
          all(diag$original_zeros == 4L), all(diag$outlier_p == 1))
for (system in c("orchards", "hedgerows")) {
  row <- diag[diag$system == system, ]
  sum_floor <- sum(residual$simulated_probability_below_added_floor[residual$system == system])
  target <- if (system == "orchards") 1.17 else 3.31
  stopifnot(abs(sum_floor-target) < 1e-10, abs(row$expected_below_added_floor-target) < 1e-10)
}
sensitivity <- read_table("analysis/current_perennial_root/saved_results/constant_sensitivity_tests.csv")
stopifnot(nrow(sensitivity) == 10L, all(sensitivity$stage == "B_shift_gamma"),
          all(sensitivity$structure == "full"), all(table(sensitivity$system) == 5L),
          setequal(sensitivity$multiplier, c(0.1, 0.5, 1, 2, 10)))
cat("Preserved perennial inputs, five constant scenarios and S1 floor counts: PASS\n")
# Check every preserved orchard simulation record without refitting likelihoods.
audit <- read_table("analysis/orchard_cumulative_correlation/saved_results/frozen_all999_fit_audit.csv")
stopifnot(nrow(audit) == 999L, ncol(audit) == 46L, identical(audit$index, seq_len(999L)),
          sum(audit$definite_exceedance) == 123L, sum(audit$definite_nonexceedance) == 871L,
          sum(audit$failed) == 4L, sum(audit$unresolved) == 5L,
          sum(audit$numerical_ambiguity) == 1L,
          identical(audit$unresolved, audit$failed | audit$numerical_ambiguity),
          sum(audit$full_kind == "LOGNORMAL_LIMIT", na.rm = TRUE) == 671L,
          sum(audit$null_kind == "LOGNORMAL_LIMIT", na.rm = TRUE) == 683L)
valid <- !audit$failed
stopifnot(max(abs(audit$LR[valid] - 2*(audit$full_LL[valid]-audit$null_LL[valid]))) < 1e-9)
counts <- c(sum(audit$definite_exceedance), sum(audit$definite_nonexceedance),
            sum(audit$failed), sum(audit$numerical_ambiguity))
stopifnot(sum(counts) == 999L, (counts[1]+1)/1000 == 0.124,
          (counts[1]+counts[3]+counts[4]+1)/1000 == 0.129)
cat("Frozen orchard 999-record likelihood arithmetic, classifications and boundary counts: PASS\n")
# Secondary archived covariance-analysis reference: the approved 17 October reproduction.
# These archived simulation checks do not select or validate the current endpoint Welch comparisons.
new_audit <- read_table("analysis/orchard_cumulative_correlation/reproduction_2026-10-17/new_reproduction_all999_fit_audit.csv")
stopifnot(nrow(new_audit) == 999L, sum(new_audit$definite_exceedance) == 125L,
          sum(new_audit$definite_nonexceedance) == 870L, sum(new_audit$failed) == 3L,
          sum(new_audit$numerical_ambiguity) == 1L,
          identical(new_audit$unresolved, new_audit$failed | new_audit$numerical_ambiguity),
          sum(new_audit$unresolved) == 4L,
          sum(new_audit$full_kind == "LOGNORMAL_LIMIT", na.rm = TRUE) == 671L,
          sum(new_audit$null_kind == "LOGNORMAL_LIMIT", na.rm = TRUE) == 682L)
new_valid <- !new_audit$failed
stopifnot(max(abs(new_audit$LR[new_valid] - 2*(new_audit$full_LL[new_valid]-new_audit$null_LL[new_valid]))) < 1e-9)
current_summary <- read_table("analysis/orchard_cumulative_correlation/reproduction_2026-10-17/new_reproduction_summary.csv")
new_counts <- c(sum(new_audit$definite_exceedance), sum(new_audit$definite_nonexceedance),
                sum(new_audit$failed), sum(new_audit$numerical_ambiguity))
stopifnot(sum(new_counts) == 999L, (new_counts[1]+1)/1000 == 0.126,
          (new_counts[1]+new_counts[3]+new_counts[4]+1)/1000 == 0.130,
          nrow(current_summary) == 1L, current_summary$bootstrap_p_lower == 0.126,
          current_summary$bootstrap_p_upper == 0.130,
          abs(current_summary$Monte_Carlo_95_lower-0.105236125639516) < 1e-12,
          abs(current_summary$Monte_Carlo_95_upper-0.151520977138336) < 1e-12)
publication <- jsonlite::fromJSON(file.path(repo, "reproducibility/PUBLICATION_TARGETS.json"))
stopifnot(publication$orchard_reference$classification_file ==
          "analysis/orchard_cumulative_correlation/reproduction_2026-10-17/new_reproduction_all999_fit_audit.csv",
          identical(as.numeric(publication$orchard_reference$p_value_bounds), c(0.126, 0.130)))
response_path <- file.path(repo, "analysis/orchard_cumulative_correlation/reproduction_2026-10-17/new_simulated_null_responses_999.rds")
responses <- readRDS(response_path)
stopifnot(is.matrix(responses), identical(dim(responses), c(24L, 999L)),
          all(is.finite(responses)), all(responses > 0))
cat("Secondary archived orchard covariance analysis, likelihood/count arithmetic, bounds and 24-by-999 simulated responses: PASS\n")
cat("The workbook is protected by the repository file checksums.\n")
cat("These checks verify saved arithmetic only; see VERIFICATION.md for execution status and scientific limits.\n")
