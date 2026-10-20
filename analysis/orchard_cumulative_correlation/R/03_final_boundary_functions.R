# Numerical boundary candidates for the same Gamma + core + OU family.
# A zero core variance is evaluated by omitting only that redundant component.
# Zero OU rate is the ordinary core-intercept Gamma model.
# Infinite Gamma shape has an exact multivariate-normal log-stock likelihood.
X_full <- model.matrix(~depth_cm*site_type,orchard_data)
X_null <- model.matrix(~depth_cm+site_type,orchard_data)
endpoint_distance <- abs(outer(c(1,2,5,7.5),c(1,2,5,7.5),"-"))
full_ou_formula <- cumulative_c_stock~depth_cm*site_type+ou(position+0|core)
null_ou_formula <- cumulative_c_stock~depth_cm+site_type+ou(position+0|core)
full_ri_formula <- cumulative_c_stock~depth_cm*site_type+(1|core)
null_ri_formula <- cumulative_c_stock~depth_cm+site_type+(1|core)

gamma_meta_original <- function(a,label,kind) {
 f <- a$fit
 if(inherits(f,"error"))return(data.frame(label=label,kind=kind,logLik=-Inf,
   convergence=99L,pdHess=FALSE,gradient=Inf,core_SD=NA_real_,OU_SD=NA_real_,
   range_cm=NA_real_,gamma_shape=NA_real_,warnings=conditionMessage(f)))
 th <- unname(f$fit$par[names(f$fit$par)=="theta"])
 data.frame(label=label,kind=kind,logLik=-f$fit$objective,convergence=f$fit$convergence,
  pdHess=isTRUE(f$sdr$pdHess),gradient=max(abs(f$obj$gr(f$fit$par))),
  core_SD=if(kind=="OU")0 else exp(th[1]),
  OU_SD=if(kind=="RI")0 else exp(th[if(kind=="OU")1 else 2]),
  range_cm=if(kind=="RI")Inf else 10/exp(th[if(kind=="OU")2 else 3]),
  gamma_shape=exp(unname(fixef(f)$disp)[1]),
  warnings=paste(unique(a$warnings),collapse=" | "))
}

shape_cap <- 1e6
boundary_LL_tolerance <- 0.001
bounded_gamma <- function(formula,dat,start,kind,limit=300L,op="nlminb") {
 warnings <- character()
 optimizer <- function(par,fn,gr,control=list(),...) {
  lo <- rep(-Inf,length(par));hi <- rep(Inf,length(par))
  hi[names(par)=="betadisp"] <- log(shape_cap)
  it <- which(names(par)=="theta")
  if(length(it)) {lo[it] <- -12;hi[it] <- 1}
  if(kind%in%c("OU","RI_OU")) {
   k <- tail(it,1);lo[k] <- -12;hi[k] <- 5
  }
  if(op=="BFGS") {
   # L-BFGS-B respects the same numerical bounds.
   a <- optim(par,fn,gr,method="L-BFGS-B",lower=lo,upper=hi,
      control=list(maxit=limit,factr=1e5,pgtol=1e-7))
   list(par=a$par,objective=a$value,convergence=a$convergence,message=a$message)
  } else {
   a <- nlminb(par,fn,gr,lower=lo,upper=hi,control=control,...)
   list(par=a$par,objective=a$objective,convergence=a$convergence,message=a$message)
  }
 }
 f <- tryCatch(withCallingHandlers(glmmTMB(formula,data=dat,family=Gamma(link="log"),
  start=start,control=glmmTMBControl(optimizer=optimizer,
   optCtrl=list(iter.max=limit,eval.max=2L*limit,rel.tol=1e-10),parallel=1)),
  warning=function(w){warnings<<-c(warnings,conditionMessage(w));invokeRestart("muffleWarning")}),error=function(e)e)
 list(fit=f,warnings=warnings)
}

gamma_metadata <- function(a,label,kind) {
 if(kind!="NONE")return(gamma_meta_original(a,label,kind))
 f <- a$fit
 if(inherits(f,"error"))return(gamma_meta_original(a,label,"RI"))
 data.frame(label=label,kind=kind,logLik=-f$fit$objective,convergence=f$fit$convergence,
  pdHess=isTRUE(f$sdr$pdHess),gradient=max(abs(f$obj$gr(f$fit$par))),
  core_SD=0,OU_SD=0,range_cm=NA_real_,gamma_shape=exp(unname(fixef(f)$disp)[1]),
  warnings=paste(unique(a$warnings),collapse=" | "))
}

lognormal_boundary_profile <- function(y,X) {
 stopifnot(length(y)==24L,nrow(X)==24L,ncol(X)%in%c(5L,8L))
 Z <- matrix(log(y),6,4,byrow=TRUE);n <- 24L
 m1 <- colMeans(Z[1:3,,drop=FALSE]);m2 <- colMeans(Z[4:6,,drop=FALSE]);mbar <- (m1+m2)/2
 delta_depth <- c(1,3,2.5);Xqr <- qr(X)
 evaluate <- function(q,details=FALSE) {
  rate <- if(is.infinite(q))Inf else exp(q)
  rho <- if(is.infinite(rate))rep(0,3)else exp(-rate*delta_depth)
  innovation <- if(is.infinite(rate))rep(1,3)else -expm1(-2*rate*delta_depth)
  h <- c(1,if(is.infinite(rate))rep(1,3)else -expm1(-rate*delta_depth)/sqrt(innovation))
  s <- sum(h^2)
  whiten <- function(M)cbind(M[,1],sweep(M[,2:4,drop=FALSE]-
    sweep(M[,1:3,drop=FALSE],2,rho,"*"),2,sqrt(innovation),"/"))
  delta <- if(ncol(X)==5L)sum(h*drop(whiten(matrix(m2-m1,1,4))))/s else NA_real_
  means <- if(ncol(X)==5L)rbind(mbar-delta/2,mbar+delta/2)else rbind(m1,m2)
  pred <- rbind(matrix(means[1,],3,4,byrow=TRUE),matrix(means[2,],3,4,byrow=TRUE))
  W <- whiten(Z-pred);g <- drop(W%*%h)
  P <- sum((W-outer(g/s,h))^2);A <- sum(g^2)/s
  if(!is.finite(P)||P<=0)return(if(details)NULL else 1e100)
  D <- max(1,3*A/P);r <- (D-1)/s
  SSE <- P+A/D;scale <- SSE/n
  logdet <- sum(log(innovation))+log(D)
  ll <- -n/2*(log(2*pi)+1+log(scale))-3*logdet-sum(log(y))
  if(!details)return(-ll)
  R <- if(is.infinite(rate))diag(4)else exp(-rate*endpoint_distance)
  list(logLik=ll,beta=unname(qr.coef(Xqr,as.vector(t(pred)))),core_SD=sqrt(scale*r),
   OU_SD=sqrt(scale),range_cm=10/rate,gamma_shape=Inf,covariance=scale*(r+R),
   rate=rate,r=r,kind=if(is.infinite(rate))"IID_limit"else if(r==0)"OU0"else "OU",
   profiled_D=D,P=P,A=A)
 }
 # Bracket every grid-resolved local maximum; include the exact independent-OU limit.
 grid <- seq(-14,5,by=.5);values <- vapply(grid,evaluate,numeric(1))
 peaks <- which(values[2:(length(grid)-1)]<=values[1:(length(grid)-2)]&
  values[2:(length(grid)-1)]<=values[3:length(grid)]&
  (values[2:(length(grid)-1)]<values[1:(length(grid)-2)]-1e-8|
   values[2:(length(grid)-1)]<values[3:length(grid)]-1e-8))+1L
 candidates <- lapply(grid,function(q){a<-evaluate(q,TRUE);a$valid<-FALSE;a$at_bound<-TRUE;a})
 for(j in unique(c(peaks,which.min(values))))if(j>1L&&j<length(grid)) {
  opt <- optimize(evaluate,c(grid[j-1L],grid[j+1L]),tol=1e-10)
  q <- opt$minimum;a <- evaluate(q,TRUE)
  gr <- abs(numDeriv::grad(evaluate,q));he <- as.numeric(numDeriv::hessian(evaluate,q))
  a$gradient <- gr;a$hessian_min <- he;a$at_bound <- q<= -13.99||q>=4.99
  a$valid <- is.finite(gr)&&gr<1e-3&&is.finite(he)&&he>0&&!a$at_bound
  candidates[[length(candidates)+1L]] <- a
 }
 a <- evaluate(Inf,TRUE);a$valid <- TRUE;a$gradient <- 0;a$hessian_min <- Inf;a$at_bound <- FALSE
 candidates[[length(candidates)+1L]] <- a
 ll <- vapply(candidates,function(x)x$logLik,numeric(1));valid<-vapply(candidates,function(x)x$valid,logical(1))
 j <- which(valid)[which.max(ll[valid])];g<-candidates[[j]]
 g$raw_max_logLik<-max(ll);g$search_ok<-max(ll)-g$logLik<1e-5
 g$all_logLik<-ll;g$all_candidates<-candidates;g$family<-"Gamma_shape_infinity";g
}

lognormal_boundary <- lognormal_boundary_profile

valid_gamma_candidates <- function(tab) {
 basic <- with(tab,is.finite(logLik)&convergence==0L&pdHess&is.finite(gradient)&
   gradient<1e-3&is.finite(gamma_shape)&gamma_shape<shape_cap*.99)
 rate_ok <- with(tab,!kind%in%c("OU","RI_OU")|
    (range_cm>10/exp(4.9)&range_cm<10/exp(-11.9)))
 core_ok <- with(tab,!kind%in%c("RI","RI_OU")|(core_SD>exp(-11.9)&core_SD<exp(.99)))
 ou_ok <- with(tab,!kind%in%c("OU","RI_OU")|(OU_SD>exp(-11.9)&OU_SD<exp(.99)))
 out <- basic&rate_ok&core_ok&ou_ok
 out[is.na(out)] <- FALSE
 out
}

robust_search_original <- function(dat,type="null",audit=FALSE) {
 X <- if(type=="full")X_full else X_null
 g <- lognormal_boundary(dat$cumulative_c_stock,X)
 ff <- if(type=="full")full_formula else null_formula
 fo <- if(type=="full")full_ou_formula else null_ou_formula
 fr <- if(type=="full")full_ri_formula else null_ri_formula
 fn <- if(type=="full")cumulative_c_stock~depth_cm*site_type else cumulative_c_stock~depth_cm+site_type
 # A limit that reaches the correlation search bounds remains unresolved.
 g_ok <- is.finite(g$logLik)&&all(is.finite(g$covariance))&&
  min(eigen(g$covariance,symmetric=TRUE,only.values=TRUE)$values)>0&&
  (is.infinite(g$rate)||(g$rate>exp(-13.9)&&g$rate<exp(4.9)))
 attempts <- list();meta <- list();k <- 0L
 add <- function(formula,start,kind,label,op="nlminb",limit=300L) {
  a <- bounded_gamma(formula,dat,start,kind,limit,op)
  k <<- k+1L;attempts[[k]] <<- a
  meta[[k]] <<- gamma_metadata(a,label,kind)
 }
 q <- if(is.finite(g$rate)&&g$rate>0)log(g$rate)else log(.2)
 s <- max(g$OU_SD,.03)
 b <- g$beta
 add(fo,list(beta=b,betadisp=log(500),theta=c(log(s),q)),"OU","OU_shape500")
 add(fo,list(beta=b,betadisp=log(5000),theta=c(log(s),q)),"OU","OU_shape5000")
 add(fr,list(beta=b,betadisp=log(500),theta=log(sqrt(s^2+g$core_SD^2))),"RI","RI_limit")
 add(ff,list(beta=b,betadisp=log(500),theta=c(log(.05),log(s),q)),"RI_OU","interior_small_RI")
 add(ff,list(beta=b,betadisp=log(5000),theta=c(log(.2),log(.1),log(.3))),"RI_OU","interior_large_RI")
 add(fn,list(beta=b,betadisp=log(100)),"NONE","no_latent_variance")
 tab <- do.call(rbind,meta)
 # Audit additional starts independently of whether the simulated LR is large or small.
 if(audit) {
  for(sh in c(100,10000))for(rate in c(.03,1)) {
   add(ff,list(beta=b,betadisp=log(sh),theta=c(log(.15),log(.15),log(rate))),
     "RI_OU",paste("audit",sh,rate),limit=700L)
   add(fo,list(beta=b,betadisp=log(sh),theta=c(log(.2),log(rate))),
     "OU",paste("auditOU",sh,rate),limit=700L)
  }
  tab <- do.call(rbind,meta)
 }
 ordinary <- valid_gamma_candidates(tab)
 # Escalate the highest finite non-boundary candidate if its active checks fail.
 finite <- which(is.finite(tab$logLik)&tab$gamma_shape<shape_cap*.99)
 if(length(finite)) {
  j <- finite[which.max(tab$logLik[finite])]
  if(!ordinary[j]&&tab$logLik[j]>g$logLik-boundary_LL_tolerance&&
     (tab$kind[j]=="OU"||tab$kind[j]=="RI"||tab$core_SD[j]>.005)) {
   a <- attempts[[j]]$fit
   st <- list(beta=unname(fixef(a)$cond),betadisp=unname(fixef(a)$disp),
      theta=unname(a$fit$par[names(a$fit$par)=="theta"]))
   fm <- switch(tab$kind[j],OU=fo,RI=fr,RI_OU=ff,NONE=fn)
   if(!length(st$theta))st$theta <- NULL
   add(fm,st,tab$kind[j],"retry_active",op="BFGS",limit=700L)
   tab <- do.call(rbind,meta)
   ordinary <- valid_gamma_candidates(tab)
  }
 }
 valid_LL <- c(if(g_ok)g$logLik else -Inf,ifelse(ordinary,tab$logLik,-Inf))
 j <- which.max(valid_LL);selected_LL <- valid_LL[j]
 # A numerically unresolved higher likelihood is not discarded.
 raw_LL <- max(c(g$logLik,tab$logLik),na.rm=TRUE)
 ok <- is.finite(selected_LL)&&raw_LL-selected_LL<=boundary_LL_tolerance
 if(j==1L) {
  selected <- data.frame(label="exact_shape_infinity",kind="LOGNORMAL_LIMIT",logLik=g$logLik,
   convergence=0L,pdHess=g_ok,gradient=NA_real_,core_SD=g$core_SD,OU_SD=g$OU_SD,
   range_cm=g$range_cm,gamma_shape=Inf,warnings="")
  fit <- NULL
 } else {selected <- tab[j-1L,,drop=FALSE];fit <- attempts[[j-1L]]$fit}
 list(ok=ok,LL=selected_LL,selected=selected,fit=fit,closure=g,
   raw_max_LL=raw_LL,objective_gap=raw_LL-selected_LL,attempts=tab)
}

robust_gamma_search <- function(dat,type="null",audit=FALSE) {
 a <- robust_search_original(dat,type,audit)
 global_raw <- max(a$raw_max_LL,a$closure$raw_max_logLik,na.rm=TRUE)
 a$raw_max_LL <- global_raw;a$objective_gap <- global_raw-a$LL
 selected_rate_cap <- with(a$selected,kind%in%c("OU","RI_OU")&
  (range_cm<=10/exp(4.9)|range_cm>=10/exp(-11.9)))
 selected_SD_cap <- with(a$selected,(kind%in%c("RI","RI_OU")&
   (core_SD<=exp(-11.9)|core_SD>=exp(.99)))|
  (kind%in%c("OU","RI_OU")&(OU_SD<=exp(-11.9)|OU_SD>=exp(.99))))
 a$ok <- a$ok&&a$objective_gap<=boundary_LL_tolerance&&
  !isTRUE(selected_rate_cap)&&!isTRUE(selected_SD_cap)
 a
}

robust_pair <- function(i,audit=FALSE) {
 dat <- orchard_data;dat$cumulative_c_stock <- as.numeric(null_responses[[i]])
 a <- robust_gamma_search(dat,"null",audit);b <- robust_gamma_search(dat,"full",audit)
 lr <- 2*(b$LL-a$LL);ok <- a$ok&&b$ok&&is.finite(lr)&&lr>=-1e-5
 list(index=i,LR=if(ok)max(0,lr)else NA_real_,failed=!ok,null_LL=a$LL,full_LL=b$LL,
  null_meta=a$selected,full_meta=b$selected,null_gap=a$objective_gap,full_gap=b$objective_gap,
  attempts=if(!ok)list(null=a$attempts,full=b$attempts)else NULL)
}

workers <- if (.Platform$OS.type == "windows") 1L else min(2L, if(is.na(parallel::detectCores())) 1L else parallel::detectCores())
robust_run <- function(indices,audit=FALSE) {
 out <- parallel::mclapply(indices,function(i)tryCatch(robust_pair(i,audit),error=function(e)
  list(index=i,LR=NA_real_,failed=TRUE,null_LL=NA_real_,full_LL=NA_real_,
   null_meta=NULL,full_meta=NULL,null_gap=Inf,full_gap=Inf,reason=conditionMessage(e))),
  mc.cores=workers,mc.set.seed=FALSE)
 for(j in seq_along(out))if(is.null(out[[j]])||inherits(out[[j]],"try-error"))
  out[[j]] <- list(index=indices[j],LR=NA_real_,failed=TRUE,null_LL=NA_real_,full_LL=NA_real_,
   null_meta=NULL,full_meta=NULL,null_gap=Inf,full_gap=Inf,reason="Worker did not return a valid result")
 out
}

LR_ambiguity <- 0.0041
summarize_bootstrap <- function(B) {
 rr <- robust_bootstrap_results[seq_len(B)]
 failed <- vapply(rr,function(x)x$failed,logical(1))
 lr <- vapply(rr,function(x)if(x$failed)NA_real_ else x$LR,numeric(1))
 ambiguous <- !failed&abs(lr-observed_robust_LR)<=LR_ambiguity
 K <- sum(!failed&!ambiguous&lr>observed_robust_LR,na.rm=TRUE)
 F <- sum(failed|ambiguous)
 mc_lower <- if(K==0)0 else binom.test(K,B)$conf.int[1]
 mc_upper <- if(K+F==B)1 else binom.test(K+F,B)$conf.int[2]
 data.frame(simulations=B,observed_LR=observed_robust_LR,exceedances=K,
  failed_refits=sum(failed),numerically_ambiguous=sum(ambiguous),
  bootstrap_p_lower=(K+1)/(B+1),bootstrap_p_upper=(K+F+1)/(B+1),
  Monte_Carlo_95_lower=mc_lower,Monte_Carlo_95_upper=mc_upper)
}
