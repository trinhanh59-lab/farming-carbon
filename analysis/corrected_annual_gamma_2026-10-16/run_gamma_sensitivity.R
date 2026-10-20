# Authorized sensitivity check only: corrected annual roots and three added masses.
# Existing models, source observations, manuscript and publication outputs are untouched.
# Run with Rscript --vanilla run_gamma_sensitivity.R from any working directory.

script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
stopifnot(length(script_arg) == 1L)
task_dir <- dirname(normalizePath(sub("^--file=", "", script_arg)))
out_dir <- file.path(task_dir, "outputs")
dir.create(out_dir, showWarnings = FALSE)
suppressPackageStartupMessages(library(glmmTMB))
suppressPackageStartupMessages(library(emmeans))
options(digits = 12)

# read.csv() reads a preserved copy of the corrected data, verified against the live
# workbook immediately before this run. No inferred or replacement masses are added.
d <- read.csv(file.path(task_dir, "input", "annual_corrected_root_profiles.csv"),
              stringsAsFactors = FALSE)
depth_levels <- c("0-10", "10-20", "20-30", "30-40", "40-50", "50-100")
management_levels <- c("monoculture", "polyculture")
core_levels <- c("IKON.1", "IKON.3", "IKON.5", "LAHE.1", "LAHE.3", "LAHE.5")
# factor() tells R that these are named groups rather than numerical depth trends.
d$management <- factor(d$management, levels = management_levels)
d$depth <- factor(paste(d$depth_top_cm, d$depth_bottom_cm, sep = "-"), levels = depth_levels)
d$core <- factor(d$core, levels = core_levels)
stopifnot(nrow(d) == 36L, !anyDuplicated(d$sample_id),
          setequal(d$sample_id, c(1:6, 13:18, 25:30, 37:42, 49:54, 61:66)),
          !anyNA(d), all(table(d$core, d$depth) == 1L),
          all(table(d$management, d$depth) == 3L),
          all(d$root_mass_current_g >= 0), all(d$volume_cm3 > 0),
          sum(d$root_mass_current_g == 0) == 9L,
          all(grepl("no roots recovered", d$zero_status[d$root_mass_current_g == 0])),
          max(abs(d$root_density_mg_cm3 - 1000*d$root_mass_current_g/d$volume_cm3)) < 1e-12)
stopifnot(all(as.character(d$management) ==
              ifelse(grepl("^IKON", d$core), "monoculture", "polyculture")))
stopifnot(max(abs(d$volume_cm3 -
              (d$depth_bottom_cm-d$depth_top_cm)*pi*1.905^2)) < 1e-10)
source_data <- d

# The sum coding is the prepared Gamma specification. Explicit contrasts below make
# the scientific comparisons identical to the earlier treatment-coded notebook.
contrast_spec <- list(management = contr.sum(2), depth = contr.sum(6))
contrasts(d$management) <- contrast_spec$management
contrasts(d$depth) <- contrast_spec$depth
fixed_formula <- ~management*depth
model_formula <- density_for_gamma ~ management*depth + (1|core)
X <- model.matrix(fixed_formula, d, contrasts.arg = contrast_spec)
stopifnot(qr(X)$rank == ncol(X))
constants <- c(half = 0.000085, original = 0.00017, double = 0.00034)

# Two optimizers check the same numerical problem; these are not alternative
# scientific models. We retain the converged solution with higher likelihood.
controls <- list(
  nlminb = glmmTMBControl(optCtrl = list(iter.max = 10000, eval.max = 20000, rel.tol = 1e-10)),
  BFGS = glmmTMBControl(optimizer = optim, optArgs = list(method = "BFGS"),
                       optCtrl = list(maxit = 10000, reltol = 1e-12)))

all_fits <- list(); selected_fits <- list(); numerical <- list()
contrast_rows <- list(); omnibus_rows <- list(); mean_rows <- list(); verification_rows <- list()

# This function calculates a joint Wald test from coefficients and their covariance.
# The same explicit hypotheses were used in the existing notebook.
wald_test <- function(L, b, V) {
  estimate <- drop(L %*% b)
  covariance <- L %*% V %*% t(L)
  statistic <- as.numeric(crossprod(estimate, solve(covariance, estimate)))
  data.frame(chisq = statistic, df = nrow(L),
             p_unadjusted = pchisq(statistic, nrow(L), lower.tail = FALSE))
}

for (label in names(constants)) {
  added_mass <- unname(constants[label])
  model_data <- d
  # Add to EVERY mass before dividing by its own volume, exactly as authorized.
  model_data$density_for_gamma <- 1000*(model_data$root_mass_current_g+added_mass)/model_data$volume_cm3
  # lm.fit() supplies starting coefficients only; it is not used for inference.
  starting <- list(beta = unname(lm.fit(X, log(model_data$density_for_gamma))$coefficients),
                   theta = log(0.5))
  fit_set <- list(); status_set <- list()
  for (optimizer_name in names(controls)) {
    warnings_seen <- character()
    fit <- withCallingHandlers(
      glmmTMB(model_formula, data = model_data, family = Gamma(link = "log"),
              ziformula = ~0, dispformula = ~1, REML = FALSE, contrasts = contrast_spec,
              na.action = na.fail, start = starting, control = controls[[optimizer_name]]),
      warning = function(w) {
        warnings_seen <<- c(warnings_seen, conditionMessage(w))
        invokeRestart("muffleWarning")
      })
    fit_set[[optimizer_name]] <- fit
    V <- vcov(fit)$cond
    status_set[[optimizer_name]] <- data.frame(
      constant = label, added_mass_g = added_mass, optimizer = optimizer_name,
      convergence = fit$fit$convergence, positive_definite_Hessian = isTRUE(fit$sdr$pdHess),
      finite_covariance = all(is.finite(V)), logLik = as.numeric(logLik(fit)),
      max_abs_gradient = max(abs(fit$obj$gr(fit$fit$par))),
      core_SD = unname(attr(VarCorr(fit)$cond$core, "stddev")[1]),
      sigma = unname(sigma(fit)), warning_text = paste(unique(warnings_seen), collapse = "; "))
  }
  status <- do.call(rbind, status_set)
  write.csv(status, file.path(out_dir, paste0(label, "_numerical_checks.csv")), row.names = FALSE)
  saveRDS(fit_set, file.path(out_dir, paste0(label, "_optimizer_fits.rds")))
  stopifnot(all(status$convergence == 0), all(status$positive_definite_Hessian),
            all(status$finite_covariance), all(is.finite(status$logLik)))
  selected <- which.max(status$logLik)
  status$selected <- seq_len(nrow(status)) == selected
  m <- fit_set[[selected]]
  numerical[[label]] <- status
  all_fits[[label]] <- fit_set
  selected_fits[[label]] <- m
  b <- fixef(m)$cond; V <- vcov(m)$cond

  # emmeans() estimates each field-by-depth mean. These are conditional means with
  # random intercept set to zero, not means integrated over the core distribution.
  e <- emmeans(m, ~management*depth, component = "cond", df = Inf)
  em <- as.data.frame(summary(e, type = "response", infer = c(TRUE, FALSE)))
  grid <- em[c("management", "depth")]
  M <- model.matrix(fixed_formula, grid, contrasts.arg = contrast_spec)[, names(b), drop = FALSE]
  manual_means <- exp(drop(M %*% b))
  manual_SE <- manual_means * sqrt(diag(M %*% V %*% t(M)))
  stopifnot(max(abs(em$response-manual_means)) < 1e-8,
            max(abs(em$SE-manual_SE)) < 1e-8)
  em$constant <- label; em$added_mass_g <- added_mass
  em$volume_cm3 <- vapply(as.character(em$depth), function(dep) unique(d$volume_cm3[d$depth == dep]), numeric(1))
  em$added_density_mg_cm3 <- 1000*added_mass/em$volume_cm3
  em$back_subtracted_mean_mg_cm3 <- em$response-em$added_density_mg_cm3
  mean_rows[[label]] <- em

  # Each L row subtracts the monoculture log mean from the polyculture log mean.
  # exp(log difference) is the POLYCULTURE / MONOCULTURE adjusted-density ratio.
  within_L <- do.call(rbind, lapply(depth_levels, function(dep) {
    M[grid$management == "polyculture" & grid$depth == dep, ] -
      M[grid$management == "monoculture" & grid$depth == dep, ]
  }))
  Lmean <- matrix(colMeans(within_L), nrow = 1)
  L <- rbind(within_L, Lmean)
  log_ratio <- drop(L %*% b)
  log_SE <- sqrt(diag(L %*% V %*% t(L)))
  z <- log_ratio/log_SE
  tab <- data.frame(constant = label, added_mass_g = added_mass,
                    comparison = c(depth_levels, "equal_depth_log_average"),
                    log_poly_over_mono = log_ratio, log_ratio_SE = log_SE,
                    poly_over_mono = exp(log_ratio),
                    lower_95 = exp(log_ratio-qnorm(.975)*log_SE),
                    upper_95 = exp(log_ratio+qnorm(.975)*log_SE),
                    z = z, p_unadjusted = 2*pnorm(-abs(z)))
  tab$mono_over_poly <- 1/tab$poly_over_mono
  tab$mono_over_poly_lower_95 <- 1/tab$upper_95
  tab$mono_over_poly_upper_95 <- 1/tab$lower_95
  contrast_rows[[label]] <- tab

  # Independently verify all manual contrasts against emmeans, with no adjustment.
  ec <- contrast(emmeans(m, ~management|depth, df = Inf),
                 method = list(poly_over_mono = c(-1, 1)), adjust = "none")
  ec <- as.data.frame(summary(ec, infer = c(TRUE, TRUE), type = "link", adjust = "none"))
  ec <- ec[match(depth_levels, ec$depth), ]
  ea <- suppressMessages(emmeans(m, ~management, weights = "equal", df = Inf))
  ea <- as.data.frame(summary(contrast(ea, method = list(poly_over_mono = c(-1, 1)),
                                       adjust = "none"), infer = c(TRUE, TRUE), type = "link"))
  gap <- max(abs(c(ec$estimate, ea$estimate)-log_ratio),
             abs(c(ec$SE, ea$SE)-log_SE), abs(c(ec$p.value, ea$p.value)-tab$p_unadjusted))
  ll_gap <- diff(range(status$logLik))
  b_gap <- max(abs(fixef(fit_set[[1]])$cond-fixef(fit_set[[2]])$cond))
  verification_rows[[label]] <- data.frame(constant = label, emmeans_max_gap = gap,
       optimizer_logLik_gap = ll_gap, optimizer_coefficient_gap = b_gap)
  stopifnot(gap < 1e-7, ll_gap < 1e-5, b_gap < 1e-3)

  # Equal-depth log averaging is NOT integration of root mass through the profile.
  depth_L <- do.call(rbind, lapply(depth_levels[-1], function(dep) {
    colMeans(M[grid$depth == dep, , drop = FALSE]) -
      colMeans(M[grid$depth == depth_levels[1], , drop = FALSE])
  }))
  interaction_L <- sweep(within_L[-1, , drop = FALSE], 2, within_L[1, ], "-")
  tests <- list(Management_equal_depth_log_average = Lmean,
                Depth_equal_field_average = depth_L,
                Management_by_depth = interaction_L)
  omnibus_rows[[label]] <- do.call(rbind, lapply(names(tests), function(term) {
    cbind(data.frame(constant = label, added_mass_g = added_mass, term = term),
          wald_test(tests[[term]], b, V))
  }))
  cat("Finished", label, "constant", added_mass, "g; both optimizers agree.\n")
}

# write.csv() saves new, separate result tables. It never writes to the workbook.
results <- do.call(rbind, contrast_rows)
write.csv(results, file.path(out_dir, "field_contrasts.csv"), row.names = FALSE)
write.csv(do.call(rbind, omnibus_rows), file.path(out_dir, "omnibus_wald_tests.csv"), row.names = FALSE)
write.csv(do.call(rbind, numerical), file.path(out_dir, "numerical_checks.csv"), row.names = FALSE)
write.csv(do.call(rbind, verification_rows), file.path(out_dir, "independent_checks.csv"), row.names = FALSE)
write.csv(do.call(rbind, mean_rows), file.path(out_dir, "adjusted_density_cell_means.csv"), row.names = FALSE)
saveRDS(selected_fits, file.path(out_dir, "three_sensitivity_models.rds"))
capture.output(sessionInfo(), file = file.path(out_dir, "R_session_info.txt"))

# Read the file again to confirm the raw masses and all observations are untouched.
reread <- read.csv(file.path(task_dir, "input", "annual_corrected_root_profiles.csv"), stringsAsFactors = FALSE)
stopifnot(identical(reread$root_mass_current_g, source_data$root_mass_current_g),
          identical(reread$sample_code, source_data$sample_code))
cat("\nPOLYCULTURE / MONOCULTURE ADJUSTED-DENSITY RATIOS\n")
print(results[c("constant", "comparison", "poly_over_mono", "lower_95", "upper_95", "p_unadjusted")], row.names = FALSE)
cat("\nOMNIBUS WALD TESTS\n")
print(do.call(rbind, omnibus_rows), row.names = FALSE)
cat("\nAll observations retained. Existing analyses and manuscript unchanged.\n")
