#!/usr/bin/env Rscript
# Verify current inputs and saved arithmetic. Use --archive for historical evidence.
# This checks saved arithmetic and display mappings without fitting any model.
a <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
stopifnot(length(a) == 1L)
repo <- normalizePath(file.path(dirname(sub("^--file=", "", a)), ".."), mustWork = TRUE)
args <- commandArgs(trailingOnly = TRUE)
usage <- "Usage: Rscript --vanilla scripts/check_saved_results.R [--archive [ARCHIVE_ZIP]]"
if (identical(args, "--help")) { cat(usage, "\n"); quit(status = 0L) }
if (length(args) > 2L || (length(args) > 0L && args[1] != "--archive")) stop(usage)
archive_mode <- length(args) > 0L
archive_path <- if (length(args) == 2L) path.expand(args[2]) else {
  combined <- file.path(repo, "archive/History_and_Support_2026-10-21.zip")
  if (file.exists(combined)) combined else
    file.path(repo, "archive/Analysis_History_2026-10-20.zip")
}

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
# Current non-root tables contain C concentration and radiocarbon only.
# Verify saved test arithmetic and display mappings without fitting these models.
omnibus <- read_table("analysis/nonroot_current/saved_results/nonroot_omnibus.csv")
plot_values <- read_table("analysis/nonroot_current/saved_results/nonroot_plot_values.csv")
pairwise <- read_table("analysis/nonroot_current/saved_results/nonroot_pairwise_contrasts.csv")
markers <- read_table("analysis/nonroot_current/saved_results/nonroot_plot_marker_tests.csv")
model_diag <- read_table("analysis/nonroot_current/saved_results/nonroot_model_diagnostics.csv")
current_responses <- c("c_percent", "del14c")
stopifnot(nrow(omnibus) == 18L, nrow(plot_values) == 64L,
  nrow(pairwise) == 44L, nrow(markers) == 28L, nrow(model_diag) == 6L,
  setequal(omnibus$response, current_responses),
  !anyDuplicated(omnibus[c("system", "response", "term")]),
  !anyDuplicated(plot_values[c("system", "response", "site_type", "depth_cm")]),
  all(pairwise$adjustment == "none"), all(markers$adjustment == "none"),
  all(is.finite(omnibus$statistic)), all(omnibus$df > 0),
  max(abs(stats::pchisq(omnibus$statistic, omnibus$df, lower.tail = FALSE) -
    omnibus$p_value)) < 1e-12,
  max(abs(plot_values$lower_one_se - (plot_values$estimate - plot_values$se))) < 1e-10,
  max(abs(plot_values$upper_one_se - (plot_values$estimate + plot_values$se))) < 1e-10)
for (system in c("annual vegetables", "orchards", "hedgerows")) {
  rows <- model_diag[model_diag$system == system, ]
  expected_n <- c("annual vegetables" = 36L, orchards = 24L, hedgerows = 36L)
  expected_cores <- c("annual vegetables" = 6L, orchards = 6L, hedgerows = 9L)
  stopifnot(nrow(rows) == 2L, setequal(rows$response, current_responses),
    all(rows$observations == expected_n[[system]]),
    all(rows$cores == expected_cores[[system]]))
}
cat("Current C-concentration/radiocarbon saved tests and figure mappings: PASS\n")

# Check the author-selected endpoint comparisons from one observed total per core.
# These are arithmetic checks of saved tests, not a new method or model selection.
current_data <- read_table("data/processed/sample_level_analysis_96_current.csv")
endpoint <- read_table("analysis/stock_endpoints_2026-10-20/saved_results/endpoint_observations.csv")
group_summary <- read_table("analysis/stock_endpoints_2026-10-20/saved_results/endpoint_group_summary.csv")
profile <- read_table("analysis/stock_endpoints_2026-10-20/saved_results/stock_profile_summary.csv")
welch <- read_table("analysis/stock_endpoints_2026-10-20/saved_results/endpoint_welch_contrasts.csv")
endpoint_markers <- read_table("analysis/stock_endpoints_2026-10-20/saved_results/endpoint_marker_tests.csv")
stopifnot(nrow(current_data) == 96L, !anyDuplicated(current_data$sample_code),
  nrow(endpoint) == 30L, nrow(group_summary) == 10L, nrow(profile) == 32L,
  nrow(welch) == 8L, nrow(endpoint_markers) == 8L,
  all(group_summary$n_cores == 3L), all(profile$n_cores == 3L),
  all(welch$n_first == 3L), all(welch$n_second == 3L),
  all(welch$alternative == "two.sided"), all(!welch$paired),
  all(abs(welch$conf_level - 0.95) < 1e-12))
matched <- match(endpoint$sample_code, current_data$sample_code)
stopifnot(!anyNA(matched),
  max(abs(endpoint$cumulative_C_stock_t_C_ha -
    current_data$cumulative_c_stock[matched])) < 1e-10,
  identical(endpoint$core, current_data$core[matched]),
  identical(endpoint$sample_id, current_data$sample_id[matched]),
  all(endpoint$endpoint_bottom_cm == current_data$nominal_depth_bottom_cm[matched]))
for (i in seq_len(nrow(profile))) {
  row <- profile[i, ]
  a <- current_data[current_data$system == row$system &
    current_data$site_type == row$management & current_data$depth_cm == row$depth_cm, ]
  observed <- a$cumulative_c_stock
  stopifnot(length(observed) == 3L,
    abs(row$mean_t_C_ha - mean(observed)) < 1e-10,
    abs(row$sd_t_C_ha - stats::sd(observed)) < 1e-10,
    abs(row$se_t_C_ha - stats::sd(observed)/sqrt(3)) < 1e-10,
    abs(row$lower_one_se_t_C_ha - (row$mean_t_C_ha-row$se_t_C_ha)) < 1e-10,
    abs(row$upper_one_se_t_C_ha - (row$mean_t_C_ha+row$se_t_C_ha)) < 1e-10)
}
for (i in seq_len(nrow(group_summary))) {
  row <- group_summary[i, ]
  a <- endpoint[endpoint$system == row$system &
    endpoint$management == row$management &
    endpoint$endpoint_bottom_cm == row$endpoint_bottom_cm, ]
  stopifnot(nrow(a) == 3L,
    abs(row$mean_t_C_ha-mean(a$cumulative_C_stock_t_C_ha)) < 1e-10,
    abs(row$sd_t_C_ha-stats::sd(a$cumulative_C_stock_t_C_ha)) < 1e-10)
}
for (i in seq_len(nrow(welch))) {
  row <- welch[i, ]
  a <- endpoint[endpoint$system == row$system &
    endpoint$endpoint_bottom_cm == row$endpoint_bottom_cm, ]
  x <- a$cumulative_C_stock_t_C_ha[a$management == row$first_group]
  y <- a$cumulative_C_stock_t_C_ha[a$management == row$second_group]
  variance_terms <- c(stats::var(x)/length(x), stats::var(y)/length(y))
  se_difference <- sqrt(sum(variance_terms))
  difference <- mean(x)-mean(y)
  statistic <- difference/se_difference
  degrees <- sum(variance_terms)^2 /
    sum(variance_terms^2/c(length(x)-1L, length(y)-1L))
  interval <- difference + c(-1,1) * stats::qt(0.975,degrees) * se_difference
  probability <- 2 * stats::pt(-abs(statistic),degrees)
  stopifnot(length(x) == 3L, length(y) == 3L,
    abs(row$first_mean_t_C_ha-mean(x)) < 1e-10,
    abs(row$second_mean_t_C_ha-mean(y)) < 1e-10,
    abs(row$difference_t_C_ha-difference) < 1e-10,
    abs(row$t-statistic) < 1e-10, abs(row$df-degrees) < 1e-10,
    abs(row$lower_95_t_C_ha-interval[1]) < 1e-10,
    abs(row$upper_95_t_C_ha-interval[2]) < 1e-10,
    abs(row$p_unadjusted-probability) < 1e-12)
}
hedgerow <- welch$system == "hedgerows"
stopifnot(sum(hedgerow) == 6L,
  max(abs(stats::p.adjust(welch$p_unadjusted[hedgerow], "holm") -
    welch$p_Holm_six_hedgerow_tests[hedgerow])) < 1e-12,
  max(abs(welch$p_reported[hedgerow] -
    welch$p_Holm_six_hedgerow_tests[hedgerow])) < 1e-12,
  max(abs(welch$p_reported[!hedgerow]-welch$p_unadjusted[!hedgerow])) < 1e-12,
  all(is.na(welch$p_Holm_six_hedgerow_tests[!hedgerow])),
  identical(endpoint_markers$p_reported,welch$p_reported),
  identical(endpoint_markers$symbol_reported_p,welch$symbol_reported_p))
if (!requireNamespace("jsonlite", quietly=TRUE)) stop("Install the recorded jsonlite dependency.")
publication <- jsonlite::fromJSON(file.path(repo,"reproducibility/PUBLICATION_TARGETS.json"))
counts <- publication$stock_endpoint_revision_2026_10_20
stopifnot(counts$comparisons == 8L, counts$endpoint_core_values == 30L,
  counts$group_summaries == 10L, counts$observed_profile_means == 32L,
  counts$hedgerow_Holm_family_tests == 6L)
cat("Current endpoint observations, profile means, eight Welch tests and six-test Holm family: PASS\n")

# Historical simulation evidence is optional. Only an explicit --archive call
# reads the ZIP. Extract the four requested data members and manifest to a new
# temporary directory; never write loose archive files into the repository.
check_archive <- function(zipfile) {
  zipfile <- normalizePath(zipfile,mustWork=TRUE)
  listing <- utils::unzip(zipfile,list=TRUE)
  entries <- listing$Name
  unsafe <- vapply(entries,function(entry) {
    parts <- strsplit(entry,"/",fixed=TRUE)[[1]]
    !nzchar(entry) || startsWith(entry,"/") ||
      grepl("^[A-Za-z]:",entry) || grepl("\\\\",entry) ||
      grepl("[[:cntrl:]]",entry) || any(parts %in% c("",".",".."))
  },logical(1))
  if (any(unsafe) || anyDuplicated(tolower(entries)))
    stop("Unsafe or duplicate archive member path; nothing was extracted.")
  needed <- c("FILE_MANIFEST.csv",
    "analysis/orchard_cumulative_correlation/saved_results/frozen_all999_fit_audit.csv",
    "analysis/orchard_cumulative_correlation/reproduction_2026-10-17/new_reproduction_all999_fit_audit.csv",
    "analysis/orchard_cumulative_correlation/reproduction_2026-10-17/new_reproduction_summary.csv",
    "analysis/orchard_cumulative_correlation/reproduction_2026-10-17/new_simulated_null_responses_999.rds")
  if (!all(needed %in% entries)) stop("The archive lacks required historical evidence.")
  unpacked <- tempfile("farming-carbon-archive-")
  if (!dir.create(unpacked)) stop("Cannot create isolated archive-check directory.")
  on.exit(unlink(unpacked,recursive=TRUE),add=TRUE)
  utils::unzip(zipfile,files=needed,exdir=unpacked)
  extracted <- file.path(unpacked,needed)
  resolved <- normalizePath(extracted,mustWork=TRUE)
  if (any(nzchar(Sys.readlink(extracted))) || any(file.info(extracted)$isdir) ||
      any(!startsWith(resolved,paste0(normalizePath(unpacked),"/"))))
    stop("Archive evidence must be regular files inside the isolated directory.")
  manifest <- read.csv(extracted[1],stringsAsFactors=FALSE)
  stopifnot(nrow(manifest)==86L,!anyDuplicated(manifest$path),
    setequal(c(manifest$path,"FILE_MANIFEST.csv"),entries))
  index <- match(needed[-1],manifest$path)
  stopifnot(!anyNA(index),
    identical(as.numeric(file.info(extracted[-1])$size),as.numeric(manifest$bytes[index])),
    identical(unname(tools::md5sum(extracted[-1])),manifest$md5[index]))
  read_table <- function(relative) read.csv(file.path(unpacked,relative),
    stringsAsFactors=FALSE,check.names=FALSE)
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
  response_path <- file.path(unpacked, "analysis/orchard_cumulative_correlation/reproduction_2026-10-17/new_simulated_null_responses_999.rds")
  responses <- readRDS(response_path)
  stopifnot(is.matrix(responses), identical(dim(responses), c(24L, 999L)),
            all(is.finite(responses)), all(responses > 0))
  cat("Secondary archived orchard covariance analysis, likelihood/count arithmetic, bounds and 24-by-999 simulated responses: PASS\n")

  invisible(TRUE)
}
# The combined container preserves the four original ZIP byte streams.
# Extract only the integrity manifest and the requested history ZIP, then reuse
# the unchanged historical arithmetic checks above. Explicit old ZIP paths work.
check_optional_archive <- function(zipfile) {
  zipfile <- normalizePath(zipfile, mustWork = TRUE)
  listing <- utils::unzip(zipfile, list = TRUE)
  entries <- listing$Name
  inner <- "archive/Analysis_History_2026-10-20.zip"
  if (!(inner %in% entries)) return(check_archive(zipfile))
  unsafe <- vapply(entries, function(entry) {
    parts <- strsplit(entry, "/", fixed = TRUE)[[1]]
    !nzchar(entry) || startsWith(entry, "/") ||
      grepl("^[A-Za-z]:", entry) || grepl("\\\\", entry) ||
      grepl("[[:cntrl:]]", entry) || any(parts %in% c("", ".", ".."))
  }, logical(1))
  if (any(unsafe) || anyDuplicated(tolower(entries)))
    stop("Unsafe or duplicate container member path; nothing was extracted.")
  if (!("FILE_MANIFEST.csv" %in% entries)) stop("The container lacks its integrity manifest.")
  unpacked <- tempfile("farming-carbon-container-")
  if (!dir.create(unpacked)) stop("Cannot create isolated container-check directory.")
  on.exit(unlink(unpacked, recursive = TRUE), add = TRUE)
  needed <- c("FILE_MANIFEST.csv", inner)
  utils::unzip(zipfile, files = needed, exdir = unpacked)
  extracted <- file.path(unpacked, needed)
  resolved <- normalizePath(extracted, mustWork = TRUE)
  if (any(nzchar(Sys.readlink(extracted))) || any(!file_test("-f", extracted)) ||
      any(!startsWith(resolved, paste0(normalizePath(unpacked), "/"))))
    stop("Container evidence must be regular files inside the isolated directory.")
  manifest <- read.csv(extracted[1], stringsAsFactors = FALSE)
  stopifnot(all(c("path", "bytes", "sha256", "md5") %in% names(manifest)),
    nrow(manifest) == 8L, !anyDuplicated(manifest$path),
    setequal(c(manifest$path, "FILE_MANIFEST.csv"), entries))
  index <- match(inner, manifest$path)
  stopifnot(!is.na(index),
    identical(as.numeric(file.info(extracted[2])$size), as.numeric(manifest$bytes[index])),
    identical(unname(tools::md5sum(extracted[2])), manifest$md5[index]))
  if (!requireNamespace("digest", quietly = TRUE)) stop("Package digest is required for the archive integrity check.")
  stopifnot(identical(digest::digest(file = extracted[2], algo = "sha256"), manifest$sha256[index]))
  cat("Combined container manifest and nested history ZIP integrity: PASS\n")
  check_archive(extracted[2])
}
if (archive_mode) {
  check_optional_archive(archive_path)
} else {
  cat("Historical orchard archive checks were not requested; use --archive to include them.\n")
}
cat("The workbook is protected by the repository file checksums.\n")
cat("These checks verify saved arithmetic only; see REPRODUCIBILITY.md for execution status and scientific limits.\n")
