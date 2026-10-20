#!/usr/bin/env Rscript
# Draw non-stock fitted panels and observed stock means from saved values.
# No models or tests are run; the complete current composites use render_profile_figures.R.
suppressPackageStartupMessages({
  library(dplyr); library(ggplot2); library(ggthemes); library(readr); library(ragg)
})
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
here <- dirname(normalizePath(sub("^--file=", "", script_arg)))
args <- commandArgs(trailingOnly = TRUE)
output_dir <- if (length(args)) args[[1]] else file.path(here, "regenerated", "nonroot_panels")
if (dir.exists(output_dir) || file.exists(output_dir)) stop("Output already exists; choose a new directory.")
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
input_dir <- file.path(here, "..", "analysis", "nonroot_current", "saved_results")
plot_values_all <- read_csv(file.path(input_dir, "nonroot_plot_values.csv"), show_col_types = FALSE)
marker_tests_all <- read_csv(file.path(input_dir, "nonroot_plot_marker_tests.csv"), show_col_types = FALSE)
stock <- read_csv(file.path(here,"..","analysis","stock_endpoints_2026-10-20","saved_results","stock_profile_summary.csv"),show_col_types=FALSE)
stopifnot(nrow(plot_values_all)==64L,nrow(stock)==32L)
observed_stock <- stock |> transmute(estimate=mean_t_C_ha,se=se_t_C_ha,
  lower_one_se=lower_one_se_t_C_ha,upper_one_se=upper_one_se_t_C_ha,
  system,response,response_label="Observed cumulative C stock",family="Observed mean +/- sample SE",
  site_type=management,depth_cm)
plot_values_all <- bind_rows(plot_values_all,observed_stock)
stopifnot(nrow(plot_values_all) == 96L, nrow(marker_tests_all) == 28L,
          !any(plot_values_all$response %in% c("root_weight_offset", "cn_ratio")))
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

axis_labels <- list(
  "root_weight_offset" = "Root dry mass (g)",
  "c_percent" = "C (%)",
  "cumulative_c_stock" = expression("Cumulative C stock (t C ha"^{-1}*")"),
  "del14c" = expression(Delta^14*C~("\u2030"))
)

make_panel <- function(system_name, response_name, show_y = FALSE, tag = "") {
  data_panel <- plot_values_all |>
    filter(system == system_name, response == response_name) |>
    mutate(
      depth_cm = factor(depth_cm, levels = depth_levels[[system_name]]),
      site_type = factor(site_type, levels = group_levels[[system_name]])
    )

  if (nrow(data_panel) == 0) {
    stop("No plot values for ", system_name, " / ", response_name)
  }

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
      name = "Management"
    ) +
    labs(
      x = axis_labels[[response_name]],
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

for (system_name in c("annual vegetables", "orchards", "hedgerows")) {
  number <- c("annual vegetables" = 2L, "orchards" = 3L, "hedgerows" = 4L)[[system_name]]
  for (response_name in c("c_percent", "cumulative_c_stock", "del14c")) {
    letter <- c(c_percent = "b", cumulative_c_stock = "c", del14c = "d")[[response_name]]
    panel <- make_panel(system_name, response_name, show_y = TRUE, tag = paste0("(", letter, ")"))
    target <- file.path(output_dir, paste0("Figure_", number, letter, ".png"))
    ragg::agg_png(target, width = 1800, height = 1400, units = "px", res = 300, background = "white")
    print(panel); invisible(dev.off())
  }
}
message("Saved-value non-root panels: ", output_dir)
