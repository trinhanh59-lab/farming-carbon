#!/usr/bin/env Rscript
# Draw Figure S2 from saved conditional residuals. No simulation or fit is run.
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
here <- dirname(normalizePath(sub("^--file=", "", script_arg)))
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[[1]] else file.path(here, "regenerated", "annual_diagnostics")
if (dir.exists(out) || file.exists(out)) stop("Output already exists; choose a new directory.")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
input <- file.path(here, "..", "analysis", "corrected_annual_validation_2026-10-16", "outputs", "residuals_by_sample.csv")
r <- read.csv(input, stringsAsFactors = FALSE)
stopifnot(sum(r$constant == "original" & r$simulation == "conditional") == 36L)
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

device_type <- if (Sys.info()[["sysname"]] == "Darwin") "quartz" else "cairo"
png(file.path(out, "Figure_S2.png"), width = 2400, height = 1600, res = 200, type = device_type)
draw_residuals("original")
invisible(dev.off())
message("Saved-residual Figure S2: ", out)
