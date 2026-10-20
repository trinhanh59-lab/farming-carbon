#!/usr/bin/env Rscript

# Current non-root subset of the selected July 30 analysis.
# Model and contrast functions below retain the selected specifications.
# Annual vegetables retain 0–100 cm; orchards and hedgerows use 0–75 cm.
# --run-hedgerows75 executes only the two retained hedgerow non-stock models.
# Cumulative stocks use the separate selected endpoint module, not this GLMM loop.

suppressPackageStartupMessages({
  library(car)
  library(DHARMa)
  library(dplyr)
  library(emmeans)
  library(glmmTMB)
  library(performance)
  library(readr)
})

options(contrasts = c("contr.sum", "contr.poly"))

args_all <- commandArgs(trailingOnly = FALSE)
script_arg <- args_all[grepl("^--file=", args_all)]
if (length(script_arg) != 1) {
  stop("Could not determine the script path.")
}
script_path <- normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE)
run_args <- commandArgs(trailingOnly = TRUE)
if (length(run_args) < 1L || !run_args[[1]] %in% c("--run-analysis", "--run-hedgerows75") || length(run_args) > 2L) {
  stop("Use --run-analysis or --run-hedgerows75 [OUTPUT_DIR]. Stock endpoint tests are in analysis/stock_endpoints_2026-10-20/.")
}
hedgerows_only <- run_args[[1]] == "--run-hedgerows75"
# Resolve the output before fitting; reject source and frozen-result folders.
resolve_new_output <- function(path, repository) {
  path <- path.expand(path)
  if(!grepl("^(/|[A-Za-z]:[/\\\\])",path)) path <- file.path(getwd(),path)
  if(file.exists(path)||dir.exists(path)) stop("Output exists; choose a new directory.")
  ancestor <- path; rest <- character()
  while(!file.exists(ancestor) && !dir.exists(ancestor)) {
    parent <- dirname(ancestor)
    if(identical(parent,ancestor)) stop("Cannot resolve output path.")
    rest <- c(basename(ancestor),rest); ancestor <- parent
  }
  if(!dir.exists(ancestor)) stop("Output parent is a file.")
  resolved <- normalizePath(ancestor,winslash="/",mustWork=TRUE)
  for(part in rest) {
    if(part=="." || !nzchar(part)) next
    resolved <- if(part=="..") dirname(resolved) else file.path(resolved,part)
    if(file.exists(resolved)||dir.exists(resolved))
      resolved <- normalizePath(resolved,winslash="/",mustWork=TRUE)
  }
  protected <- file.path(repository,c("data","analysis","figures","reproducibility"))
  if(identical(resolved,repository) || any(vapply(protected,function(p)
    identical(resolved,p)||startsWith(resolved,paste0(p,"/")),logical(1))))
    stop("Choose a new output outside data, analysis, figures and reproducibility folders.")
  if(file.exists(resolved)||dir.exists(resolved)) stop("Output exists; choose a new directory.")
  resolved
}
repository <- normalizePath(file.path(dirname(script_path),"..",".."),mustWork=TRUE)
output_dir <- resolve_new_output(if(length(run_args)==2L) run_args[[2]] else
  file.path(repository,"outputs_rerun","nonroot_current"),repository)
dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
input_path <- file.path(dirname(script_path), "..", "..", "data", "processed", "sample_level_analysis_96_current.csv")

data_all <- read_csv(input_path, show_col_types = FALSE)

stopifnot(
  nrow(data_all) == 96,
  n_distinct(data_all$core) == 21,
  identical(data_all$del14c[data_all$sample_id == 142], -11.5),
  identical(data_all$del14c[data_all$sample_id == 143], 13.2),
  identical(data_all$root_weight[data_all$sample_id == 143], 0.0086),
  !any(data_all$system == "orchards" & data_all$depth_cm == "75-100")
)

depth_levels <- list(
  "annual vegetables" = c("0-10", "10-20", "20-30", "30-40", "40-50", "50-100"),
  "orchards" = c("0-10", "10-20", "20-50", "50-75"),
  "hedgerows" = c("0-10", "10-20", "20-50", "50-75")
)

group_levels <- list(
  "annual vegetables" = c("monoculture", "polyculture"),
  "orchards" = c("20-year-old orchard", "60-year-old orchard"),
  "hedgerows" = c(
    "bare field margin",
    "10-year-old hedgerow",
    "30-year-old hedgerow"
  )
)

group_labels <- c(
  "monoculture" = "monoculture",
  "polyculture" = "polyculture",
  "20-year-old orchard" = "20-year",
  "60-year-old orchard" = "60-year",
  "bare field margin" = "bare margin",
  "10-year-old hedgerow" = "10-year",
  "30-year-old hedgerow" = "30-year"
)

group_colors <- c(
  "monoculture" = "#8C9C6D",
  "polyculture" = "#4C6B5F",
  "20-year-old orchard" = "#E28065",
  "60-year-old orchard" = "#AB3F21",
  "bare field margin" = "#ECD693",
  "10-year-old hedgerow" = "#F7C548",
  "30-year-old hedgerow" = "#A98743"
)

response_specs <- tribble(
  ~response,             ~response_label,       ~family_label,         ~figure_order, ~axis_label,
  "c_percent",           "C concentration",     "Gamma(log)",          2L,             "C concentration (%)",
  "del14c",              expression(Delta^14*C), "Gaussian(identity)",  4L,             expression(Delta^14*C~("\u2030"))
)

family_for <- function(family_label) {
  if (family_label == "Gamma(log)") {
    return(Gamma(link = "log"))
  }
  gaussian(link = "identity")
}

term_names <- c(
  "depth_cm" = "Depth",
  "site_type" = "Comparison group",
  "depth_cm:site_type" = "Depth \u00d7 comparison group"
)

symbol_for_p <- function(p) {
  case_when(
    is.na(p) ~ "",
    p < 0.001 ~ "***",
    p < 0.01 ~ "**",
    p < 0.05 ~ "*",
    p < 0.10 ~ "\u2020",
    TRUE ~ ""
  )
}

safe_scalar <- function(x) {
  if (length(x) == 0 || !is.finite(x[[1]])) {
    return(NA_real_)
  }
  as.numeric(x[[1]])
}

make_system_data <- function(system_name) {
  data_all |>
    filter(system == system_name) |>
    mutate(
      depth_cm = factor(depth_cm, levels = depth_levels[[system_name]]),
      site_type = factor(site_type, levels = group_levels[[system_name]]),
      core = factor(core),
      root_weight_offset = root_weight + 0.00017
    )
}

fit_one <- function(system_name, spec, model_index) {
  data_system <- make_system_data(system_name)
  # Retain the term labels used in the saved hedgerow table.
  display_terms <- term_names
  if (system_name == "hedgerows") {
    display_terms[c("site_type", "depth_cm:site_type")] <-
      c("Management", "Depth \u00d7 Management")
  }
  response_name <- spec$response[[1]]
  response_label <- as.character(spec$response_label[[1]])
  family_label <- spec$family_label[[1]]

  model_formula <- as.formula(
    paste(response_name, "~ depth_cm * site_type + (1 | core)")
  )

  warning_text <- character()
  model <- withCallingHandlers(
    glmmTMB(
      model_formula,
      data = data_system,
      family = family_for(family_label),
      na.action = na.fail,
      control = glmmTMBControl(
        optCtrl = list(iter.max = 10000, eval.max = 10000)
      )
    ),
    warning = function(w) {
      warning_text <<- c(warning_text, conditionMessage(w))
      invokeRestart("muffleWarning")
    }
  )

  anova_table <- as.data.frame(car::Anova(model, type = 3)) |>
    tibble::rownames_to_column("term")

  omnibus <- anova_table |>
    filter(term %in% names(term_names)) |>
    transmute(
      system = system_name,
      response = response_name,
      response_label = response_label,
      family = family_label,
      term = unname(display_terms[term]),
      statistic = Chisq,
      df = Df,
      p_value = `Pr(>Chisq)`,
      symbol = symbol_for_p(p_value)
    )

  emm <- emmeans(model, ~ site_type | depth_cm, type = "response")
  emm_raw <- as.data.frame(summary(emm, type = "response"))
  estimate_column <- intersect(c("response", "emmean"), names(emm_raw))[[1]]

  plot_values <- emm_raw |>
    transmute(
      estimate = .data[[estimate_column]],
      se = SE,
      lower_one_se = estimate - se,
      upper_one_se = estimate + se,
      system = system_name,
      response = response_name,
      response_label = response_label,
      family = family_label,
      site_type = as.character(site_type),
      depth_cm = as.character(depth_cm)
    )

  pair_raw <- as.data.frame(
    summary(
      pairs(emm, adjust = "none"),
      infer = c(TRUE, TRUE),
      type = "response"
    )
  )
  effect_column <- intersect(
    c("ratio", "estimate", "response", "odds.ratio"),
    names(pair_raw)
  )[[1]]
  lower_column <- grep("(lower.CL|asymp.LCL)$", names(pair_raw), value = TRUE)[[1]]
  upper_column <- grep("(upper.CL|asymp.UCL)$", names(pair_raw), value = TRUE)[[1]]

  pairwise <- pair_raw |>
    transmute(
      system = system_name,
      response = response_name,
      response_label = response_label,
      depth_cm = as.character(depth_cm),
      contrast = as.character(contrast),
      effect_scale = effect_column,
      effect = .data[[effect_column]],
      lower_95 = .data[[lower_column]],
      upper_95 = .data[[upper_column]],
      p_value = p.value,
      symbol = symbol_for_p(p_value),
      adjustment = "none"
    )

  if (length(group_levels[[system_name]]) == 2) {
    marker_tests <- pairwise |>
      transmute(
        system,
        response,
        response_label,
        depth_cm,
        marker_test = "pairwise contrast",
        contrast,
        df1 = 1,
        df2 = NA_real_,
        statistic = NA_real_,
        p_value,
        symbol,
        adjustment
      )
  } else {
    joint_raw <- as.data.frame(joint_tests(model, by = "depth_cm"))
    marker_tests <- joint_raw |>
      transmute(
        system = system_name,
        response = response_name,
        response_label = response_label,
        depth_cm = as.character(depth_cm),
        marker_test = "joint management test within depth",
        contrast = "(all management categories)",
        df1 = df1,
        df2 = df2,
        statistic = F.ratio,
        p_value = p.value,
        symbol = symbol_for_p(p_value),
        adjustment = "none"
      )
  }

  set.seed(7302026 + model_index)
  dharma <- tryCatch(
    simulateResiduals(model, n = 500, plot = FALSE),
    error = function(e) e
  )
  if (inherits(dharma, "error")) {
    uniformity_p <- dispersion_p <- outlier_p <- NA_real_
    dharma_error <- conditionMessage(dharma)
  } else {
    uniformity_p <- tryCatch(testUniformity(dharma)$p.value, error = function(e) NA_real_)
    dispersion_p <- tryCatch(testDispersion(dharma)$p.value, error = function(e) NA_real_)
    outlier_p <- tryCatch(testOutliers(dharma)$p.value, error = function(e) NA_real_)
    dharma_error <- ""
  }

  core_sd <- tryCatch(
    as.numeric(attr(VarCorr(model)$cond$core, "stddev")[[1]]),
    error = function(e) NA_real_
  )

  model_summary <- tibble(
    system = system_name,
    response = response_name,
    response_label = response_label,
    family = family_label,
    observations = nrow(data_system),
    cores = n_distinct(data_system$core),
    fixed_parameters = length(fixef(model)$cond),
    convergence_code = model$fit$convergence,
    positive_definite_hessian = isTRUE(model$sdr$pdHess),
    core_random_sd = core_sd,
    singular_random_effect = isTRUE(
      performance::check_singularity(model, tolerance = 1e-5)
    ),
    dharma_uniformity_p = uniformity_p,
    dharma_dispersion_p = dispersion_p,
    dharma_outlier_p = outlier_p,
    warnings = paste(unique(warning_text), collapse = " | "),
    dharma_error = dharma_error
  )

  list(
    model = model,
    dharma = dharma,
    input_data = data_system,
    omnibus = omnibus,
    plot_values = plot_values,
    pairwise = pairwise,
    marker_tests = marker_tests,
    model_summary = model_summary
  )
}

# Current primary non-root models exclude cumulative stocks, which use endpoint Welch tests.
response_specs <- response_specs |> filter(response %in% c("c_percent", "del14c"))
systems <- c("annual vegetables", "orchards", "hedgerows")
source_response_index <- c(c_percent = 2L, del14c = 5L)
fits <- list()
for (system_name in if (hedgerows_only) "hedgerows" else systems) {
  for (row_index in seq_len(nrow(response_specs))) {
    spec <- response_specs[row_index, ]
    response_name <- spec$response[[1]]
    # Preserve the selected-source DHARMa seed for each retained model.
    model_index <- (match(system_name, systems) - 1L) * 5L + source_response_index[[response_name]]
    key <- paste(system_name, response_name, sep = "__")
    fits[[key]] <- fit_one(system_name, spec, model_index)
  }
}
stopifnot(length(fits) == if (hedgerows_only) 2L else 6L)
for (item in c("omnibus", "plot_values", "pairwise", "marker_tests", "model_summary")) {
  output_name <- c(omnibus = "nonroot_omnibus.csv", plot_values = "nonroot_plot_values.csv",
    pairwise = "nonroot_pairwise_contrasts.csv", marker_tests = "nonroot_plot_marker_tests.csv",
    model_summary = "nonroot_model_diagnostics.csv")[[item]]
  write_csv(bind_rows(lapply(fits, `[[`, item)), file.path(output_dir, output_name))
}
saveRDS(lapply(fits, `[[`, "dharma"), file.path(output_dir, "nonroot_DHARMa_objects.rds"), compress = "xz")
saveRDS(lapply(fits, `[[`, "model"), file.path(output_dir, "nonroot_model_objects.rds"), compress = "xz")
settings <- tibble(system = "hedgerows", response = c("c_percent", "del14c"),
  observations = 36L, cores = 9L, simulations = 500L,
  precall_seed = 7302026L + c(12L,15L), DHARMa_seed_argument = 123L,
  refit = FALSE, simulation_method = "Selected simulateResiduals defaults; DHARMa 0.5.0")
if (hedgerows_only) write_csv(settings, file.path(output_dir,"diagnostic_settings.csv"))

residuals <- bind_rows(lapply(fits,function(x) {
  if (inherits(x$dharma,"error")) return(NULL)
  tibble(system=x$model_summary$system,response=x$model_summary$response,
    sample_code=x$input_data$sample_code,observed=x$dharma$observedResponse,
    fitted=x$dharma$fittedPredictedResponse,scaled_residual=x$dharma$scaledResiduals)
}))
write_csv(residuals,file.path(output_dir,"nonroot_DHARMa_residuals.csv"))
capture.output(sessionInfo(), file = file.path(output_dir, "R_session_info.txt"))
message("New non-root outputs: ", normalizePath(output_dir))
