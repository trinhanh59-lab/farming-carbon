#!/usr/bin/env Rscript
# Author-selected cumulative-stock endpoint comparisons.
# This reads the existing stocks; it does not fit profile models or change data.
# R's stats package supplies Welch tests and Holm adjustment. digest records hashes.

options(stringsAsFactors = FALSE, digits = 17)
if (!requireNamespace("digest", quietly = TRUE)) {
  stop("Install the digest version recorded in the repository renv.lock.")
}
script_flag <- grep("^--file=", commandArgs(FALSE), value = TRUE)
stopifnot(length(script_flag) == 1L)
script <- normalizePath(sub("^--file=", "", script_flag), mustWork = TRUE)
repository <- normalizePath(file.path(dirname(script), "..", ".."), mustWork = TRUE)
args <- commandArgs(TRUE)
if (length(args) < 1L || args[1] != "--run-analysis" || length(args) > 2L) {
  stop("Use --run-analysis [NEW_OUTPUT_DIR]. Only the selected endpoints are tested.")
}
output <- if (length(args) == 2L) path.expand(args[2]) else
  file.path(repository, "outputs_rerun", "stock_endpoints")
if (!grepl("^(/|[A-Za-z]:[/\\\\])", output)) output <- file.path(getwd(), output)
if (file.exists(output) || dir.exists(output)) stop("Choose a new output directory.")
# Resolve the existing ancestor before allowing any write.
ancestor <- output
tail <- character()
while (!dir.exists(ancestor)) {
  stopifnot(dirname(ancestor) != ancestor, !file.exists(ancestor))
  tail <- c(basename(ancestor), tail)
  ancestor <- dirname(ancestor)
}
resolved <- normalizePath(ancestor, mustWork = TRUE)
for (part in tail) {
  if (part == ".") next
  resolved <- if (part == "..") dirname(resolved) else file.path(resolved, part)
}
protected <- file.path(repository, c("data", "analysis", "figures", "reproducibility"))
if (identical(resolved, repository) ||
    any(vapply(protected, function(p) identical(resolved, p) ||
      startsWith(resolved, paste0(p, "/")), logical(1)))) {
  stop("Output must be outside protected source and frozen-result folders.")
}
if (!dir.create(output, recursive = TRUE)) stop("Cannot create output directory.")

# CSV writing retains 17 significant digits; display rounding belongs in tables.
write_exact <- function(x, filename) {
  for (name in names(x)) if (is.numeric(x[[name]])) {
    value <- x[[name]]
    x[[name]] <- ifelse(is.na(value), NA_character_,
      format(value, digits = 17, trim = TRUE, scientific = FALSE))
  }
  write.table(x, file.path(output, filename), sep = ",", row.names = FALSE,
    col.names = TRUE, quote = TRUE, na = "", fileEncoding = "UTF-8")
}
sha256 <- function(path) digest::digest(file = path, algo = "sha256", serialize = FALSE)
read_input <- function(relative) read.csv(file.path(repository, relative),
  check.names = FALSE, stringsAsFactors = FALSE)
input_relative <- "data/processed/sample_level_analysis_96_current.csv"
d <- read_input(input_relative)
full <- read_input("data/processed/sample_level_full_111_current.csv")
stopifnot(nrow(d) == 96L, nrow(full) == 111L, !anyDuplicated(d$sample_code),
  !anyDuplicated(d$sample_id), length(unique(d$core)) == 21L)
stopifnot(all(is.finite(d$cumulative_c_stock)), all(d$cumulative_c_stock > 0))

systems <- c("annual vegetables", "orchards", "hedgerows")
depths <- list(
  "annual vegetables" = c("0-10", "10-20", "20-30", "30-40", "40-50", "50-100"),
  orchards = c("0-10", "10-20", "20-50", "50-75"),
  hedgerows = c("0-10", "10-20", "20-50", "50-75")
)
groups <- list(
  "annual vegetables" = c("monoculture", "polyculture"),
  orchards = c("20-year-old orchard", "60-year-old orchard"),
  hedgerows = c("bare field margin", "10-year-old hedgerow", "30-year-old hedgerow")
)
# Verify one sample per core/depth and three cores per field at every used depth.
for (system in systems) {
  a <- d[d$system == system, ]
  stopifnot(setequal(unique(a$depth_cm), depths[[system]]))
  stopifnot(setequal(unique(a$site_type), groups[[system]]))
  stopifnot(!anyDuplicated(paste(a$core, a$depth_cm)))
  stopifnot(all(table(a$site_type, a$depth_cm) == 3L))
}

# Check the existing stock arithmetic without replacing any supplied value.
stopifnot(max(abs(d$layer_c_stock -
  d$c_percent * d$bulk_density * d$depth_total_cm)) < 1e-10)
stopifnot(max(abs(d$bulk_density -
  d$total_dry_soil_g / d$volume_cm3)) < 1e-12)
stopifnot(max(abs(d$volume_cm3 -
  pi * 1.905^2 * d$depth_total_cm)) < 1e-9)
for (core in unique(d$core)) {
  a <- d[d$core == core, ]
  a <- a[order(a$nominal_depth_top_cm), ]
  stopifnot(max(abs(cumsum(a$layer_c_stock) - a$cumulative_c_stock)) < 1e-10)
}
matched <- match(d$sample_code, full$sample_code)
stopifnot(!anyNA(matched))
for (name in c("sample_id", "core", "site_type", "depth_cm",
    "c_percent", "layer_c_stock", "cumulative_c_stock")) {
  stopifnot(identical(d[[name]], full[[name]][matched]))
}

# Preserve the 12 direct-input source identities recorded by data preparation.
source_manifest_relative <- "data/processed/source_measurement_manifest.csv"
source_manifest <- read_input(source_manifest_relative)
stopifnot(nrow(source_manifest) == 12L)
raw_relative <- paste0("data/source_measurements/", source_manifest$file)
# Open original source workbooks from the current ZIP, or an explicitly supplied
# legacy directory. Only temporary files are extracted; source bytes stay intact.
resolve_source_workbooks <- function(repository, raw_dir = NULL) {
  if (!is.null(raw_dir)) {
    path <- normalizePath(raw_dir, mustWork = TRUE)
    if (!dir.exists(path)) stop("RAW_DIR must be an existing source directory.")
    return(list(directory = path, cleanup = NULL))
  }
  archive <- file.path(repository, "data/Original_Source_Workbooks.zip")
  if (!file.exists(archive)) {
    path <- normalizePath(file.path(repository, "data/source_measurements"), mustWork = TRUE)
    if (!dir.exists(path)) stop("The source ZIP or restored source directory is required.")
    return(list(directory = path, cleanup = NULL))
  }
  expected <- read.csv(file.path(repository, "data/source_measurements/SOURCE_FILES.csv"),
    stringsAsFactors = FALSE, check.names = FALSE)
  stopifnot(nrow(expected) == 23L, !anyDuplicated(expected$file),
    all(startsWith(expected$file, "data/source_measurements/")),
    all(grepl("\\.xlsx$", expected$file)))
  entries <- utils::unzip(archive, list = TRUE)$Name
  unsafe <- vapply(entries, function(entry) {
    parts <- strsplit(entry, "/", fixed = TRUE)[[1]]
    !nzchar(entry) || startsWith(entry, "/") ||
      grepl("^[A-Za-z]:", entry) || grepl("\\\\", entry) ||
      grepl("[[:cntrl:]]", entry) || any(parts %in% c("", ".", ".."))
  }, logical(1))
  if (any(unsafe) || anyDuplicated(tolower(entries)))
    stop("Unsafe or duplicate source ZIP member path; nothing was extracted.")
  if (!setequal(entries, c("FILE_MANIFEST.csv", expected$file)))
    stop("The source ZIP must contain exactly the 23 recorded workbooks and manifest.")
  temporary <- tempfile("farming-carbon-sources-")
  if (!dir.create(temporary)) stop("Cannot create isolated source directory.")
  success <- FALSE
  on.exit(if (!success) unlink(temporary, recursive = TRUE), add = TRUE)
  utils::unzip(archive, files = c("FILE_MANIFEST.csv", expected$file), exdir = temporary)
  extracted <- file.path(temporary, c("FILE_MANIFEST.csv", expected$file))
  resolved <- normalizePath(extracted, mustWork = TRUE)
  if (any(nzchar(Sys.readlink(extracted))) || any(!file_test("-f", extracted)) ||
      any(!startsWith(resolved, paste0(normalizePath(temporary), "/"))))
    stop("Source ZIP members must be regular files inside the temporary directory.")
  manifest <- read.csv(extracted[1], stringsAsFactors = FALSE, check.names = FALSE)
  stopifnot(all(c("path", "bytes", "sha256", "md5") %in% names(manifest)),
    nrow(manifest) == 23L, !anyDuplicated(manifest$path),
    setequal(manifest$path, expected$file))
  index <- match(expected$file, manifest$path)
  paths <- extracted[-1]
  actual_sha <- vapply(paths, function(path)
    digest::digest(file = path, algo = "sha256", serialize = FALSE), character(1))
  stopifnot(identical(as.numeric(file.info(paths)$size), as.numeric(expected$bytes)),
    identical(as.numeric(manifest$bytes[index]), as.numeric(expected$bytes)),
    identical(unname(actual_sha), expected$sha256),
    identical(manifest$sha256[index], expected$sha256),
    identical(unname(tools::md5sum(paths)), manifest$md5[index]))
  # Keep the token alive for the script; cleanup also runs on normal/error exit.
  cleanup <- new.env(parent = emptyenv())
  cleanup$directory <- temporary
  reg.finalizer(cleanup, function(token) unlink(token$directory, recursive = TRUE), onexit = TRUE)
  success <- TRUE
  list(directory = file.path(temporary, "data/source_measurements"), cleanup = cleanup)
}

source_inputs <- resolve_source_workbooks(repository)
raw_paths <- file.path(source_inputs$directory, source_manifest$file)
stopifnot(all(file.exists(raw_paths)))
raw_sha <- vapply(raw_paths, sha256, character(1))
stopifnot(identical(unname(raw_sha), source_manifest$sha256))
stopifnot(identical(as.numeric(file.info(raw_paths)$size),
  as.numeric(source_manifest$bytes)))

# Means and sample SD describe the three observed cores, not fitted model means.
profile <- do.call(rbind, lapply(systems, function(system) {
  do.call(rbind, lapply(groups[[system]], function(group) {
    do.call(rbind, lapply(depths[[system]], function(depth) {
      a <- d[d$system == system & d$site_type == group & d$depth_cm == depth, ]
      a <- a[order(a$core), ]
      n <- nrow(a)
      stock <- a$cumulative_c_stock
      se <- sd(stock) / sqrt(n)
      data.frame(system = system, response = "cumulative_c_stock",
        management = group, depth_cm = depth,
        cumulative_top_cm = 0, cumulative_bottom_cm = unique(a$nominal_depth_bottom_cm),
        n_cores = n, mean_t_C_ha = mean(stock), sd_t_C_ha = sd(stock),
        se_t_C_ha = se, lower_one_se_t_C_ha = mean(stock) - se,
        upper_one_se_t_C_ha = mean(stock) + se,
        uncertainty = "observed core mean +/-1 sample SE; not a confidence interval",
        source_sample_codes = paste(a$sample_code, collapse = ";"),
        source_core_ids = paste(a$core, collapse = ";"),
        source_field_ids = paste(unique(a$site_name), collapse = ";"))
    }))
  }))
}))
stopifnot(nrow(profile) == 32L)

# Each endpoint contains one cumulative total per core, with the target bottom.
endpoint_spec <- data.frame(system = c("annual vegetables", "orchards",
  "hedgerows", "hedgerows"), depth_cm = c("50-100", "50-75", "10-20", "50-75"),
  endpoint_bottom_cm = c(100, 75, 20, 75))
endpoint_data <- do.call(rbind, lapply(seq_len(nrow(endpoint_spec)), function(i) {
  spec <- endpoint_spec[i, ]
  a <- d[d$system == spec$system & d$depth_cm == spec$depth_cm, ]
  stopifnot(all(a$nominal_depth_bottom_cm == spec$endpoint_bottom_cm),
    all(a$effective_depth_bottom_cm == spec$endpoint_bottom_cm),
    !anyDuplicated(a$core))
  data.frame(system = a$system, endpoint_top_cm = 0,
    endpoint_bottom_cm = spec$endpoint_bottom_cm, source_depth_cm = a$depth_cm,
    management = a$site_type, field_id = a$site_name, core = a$core,
    sample_id = a$sample_id, sample_code = a$sample_code,
    cumulative_C_stock_t_C_ha = a$cumulative_c_stock)
}))
stopifnot(nrow(endpoint_data) == 30L)
endpoint_summary <- do.call(rbind, lapply(seq_len(nrow(endpoint_spec)), function(i) {
  spec <- endpoint_spec[i, ]
  a <- profile[profile$system == spec$system & profile$depth_cm == spec$depth_cm, ]
  a$endpoint_top_cm <- 0
  a$endpoint_bottom_cm <- spec$endpoint_bottom_cm
  a
}))
stopifnot(nrow(endpoint_summary) == 10L)

# t.test compares two independent core means; Welch permits unequal variances.
# These are unpaired field comparisons. Matching distances do not create pairs.
welch <- function(system, bottom, first, second) {
  a <- endpoint_data[endpoint_data$system == system &
    endpoint_data$endpoint_bottom_cm == bottom, ]
  x <- a$cumulative_C_stock_t_C_ha[a$management == first]
  y <- a$cumulative_C_stock_t_C_ha[a$management == second]
  stopifnot(length(x) == 3L, length(y) == 3L)
  fit <- stats::t.test(x, y, alternative = "two.sided", paired = FALSE,
    var.equal = FALSE, mu = 0, conf.level = 0.95)
  data.frame(system = system, endpoint_top_cm = 0, endpoint_bottom_cm = bottom,
    first_group = first, second_group = second,
    contrast = paste(first, "minus", second), n_first = length(x),
    n_second = length(y), first_mean_t_C_ha = mean(x), first_SD_t_C_ha = sd(x),
    second_mean_t_C_ha = mean(y), second_SD_t_C_ha = sd(y),
    difference_t_C_ha = mean(x) - mean(y), lower_95_t_C_ha = fit$conf.int[1],
    upper_95_t_C_ha = fit$conf.int[2], t = unname(fit$statistic),
    df = unname(fit$parameter), p_unadjusted = fit$p.value,
    alternative = "two.sided", paired = FALSE, conf_level = 0.95,
    CI_adjustment = "unadjusted pointwise 95% CI")
}
two_group <- rbind(
  welch("annual vegetables", 100, "polyculture", "monoculture"),
  welch("orchards", 75, "20-year-old orchard", "60-year-old orchard"))
hedgerow <- do.call(rbind, lapply(c(20, 75), function(bottom) rbind(
  welch("hedgerows", bottom, "10-year-old hedgerow", "bare field margin"),
  welch("hedgerows", bottom, "30-year-old hedgerow", "bare field margin"),
  welch("hedgerows", bottom, "30-year-old hedgerow", "10-year-old hedgerow"))))
# Adjust all six hedgerow p values together, not separately by endpoint.
# Holm remains a six-test family although the two endpoints reuse the same cores.
hedgerow$p_Holm_six_hedgerow_tests <- stats::p.adjust(hedgerow$p_unadjusted, "holm")
two_group$p_Holm_six_hedgerow_tests <- NA_real_
tests <- rbind(two_group, hedgerow)
tests$p_reported <- ifelse(tests$system == "hedgerows",
  tests$p_Holm_six_hedgerow_tests, tests$p_unadjusted)
tests$p_adjustment <- ifelse(tests$system == "hedgerows",
  "Holm across all six hedgerow pairwise endpoint tests", "none")
tests$symbol_reported_p <- ifelse(tests$p_reported < 0.001, "***",
  ifelse(tests$p_reported < 0.01, "**", ifelse(tests$p_reported < 0.05, "*",
    ifelse(tests$p_reported < 0.10, "\u2020", ""))))
stopifnot(nrow(tests) == 8L)
# Verify the previously saved orchard endpoint result at the saved precision.
stopifnot(abs(tests$p_unadjusted[tests$system == "orchards"] -
  0.38124101306607633) < 1e-12)

write_exact(endpoint_data, "endpoint_observations.csv")
write_exact(endpoint_summary, "endpoint_group_summary.csv")
write_exact(tests, "endpoint_welch_contrasts.csv")
write_exact(profile, "stock_profile_summary.csv")
markers <- tests[, c("system", "endpoint_bottom_cm", "first_group",
  "second_group", "p_unadjusted", "p_reported", "p_adjustment", "symbol_reported_p")]
markers$source_depth_cm <- ifelse(markers$endpoint_bottom_cm == 100, "50-100",
  ifelse(markers$endpoint_bottom_cm == 75, "50-75", "10-20"))
write_exact(markers, "endpoint_marker_tests.csv")
source_relative <- c(input_relative, "data/processed/sample_level_full_111_current.csv",
  source_manifest_relative, "scripts/prepare_analysis_data.R",
  sub(paste0(repository, "/"), "", script, fixed = TRUE), raw_relative)
source_paths <- file.path(repository, source_relative)
source_paths[match(raw_relative, source_relative)] <- raw_paths
sources <- data.frame(file = source_relative,
  bytes = as.numeric(file.info(source_paths)$size),
  sha256 = vapply(source_paths, sha256, character(1)))
write_exact(sources, "source_sha256.csv")
capture.output(sessionInfo(), file = file.path(output, "R_session_info.txt"))
writeLines(c(
  "Author-selected Welch endpoint comparisons; no profile model or sensitivity fit.",
  "Annual:0-100cm;orchard:0-75cm;hedgerows:0-20cm and0-75cm.",
  "All endpoint groups contain3cores from one field or field-margin location.",
  "Differences are first_group minus second_group; stock units:t C ha^-1.",
  "Hedgerow p values use one Holm family of6; all CIs are unadjusted pointwise95%.",
  "Profiles show observed core means+/-1SE, not fitted means or confidence intervals.",
  "Welch permits unequal variances; independence/approximate normality remain assumptions.",
  "Field-level management effects are not identifiable from one location per category.",
  "No raw measurement, stock calculation, source file, profile model or other analysis changed."
), file.path(output, "METHOD_SCOPE.txt"))
message("Endpoint comparisons and observed profiles saved: ", normalizePath(output))
