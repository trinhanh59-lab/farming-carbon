# Approved follow-up checks for the corrected annual Gamma analysis only.
# No original fits, workbook values or manuscript text are overwritten.
# DHARMa diagnoses saved fits; new fits are only whole-core deletion sensitivities.
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
task_dir <- dirname(normalizePath(sub("^--file=", "", script_arg)))
prior_dir <- file.path(dirname(task_dir), "corrected_annual_gamma_2026-10-16")
out_dir <- file.path(task_dir, "outputs")
dir.create(out_dir, showWarnings = FALSE)
suppressPackageStartupMessages(library(glmmTMB))
suppressPackageStartupMessages(library(emmeans))
suppressPackageStartupMessages(library(DHARMa))
options(digits = 10)

# read.csv() imports the exact input independently rechecked against the live sheet.
d <- read.csv(file.path(task_dir, "input", "annual_corrected_root_profiles.csv"), stringsAsFactors = FALSE)
depth_levels <- c("0-10", "10-20", "20-30", "30-40", "40-50", "50-100")
core_levels <- c("IKON.1", "IKON.3", "IKON.5", "LAHE.1", "LAHE.3", "LAHE.5")
d$management <- factor(d$management, levels = c("monoculture", "polyculture"))
d$depth <- factor(paste(d$depth_top_cm, d$depth_bottom_cm, sep = "-"), levels = depth_levels)
d$core <- factor(d$core, levels = core_levels)
stopifnot(nrow(d) == 36L, !anyNA(d), !anyDuplicated(d$sample_id),
          all(table(d$core, d$depth) == 1L), all(table(d$management, d$depth) == 3L),
          sum(d$root_mass_current_g == 0) == 9L,
          max(abs(d$root_density_mg_cm3-1000*d$root_mass_current_g/d$volume_cm3)) < 1e-12)
constants <- c(half = .000085, original = .00017, double = .00034)
full_models_path <- file.path(prior_dir, "outputs", "three_sensitivity_models.rds")
full_contrasts <- read.csv(file.path(prior_dir, "outputs", "field_contrasts.csv"), stringsAsFactors = FALSE)
contrasts_spec <- list(management = contr.sum(2), depth = contr.sum(6))

# p.adjust(method='holm') adjusts the SIX within-depth tests as one family.
# Each constant is a separate sensitivity scenario; the equal-depth summary and
# interaction are not members of this family. Existing CIs remain pointwise CIs.
holm <- full_contrasts[full_contrasts$comparison != "equal_depth_log_average", ]
holm$p_Holm_six_depths <- NA_real_
for (label in names(constants)) {
  index <- holm$constant == label
  stopifnot(sum(index) == 6L)
  holm$p_Holm_six_depths[index] <- p.adjust(holm$p_unadjusted[index], method = "holm")
}
write.csv(holm, file.path(out_dir, "Holm_six_depth_comparisons.csv"), row.names = FALSE)

# simulateResiduals() generates data under the fitted model and compares observed
# responses with them. Conditional simulations hold the fitted core effects fixed;
# unconditional simulations draw new core effects from the fitted distribution.
# Both sets are diagnostic simulations, not a bootstrap of parameter uncertainty.
diagnostic_rows <- list(); residual_rows <- list(); floor_rows <- list(); sim_objects <- list()
for (label in names(constants)) {
  for (mode in c("conditional", "unconditional")) {
    # Reloading makes a fresh in-memory object; the source RDS is never saved over.
    m <- readRDS(full_models_path)[[label]]
    expected_response <- 1000*(d$root_mass_current_g+constants[label])/d$volume_cm3
    # The saved fit's original call refers to model_data. Restore that exact input
    # in memory for DHARMa's model-frame lookup; this does not refit the model.
    model_data <- d
    model_data$density_for_gamma <- expected_response
    contrasts(model_data$management) <- contrasts_spec$management
    contrasts(model_data$depth) <- contrasts_spec$depth
    stopifnot(max(abs(model.response(model.frame(m))-expected_response)) < 1e-12,
              identical(as.character(model.frame(m)$core), as.character(d$core)),
              identical(as.character(model.frame(m)$depth), as.character(d$depth)))
    seed <- 20261016L + 100L*match(label, names(constants)) + match(mode, c("conditional", "unconditional"))
    sr <- simulateResiduals(m, n = 2000, simulateREs = mode, refit = FALSE,
                            plot = FALSE, seed = seed)
    key <- paste(label, mode, sep = "_")
    sim_objects[[key]] <- sr
    tests <- list(uniformity = testUniformity(sr, plot = FALSE),
                  dispersion = testDispersion(sr, plot = FALSE),
                  outliers = testOutliers(sr, type = "binomial", plot = FALSE))
    for (test_name in names(tests)) {
      tt <- tests[[test_name]]
      diagnostic_rows[[paste(key, test_name)]] <- data.frame(
        constant = label, added_mass_g = unname(constants[label]), simulation = mode,
        test = test_name, statistic = if(length(tt$statistic)) unname(tt$statistic[1]) else NA_real_,
        p_diagnostic = tt$p.value, simulations = 2000, seed = seed)
    }
    residual_rows[[key]] <- data.frame(constant = label, simulation = mode,
      sample_code = d$sample_code, management = d$management, core = d$core, depth = d$depth,
      was_observed_zero = d$root_mass_current_g == 0,
      fitted_adjusted_density = predict(m, type = "response"), scaled_residual = sr$scaledResiduals)

    # Shifted measurements cannot be below their own c/volume floor. Gamma can
    # nevertheless simulate below it. Quantify that mismatch without clipping it.
    # No literal-zero inflation test is applied to the positive shifted response.
    floor_density <- 1000*constants[label]/d$volume_cm3
    below_floor <- sweep(sr$simulatedResponse, 1, floor_density, "<")
    counts <- colSums(below_floor)
    observed_count <- sum(sr$observedResponse < floor_density - 1e-12)
    floor_rows[[key]] <- data.frame(constant = label, simulation = mode,
      observed_below_floor = observed_count, mean_simulated_below_floor = mean(counts),
      lower95_simulated_count = unname(quantile(counts, .025)),
      upper95_simulated_count = unname(quantile(counts, .975)),
      fraction_simulations_with_none_below_floor = mean(counts == 0),
      monte_carlo_lower_tail = (1+sum(counts <= observed_count))/(length(counts)+1))
    by_sample <- data.frame(sample_code = d$sample_code, depth = d$depth,
      was_observed_zero = d$root_mass_current_g == 0,
      fraction_simulated_below_floor = rowMeans(below_floor))
    write.csv(by_sample, file.path(out_dir, paste0(key, "_below_floor_by_sample.csv")), row.names = FALSE)
    cat("Residual simulations complete:", key, "\n")
  }
}
diagnostics <- do.call(rbind, diagnostic_rows)
residuals <- do.call(rbind, residual_rows)
floors <- do.call(rbind, floor_rows)
write.csv(diagnostics, file.path(out_dir, "residual_tests.csv"), row.names = FALSE)
write.csv(residuals, file.path(out_dir, "residuals_by_sample.csv"), row.names = FALSE)
write.csv(floors, file.path(out_dir, "below_floor_prediction_check.csv"), row.names = FALSE)
saveRDS(sim_objects, file.path(out_dir, "DHARMa_simulations.rds"))

# Core deletion refits the SAME model after omitting every depth from one core.
# These are influence checks, not new independent experiments or a bootstrap.
extract_comparisons <- function(m) {
  e <- emmeans(m, ~management*depth, df = Inf)
  g <- as.data.frame(e)[c("management", "depth")]
  b <- fixef(m)$cond; V <- vcov(m)$cond
  M <- model.matrix(~management*depth, g, contrasts.arg = contrasts_spec)[, names(b), drop = FALSE]
  L <- do.call(rbind, lapply(depth_levels, function(dep) {
    M[g$management == "polyculture" & g$depth == dep, ] -
      M[g$management == "monoculture" & g$depth == dep, ]
  }))
  interaction_L <- sweep(L[-1, , drop = FALSE], 2, L[1, ], "-")
  interaction_est <- drop(interaction_L %*% b)
  interaction_cov <- interaction_L %*% V %*% t(interaction_L)
  interaction_chi <- as.numeric(crossprod(interaction_est, solve(interaction_cov, interaction_est)))
  L <- rbind(L, colMeans(L))
  estimate <- drop(L %*% b)
  se <- sqrt(diag(L %*% V %*% t(L)))
  out <- data.frame(comparison = c(depth_levels, "equal_depth_log_average"),
    log_poly_over_mono = estimate, log_ratio_SE = se, poly_over_mono = exp(estimate),
    lower_95 = exp(estimate-qnorm(.975)*se), upper_95 = exp(estimate+qnorm(.975)*se),
    p_unadjusted = 2*pnorm(-abs(estimate/se)),
    interaction_p = pchisq(interaction_chi, 5, lower.tail = FALSE))
  out$p_Holm_six_depths <- c(p.adjust(out$p_unadjusted[1:6], method = "holm"), NA_real_)
  out
}
controls <- list(
  nlminb = glmmTMBControl(optCtrl = list(iter.max = 10000, eval.max = 20000, rel.tol = 1e-10)),
  BFGS = glmmTMBControl(optimizer = optim, optArgs = list(method = "BFGS"),
                       optCtrl = list(maxit = 10000, reltol = 1e-12)))
loco_results <- list(); loco_status <- list(); loco_models <- list()
for (label in names(constants)) {
  for (omitted in core_levels) {
    sub <- d[as.character(d$core) != omitted, ]
    sub$core <- droplevels(sub$core)
    sub$density_for_gamma <- 1000*(sub$root_mass_current_g+constants[label])/sub$volume_cm3
    stopifnot(nrow(sub) == 30L, nlevels(sub$core) == 5L,
              all(table(sub$core, sub$depth) == 1L), all(table(sub$management, sub$depth) %in% 2:3))
    X <- model.matrix(~management*depth, sub, contrasts.arg = contrasts_spec)
    stopifnot(qr(X)$rank == ncol(X))
    starting <- list(beta = unname(lm.fit(X, log(sub$density_for_gamma))$coefficients), theta = log(.5))
    key <- paste(label, omitted, sep = "_")
    fits <- list(); status <- list()
    for (op in names(controls)) {
      ww <- character(); error_text <- ""
      m <- tryCatch(withCallingHandlers(
        glmmTMB(density_for_gamma ~ management*depth+(1|core), data = sub,
                family = Gamma(link = "log"), ziformula = ~0, dispformula = ~1,
                REML = FALSE, contrasts = contrasts_spec, na.action = na.fail,
                start = starting, control = controls[[op]]),
        warning = function(w) { ww <<- c(ww, conditionMessage(w)); invokeRestart("muffleWarning") }),
        error = function(e) { error_text <<- conditionMessage(e); NULL })
      fits[op] <- list(m)
      usable <- !is.null(m) && m$fit$convergence == 0 && isTRUE(m$sdr$pdHess) &&
        all(is.finite(vcov(m)$cond)) && is.finite(as.numeric(logLik(m)))
      status[[op]] <- data.frame(constant = label, omitted_core = omitted, optimizer = op,
        usable = usable, convergence = if(is.null(m)) NA else m$fit$convergence,
        pdHess = if(is.null(m)) FALSE else isTRUE(m$sdr$pdHess),
        logLik = if(is.null(m)) NA_real_ else as.numeric(logLik(m)),
        core_SD = if(is.null(m)) NA_real_ else unname(attr(VarCorr(m)$cond$core, "stddev")[1]),
        max_abs_gradient = if(is.null(m)) NA_real_ else max(abs(m$obj$gr(m$fit$par))),
        warnings = paste(unique(ww), collapse = "; "), error = error_text)
    }
    st <- do.call(rbind, status)
    good <- which(st$usable)
    if (!length(good)) {
      st$selected <- FALSE
      loco_status[[key]] <- st
      cat("FAILED core deletion:", key, "\n")
      next
    }
    selected <- good[which.max(st$logLik[good])]
    st$selected <- seq_len(nrow(st)) == selected
    st$optimizer_logLik_gap <- if(length(good) == 2L) diff(range(st$logLik[good])) else NA_real_
    st$optimizer_coefficient_gap <- if(length(good) == 2L)
      max(abs(fixef(fits[[1]])$cond-fixef(fits[[2]])$cond)) else NA_real_
    loco_status[[key]] <- st
    m <- fits[[selected]]
    loco_models[[key]] <- m
    rr <- extract_comparisons(m)
    rr$constant <- label; rr$added_mass_g <- unname(constants[label]); rr$omitted_core <- omitted
    rr$n_observations <- 30L; rr$n_cores <- 5L
    base <- full_contrasts[full_contrasts$constant == label, ]
    rr$full_data_ratio <- base$poly_over_mono[match(rr$comparison, base$comparison)]
    rr$ratio_relative_to_full_data <- rr$poly_over_mono/rr$full_data_ratio
    loco_results[[key]] <- rr
    cat("Core deletion complete:", key, "\n")
  }
}
write.csv(do.call(rbind, loco_status), file.path(out_dir, "leave_one_core_out_numerical_checks.csv"), row.names = FALSE)
write.csv(do.call(rbind, loco_results), file.path(out_dir, "leave_one_core_out_contrasts.csv"), row.names = FALSE)
saveRDS(loco_models, file.path(out_dir, "leave_one_core_out_models.rds"))
capture.output(sessionInfo(), file = file.path(out_dir, "R_session_info.txt"))
cat("\nRESIDUAL TESTS\n"); print(diagnostics, row.names = FALSE)
cat("\nBELOW-FLOOR PREDICTIONS\n"); print(floors, row.names = FALSE)
cat("\nHOLM ADJUSTMENT\n"); print(holm[c("constant", "comparison", "p_unadjusted", "p_Holm_six_depths")], row.names = FALSE)
cat("\nCORE DELETION: DEPTH-AVERAGED LOG COMPARISONS\n")
loco <- do.call(rbind, loco_results)
print(loco[loco$comparison == "equal_depth_log_average", c("constant", "omitted_core", "poly_over_mono", "lower_95", "upper_95", "p_unadjusted")], row.names = FALSE)
