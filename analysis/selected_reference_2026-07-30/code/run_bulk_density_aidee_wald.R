#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(car)
  library(dplyr)
  library(emmeans)
  library(glmmTMB)
  library(readr)
})

options(contrasts = c("contr.sum", "contr.poly"))



script_arg <- commandArgs(trailingOnly = FALSE)
script_arg <- script_arg[grepl("^--file=", script_arg)]
stopifnot(length(script_arg) == 1)
script_dir <- dirname(normalizePath(sub("^--file=", "", script_arg), mustWork = TRUE))
input_path <- file.path(script_dir, "..", "data", "sample_level_analysis_105.csv")
output_dir <- file.path(script_dir, "..", "outputs")
if (!dir.exists(output_dir)) {
  dir.create(output_dir, recursive = TRUE)
}
stopifnot(dir.exists(output_dir))

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

term_names <- c(
  "depth_cm" = "Depth",
  "site_type" = "Comparison group",
  "depth_cm:site_type" = "Depth × comparison group"
)

data_all <- read_csv(input_path, show_col_types = FALSE)

stopifnot(
  nrow(data_all) == 105,
  n_distinct(data_all$core) == 21,
  !any(data_all$system == "orchards" & data_all$depth_cm == "75-100")
)

omnibus_rows <- list()
contrast_rows <- list()
diagnostic_rows <- list()

for (system_name in names(depth_levels)) {
  data_system <- data_all |>
    filter(system == system_name) |>
    mutate(
      depth_cm = factor(depth_cm, levels = depth_levels[[system_name]]),
      site_type = factor(site_type, levels = group_levels[[system_name]]),
      core = factor(core)
    )

  model <- glmmTMB(
    bulk_density ~ depth_cm * site_type + (1 | core),
    data = data_system,
    family = gaussian(link = "identity"),
    na.action = na.fail
  )

  omnibus_rows[[system_name]] <- as.data.frame(car::Anova(model, type = 3)) |>
    tibble::rownames_to_column("term") |>
    filter(term %in% names(term_names)) |>
    transmute(
      system = system_name,
      term = unname(term_names[term]),
      statistic = Chisq,
      df = Df,
      p_value = `Pr(>Chisq)`
    )

  contrasts <- emmeans(model, ~ site_type | depth_cm) |>
    pairs(adjust = "none") |>
    summary(infer = c(TRUE, TRUE)) |>
    as.data.frame()
  lower_column <- grep("lower.CL|asymp.LCL", names(contrasts), value = TRUE)[[1]]
  upper_column <- grep("upper.CL|asymp.UCL", names(contrasts), value = TRUE)[[1]]

  contrast_rows[[system_name]] <- contrasts |>
    transmute(
      system = system_name,
      depth_cm = as.character(depth_cm),
      contrast = as.character(contrast),
      estimate,
      standard_error = SE,
      df,
      lower_95 = .data[[lower_column]],
      upper_95 = .data[[upper_column]],
      p_value = p.value,
      adjustment = "none"
    )

  diagnostic_rows[[system_name]] <- tibble(
    system = system_name,
    observations = nrow(data_system),
    cores = n_distinct(data_system$core),
    convergence_code = model$fit$convergence,
    positive_definite_hessian = isTRUE(model$sdr$pdHess),
    core_random_sd = as.numeric(attr(VarCorr(model)$cond$core, "stddev")[[1]])
  )
}

write_csv(
  bind_rows(omnibus_rows),
  file.path(output_dir, "bulk_density_aidee_wald_omnibus.csv")
)
write_csv(
  bind_rows(contrast_rows),
  file.path(output_dir, "bulk_density_aidee_wald_contrasts.csv")
)
write_csv(
  bind_rows(diagnostic_rows),
  file.path(output_dir, "bulk_density_aidee_wald_diagnostics.csv")
)

capture.output(
  sessionInfo(),
  file = file.path(output_dir, "bulk_density_aidee_wald_session_info.txt")
)
