#!/usr/bin/env Rscript
# Reproduce the three author-selected overall cumulative C-stock comparisons.
# Sourcing defines functions only. The explicit CLI flag runs the comparisons.

read_stock_omnibus_input <- function(input_csv) {
  d <- read.csv(input_csv, stringsAsFactors = FALSE, check.names = FALSE)
  required <- c("system", "endpoint_top_cm", "endpoint_bottom_cm", "management",
                "core", "sample_id", "sample_code", "cumulative_C_stock_t_C_ha")
  stopifnot(all(required %in% names(d)), nrow(d) == 21L,
            !anyNA(d[required]), !anyDuplicated(d$core),
            !anyDuplicated(d$sample_code), all(d$endpoint_top_cm == 0),
            all(is.finite(d$cumulative_C_stock_t_C_ha)),
            all(d$cumulative_C_stock_t_C_ha > 0))
  groups <- list(
    "annual vegetables" = c("monoculture", "polyculture"),
    orchards = c("20-year-old orchard", "60-year-old orchard"),
    hedgerows = c("bare field margin", "10-year-old hedgerow", "30-year-old hedgerow"))
  stopifnot(setequal(unique(d$system), names(groups)))
  for (system in names(groups)) {
    z <- d[d$system == system, , drop = FALSE]
    endpoint <- if (system == "annual vegetables") 100 else 75
    stopifnot(setequal(unique(z$management), groups[[system]]),
              all(z$endpoint_bottom_cm == endpoint),
              all(table(factor(z$management, levels = groups[[system]])) == 3L))
  }
  d
}

# Resolve existing ancestors before allowing a new output directory. Supplied
# inputs and saved results cannot be overwritten through a path or symlink.
stock_output_directory <- function(module_dir, output_dir) {
  module <- normalizePath(module_dir, winslash = "/", mustWork = TRUE)
  stopifnot(dir.exists(module), length(output_dir) == 1L,
            !is.na(output_dir), nzchar(output_dir))
  destination <- path.expand(output_dir)
  if (!grepl("^(/|[A-Za-z]:)", destination)) destination <- file.path(getwd(), destination)
  if (file.exists(destination) || dir.exists(destination))
    stop("Choose a new output directory.")
  pending <- character()
  while (!file.exists(destination) && !dir.exists(destination)) {
    parent <- dirname(destination)
    if (identical(parent, destination)) stop("Cannot resolve the output path.")
    pending <- c(basename(destination), pending)
    destination <- parent
  }
  if (!dir.exists(destination)) stop("Output parent is a file.")
  destination <- normalizePath(destination, winslash = "/", mustWork = TRUE)
  for (part in pending) {
    if (part == "..") destination <- dirname(destination)
    else if (part != ".") destination <- file.path(destination, part)
  }
  if (identical(destination, module) || startsWith(destination, paste0(module, "/")))
    stop("Choose an output directory outside the supplied analysis module.")
  destination
}

run_stock_omnibus <- function(module_dir, output_dir) {
  if (!requireNamespace("digest", quietly = TRUE) ||
      !requireNamespace("jsonlite", quietly = TRUE))
    stop("Install the recorded digest and jsonlite dependencies first.")
  module <- normalizePath(module_dir, winslash = "/", mustWork = TRUE)
  output <- stock_output_directory(module, output_dir)
  input_path <- file.path(module, "input", "stock_omnibus_observations.csv")
  observed <- read_stock_omnibus_input(input_path)
  systems <- c("annual vegetables", "orchards", "hedgerows")
  management_order <- c("monoculture", "polyculture", "20-year-old orchard",
                        "60-year-old orchard", "bare field margin",
                        "10-year-old hedgerow", "30-year-old hedgerow")
  observed <- observed[order(match(observed$system, systems),
                             match(observed$management, management_order),
                             observed$core), , drop = FALSE]
  rownames(observed) <- NULL
  summaries <- tests <- list()
  for (system in systems) {
    z <- observed[observed$system == system, , drop = FALSE]
    for (group in management_order[management_order %in% z$management]) {
      values <- z$cumulative_C_stock_t_C_ha[z$management == group]
      summaries[[length(summaries) + 1L]] <- data.frame(
        system = system, management = group, n = length(values),
        mean_t_C_ha = mean(values), SD_t_C_ha = sd(values),
        SE_t_C_ha = sd(values) / sqrt(length(values)))
    }
    # Welch ANOVA permits unequal group variances and gives one overall p value.
    # It uses one observed total per core and does not identify a specific pair.
    fit <- stats::oneway.test(cumulative_C_stock_t_C_ha ~ management,
                             data = z, var.equal = FALSE)
    tests[[length(tests) + 1L]] <- data.frame(
      system = system, F_statistic = unname(fit$statistic),
      numerator_df = unname(fit$parameter[1]),
      denominator_df = unname(fit$parameter[2]), p_value = fit$p.value,
      alpha = 0.05, statistically_significant = fit$p.value < 0.05,
      n_total_cores = nrow(z))
  }
  group_summary <- do.call(rbind, summaries)
  welch_anova <- do.call(rbind, tests)
  stopifnot(nrow(group_summary) == 7L, all(group_summary$n == 3L),
            nrow(welch_anova) == 3L)
  # Recheck the destination immediately before any write.
  output <- stock_output_directory(module, output)
  if (!dir.create(output, recursive = TRUE)) stop("Cannot create output directory.")
  write_exact <- function(x, filename) {
    for (name in names(x)) if (is.numeric(x[[name]]))
      x[[name]] <- format(x[[name]], digits = 17, trim = TRUE, scientific = FALSE)
    write.table(x, file.path(output, filename), sep = ",", row.names = FALSE,
                col.names = TRUE, quote = TRUE, na = "", fileEncoding = "UTF-8")
  }
  write_exact(observed, "stock_omnibus_observations.csv")
  write_exact(group_summary, "group_summary.csv")
  write_exact(welch_anova, "welch_anova.csv")
  provenance <- list(
    generated_at_UTC = format(Sys.time(), tz = "UTC", usetz = TRUE),
    method = "stats::oneway.test(cumulative_C_stock_t_C_ha ~ management, var.equal=FALSE)",
    endpoints_cm = list(annual = c(0, 100), orchards = c(0, 75), hedgerows = c(0, 75)),
    units = "t C ha^-1", unit_of_analysis = "One cumulative total per core; three cores per field or margin.",
    selection = "The author selected these endpoints and overall tests on 2026-10-21 after reviewing the earlier pairwise results.",
    multiplicity = "One overall test per system; no pairwise contrasts or Holm adjustment in this module.",
    input_sha256 = digest::digest(file = input_path, algo = "sha256", serialize = FALSE),
    code_sha256 = digest::digest(file = file.path(module, "run_stock_omnibus.R"),
                                 algo = "sha256", serialize = FALSE),
    R_version = R.version.string)
  jsonlite::write_json(provenance, file.path(output, "provenance.json"),
                       auto_unbox = TRUE, pretty = TRUE, digits = NA)
  writeLines(capture.output(sessionInfo()), file.path(output, "R_session_info.txt"))
  invisible(list(observations = observed, groups = group_summary, tests = welch_anova))
}

if (sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) != 2L || args[1] != "--run-analysis")
    stop("Use: Rscript --vanilla run_stock_omnibus.R --run-analysis NEW_OUTPUT_DIR")
  flag <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  stopifnot(length(flag) == 1L)
  module <- dirname(normalizePath(sub("^--file=", "", flag), mustWork = TRUE))
  run_stock_omnibus(module, args[2])
}
