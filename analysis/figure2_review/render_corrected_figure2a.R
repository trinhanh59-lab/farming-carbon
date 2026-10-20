# Render the approved corrected Gamma results for the local REVIEW package only.
# This reads saved results. It does not fit models or change manuscript files.
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
out_dir <- dirname(normalizePath(sub("^--file=", "", script_arg)))
results_dir <- file.path(dirname(out_dir), "corrected_annual_gamma_2026-10-16", "outputs")
means <- read.csv(file.path(results_dir, "adjusted_density_cell_means.csv"),
                  stringsAsFactors = FALSE)
tests <- read.csv(file.path(results_dir, "field_contrasts.csv"), stringsAsFactors = FALSE)
# Keep the author-selected 0.00017 g addition. No other fitted branch is substituted.
means <- means[means$constant == "original", ]
tests <- tests[tests$constant == "original", ]
depths <- c("0-10", "10-20", "20-30", "30-40", "40-50", "50-100")
stopifnot(nrow(means) == 12L, nrow(tests) == 7L,
          all(means$added_mass_g == 0.00017))
# Subtracting a deterministic added density shifts means and interval ends, but
# does not change the saved fitted standard error. This matches the current caption.
means$display_mean <- means$response - means$added_density_mg_cm3
means$display_lower_one_SE <- means$display_mean - means$SE
means$display_upper_one_SE <- means$display_mean + means$SE
stopifnot(max(abs(means$display_mean - means$back_subtracted_mean_mg_cm3)) < 1e-12)
means$y <- 7 - match(means$depth, depths)
tests <- tests[match(depths, tests$comparison), ]
tests$symbol <- ifelse(tests$p_unadjusted < .001, "***",
                ifelse(tests$p_unadjusted < .01, "**",
                ifelse(tests$p_unadjusted < .05, "*",
                ifelse(tests$p_unadjusted < .10, "\u2020", ""))))
write.csv(means, file.path(out_dir, "figure2a_display_values.csv"), row.names = FALSE)
write.csv(tests, file.path(out_dir, "figure2a_significance_values.csv"), row.names = FALSE)

# Match the original annual figure's panel-A position and typography; panels B-D
# are preserved from the freshly exported current manuscript by the compositor.
png(file.path(out_dir, "figure2a_corrected_REVIEW.png"), width = 832, height = 700,
    res = 100, pointsize = 20, type = "quartz", bg = "white")
par(plt = c(192/832, 788/832, (700-566)/700, (700-90)/700),
    xaxs = "i", yaxs = "i", family = "Arial", xpd = FALSE)
plot(NA_real_, NA_real_, xlim = c(-.01, .36), ylim = c(.4, 6.6),
     axes = FALSE, ann = FALSE)
box(col = "#888888", lwd = 1)
abline(v = 0, col = "#D7D7D7", lty = 2, lwd = 1)
axis(1, at = c(0, .1, .2, .3), labels = FALSE,
     lwd = 0, lwd.ticks = 1, cex.axis = .97, tck = -.018)
axis(2, at = 6:1, labels = FALSE, las = 1,
     lwd = 0, lwd.ticks = 1, cex.axis = .97, tck = -.015)
colors <- c(monoculture = "#8C9C6D", polyculture = "#4C6B5F")
for (management in names(colors)) {
  z <- means[means$management == management, ]
  z <- z[match(depths, z$depth), ]
  segments(z$display_lower_one_SE, z$y, z$display_upper_one_SE, z$y,
           col = colors[[management]], lwd = 1.2)
  lines(z$display_mean, z$y, col = colors[[management]], lwd = 1.2)
  points(z$display_mean, z$y, col = colors[[management]], pch = 19, cex = .68)
}
text(.334, 6:1, labels = tests$symbol, cex = 1.10)
# Absolute positions keep the long unit label and panel tag away from data.
par(fig = c(0, 1, 0, 1), mar = c(0, 0, 0, 0), new = TRUE)
plot(NA_real_, NA_real_, xlim = c(0, 832), ylim = c(700, 0),
     xaxs = "i", yaxs = "i", axes = FALSE, ann = FALSE)
text(192 + (c(0, .1, .2, .3)+.01)/.37*596, 599,
     labels = c("0.00", "0.10", "0.20", "0.30"), cex = .97)
text(174, 566 - ((6:1)-.4)/6.2*476, labels = depths, adj = c(1, .5), cex = .97)
text(192, 54, "(a)", adj = c(0, .5), cex = 1.08)
text(45, 329, "Depth (cm)", srt = 90, cex = 1.08)
text(490, 638, "Recovered root mass density", cex = .96)
text(490, 673, expression("(mg cm"^{-3}*")"), cex = .96)
invisible(dev.off())
