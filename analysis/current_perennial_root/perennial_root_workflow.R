# Perennial recovered-root density: the full Gamma model reported in the paper.
# Sourcing this file defines functions only. Fitting and simulation require explicit calls.
# The original mass correction and all zero observations are retained.

perennial_require_packages <- function(diagnostics = FALSE) {
  needed <- c("glmmTMB", "emmeans", "jsonlite", if (diagnostics) "DHARMa")
  missing <- needed[!vapply(needed, requireNamespace, logical(1), quietly = TRUE)]
  if (length(missing)) stop("Install required packages before running: ", paste(missing, collapse = ", "))
  suppressPackageStartupMessages(library(glmmTMB))
  suppressPackageStartupMessages(library(emmeans))
}

read_perennial_root_input <- function(input_csv) {
  d <- read.csv(input_csv, stringsAsFactors = FALSE, check.names = FALSE)
  required <- c("sample_code", "system", "site_type", "core", "top_cm", "bottom_cm",
  "root_weight_raw", "root_weight", "volume_cm3")
  stopifnot(all(required %in% names(d)), nrow(d) == 60L,
  !anyDuplicated(d$sample_code), !anyNA(d[required]),
  all(is.finite(d$root_weight)), all(d$root_weight >= 0),
  all(is.finite(d$volume_cm3)), all(d$volume_cm3 > 0),
  all(d$bottom_cm > d$top_cm), all(d$bottom_cm <= 75))
  # Observed density has no added mass. The model response is constructed separately.
  d$density <- 1000 * d$root_weight / d$volume_cm3
  orders <- list(orchards = c("20-year-old orchard", "60-year-old orchard"),
  hedgerows = c("bare field margin", "10-year-old hedgerow", "30-year-old hedgerow"))
  expected_n <- c(orchards = 24L, hedgerows = 36L)
  expected_cores <- c(orchards = 6L, hedgerows = 9L)
  out <- list()
  for (s in names(orders)) {
    z <- d[d$system == s, , drop = FALSE]
    z$site_type <- factor(z$site_type, levels = orders[[s]])
    z$core <- factor(z$core)
    z$depth_factor <- factor(paste(z$top_cm, z$bottom_cm, sep = "-"),
    levels = c("0-10", "10-20", "20-50", "50-75"))
    stopifnot(nrow(z) == expected_n[[s]], nlevels(z$core) == expected_cores[[s]],
    sum(z$root_weight == 0) == 4L, !anyNA(z$site_type), !anyNA(z$depth_factor),
    all(table(z$site_type, z$depth_factor) == 3L),
    !anyDuplicated(z[c("core", "depth_factor")]))
    volumes <- tapply(z$volume_cm3, z$depth_factor, function(v) length(unique(v)))
    stopifnot(all(volumes == 1L))
    out[[s]] <- list(data = z, contrast_spec = list(
    site_type = contr.treatment(orders[[s]]),
    depth_factor = contr.treatment(levels(z$depth_factor))))
  }
  out
}

# These helpers retain the original fitted-model checks and Wald calculations.
# Equal depth weights are applied to log means; the resulting ratios are not
# ratios of integrated root mass across the soil profile.
ss_safe <- function(expr,fallback=NA_real_) tryCatch(expr,error=function(e)fallback)

ss_fixed <- function(structure) {
  stopifnot(structure == "full")
  ~site_type*depth_factor
}

ss_start <- function(m,beta=NULL,include_power=FALSE) {
  stopifnot(!include_power)
  pl <- m$obj$env$parList()
  dn <- intersect(c("betad","betadisp"),names(pl))
  stopifnot(length(dn)==1)
  z <- list(beta=if(is.null(beta))unname(fixef(m)$cond)else unname(beta),
  theta=unname(m$fit$par[names(m$fit$par)=="theta"]))
  z[[dn]] <- unname(fixef(m)$disp)
  z
}

ss_grid <- function(x) {
  d <- x$data
  g <- expand.grid(site_type=levels(d$site_type),depth_factor=levels(d$depth_factor))
  g$site_type <- factor(g$site_type,levels=levels(d$site_type))
  g$depth_factor <- factor(g$depth_factor,levels=levels(d$depth_factor))
  g$core <- factor(levels(d$core)[1],levels=levels(d$core))
  g
}

ss_status_one <- function(m,system,stage,structure,optimizer,warnings="",error="",elapsed=0) {
  b <- if(is.null(m)) NA_real_ else fixef(m)$cond
  V <- if(is.null(m)) matrix(NA_real_) else ss_safe(vcov(m)$cond,matrix(NA_real_))
  cv <- all(is.finite(V))&&all(diag(V)>0)&&ss_safe(min(eigen(V,symmetric=TRUE,only.values=TRUE)$values)>0,FALSE)
  pw <- NA_real_
  edge <- FALSE
  data.frame(system=system,stage=stage,structure=structure,optimizer=optimizer,
  convergence=if(is.null(m))NA_integer_ else m$fit$convergence,
  pdHess=if(is.null(m))FALSE else isTRUE(m$sdr$pdHess),finite_beta=all(is.finite(b)),
  finite_cov=cv,max_abs_beta=max(abs(b)),max_fixed_se=sqrt(max(diag(V))),
  core_sd=if(is.null(m))NA_real_ else ss_safe(unname(attr(VarCorr(m)$cond$core,"stddev")[1])),
  power=pw,power_edge_flag=edge,dispersion=if(is.null(m))NA_real_ else ss_safe(unname(sigma(m))),
  logLik=if(is.null(m))NA_real_ else ss_safe(as.numeric(logLik(m))),
  warnings=warnings,error=error,elapsed_seconds=elapsed,
  numeric_ok=!is.null(m)&&isTRUE(m$fit$convergence==0)&&isTRUE(m$sdr$pdHess)&&
  all(is.finite(b))&&cv&&!nzchar(warnings)&&!edge)
}

ss_fit_pair <- function(x,system,stage,structure,start) {
  stopifnot(stage %in% c("A_mass_gamma", "B_shift_gamma"), structure == "full")
  d <- x$data
  f <- audit_response ~ site_type*depth_factor+(1|core)
  d$audit_response <- switch(stage,A_mass_gamma=d$root_weight+0.00017,
  B_shift_gamma=1000*(d$root_weight+0.00017)/d$volume_cm3)
  stopifnot(all(d$audit_response>0),length(d$audit_response)==nrow(d))
  fam <- Gamma(link="log")
  controls <- list(nlminb=glmmTMBControl(optCtrl=list(iter.max=1000,
  eval.max=2000,rel.tol=1e-10)),
  BFGS=glmmTMBControl(optimizer=optim,optArgs=list(method="BFGS"),
  optCtrl=list(maxit=1000,reltol=1e-12)))
  models <- list()
  sts <- list()
  grid <- ss_grid(x)
  for(op in names(controls)) {
    cat(system,stage,structure,op,"\n")
    st <- start
    if(op=="BFGS")st$theta <- log(.5)
    ww <- character()
    ee <- ""
    t0 <- proc.time()[["elapsed"]]
    setTimeLimit(elapsed=45,transient=TRUE)
    m <- tryCatch(withCallingHandlers(glmmTMB(f,data=d,family=fam,
    ziformula=~0,dispformula=~1,REML=FALSE,contrasts=x$contrast_spec,
    na.action=na.fail,start=st,control=controls[[op]]),
    warning=function(w){ww<<-c(ww,conditionMessage(w))
      invokeRestart("muffleWarning")}),
    error=function(e){ee<<-conditionMessage(e)
      NULL})
    setTimeLimit(cpu=Inf,elapsed=Inf,transient=FALSE)
    models[op] <- list(m)
    sts[[op]] <- ss_status_one(m,system,stage,structure,op,
    paste(unique(ww),collapse="; "),ee,proc.time()[["elapsed"]]-t0)
  }
  status <- do.call(rbind,sts)
  good <- which(status$numeric_ok & is.finite(status$logLik))
  choice <- if(length(good))status$optimizer[good[which.max(status$logLik[good])]]else"nlminb"
  m <- models[[choice]]
  gaps <- c(logLik=NA_real_,link=NA_real_,SE_relative=NA_real_,power=NA_real_,dispersion_relative=NA_real_)
  agree <- FALSE
  if(all(status$numeric_ok)) {
    p <- lapply(models,function(mm)predict(mm,newdata=grid,type="link",se.fit=TRUE,re.form=NA,allow.new.levels=TRUE))
    gaps["logLik"] <- diff(range(status$logLik))
    gaps["link"] <- max(abs(p[[1]]$fit-p[[2]]$fit))
    gaps["SE_relative"] <- max(abs(p[[1]]$se.fit-p[[2]]$se.fit)/pmax(p[[1]]$se.fit,p[[2]]$se.fit))
    gaps["power"] <- 0
    gaps["dispersion_relative"] <- diff(range(status$dispersion))/mean(status$dispersion)
    agree <- all(is.finite(gaps))&&gaps["logLik"]<1e-5&&gaps["link"]<1e-3&&
    gaps["SE_relative"]<1e-2&&gaps["power"]<1e-4&&gaps["dispersion_relative"]<1e-3
  }
  list(model=m,models=models,status=status,regular=isTRUE(agree),gaps=gaps,
  reused=FALSE,boundary=FALSE,structure=structure,stage=stage)
}

ss_summarize <- function(result,x,system) {
  k <- result$stage
  structure <- result$structure
  ok <- result$regular
  empty <- data.frame(system=system,stage=k,structure=structure,regular=ok,
  boundary=result$boundary,management_chisq=NA_real_,management_df=nlevels(x$data$site_type)-1,
  management_p=NA_real_,depth_chisq=NA_real_,depth_df=nlevels(x$data$depth_factor)-1,
  depth_p=NA_real_,interaction_chisq=NA_real_,interaction_df=if(structure=="full")
  (nlevels(x$data$site_type)-1)*(nlevels(x$data$depth_factor)-1)else 0,
  interaction_p=NA_real_)
  if(!ok)return(list(tests=empty,pairs=data.frame(),layers=data.frame()))
  m <- result$model
  b <- fixef(m)$cond
  V <- vcov(m)$cond
  g <- ss_grid(x)
  X <- model.matrix(ss_fixed(structure),g,contrasts.arg=x$contrast_spec)[,names(b),drop=FALSE]
  sites <- levels(x$data$site_type)
  deps <- levels(x$data$depth_factor)
  # rowMeans of predictions on the log scale correspond to geometric-mean ratios.
  avgX <- function(index)colMeans(X[index,,drop=FALSE])
  Lsite <- do.call(rbind,lapply(sites[-1],function(z)avgX(g$site_type==z)-avgX(g$site_type==sites[1])))
  Ldepth <- do.call(rbind,lapply(deps[-1],function(z)avgX(g$depth_factor==z)-avgX(g$depth_factor==deps[1])))
  wald <- function(L) {
    e <- drop(L%*%b)
    C <- L%*%V%*%t(L)
    chi <- as.numeric(crossprod(e,solve(C,e)))
    c(statistic=chi,df=nrow(L),p=pchisq(chi,nrow(L),lower.tail=FALSE))
  }
  wa <- wald(Lsite)
  wd <- wald(Ldepth)
  empty$management_chisq <- wa[1]
  empty$management_p <- wa[3]
  empty$depth_chisq <- wd[1]
  empty$depth_p <- wd[3]
  if(structure=="full") {
    jj <- which(grepl(":",names(b),fixed=TRUE))
    L <- diag(length(b))[jj,,drop=FALSE]
    wi <- wald(L)
    empty$interaction_chisq <- wi[1]
    empty$interaction_p <- wi[3]
  }
  contrasts <- combn(sites,2,simplify=FALSE)
  pairs <- list()
  layers <- list()
  contrast_row <- function(L,a,z,dep="equal-layer log average") {
    est <- sum(L*b)
    se <- sqrt(drop(L%*%V%*%L))
    data.frame(system=system,stage=k,structure=structure,comparison=paste(a,"/",z),
    depth=dep,log_ratio=est,SE=se,ratio=exp(est),lower_95=exp(est-qnorm(.975)*se),
    upper_95=exp(est+qnorm(.975)*se),p_unadjusted=2*pnorm(-abs(est/se)))
  }
  for(j in seq_along(contrasts)) {
    a <- contrasts[[j]][1]
    z <- contrasts[[j]][2]
    pairs[[j]] <- contrast_row(avgX(g$site_type==a)-avgX(g$site_type==z),a,z)
    for(dep in deps)layers[[length(layers)+1]] <- contrast_row(
    X[g$site_type==a&g$depth_factor==dep,]-X[g$site_type==z&g$depth_factor==dep,],a,z,dep)
  }
  list(tests=empty,pairs=do.call(rbind,pairs),layers=do.call(rbind,layers))
}

fit_current_perennial_roots <- function(prepared_input) {
  perennial_require_packages()
  stopifnot(identical(names(prepared_input), c("orchards", "hedgerows")))
  results <- list()
  for (system in names(prepared_input)) {
    x <- prepared_input[[system]]
    d <- x$data
    X <- model.matrix(~site_type * depth_factor, d, contrasts.arg = x$contrast_spec)
    stopifnot(qr(X)$rank == ncol(X))
    # Log-response least squares gives starting values, not the final model fit.
    b0 <- lm.fit(X, log(d$root_weight + 0.00017))$coefficients
    A <- ss_fit_pair(x, system, "A_mass_gamma", "full",
    list(beta = unname(b0), theta = log(0.5)))
    if (!isTRUE(A$regular)) stop("Mass-scale starting fit unresolved for ", system)
    # Normalization is an exact depth-specific scale adjustment for this Gamma model.
    scale_beta <- lm.fit(X, log(1000 / d$volume_cm3))$coefficients
    stopifnot(max(abs(drop(X %*% scale_beta) - log(1000 / d$volume_cm3))) < 1e-10)
    bB <- fixef(A$model)$cond + scale_beta[names(fixef(A$model)$cond)]
    B <- ss_fit_pair(x, system, "B_shift_gamma", "full", ss_start(A$model, bB, FALSE))
    if (!isTRUE(B$regular)) stop("Density-scale optimizer agreement unresolved for ", system)
    q <- ss_summarize(B, x, system)
    results[[system]] <- list(data = d, contrast_spec = x$contrast_spec,
    mass_anchor = A, current = B, tests = q$tests, pairs = q$pairs, layers = q$layers)
  }
  results
}

check_perennial_contrasts <- function(current) {
  perennial_require_packages()
  rows <- list()
  for (system in names(current)) {
    r <- current[[system]]
    sites <- levels(r$data$site_type)
    ee <- emmeans(r$current$model, ~site_type, weights = "equal", component = "cond")
    for (j in seq_len(nrow(r$pairs))) {
      az <- strsplit(r$pairs$comparison[j], " / ", fixed = TRUE)[[1]]
      L <- setNames(as.numeric(sites == az[1]) - as.numeric(sites == az[2]), sites)
      cc <- as.data.frame(summary(contrast(ee, list(check = L), adjust = "none"), type = "link"))
      rows[[length(rows) + 1L]] <- data.frame(system = system,
      comparison = r$pairs$comparison[j], log_ratio_gap = abs(cc$estimate - r$pairs$log_ratio[j]),
      SE_gap = abs(cc$SE - r$pairs$SE[j]))
    }
  }
  out <- do.call(rbind, rows)
  stopifnot(max(out$log_ratio_gap) < 1e-6, max(out$SE_gap) < 1e-6)
  out
}

# The five additions are sensitivity checks, not candidate detection limits.
# Only the mass addition varies; rows, depth scope and model structure stay fixed.
run_perennial_constant_sensitivity <- function(current) {
  perennial_require_packages()
  before <- lapply(current, function(r) list(beta=fixef(r$current$model)$cond,
  V=vcov(r$current$model)$cond, ll=as.numeric(logLik(r$current$model))))
  fits <- lapply(current, function(r) list(data = r$data, contrast_spec = r$contrast_spec))
  ss_results <- lapply(current, function(r) list(records = list("full B" = r$current)))
  oc_c0 <- 0.00017
  oc_multipliers <- c(0.1, 0.5, 1, 2, 10)
  oc_controls <- list(
  nlminb = glmmTMBControl(optCtrl = list(iter.max=1000, eval.max=2000, rel.tol=1e-10)),
  BFGS = glmmTMBControl(optimizer=optim, optArgs=list(method="BFGS"),
  optCtrl=list(maxit=1000, reltol=1e-12)))
  oc_fit_one <- function(system,multiplier) {
    x <- fits[[system]]
    d <- x$data
    base <- ss_results[[system]]$records[["full B"]]
    stopifnot(isTRUE(base$regular),nrow(d)==c(orchards=24,hedgerows=36)[system])
    if(multiplier==1)return(base)
    d$audit_response <- 1000*(d$root_weight+oc_c0*multiplier)/d$volume_cm3
    stopifnot(all(is.finite(d$audit_response)),all(d$audit_response>0))
    X <- model.matrix(~site_type*depth_factor,d,contrasts.arg=x$contrast_spec)
    stopifnot(qr(X)$rank==ncol(X))
    # Log-response least squares supplies starting values, not the final estimates.
    beta0 <- lm.fit(X,log(d$audit_response))$coefficients
    st0 <- ss_start(base$model,beta=beta0,include_power=FALSE)
    models <- list()
    sts <- list()
    grid <- ss_grid(x)
    for(op in names(oc_controls)) {
      cat("Fitting",system,"addition multiplier",multiplier,op,"\n")
      st <- st0
      if(op=="BFGS")st$theta <- log(0.5)
      ww <- character()
      ee <- ""
      t0 <- proc.time()[["elapsed"]]
      setTimeLimit(elapsed=45,transient=TRUE)
      m <- tryCatch(withCallingHandlers(glmmTMB(
      audit_response ~ site_type*depth_factor+(1|core),data=d,
      family=Gamma(link="log"),ziformula=~0,dispformula=~1,REML=FALSE,
      contrasts=x$contrast_spec,na.action=na.fail,start=st,control=oc_controls[[op]]),
      warning=function(w){ww<<-c(ww,conditionMessage(w))
        invokeRestart("muffleWarning")}),
      error=function(e){ee<<-conditionMessage(e)
        NULL})
      setTimeLimit(cpu=Inf,elapsed=Inf,transient=FALSE)
      models[op] <- list(m)
      sts[[op]] <- ss_status_one(m,system,"B_shift_gamma","full",op,
      paste(unique(ww),collapse="; "),ee,proc.time()[["elapsed"]]-t0)
    }
    status <- do.call(rbind,sts)
    good <- which(status$numeric_ok & is.finite(status$logLik))
    choice <- if(length(good))status$optimizer[good[which.max(status$logLik[good])]]else"nlminb"
    gaps <- c(logLik=NA_real_,link=NA_real_,SE_relative=NA_real_,dispersion_relative=NA_real_)
    agree <- FALSE
    if(all(status$numeric_ok)) {
      pp <- lapply(models,function(m)predict(m,newdata=grid,type="link",se.fit=TRUE,
      re.form=NA,allow.new.levels=TRUE))
      gaps["logLik"] <- diff(range(status$logLik))
      gaps["link"] <- max(abs(pp[[1]]$fit-pp[[2]]$fit))
      gaps["SE_relative"] <- max(abs(pp[[1]]$se.fit-pp[[2]]$se.fit)/pmax(pp[[1]]$se.fit,pp[[2]]$se.fit))
      gaps["dispersion_relative"] <- diff(range(status$dispersion))/mean(status$dispersion)
      agree <- all(is.finite(gaps))&&gaps["logLik"]<1e-5&&gaps["link"]<1e-3&&
      gaps["SE_relative"]<1e-2&&gaps["dispersion_relative"]<1e-3
    }
    list(model=models[[choice]],models=models,status=status,regular=isTRUE(agree),
    gaps=gaps,reused=FALSE,boundary=FALSE,structure="full",stage="B_shift_gamma")
  }

  tag <- function(d, multiplier) cbind(multiplier = multiplier, addition_g = oc_c0 * multiplier, d)
  tests <- pairs <- layers <- status <- agreement <- checks <- list()
  for (system in names(fits)) for (multiplier in oc_multipliers) {
    key <- paste(system, multiplier, sep = " | ")
    rr <- oc_fit_one(system, multiplier)
    if (!isTRUE(rr$regular)) stop("Sensitivity optimizer agreement unresolved: ", key)
    q <- ss_summarize(rr, fits[[system]], system)
    tests[[key]] <- tag(q$tests, multiplier)
    pairs[[key]] <- tag(q$pairs, multiplier)
    layers[[key]] <- tag(q$layers, multiplier)
    status[[key]] <- tag(rr$status, multiplier)
    agreement[[key]] <- data.frame(system = system, multiplier = multiplier,
    reused = multiplier == 1, regular = rr$regular,
    logLik_gap = if (multiplier == 1) 0 else rr$gaps["logLik"],
    cell_link_gap = if (multiplier == 1) 0 else rr$gaps["link"],
    SE_relative_gap = if (multiplier == 1) 0 else rr$gaps["SE_relative"])
    ee <- emmeans(rr$model, ~site_type, weights = "equal", component = "cond")
    sites <- levels(fits[[system]]$data$site_type)
    for (j in seq_len(nrow(q$pairs))) {
      az <- strsplit(q$pairs$comparison[j], " / ", fixed = TRUE)[[1]]
      L <- setNames(as.numeric(sites == az[1]) - as.numeric(sites == az[2]), sites)
      cc <- as.data.frame(summary(contrast(ee, list(check = L), adjust = "none"), type = "link"))
      checks[[length(checks) + 1L]] <- data.frame(system = system, multiplier = multiplier,
      comparison = q$pairs$comparison[j], log_ratio_gap = abs(cc$estimate-q$pairs$log_ratio[j]),
      SE_gap = abs(cc$SE-q$pairs$SE[j]))
    }
  }
  checks <- do.call(rbind, checks)
  stopifnot(max(checks$log_ratio_gap) < 1e-6, max(checks$SE_gap) < 1e-6)
  after <- lapply(current, function(r) list(beta=fixef(r$current$model)$cond,
  V=vcov(r$current$model)$cond, ll=as.numeric(logLik(r$current$model))))
  stopifnot(identical(before, after))
  list(tests = do.call(rbind, tests), pairs = do.call(rbind, pairs),
  layers = do.call(rbind, layers), status = do.call(rbind, status),
  agreement = do.call(rbind, agreement), contrast_checks = checks)
}

# Residual simulations use the fitted core effects, 1000 draws and no refitting.
# The lower response floor is the added mass divided by the sampled volume.
# Simulated values below this floor are retained and counted, not clipped.
run_perennial_gamma_diagnostics <- function(current) {
  perennial_require_packages(diagnostics = TRUE)
  stopifnot(as.character(packageVersion("DHARMa")) == "0.5.0",
  as.character(packageVersion("glmmTMB")) == "1.1.15.2")
  gamma_root_models <- lapply(current, function(r) r$current$model)
  gamma_root_data <- lapply(current, function(r) {
    d <- r$data
    d$root_model_response <- 1000 * (d$root_weight + 0.00017) / d$volume_cm3
    d
  })
  gamma_before <- lapply(gamma_root_models, function(m) list(
  beta=fixef(m)$cond, V=vcov(m)$cond, ll=as.numeric(logLik(m))))
  gamma_conditional_dharma <- function(m,seed) {
    ee <- m$obj$env
    original_codes <- lapply(ee$data$terms,function(z)z$simCode)
    stopifnot(length(original_codes)==1L)
    restore_codes <- function() {
      for(j in seq_along(original_codes)) ee$data$terms[[j]]$simCode <- original_codes[[j]]
      if(!is.null(ee$rtmb_data_env)) ee$rtmb_data_env$d <- ee$data
    }
    on.exit(restore_codes(),add=TRUE)
    notes <- character()
    warnings_seen <- character()
    ds <- withCallingHandlers(DHARMa::simulateResiduals(
    fittedModel=m,n=1000,simulateREs="conditional",refit=FALSE,
    integerResponse=FALSE,seed=seed,plot=FALSE),
    message=function(z){notes<<-c(notes,conditionMessage(z))
      invokeRestart("muffleMessage")},
    warning=function(z){warnings_seen<<-c(warnings_seen,conditionMessage(z))
      invokeRestart("muffleWarning")})
    fix_code <- getFromNamespace(".valid_simcode","glmmTMB")[["fix"]]
    current_codes <- vapply(ee$data$terms,function(z)z$simCode,numeric(1))
    stopifnot(all(current_codes==fix_code))
    restore_codes()
    stopifnot(identical(lapply(ee$data$terms,function(z)z$simCode),original_codes))
    list(ds=ds,messages=notes,warnings=warnings_seen,codes_restored=TRUE)
  }
  gamma_diagnostics <- list()
  gamma_diagnostic_rows <- list()
  gamma_residual_rows <- list()
  for(i in seq_along(gamma_root_models)) {
    s <- names(gamma_root_models)[i]
    m <- gamma_root_models[[s]]
    d <- gamma_root_data[[s]]
    seed <- c(orchards=20261116L, hedgerows=20261117L)[[s]]
    z <- gamma_conditional_dharma(m,seed)
    ds <- z$ds
    # Analytic Gamma probabilities provide an independent check of simulation settings.
    mu <- as.numeric(predict(m,type="response",re.form=NULL))
    shape <- 1/sigma(m)^2
    analytic_pit <- pgamma(d$root_model_response,shape=shape,scale=mu/shape)
    pit_gap <- max(abs(analytic_pit-ds$scaledResiduals))
    stopifnot(all(dim(ds$simulatedResponse)==c(nrow(d),1000L)),
    all(ds$simulatedResponse>0),pit_gap<0.10,
    isTRUE(all.equal(as.numeric(ds$observedResponse),d$root_model_response,tolerance=1e-10)))
    uu <- DHARMa::testUniformity(ds,plot=FALSE)
    dd <- DHARMa::testDispersion(ds,plot=FALSE)
    oo <- DHARMa::testOutliers(ds,type="binomial",plot=FALSE)
    # A literal-zero test is uninformative because this modeled response is positive.
    # Record simulations below the observation-specific added-mass floor without clipping.
    floor_density <- 1000*0.00017/d$volume_cm3
    below_floor <- rowMeans(sweep(ds$simulatedResponse,1,floor_density,"<"))
    gamma_diagnostic_rows[[s]] <- data.frame(system=s,n=nrow(d),cores=nlevels(d$core),
    original_zeros=sum(d$root_weight==0),simulations=1000L,seed=seed,
    uniformity_D=unname(uu$statistic),uniformity_p=uu$p.value,
    dispersion_ratio=unname(dd$statistic),dispersion_p=dd$p.value,
    outliers=sum(ds$scaledResiduals==0|ds$scaledResiduals==1),outlier_p=oo$p.value,
    analytic_PIT_max_gap=pit_gap,expected_below_added_floor=sum(below_floor),
    conditional_verified=TRUE,simulation_codes_restored=z$codes_restored,
    messages=paste(unique(z$messages),collapse="; "),warnings=paste(unique(z$warnings),collapse="; "))
    gamma_residual_rows[[s]] <- data.frame(system=s,sample_code=d$sample_code,
    management=as.character(d$site_type),core=as.character(d$core),
    depth=as.character(d$depth_factor),root_mass_g=d$root_weight,volume_cm3=d$volume_cm3,
    original_zero=d$root_weight==0,modeled_density=d$root_model_response,
    conditional_fitted=mu,residual=ds$scaledResiduals,analytic_PIT=analytic_pit,
    simulated_probability_below_added_floor=below_floor)
    gamma_diagnostics[[s]] <- z
  }
  gamma_diagnostic_table <- do.call(rbind,gamma_diagnostic_rows)
  gamma_residual_table <- do.call(rbind,gamma_residual_rows)
  gamma_after <- lapply(gamma_root_models,function(m)list(
  beta=fixef(m)$cond,V=vcov(m)$cond,ll=as.numeric(logLik(m))))
  stopifnot(identical(gamma_before,gamma_after))
  list(diagnostics = gamma_diagnostic_table, residuals = gamma_residual_table,
  simulation_objects = gamma_diagnostics)
}


# These are scientific residual plots, not manuscript-production utilities.
plot_perennial_gamma_diagnostics <- function(current, diagnostics, output_dir) {
  gamma_residual_table <- diagnostics$residuals
  gamma_root_data <- lapply(current, function(r) r$data)
  gamma_plot_one <- function(s) {
    z <- gamma_residual_table[gamma_residual_table$system==s,,drop=FALSE]
    d <- gamma_root_data[[s]]
    pc <- ifelse(z$original_zero,17,16)
    cl <- ifelse(z$original_zero,"#B86019","#245A81")
    op <- par(mfrow=c(2,2),mar=c(4.5,4.5,2.2,1),oma=c(0,0,2,0))
    on.exit(par(op),add=TRUE)
    ii <- order(z$residual)
    plot(ppoints(nrow(z)),z$residual[ii],xlim=c(0,1),ylim=c(0,1),
    xlab="Expected uniform quantile",ylab="Observed residual",
    main="Residual distribution",pch=pc[ii],col=cl[ii])
    abline(0,1,lty=2,col="grey45")
    plot(z$conditional_fitted,z$residual,log="x",ylim=c(0,1),
    xlab=expression("Fitted density (mg "*cm^{-3}*")"),ylab="Residual",
    main="Residuals versus fitted density",pch=pc,col=cl)
    abline(h=0.5,lty=2,col="grey55")
    legend("topright",c("Roots recovered","No roots recovered"),
    pch=c(16,17),col=c("#245A81","#B86019"),bty="n",cex=0.8)
    dep <- d$depth_factor
    boxplot(z$residual~dep,ylim=c(0,1),outline=FALSE,col="grey95",
    xlab="Depth interval (cm)",ylab="Residual",main="Residuals by depth")
    offsets <- (as.integer(factor(z$core))-mean(as.integer(factor(z$core))))*0.025
    points(as.integer(dep)+offsets,z$residual,pch=pc,col=cl)
    abline(h=0.5,lty=2,col="grey55")
    labels <-     if(s=="orchards")c("20-year","60-year") else c("Bare margin","10-year","30-year")
    boxplot(z$residual~d$site_type,ylim=c(0,1),outline=FALSE,col="grey95",names=labels,
    xlab="Comparison group",ylab="Residual",main="Residuals by group")
    points(as.integer(d$site_type)+offsets,z$residual,pch=pc,col=cl)
    abline(h=0.5,lty=2,col="grey55")
    mtext(s,outer=TRUE,line=0.3,font=2,cex=1.2)
  }

  dir.create(output_dir, recursive=TRUE, showWarnings=FALSE)
  pdf(file.path(output_dir, "conditional_residual_diagnostics.pdf"), width=10, height=7)
  on.exit(dev.off(), add=TRUE)
  for (system in names(current)) gamma_plot_one(system)
  invisible(NULL)
}

# Check the destination before any input processing or model fitting.
# Resolve existing ancestors so aliases and symlinks cannot reach protected files.
validate_perennial_output_dir <- function(module_dir, output_dir) {
  stopifnot(is.character(output_dir), length(output_dir) == 1L,
            !is.na(output_dir), nzchar(output_dir))
  module <- normalizePath(module_dir, winslash = "/", mustWork = TRUE)
  if (!dir.exists(module)) stop("The module directory must exist")
  destination <- path.expand(output_dir)
  if (!grepl("^(/|[A-Za-z]:)", destination)) destination <- file.path(getwd(), destination)
  pending <- character()
  while (!file.exists(destination) && !dir.exists(destination)) {
    parent <- dirname(destination)
    if (identical(parent, destination)) stop("Cannot normalize the output directory")
    pending <- c(basename(destination), pending)
    destination <- parent
  }
  destination <- normalizePath(destination, winslash = "/", mustWork = TRUE)
  for (part in pending) {
    if (part == "..") destination <- dirname(destination)
    else if (part != ".") destination <- file.path(destination, part)
  }
  if (identical(destination, module) || startsWith(destination, paste0(module, "/"))) {
    stop("Choose an output directory outside the analysis module and its inputs, saved results and provenance")
  }
  if (file.exists(destination) && !dir.exists(destination)) stop("The output path is an existing file")
  if (dir.exists(destination) && length(list.files(destination, all.files = TRUE, no.. = TRUE))) {
    stop("The output directory must be new or empty")
  }
  destination
}

# A future rerun writes separate files. Supplied saved_results remain unchanged.
write_perennial_rerun <- function(current, sensitivity = NULL, diagnostics = NULL,
output_dir = file.path("outputs_rerun", "current_perennial_root")) {
  # Recheck immediately before writing in case another process used the destination.
  if (file.exists(output_dir) && !dir.exists(output_dir)) stop("The output path is an existing file")
  if (dir.exists(output_dir) && length(list.files(output_dir, all.files = TRUE, no.. = TRUE))) {
    stop("The output directory must be new or empty")
  }
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)
  write_json <- function(x, name) jsonlite::write_json(x, file.path(output_dir, name),
  dataframe = "rows", auto_unbox = TRUE, digits = 16, na = "null", pretty = TRUE)
  for (what in c("tests", "pairs", "layers")) {
    write_json(do.call(rbind, lapply(current, function(r) r[[what]])), paste0("baseline_", what, ".json"))
  }
  write_json(do.call(rbind, lapply(current, function(r) r$current$status)), "baseline_status.json")
  write_json(check_perennial_contrasts(current), "baseline_contrast_checks.json")
  if (!is.null(sensitivity)) write_json(sensitivity, "constant_sensitivity.json")
  if (!is.null(diagnostics)) {
    write_json(diagnostics[c("diagnostics", "residuals")], "conditional_diagnostics.json")
    saveRDS(diagnostics$simulation_objects, file.path(output_dir, "conditional_simulations.rds"))
    plot_perennial_gamma_diagnostics(current, diagnostics, output_dir)
  }
  saveRDS(current, file.path(output_dir, "perennial_gamma_models.rds"))
  writeLines(capture.output(sessionInfo()), file.path(output_dir, "session_info.txt"))
  invisible(output_dir)
}

run_perennial_root_workflow <- function(module_dir,
output_dir = file.path("outputs_rerun", "current_perennial_root"),
sensitivity = TRUE, diagnostics = TRUE) {
  output_dir <- validate_perennial_output_dir(module_dir, output_dir)
  input <- read_perennial_root_input(file.path(module_dir, "input", "perennial_root_input.csv"))
  current <- fit_current_perennial_roots(input)
  sensitivity_result <- if (sensitivity) run_perennial_constant_sensitivity(current) else NULL
  diagnostic_result <- if (diagnostics) run_perennial_gamma_diagnostics(current) else NULL
  write_perennial_rerun(current, sensitivity_result, diagnostic_result, output_dir)
  invisible(list(current = current, sensitivity = sensitivity_result, diagnostics = diagnostic_result))
}
