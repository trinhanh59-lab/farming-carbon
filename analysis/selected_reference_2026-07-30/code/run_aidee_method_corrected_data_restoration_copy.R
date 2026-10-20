#!/usr/bin/env Rscript

# Restore the analysis and figure logic described in Aidee Guzman's June 2026
# manuscript and reaffirmed in the July 30 meeting, while retaining the audited
# source-data corrections and the justified 0-75 cm orchard restriction.

suppressPackageStartupMessages({
  library(car)
  library(DHARMa)
  library(dplyr)
  library(emmeans)
  library(ggplot2)
  library(ggthemes)
  library(glmmTMB)
  library(patchwork)
  library(performance)
  library(readr)
  library(ragg)
  library(tidyr)
})

options(contrasts = c("contr.sum", "contr.poly"))

args_all <- commandArgs(trailingOnly = FALSE)
script_arg <- args_all[grepl("^--file=", args_all)]
if (length(script_arg) != 1) {
  stop("Could not determine the script path.")
}
script_path <- normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE)
output_dir <- file.path(dirname(script_path), "..", "outputs")

input_path <- file.path(dirname(script_path), "..", "data", "sample_level_analysis_105.csv")

data_all <- read_csv(input_path, show_col_types = FALSE)

stopifnot(
  nrow(data_all) == 105,
  n_distinct(data_all$core) == 21,
  identical(data_all$del14c[data_all$sample_id == 142], -11.5),
  identical(data_all$del14c[data_all$sample_id == 143], 13.2),
  identical(data_all$root_weight[data_all$sample_id == 143], 0.0086),
  !any(data_all$system == "orchards" & data_all$depth_cm == "75-100")
)

depth_levels <- list(
  "annual vegetables" = c("0-10", "10-20", "20-30", "30-40", "40-50", "50-100"),
  "orchards" = c("0-10", "10-20", "20-50", "50-75"),
  "hedgerows" = c("0-10", "10-20", "20-50", "50-75", "75-100")
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
  "root_weight_offset",  "Root biomass",        "Gamma(log)",          1L,             "Root dry mass (g)",
  "c_percent",           "C concentration",     "Gamma(log)",          2L,             "C concentration (%)",
  "cn_ratio",            "C:N",                 "Gamma(log)",          NA_integer_,    "C:N",
  "cumulative_c_stock",  "Cumulative C stock",  "Gamma(log)",          3L,             expression("Cumulative C stock (t C ha"^{-1}*")"),
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
      term = unname(term_names[term]),
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
      adjustment = "none (Fisher LSD)"
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
        marker_test = "joint comparison-group test within depth",
        contrast = "(all comparison groups)",
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
    omnibus = omnibus,
    plot_values = plot_values,
    pairwise = pairwise,
    marker_tests = marker_tests,
    model_summary = model_summary
  )
}

systems <- c("annual vegetables", "orchards", "hedgerows")
fits <- list()
model_counter <- 0L

for (system_name in systems) {
  for (row_index in seq_len(nrow(response_specs))) {
    model_counter <- model_counter + 1L
    spec <- response_specs[row_index, ]
    key <- paste(system_name, spec$response[[1]], sep = "__")
    message("Fitting ", key)
    fits[[key]] <- fit_one(system_name, spec, model_counter)
  }
}

omnibus_all <- bind_rows(lapply(fits, `[[`, "omnibus"))
plot_values_all <- bind_rows(lapply(fits, `[[`, "plot_values"))
pairwise_all <- bind_rows(lapply(fits, `[[`, "pairwise"))
marker_tests_all <- bind_rows(lapply(fits, `[[`, "marker_tests"))
model_summary_all <- bind_rows(lapply(fits, `[[`, "model_summary"))

write_csv(omnibus_all, file.path(output_dir, "aidee_corrected_omnibus.csv"))
write_csv(plot_values_all, file.path(output_dir, "aidee_corrected_plot_values.csv"))
write_csv(pairwise_all, file.path(output_dir, "aidee_corrected_pairwise_contrasts.csv"))
write_csv(marker_tests_all, file.path(output_dir, "aidee_corrected_plot_marker_tests.csv"))
write_csv(model_summary_all, file.path(output_dir, "aidee_corrected_model_diagnostics.csv"))

holm_equivalence <- bind_rows(lapply(names(fits), function(key) {
  fit <- fits[[key]]
  system_name <- fit$omnibus$system[[1]]
  if (length(group_levels[[system_name]]) != 2) {
    return(NULL)
  }
  emm <- emmeans(fit$model, ~ site_type | depth_cm)
  none <- as.data.frame(summary(pairs(emm, adjust = "none")))
  holm <- as.data.frame(summary(pairs(emm, adjust = "holm")))
  tibble(
    system = system_name,
    response = fit$omnibus$response[[1]],
    contrasts_per_depth = 1L,
    maximum_absolute_p_difference = max(abs(none$p.value - holm$p.value))
  )
}))
write_csv(
  holm_equivalence,
  file.path(output_dir, "historical_holm_equivalence_check.csv")
)

saveRDS(
  lapply(fits, `[[`, "model"),
  file.path(output_dir, "aidee_corrected_model_objects.rds"),
  compress = "xz"
)

capture.output(
  sessionInfo(),
  file = file.path(output_dir, "R_session_info.txt")
)

input_manifest <- tibble(
  item = c(
    "input_file",
    "input_rows",
    "input_cores",
    "sample_142_del14c",
    "sample_143_del14c",
    "sample_143_root_weight_g",
    "orchard_75_100_rows",
    "root_offset_g",
    "pairwise_adjustment",
    "orchard_depth_scope"
  ),
  value = c(
    input_path,
    nrow(data_all),
    n_distinct(data_all$core),
    data_all$del14c[data_all$sample_id == 142],
    data_all$del14c[data_all$sample_id == 143],
    data_all$root_weight[data_all$sample_id == 143],
    sum(data_all$system == "orchards" & data_all$depth_cm == "75-100"),
    0.00017,
    "none (Fisher LSD)",
    "0-75 cm"
  )
)
write_csv(input_manifest, file.path(output_dir, "input_and_method_manifest.csv"))

make_panel <- function(system_name, response_name, show_y = FALSE, tag = "") {
  data_panel <- plot_values_all |>
    filter(system == system_name, response == response_name) |>
    mutate(
      depth_cm = factor(depth_cm, levels = depth_levels[[system_name]]),
      site_type = factor(site_type, levels = group_levels[[system_name]])
    )

  marker_panel <- marker_tests_all |>
    filter(system == system_name, response == response_name) |>
    mutate(depth_cm = factor(depth_cm, levels = depth_levels[[system_name]])) |>
    left_join(
      data_panel |>
        group_by(depth_cm) |>
        summarise(
          x_max = max(upper_one_se, na.rm = TRUE),
          x_min = min(lower_one_se, na.rm = TRUE),
          .groups = "drop"
        ),
      by = "depth_cm"
    ) |>
    mutate(
      span = pmax(x_max - x_min, abs(x_max) * 0.08, 1e-8),
      marker_x = x_max + 0.24 * span
    )

  spec <- response_specs |> filter(response == response_name)
  axis_label <- spec$axis_label[[1]]

  ggplot(data_panel, aes(x = estimate, y = depth_cm, color = site_type, group = site_type)) +
    geom_errorbar(
      aes(xmin = lower_one_se, xmax = upper_one_se),
      orientation = "y",
      width = 0,
      linewidth = 0.75
    ) +
    geom_path(linewidth = 0.75) +
    geom_point(size = 2.4) +
    geom_text(
      data = marker_panel,
      aes(x = marker_x, y = depth_cm, label = symbol),
      inherit.aes = FALSE,
      color = "black",
      size = 4.4,
      family = "Arial"
    ) +
    annotate(
      "text",
      x = -Inf,
      y = Inf,
      label = tag,
      hjust = -0.35,
      vjust = 1.3,
      size = 4.3,
      family = "Arial"
    ) +
    scale_y_discrete(limits = rev(depth_levels[[system_name]])) +
    scale_x_continuous(expand = expansion(mult = c(0.05, 0.30))) +
    scale_color_manual(
      values = group_colors[group_levels[[system_name]]],
      breaks = group_levels[[system_name]],
      labels = unname(group_labels[group_levels[[system_name]]]),
      name = "Comparison group"
    ) +
    labs(
      x = axis_label,
      y = if (show_y) "Depth (cm)" else NULL
    ) +
    ggthemes::theme_few(base_size = 11, base_family = "Arial") +
    theme(
      legend.position = "bottom",
      legend.title = element_text(size = 10),
      legend.text = element_text(size = 10),
      axis.title = element_text(size = 11),
      axis.text = element_text(size = 10),
      panel.grid = element_blank(),
      plot.margin = margin(6, 5, 6, 5)
    )
}

figure_responses <- c(
  "root_weight_offset",
  "c_percent",
  "cumulative_c_stock",
  "del14c"
)

figure_files <- c(
  "annual vegetables" = "Figure_2_annual_Aidee_method_corrected.png",
  "orchards" = "Figure_3_orchard_Aidee_method_corrected.png",
  "hedgerows" = "Figure_4_hedgerow_Aidee_method_corrected.png"
)

figure_manifest <- list()

for (system_name in systems) {
  panels <- lapply(
    seq_along(figure_responses),
    function(i) {
      make_panel(
        system_name,
        figure_responses[[i]],
        show_y = i == 1,
        tag = paste0("(", letters[[i]], ")")
      )
    }
  )

  combined <- wrap_plots(panels, nrow = 1, guides = "collect") &
    theme(legend.position = "bottom")

  figure_path <- file.path(output_dir, figure_files[[system_name]])
  ragg::agg_png(
    filename = figure_path,
    width = 3510,
    height = 1350,
    units = "px",
    res = 300,
    background = "white"
  )
  print(combined)
  invisible(dev.off())

  figure_manifest[[system_name]] <- tibble(
    system = system_name,
    file = figure_path,
    width_px = 3510,
    height_px = 1350,
    points = "estimated marginal means",
    error_bars = "plus or minus one model-based standard error",
    marker_rule = ifelse(
      system_name == "hedgerows",
      "unadjusted joint comparison-group test within depth",
      "unadjusted pairwise comparison-group contrast within depth"
    ),
    data_scope = ifelse(system_name == "orchards", "0-75 cm", "full retained profile")
  )
}

write_csv(
  bind_rows(figure_manifest),
  file.path(output_dir, "figure_manifest.csv")
)

message("Wrote Aidee-method corrected outputs to: ", output_dir)
