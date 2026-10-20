# Plot the saved sensitivity results only. This script fits no models.
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
task_dir <- dirname(normalizePath(sub("^--file=", "", script_arg)))
out_dir <- file.path(task_dir, "outputs")
r <- read.csv(file.path(out_dir, "field_contrasts.csv"), stringsAsFactors = FALSE)
draw_plot <- function() {
  par(mfrow = c(1, 3), mar = c(4.1, 5.8, 3.2, 0.8), oma = c(3.5, 0.5, 2.5, 0),
      family = "sans", las = 1, col.axis = "#444444", col.lab = "#333333")
  cols <- c(half = "#377A9C", original = "#272F38", double = "#B86732")
  comparisons <- c("equal_depth_log_average", "40-50", "50-100")
  panel_titles <- c("Equal-depth summary", "40-50 cm", "50-100 cm")
  for (i in seq_along(comparisons)) {
    z <- r[r$comparison == comparisons[i], ]
    z <- z[match(c("half", "original", "double"), z$constant), ]
    plot(NA_real_, NA_real_, xlim = c(0.8, 230), ylim = c(.65, 3.65), log = "x",
         axes = FALSE, xlab = "Polyculture / monoculture ratio", ylab = "")
    abline(v = 1, col = "#999999", lty = 2, lwd = 1)
    axis(1, at = c(1, 2, 5, 10, 20, 50, 100, 200), labels = c("1", "2", "5", "10", "20", "50", "100", "200"), cex.axis = .8)
    axis(2, at = 3:1, labels = c("Half\n0.000085 g", "Original\n0.000170 g", "Double\n0.000340 g"),
         tick = FALSE, cex.axis = .85)
    segments(z$lower_95, 3:1, z$upper_95, 3:1, col = cols[z$constant], lwd = 2)
    points(z$poly_over_mono, 3:1, pch = 19, col = cols[z$constant], cex = 1.2)
    text(z$poly_over_mono, 3:1+.22, labels = sprintf("%.2f", z$poly_over_mono),
         col = cols[z$constant], cex = .9)
    title(panel_titles[i], line = 1.1, cex.main = 1.05)
  }
  mtext("Corrected annual roots: Gamma sensitivity to the added mass", side = 3,
        outer = TRUE, line = .7, cex = 1.25, font = 2)
  mtext("Points: fitted adjusted-density ratios. Bars: approximate 95% confidence intervals. Horizontal axes use a log scale.",
        side = 1, outer = TRUE, line = 1.0, cex = .86)
  mtext("The summary equally weights six depth categories on the log scale; it is not total root mass through the profile.",
        side = 1, outer = TRUE, line = 2.25, cex = .86)
}
png(file.path(out_dir, "gamma_sensitivity_comparison.png"), width = 2400, height = 1080, res = 200, type = "quartz")
draw_plot()
dev.off()
pdf(file.path(out_dir, "gamma_sensitivity_comparison.pdf"), width = 12, height = 5.4)
draw_plot()
dev.off()
