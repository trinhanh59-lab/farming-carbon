# Matched model audit: identical samples, fixed contrasts, ML, and core intercept.
# A/B preserve the MASS-SCALE addition: B = 1000*(mass+0.00017)/volume.
# Adding a NEW constant directly to density would change two choices at once.
# Compare common equal-layer mean LOG field contrasts, not unlike main-effect tests.
# This weighting describes an average log contrast, not integrated profile root mass.
ss_safe <- function(expr,fallback=NA_real_) tryCatch(expr,error=function(e)fallback)
ss_fixed <- function(structure) if(structure=="full") ~site_type*depth_factor else ~site_type+depth_factor
ss_start <- function(m,beta=NULL,include_power=TRUE) {
  pl <- m$obj$env$parList()
  dn <- intersect(c("betad","betadisp"),names(pl));stopifnot(length(dn)==1)
  z <- list(beta=if(is.null(beta))unname(fixef(m)$cond)else unname(beta),
    theta=unname(m$fit$par[names(m$fit$par)=="theta"]))
  z[[dn]] <- unname(fixef(m)$disp)
  if(include_power) z$psi <- unname(m$fit$par[names(m$fit$par)=="psi"])
  z
}
ss_grid <- function(x) {
  d <- x$data
  g <- expand.grid(site_type=levels(d$site_type),depth_factor=levels(d$depth_factor))
  g$site_type <- factor(g$site_type,levels=levels(d$site_type))
  g$depth_factor <- factor(g$depth_factor,levels=levels(d$depth_factor))
  g$core <- factor(levels(d$core)[1],levels=levels(d$core));g
}
ss_status_one <- function(m,system,stage,structure,optimizer,warnings="",error="",elapsed=0) {
  b <- if(is.null(m)) NA_real_ else fixef(m)$cond
  V <- if(is.null(m)) matrix(NA_real_) else ss_safe(vcov(m)$cond,matrix(NA_real_))
  cv <- all(is.finite(V))&&all(diag(V)>0)&&ss_safe(min(eigen(V,symmetric=TRUE,only.values=TRUE)$values)>0,FALSE)
  pw <- if(is.null(m)||stage %in% c("A_mass_gamma","B_shift_gamma"))NA_real_ else ss_safe(unname(family_params(m)[1]))
  edge <- is.finite(pw)&&(pw<1.0001||pw>1.9999)
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
  d <- x$data;f <- as.formula(paste("audit_response",if(structure=="full")"~site_type*depth_factor"else"~site_type+depth_factor","+(1|core)"))
  d$audit_response <- switch(stage,A_mass_gamma=d$root_weight+0.00017,
    B_shift_gamma=1000*(d$root_weight+0.00017)/d$volume_cm3,
    C_shift_tweedie=1000*(d$root_weight+0.00017)/d$volume_cm3)
  stopifnot(all(d$audit_response>0),length(d$audit_response)==nrow(d))
  fam <- if(stage %in% c("A_mass_gamma","B_shift_gamma"))Gamma(link="log")else tweedie(link="log")
  bridge <- stage=="C_shift_tweedie"
  controls <- list(nlminb=glmmTMBControl(optCtrl=list(iter.max=if(bridge)400 else 1000,
    eval.max=if(bridge)800 else 2000,rel.tol=1e-10)),
    BFGS=glmmTMBControl(optimizer=optim,optArgs=list(method="BFGS"),
      optCtrl=list(maxit=if(bridge)400 else 1000,reltol=1e-12)))
  models <- list();sts <- list();grid <- ss_grid(x)
  for(op in names(controls)) {
    cat(system,stage,structure,op,"\n")
    st <- start;if(op=="BFGS")st$theta <- log(.5)
    ww <- character();ee <- "";t0 <- proc.time()[["elapsed"]]
    setTimeLimit(elapsed=45,transient=TRUE)
    m <- tryCatch(withCallingHandlers(glmmTMB(f,data=d,family=fam,
      ziformula=~0,dispformula=~1,REML=FALSE,contrasts=x$contrast_spec,
      na.action=na.fail,start=st,control=controls[[op]]),
      warning=function(w){ww<<-c(ww,conditionMessage(w));invokeRestart("muffleWarning")}),
      error=function(e){ee<<-conditionMessage(e);NULL})
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
    gaps["power"] <- if(bridge)diff(range(status$power))else 0
    gaps["dispersion_relative"] <- diff(range(status$dispersion))/mean(status$dispersion)
    agree <- all(is.finite(gaps))&&gaps["logLik"]<1e-5&&gaps["link"]<1e-3&&
      gaps["SE_relative"]<1e-2&&gaps["power"]<1e-4&&gaps["dispersion_relative"]<1e-3
  }
  list(model=m,models=models,status=status,regular=isTRUE(agree),gaps=gaps,
    reused=FALSE,boundary=FALSE,structure=structure,stage=stage)
}
ss_reuse_raw <- function(x,system,structure) {
  if(structure=="additive") {
    m <- x$primary;st <- ss_status_one(m,system,"D_raw_tweedie",structure,"selected primary",
      paste(attr(m,"captured_warnings"),collapse="; "))
    return(list(model=m,models=list(selected=m),status=st,regular=isTRUE(st$numeric_ok),
      gaps=rep(NA_real_,5),reused=TRUE,boundary=FALSE,structure=structure,stage="D_raw_tweedie"))
  }
  key <- if(system=="hedgerows")"hedgerows_tight"else system
  r <- ri_full_check_all[[key]];sel <- r$selected[[system]]
  ms <- r$full_fits[[system]]
  sts <- do.call(rbind,lapply(names(ms),function(op)ss_status_one(ms[[op]],system,
    "D_raw_tweedie",structure,op,r$status$warnings[match(op,r$status$optimizer)])))
  list(model=sel$model,models=ms,status=sts,regular=isTRUE(sel$provisional_test_eligible),
    gaps=c(logLik=sel$logLik_gap,link=sel$link_gap),reused=TRUE,
    boundary=isTRUE(sel$all_zero_cell),structure=structure,stage="D_raw_tweedie")
}
ss_summarize <- function(result,x,system) {
  k <- result$stage;structure <- result$structure;ok <- result$regular
  empty <- data.frame(system=system,stage=k,structure=structure,regular=ok,
    boundary=result$boundary,management_chisq=NA_real_,management_df=nlevels(x$data$site_type)-1,
    management_p=NA_real_,depth_chisq=NA_real_,depth_df=nlevels(x$data$depth_factor)-1,
    depth_p=NA_real_,interaction_chisq=NA_real_,interaction_df=if(structure=="full")
      (nlevels(x$data$site_type)-1)*(nlevels(x$data$depth_factor)-1)else 0,
    interaction_p=NA_real_)
  if(!ok)return(list(tests=empty,pairs=data.frame(),layers=data.frame()))
  m <- result$model;b <- fixef(m)$cond;V <- vcov(m)$cond
  g <- ss_grid(x);X <- model.matrix(ss_fixed(structure),g,contrasts.arg=x$contrast_spec)[,names(b),drop=FALSE]
  sites <- levels(x$data$site_type);deps <- levels(x$data$depth_factor)
  # rowMeans of predictions on the log scale correspond to geometric-mean ratios.
  avgX <- function(index)colMeans(X[index,,drop=FALSE])
  Lsite <- do.call(rbind,lapply(sites[-1],function(z)avgX(g$site_type==z)-avgX(g$site_type==sites[1])))
  Ldepth <- do.call(rbind,lapply(deps[-1],function(z)avgX(g$depth_factor==z)-avgX(g$depth_factor==deps[1])))
  wald <- function(L) {
    e <- drop(L%*%b);C <- L%*%V%*%t(L)
    chi <- as.numeric(crossprod(e,solve(C,e)))
    c(statistic=chi,df=nrow(L),p=pchisq(chi,nrow(L),lower.tail=FALSE))
  }
  wa <- wald(Lsite);wd <- wald(Ldepth)
  empty$management_chisq <- wa[1];empty$management_p <- wa[3]
  empty$depth_chisq <- wd[1];empty$depth_p <- wd[3]
  if(structure=="full") {
    jj <- which(grepl(":",names(b),fixed=TRUE));L <- diag(length(b))[jj,,drop=FALSE]
    wi <- wald(L);empty$interaction_chisq <- wi[1];empty$interaction_p <- wi[3]
  }
  contrasts <- combn(sites,2,simplify=FALSE);pairs <- list();layers <- list()
  contrast_row <- function(L,a,z,dep="equal-layer log average") {
    est <- sum(L*b);se <- sqrt(drop(L%*%V%*%L))
    data.frame(system=system,stage=k,structure=structure,comparison=paste(a,"/",z),
      depth=dep,log_ratio=est,SE=se,ratio=exp(est),lower_95=exp(est-qnorm(.975)*se),
      upper_95=exp(est+qnorm(.975)*se),p_unadjusted=2*pnorm(-abs(est/se)))
  }
  for(j in seq_along(contrasts)) {
    a <- contrasts[[j]][1];z <- contrasts[[j]][2]
    pairs[[j]] <- contrast_row(avgX(g$site_type==a)-avgX(g$site_type==z),a,z)
    for(dep in deps)layers[[length(layers)+1]] <- contrast_row(
      X[g$site_type==a&g$depth_factor==dep,]-X[g$site_type==z&g$depth_factor==dep,],a,z,dep)
  }
  list(tests=empty,pairs=do.call(rbind,pairs),layers=do.call(rbind,layers))
}
ss_run_system <- function(system) {
  x <- fits[[system]];d <- x$data;records <- list();out <- list();checks <- list()
  for(structure in c("additive","full")) {
    X <- model.matrix(ss_fixed(structure),d,contrasts.arg=x$contrast_spec)
    stopifnot(qr(X)$rank==ncol(X))
    # Least-squares log-response coefficients provide starts, not final estimates.
    b0 <- lm.fit(X,log(d$root_weight+.00017))$coefficients
    startA <- list(beta=unname(b0),theta=log(.5))
    A <- ss_fit_pair(x,system,"A_mass_gamma",structure,startA)
    records[[paste(structure,"A")]] <- A
    if(is.null(A$model)||!any(A$status$numeric_ok))stop("Gamma anchor unresolved; inspect before proceeding")
    # Exact depth-specific scale adjustment for the normalized Gamma start.
    scale_beta <- lm.fit(X,log(1000/d$volume_cm3))$coefficients
    stopifnot(max(abs(drop(X%*%scale_beta)-log(1000/d$volume_cm3)))<1e-10)
    bB <- fixef(A$model)$cond+scale_beta[names(fixef(A$model)$cond)]
    B <- ss_fit_pair(x,system,"B_shift_gamma",structure,ss_start(A$model,bB,FALSE))
    records[[paste(structure,"B")]] <- B
    if(!is.null(B$model)&&any(B$status$numeric_ok)) {
      # Tweedie dispersion and power starts come from the existing Tweedie fit,
      # because Gamma's dispersion parameter has a different interpretation.
      stC <- ss_start(x$primary,include_power=TRUE)
      stC$beta <- unname(fixef(B$model)$cond)
      stC$theta <- unname(B$model$fit$par[names(B$model$fit$par)=="theta"])
      C <- ss_fit_pair(x,system,"C_shift_tweedie",structure,stC)
    }else C <- list(model=NULL,models=list(),status=ss_status_one(NULL,system,
      "C_shift_tweedie",structure,"not attempted",error="Gamma density start unresolved"),
      regular=FALSE,gaps=rep(NA_real_,5),reused=FALSE,boundary=FALSE,
      structure=structure,stage="C_shift_tweedie")
    records[[paste(structure,"C")]] <- C
    records[[paste(structure,"D")]] <- ss_reuse_raw(x,system,structure)
    for(letter in c("A","B","C","D"))out[[paste(structure,letter)]] <-
      ss_summarize(records[[paste(structure,letter)]],x,system)
    aa <- out[[paste(structure,"A")]];bb <- out[[paste(structure,"B")]]
    same <- A$regular&&B$regular
    ratgap <- if(same)max(abs(aa$pairs$log_ratio-bb$pairs$log_ratio))else NA_real_
    segap <- if(same)max(abs(aa$pairs$SE-bb$pairs$SE))else NA_real_
    llgap <- if(same)abs(as.numeric(logLik(B$model))-as.numeric(logLik(A$model))+
      sum(log(1000/d$volume_cm3)))else NA_real_
    checks[[structure]] <- data.frame(system=system,structure=structure,
      Gamma_equivalence_regular=same,field_log_ratio_max_gap=ratgap,field_SE_max_gap=segap,
      likelihood_Jacobian_error=llgap,
      interaction_chisq_gap=if(same&&structure=="full")abs(aa$tests$interaction_chisq-bb$tests$interaction_chisq)else NA_real_)
  }
  sts <- do.call(rbind,lapply(records,function(r)r$status))
  tests <- do.call(rbind,lapply(out,function(r)r$tests))
  pairs <- do.call(rbind,lapply(out,function(r)r$pairs))
  layers <- do.call(rbind,lapply(out,function(r)r$layers))
  checks <- do.call(rbind,checks)
  stopifnot(identical(root_source,ss_source_before),identical(ss_primary_before,
    lapply(fits,function(x)list(beta=fixef(x$primary)$cond,logLik=as.numeric(logLik(x$primary))))))
  summary <- list(system=system,n=nrow(d),cores=nlevels(d$core),sample_ids=d$sample_code,
    status=sts,tests=tests,pairs=pairs,normalization_checks=checks,
    source_preserved=TRUE,primary_preserved=TRUE,
    scope="Same samples; diagnostic sensitivity audit. No AIC across responses or cross-family LRT.")
  print(tests,digits=5,row.names=FALSE)
  print(checks,digits=6,row.names=FALSE)
  cat("SAME_SAMPLE_JSON_BEGIN\n")
  cat(toJSON(summary,dataframe="rows",auto_unbox=TRUE,na="null",digits=16))
  cat("\nSAME_SAMPLE_JSON_END\n")
  cat("SAME_SAMPLE_SYSTEM_COMPLETE:",system,"\n")
  invisible(list(records=records,summary=summary,layers=layers))
}
cat("SAME_SAMPLE_FUNCTIONS_READY\n")
