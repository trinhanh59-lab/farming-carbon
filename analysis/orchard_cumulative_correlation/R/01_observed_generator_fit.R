# Fit the agreed Gamma/log model. This cell changes no source values.
# OU adds positive correlation that decreases with the actual depth separation.
# Full and null models have the SAME covariance terms; only the fixed interaction differs.
full_formula <- cumulative_c_stock ~ depth_cm * site_type + (1|core) + ou(position + 0|core)
null_formula <- cumulative_c_stock ~ depth_cm + site_type + (1|core) + ou(position + 0|core)

# Keep warnings and failed attempts visible, rather than selecting a convenient result.
fit_once <- function(formula, dat, start=NULL, optimizer="nlminb") {
  warnings <- character()
  ctl <- if(optimizer=="BFGS") glmmTMBControl(optimizer=optim,
      optArgs=list(method="BFGS"),optCtrl=list(maxit=3000,reltol=1e-10),parallel=1)
    else glmmTMBControl(optCtrl=list(iter.max=3000,eval.max=3000),parallel=1)
  fit <- tryCatch(withCallingHandlers(glmmTMB(formula,data=dat,
        family=Gamma(link="log"),start=start,control=ctl),
        warning=function(w){warnings <<- c(warnings,conditionMessage(w));invokeRestart("muffleWarning")}),
        error=function(e)e)
  list(fit=fit,warnings=warnings)
}
fit_info <- function(attempt,label) {
  f <- attempt$fit
  if(inherits(f,"error")) return(data.frame(attempt=label,logLik=NA_real_,convergence=99L,
      pdHess=FALSE,max_gradient=Inf,core_SD=NA_real_,OU_SD=NA_real_,range_cm=NA_real_,
      gamma_shape=NA_real_,warnings=conditionMessage(f)))
  theta <- unname(f$fit$par[names(f$fit$par)=="theta"])
  grad <- tryCatch(max(abs(f$obj$gr(f$fit$par))),error=function(e)Inf)
  data.frame(attempt=label,logLik=-f$fit$objective,convergence=f$fit$convergence,
    pdHess=isTRUE(f$sdr$pdHess),max_gradient=grad,core_SD=exp(theta[1]),
    OU_SD=if(length(theta)==3)exp(theta[2])else NA_real_,
    range_cm=if(length(theta)==3)10/exp(theta[3])else NA_real_,
    gamma_shape=exp(unname(f$fit$par[names(f$fit$par)=="betadisp"])),
    warnings=paste(unique(attempt$warnings),collapse=" | "))
}
theta_starts <- list(default=NULL,
   medium=c(log(.15),log(.10),log(.2)),
   short=c(log(.05),log(.20),log(1)),
   long=c(log(.05),log(.20),log(.03)),
   mostly_intercept=c(log(.20),log(.02),log(.2)),
   mostly_OU=c(log(.02),log(.20),log(.2)))
fit_many <- function(formula,dat,extra_start=NULL) {
  starts <- lapply(theta_starts,function(th)if(is.null(th))NULL else list(theta=th))
  if(!is.null(extra_start)) starts <- c(starts,list(nested=extra_start))
  fits <- list(); rows <- list(); n <- 0L
  for(s in names(starts)) for(op in c("nlminb","BFGS")) {
    n <- n+1L; label <- paste(s,op,sep="_")
    fits[[n]] <- fit_once(formula,dat,starts[[s]],op)
    rows[[n]] <- fit_info(fits[[n]],label)
  }
  tab <- do.call(rbind,rows)
  finite <- which(is.finite(tab$logLik))
  stopifnot(length(finite)>0L)
  top <- max(tab$logLik[finite])
  near <- which(is.finite(tab$logLik)&tab$logLik>=top-1e-5)
  valid <- near[tab$pdHess[near]&tab$convergence[near]==0L&tab$max_gradient[near]<1e-3]
  best <- if(length(valid))valid[which.max(tab$logLik[valid])]else finite[which.max(tab$logLik[finite])]
  list(fit=fits[[best]]$fit,attempts=tab,best=best,near=near,
       basic_ok=length(valid)>0L,max_logLik=top)
}
null_search <- fit_many(null_formula,orchard_data)
# The full model starts at the null optimum, with the extra interaction coefficients set to zero.
full_names <- colnames(model.matrix(~depth_cm*site_type,orchard_data))
initial_beta <- setNames(rep(0,length(full_names)),full_names)
null_beta <- fixef(null_search$fit)$cond
initial_beta[names(null_beta)] <- null_beta
nested_start <- list(beta=unname(initial_beta),
  betadisp=unname(null_search$fit$fit$par[names(null_search$fit$fit$par)=="betadisp"]),
  theta=unname(null_search$fit$fit$par[names(null_search$fit$fit$par)=="theta"]))
full_search <- fit_many(full_formula,orchard_data,extra_start=nested_start)
cat("NULL MODEL: NO FIXED INTERACTION\n")
print(null_search$attempts[,1:9],digits=7,row.names=FALSE)
cat("FULL MODEL: DEPTH BY ORCHARD INTERACTION\n")
print(full_search$attempts[,1:9],digits=7,row.names=FALSE)
cat("Selected full covariance components\n"); print(VarCorr(full_search$fit))
cat("Full-model optimizer warnings\n")
print(unique(full_search$attempts$warnings[nzchar(full_search$attempts$warnings)]))
cat("Null-model optimizer warnings\n")
print(unique(null_search$attempts$warnings[nzchar(null_search$attempts$warnings)]))
full_fit <- full_search$fit; null_fit <- null_search$fit
observed_LR <- 2*(full_search$max_logLik-null_search$max_logLik)
cat("Observed likelihood-ratio statistic (not yet a validated p value):",observed_LR,"\n")
cat("Basic full/null fit gates:",full_search$basic_ok,null_search$basic_ok,"\n")
stopifnot(identical(serialize(orchard_data,NULL),orchard_inputs_before))
cat("ORCHARD_OU_FIT_REVIEW_READY_STOCK_INPUTS_UNCHANGED\n")
