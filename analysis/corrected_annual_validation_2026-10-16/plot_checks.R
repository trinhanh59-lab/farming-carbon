# Visualize saved diagnostics and core-deletion estimates; fit no models here.
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
task_dir <- dirname(normalizePath(sub("^--file=", "", script_arg)))
out <- file.path(task_dir, "outputs")
r <- read.csv(file.path(out, "residuals_by_sample.csv"), stringsAsFactors = FALSE)
loco <- read.csv(file.path(out, "leave_one_core_out_contrasts.csv"), stringsAsFactors = FALSE)
depths <- c("0-10", "10-20", "20-30", "30-40", "40-50", "50-100")
cores <- c("IKON.1", "IKON.3", "IKON.5", "LAHE.1", "LAHE.3", "LAHE.5")
colors <- c("#265C82", "#4A8FB6", "#90BBD1", "#895336", "#BA7949", "#D8A278")

draw_residuals <- function(label) {
  z <- r[r$constant == label & r$simulation == "conditional", ]
  z$depth <- factor(z$depth, levels = depths)
  z$core <- factor(z$core, levels = cores)
  par(mfrow = c(2, 3), mar = c(4.1, 4.3, 3.0, 1), oma = c(3, 0, 2.5, 0),
      family = "sans", las = 1)
  plot(ppoints(nrow(z)), sort(z$scaled_residual), xlab = "Expected uniform quantile",
       ylab = "Observed residual quantile", main = "Overall residual distribution", pch = 16)
  abline(0, 1, col = "#888888", lty = 2)
  plot(z$fitted_adjusted_density, z$scaled_residual, log = "x", ylim = c(0, 1),
       pch = ifelse(z$was_observed_zero, 1, 16), col = colors[as.integer(z$core)],
       xlab = "Fitted adjusted density (log scale)", ylab = "Scaled residual", main = "Residuals versus fitted density")
  abline(h = .5, lty = 2, col = "#999999")
  boxplot(scaled_residual ~ depth, data = z, ylim = c(0, 1), col = "#E3EAF0",
          xlab = "Depth interval (cm)", ylab = "Scaled residual", main = "Residuals by depth", cex.axis = .8)
  abline(h = .5, lty = 2, col = "#999999")
  boxplot(scaled_residual ~ management, data = z, ylim = c(0, 1), col = c("#D4E3EF", "#EBD7C5"),
          xlab = "Sampled field", ylab = "Scaled residual", main = "Residuals by field")
  abline(h = .5, lty = 2, col = "#999999")
  boxplot(scaled_residual ~ core, data = z, ylim = c(0, 1), col = colors,
          xlab = "Actual core", ylab = "Scaled residual", main = "Residuals by core", cex.axis = .75)
  abline(h = .5, lty = 2, col = "#999999")
  plot(NA_real_, NA_real_, xlim = c(1, 6), ylim = c(0, 1), axes = FALSE,
       xlab = "Ordered depth intervals", ylab = "Scaled residual", main = "Patterns within each core")
  axis(1, at = 1:6, labels = depths, cex.axis = .75); axis(2)
  abline(h = .5, lty = 2, col = "#999999")
  for (i in seq_along(cores)) {
    zz <- z[z$core == cores[i], ]; zz <- zz[order(zz$depth), ]
    lines(1:6, zz$scaled_residual, col = colors[i], lwd = 1.5)
    points(1:6, zz$scaled_residual, col = colors[i], pch = ifelse(zz$was_observed_zero, 1, 16))
  }
  mtext(paste("Corrected annual Gamma residuals:", label, "constant"), side = 3, outer = TRUE, font = 2, line = .7, cex = 1.2)
  mtext("Conditional simulations hold fitted core effects fixed. Open points identify observations originally recorded as zero.",
        side = 1, outer = TRUE, line = .7, cex = .85)
  mtext("Depth intervals are ordered categories here. Joined residuals illustrate patterns; they do not interpolate roots or test autocorrelation.",
        side = 1, outer = TRUE, line = 1.8, cex = .85)
}
for (label in c("half", "original", "double")) {
  png(file.path(out, paste0(label, "_residual_diagnostics.png")), width = 2400, height = 1600, res = 200, type = "quartz")
  draw_residuals(label); dev.off()
}

png(file.path(out, "leave_one_core_out_comparison.png"), width = 2400, height = 1080, res = 200, type = "quartz")
par(mfrow = c(1, 3), mar = c(4, 4.6, 3, 1), oma = c(3.2, .2, 2.4, 0), family = "sans", las = 1)
for (label in c("half", "original", "double")) {
  z <- loco[loco$constant == label & loco$comparison == "equal_depth_log_average", ]
  z <- z[match(cores, z$omitted_core), ]
  plot(NA_real_, NA_real_, xlim = c(.8, 45), ylim = c(.5, 6.5), log = "x", axes = FALSE,
       xlab = "Polyculture / monoculture ratio", ylab = "", main = paste(label, "constant"))
  axis(1, at = c(1, 2, 5, 10, 20, 40)); axis(2, at = 6:1, labels = cores, tick = FALSE, cex.axis = .9)
  abline(v = 1, col = "#888888", lty = 2)
  abline(v = z$full_data_ratio[1], col = "#BBBBBB", lty = 3)
  segments(z$lower_95, 6:1, z$upper_95, 6:1, col = colors, lwd = 2)
  points(z$poly_over_mono, 6:1, pch = 19, col = colors)
}
mtext("Effect of leaving out one whole core", side = 3, outer = TRUE, line = .7, font = 2, cex = 1.3)
mtext("Rows name the omitted core. Points show equal-depth log-average ratios; bars show approximate pointwise 95% intervals.",
      side = 1, outer = TRUE, line = .7, cex = .85)
mtext("Dotted line: matching full-data estimate. Each refit uses five cores; these are influence checks, not independent experiments.",
      side = 1, outer = TRUE, line = 1.9, cex = .85)
dev.off()

# Group summaries aid review without treating within-core observations as independent tests.
summary_rows <- list()
for (label in c("half", "original", "double")) {
  for (mode in c("conditional", "unconditional")) {
    z <- r[r$constant == label & r$simulation == mode, ]
    for (group in c("management", "depth", "core")) {
      for (level in unique(z[[group]])) {
        x <- z$scaled_residual[z[[group]] == level]
        summary_rows[[paste(label, mode, group, level)]] <- data.frame(constant = label, simulation = mode,
          grouping = group, level = level, n = length(x), mean = mean(x), median = median(x),
          minimum = min(x), maximum = max(x))
      }
    }
  }
}
write.csv(do.call(rbind, summary_rows), file.path(out, "residual_group_summaries.csv"), row.names = FALSE)
