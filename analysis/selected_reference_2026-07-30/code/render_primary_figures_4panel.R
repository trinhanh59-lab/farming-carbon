#!/usr/bin/env Rscript

# Render four primary manuscript figures from the already-selected Aidee
# model outputs. This script does not refit any model or change the root offset.

suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(ggthemes)
  library(patchwork)
  library(readr)
  library(ragg)
})

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 3) {
  stop("usage: render_primary_figures_4panel.R PLOT_VALUES.csv MARKER_TESTS.csv OUTPUT_DIR")
}

plot_values_path <- normalizePath(args[[1]], mustWork = TRUE)
marker_tests_path <- normalizePath(args[[2]], mustWork = TRUE)
output_dir <- normalizePath(args[[3]], mustWork = FALSE)
dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

plot_values_all <- read_csv(plot_values_path, show_col_types = FALSE)
marker_tests_all <- read_csv(marker_tests_path, show_col_types = FALSE)

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

  if (response_name == "root_weight_offset") {
    data_panel <- data_panel |>
      mutate(
        estimate = estimate - 0.00017,
        lower_one_se = lower_one_se - 0.00017,
        upper_one_se = upper_one_se - 0.00017
      )
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

systems <- c("annual vegetables", "orchards", "hedgerows")
figure_responses <- c("root_weight_offset", "c_percent", "cumulative_c_stock", "del14c")
figure_files <- c(
  "annual vegetables" = "Figure_2_annual_primary_4panel.png",
  "orchards" = "Figure_3_orchard_primary_4panel.png",
  "hedgerows" = "Figure_4_hedgerow_primary_4panel.png"
)

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
}

message("Wrote four-panel figures to: ", output_dir)
