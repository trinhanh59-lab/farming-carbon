# Review numerical identification before interpreting any interaction p value.
# A positive Hessian alone is not enough when the covariance parameters are nearly flat.
observed_LR <- 2*((-full_fit$fit$objective)-(-null_fit$fit$objective))
stopifnot(observed_LR >= -1e-5)
observed_LR <- max(0,observed_LR)
vc_full <- VarCorr(full_fit)$cond
vc_null <- VarCorr(null_fit)$cond
stopifnot(length(vc_full)==2L,length(vc_null)==2L,
          identical(unname(vapply(vc_full,nrow,integer(1))),c(1L,4L)),
          identical(unname(vapply(vc_null,nrow,integer(1))),c(1L,4L)))
# Log-stock covariance includes the shared intercept, OU process, and Gamma variation.
log_stock_covariance <- function(row) {
  distance <- abs(outer(c(10,20,50,75),c(10,20,50,75),"-"))
  if(any(!is.finite(c(row$core_SD,row$OU_SD,row$range_cm,row$gamma_shape))) || row$range_cm<=0 || row$gamma_shape<=0) return(matrix(NA_real_,4,4))
  row$core_SD^2 + row$OU_SD^2*exp(-distance/row$range_cm) + diag(trigamma(row$gamma_shape),4L)
}
hessian_review <- function(f) {
  covariance <- f$sdr$cov.fixed
  if(is.null(covariance)||any(!is.finite(covariance))) return(data.frame(min_cov_eigenvalue=NA_real_,max_cov_eigenvalue=NA_real_,relative_eigenvalue=NA_real_))
  eigenvalues <- tryCatch(eigen((covariance+t(covariance))/2,symmetric=TRUE,only.values=TRUE)$values,error=function(e)NA_real_)
  data.frame(min_cov_eigenvalue=min(eigenvalues),max_cov_eigenvalue=max(eigenvalues),
     relative_eigenvalue=min(eigenvalues)/max(eigenvalues))
}
cat("FULL PARAMETER COVARIANCE CONDITIONING\n"); print(hessian_review(full_fit),digits=8)
cat("NULL PARAMETER COVARIANCE CONDITIONING\n"); print(hessian_review(null_fit),digits=8)
cat("FULL MODEL IDENTIFICATION DETAILS\n"); diagnose(full_fit)
cat("NULL MODEL IDENTIFICATION DETAILS\n"); diagnose(null_fit)
cat("Selected objective gaps below raw best full/null:",
 full_search$max_logLik+full_fit$fit$objective,null_search$max_logLik+null_fit$fit$objective,"\n")
full_row <- full_search$attempts[full_search$best,]
null_row <- null_search$attempts[null_search$best,]
cat("Fitted log-stock correlation matrix\n")
if(all(is.finite(log_stock_covariance(full_row)))) print(cov2cor(log_stock_covariance(full_row)),digits=4) else cat("Covariance boundary prevents a finite correlation matrix.\n")
for(label in c("full","null")) {
  search <- if(label=="full")full_search else null_search
  selected <- search$attempts[search$best,]
  near <- search$attempts[search$near,]
  matrices <- lapply(seq_len(nrow(near)),function(i)log_stock_covariance(near[i,]))
  baseline <- log_stock_covariance(selected)
  max_relative_covariance_difference <- max(vapply(matrices,
       function(m)max(abs(m-baseline))/max(abs(baseline)),numeric(1)))
  cat(label,"near-optimum ranges in cm:",range(near$range_cm),"\n")
  cat(label,"near-optimum core SDs:",range(near$core_SD),"\n")
  cat(label,"near-optimum Gamma shapes:",range(near$gamma_shape),"\n")
  cat(label,"near-optimum total covariance relative difference:",max_relative_covariance_difference,"\n")
}
# Do not run bootstrap inference from an unstable maximum.
basic_fit_ok <- full_search$basic_ok && null_search$basic_ok
cat("NUMERICAL_FIT_GATE:",basic_fit_ok,"\n")
if(!basic_fit_ok) {
  cat("SIMULATION_TEST_NOT_RUN: correlated fit is not numerically stable.\n")
} else {
  # Compare the same residual-profile features in observed and simulated full profiles.
  # Both are centered by orchard endpoint mean and each core's overall deviation.
  profile_features <- function(response) {
    raw <- matrix(response,nrow=6L,ncol=4L,byrow=TRUE)
    z <- log(raw)
    for(ii in list(1:3,4:6))z[ii,] <- sweep(z[ii,,drop=FALSE],2,colMeans(z[ii,,drop=FALSE]),"-")
    z <- sweep(z,1,rowMeans(z),"-")
    spread <- colMeans(z^2)
    c(smoothness=sum((z[,2:4]-z[,1:3])^2)/sum(z^2),
      spread_ratio=max(spread)/min(spread),
      decreasing_profiles=sum(apply(raw,1,function(v)any(diff(v)<0))))
  }
  observed_features <- profile_features(orchard_data$cumulative_c_stock)
  full_simulations <- simulate(full_fit,nsim=2000L,seed=20261016L)
  simulated_features <- vapply(full_simulations,profile_features,numeric(3))
  diagnostic_table <- data.frame(feature=names(observed_features),observed=observed_features,
    lower_2.5=apply(simulated_features,1,quantile,.025),
    upper_97.5=apply(simulated_features,1,quantile,.975),
    lower_tail=(1+rowSums(simulated_features<=observed_features))/(2000+1),
    upper_tail=(1+rowSums(simulated_features>=observed_features))/(2000+1))
  cat("FULL MODEL PROFILE SIMULATION CHECK\n");print(diagnostic_table,row.names=FALSE,digits=7)
  par(mfrow=c(1,2),mar=c(4.4,4.4,3,1))
  hist(simulated_features["smoothness",],breaks=40,col="grey85",border="white",
    xlab="Residual-profile smoothness",main="Correlated model simulations")
  abline(v=observed_features["smoothness"],col="#0072B2",lwd=3)
  legend("topright",legend="Observed",col="#0072B2",lwd=3,bty="n")
  observed_matrix <- matrix(orchard_data$cumulative_c_stock,6,4,byrow=TRUE)
  matplot(c(10,20,50,75),t(observed_matrix),type="b",lty=c(1,1,1,2,2,2),
    pch=c(16,17,15,1,2,0),col=c(rep("#D55E00",3),rep("#0072B2",3)),
    xlab="Cumulative endpoint (cm)",ylab="C stock (t C per ha)",main="Existing observed stocks")
  legend("topleft",legend=c("60-year orchard","20-year orchard"),
     col=c("#D55E00","#0072B2"),lty=c(1,2),pch=c(16,1),bty="n")
  par(mfrow=c(1,1))
  adequacy_smoothness_ok <- with(diagnostic_table[diagnostic_table$feature=="smoothness",],
      observed>=lower_2.5 && observed<=upper_97.5)
  cat("RESIDUAL_SMOOTHNESS_GATE:",adequacy_smoothness_ok,"\n")
  cat("Identification and all diagnostic features must be reviewed before bootstrap.\n")
}
stopifnot(identical(serialize(orchard_data,NULL),orchard_inputs_before))
cat("ORCHARD_CORRELATION_DIAGNOSTIC_REVIEW_COMPLETE_STOCKS_UNCHANGED\n")


# The first 2,000-dataset smoothness check landed almost exactly on its 2.5% boundary.
# Increase simulation precision for the SAME model and SAME statistic, without changing the fit.
# Keep the first output visible and verify that the initial simulations are reproduced.
cat("CORRELATED PARAMETER STANDARD ERRORS (boundary core log-SD is flagged separately)\n")
for(label in c("full","null")) {
 f <- if(label=="full")full_fit else null_fit
 pars <- f$fit$par
 se <- sqrt(diag(f$sdr$cov.fixed))
 stopifnot(length(pars)==length(se))
 ii <- which(names(pars)%in%c("betadisp","theta"))
 print(data.frame(model=label,parameter=names(pars)[ii],estimate=unname(pars[ii]),SE=unname(se[ii])),row.names=FALSE,digits=8)
}
refined_simulations <- simulate(full_fit,nsim=20000L,seed=20261016L)
stopifnot(all(vapply(seq_len(2000L),function(i)identical(refined_simulations[[i]],full_simulations[[i]]),logical(1))))
refined_features <- vapply(refined_simulations,profile_features,numeric(3))
refined_diagnostic <- data.frame(feature=names(observed_features),observed=observed_features,
 lower_2.5=apply(refined_features,1,quantile,.025),
 upper_97.5=apply(refined_features,1,quantile,.975),
 lower_tail=(1+rowSums(refined_features<=observed_features))/(20000+1),
 upper_tail=(1+rowSums(refined_features>=observed_features))/(20000+1))
cat("REFINED SAME-MODEL PROFILE DIAGNOSTIC: 20,000 SIMULATIONS\n")
print(refined_diagnostic,row.names=FALSE,digits=9)
k_smooth <- sum(refined_features["smoothness",]<=observed_features["smoothness"])
cat("Smoothness diagnostic count:",k_smooth,"of 20000\n")
print(binom.test(k_smooth,20000L)$conf.int)
cat("This interval describes Monte Carlo precision, not confidence in the orchard effect.\n")
cat("A borderline predictive feature is reviewed with covariance stability, not treated as a proof of model validity or invalidity.\n")
par(mar=c(4.5,4.5,3,1))
hist(refined_features["smoothness",],breaks=60,col="grey85",border="white",
 main="Residual profiles: correlated Gamma model",xlab="Residual-profile smoothness")
abline(v=observed_features["smoothness"],col="#0072B2",lwd=3)
abline(v=quantile(refined_features["smoothness",],c(.025,.975)),lty=2,col="grey40")
legend("topright",legend=c("Observed","Central 95% simulated range"),
 col=c("#0072B2","grey40"),lty=c(1,2),lwd=c(3,1),bty="n")
stopifnot(identical(serialize(orchard_data,NULL),orchard_inputs_before))
cat("ORCHARD_REFINED_DIAGNOSTIC_COMPLETE_STOCKS_UNCHANGED\n")
