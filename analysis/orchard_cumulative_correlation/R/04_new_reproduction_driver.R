# New reproduction using the final recorded fitting and boundary rules.
# This does not restore the original interactive fit cache or RNG state.
stopifnot(basic_fit_ok,identical(serialize(orchard_data,NULL),orchard_inputs_before))
B_initial <- 999L;B_max <- 4999L;LR_tolerance <- 1e-5
bootstrap_seed <- 20261018L
null_responses <- simulate(null_fit,nsim=B_max,seed=bootstrap_seed)

observed_robust_null <- robust_gamma_search(orchard_data,"null",audit=TRUE)
observed_robust_full <- robust_gamma_search(orchard_data,"full",audit=TRUE)
cat("BOUNDARY-AWARE OBSERVED NULL AND FULL\n")
print(observed_robust_null$selected,row.names=FALSE,digits=10)
print(observed_robust_full$selected,row.names=FALSE,digits=10)
cat("Fit checks:",observed_robust_null$ok,observed_robust_full$ok,"\n")
cat("Objective gaps:",observed_robust_null$objective_gap,observed_robust_full$objective_gap,"\n")
observed_robust_LR <- 2*(observed_robust_full$LL-observed_robust_null$LL)
cat("Boundary-aware observed LR:",observed_robust_LR,"\n")
# Keep the pre-generated responses only if the fitted null remains numerically the same.
null_objective_change <- observed_robust_null$LL-(-null_fit$fit$objective)
cat("Null objective change versus original generator:",null_objective_change,"\n")
stopifnot(observed_robust_null$ok,observed_robust_full$ok,abs(null_objective_change)<1e-5)


robust_bootstrap_results <- vector("list", B_max)
# Complete every missing response in the fixed 999-dataset plan.
# All previously completed response datasets are retained; no tail counts have been used
# to select an optimizer or stop early. Retry metadata are preserved with each result.
bootstrap_target <- B_initial
remaining <- which(vapply(robust_bootstrap_results[seq_len(bootstrap_target)],is.null,logical(1)))
if(length(remaining))for(j in seq.int(1L,length(remaining),by=10L)) {
 ii <- remaining[seq.int(j,min(j+9L,length(remaining)))]
 robust_bootstrap_results[ii] <- robust_run(ii,FALSE)
 bad <- ii[vapply(robust_bootstrap_results[ii],function(x)x$failed,logical(1))]
 if(length(bad)) {
  old <- robust_bootstrap_results[bad];new <- robust_run(bad,TRUE)
  for(k in seq_along(bad)){new[[k]]$initial_fast_attempt<-old[[k]];new[[k]]$retried<-TRUE}
  robust_bootstrap_results[bad] <- new
 }
 completed<-which(!vapply(robust_bootstrap_results[seq_len(bootstrap_target)],is.null,logical(1)))
 fail<-sum(vapply(robust_bootstrap_results[completed],function(x)x$failed,logical(1)))
 cat("SIMULATION CHECKPOINT",length(completed),"of",bootstrap_target,"; unresolved refits",fail,"\n")
 flush.console();gc()
}

