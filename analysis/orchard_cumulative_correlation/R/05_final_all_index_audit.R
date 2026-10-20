# Final audit: every response and every selected full/null fit is included.
# Numerical caps are not accepted as ordinary active-parameter optima.
stopifnot(length(robust_bootstrap_results)>=999L,
 all(vapply(robust_bootstrap_results[1:999],function(x)!is.null(x),logical(1))),
 identical(serialize(orchard_data,NULL),orchard_inputs_before))
results_before_final_audit <- robust_bootstrap_results[1:999]
# Revalidate the observed comparison using the final cap-excluding criteria.
final_observed_null <- robust_gamma_search(orchard_data,"null",TRUE)
final_observed_full <- robust_gamma_search(orchard_data,"full",TRUE)
final_observed_LR <- 2*(final_observed_full$LL-final_observed_null$LL)
stopifnot(final_observed_null$ok,final_observed_full$ok,
 abs(final_observed_null$LL-observed_robust_null$LL)<1e-5,
 abs(final_observed_full$LL-observed_robust_full$LL)<1e-5,
 abs(final_observed_LR-observed_robust_LR)<1e-4)
cat("FINAL OBSERVED LR REVALIDATED:",format(final_observed_LR,digits=12),"\n")
metadata_rows <- function(rr)do.call(rbind,lapply(seq_along(rr),function(i)
 do.call(rbind,lapply(c("null","full"),function(type){
  m<-rr[[i]][[paste0(type,"_meta")]]
  if(is.null(m))return(data.frame(index=i,model=type,kind="FAILED",logLik=NA_real_,
    gamma_shape=NA_real_,core_SD=NA_real_,OU_SD=NA_real_,range_cm=NA_real_,
    ordinary_ok=FALSE))
  data.frame(index=i,model=type,kind=m$kind,logLik=m$logLik,gamma_shape=m$gamma_shape,
   core_SD=m$core_SD,OU_SD=m$OU_SD,range_cm=m$range_cm,
   ordinary_ok=if(m$kind=="LOGNORMAL_LIMIT")TRUE else valid_gamma_candidates(m))
 }))))
initial_metadata <- metadata_rows(robust_bootstrap_results[1:999])
initial_bad <- unique(c(which(vapply(robust_bootstrap_results[1:999],function(x)x$failed,logical(1))),
 initial_metadata$index[!initial_metadata$ordinary_ok]))
cat("Selected-fit metadata flagged for final review:",initial_bad,"\n")
# Independently re-evaluate the exact analytical boundary on ALL 999 responses.
# This also audits the earlier checkpoint results against the final exact profile.
audit_boundary_response <- function(i)tryCatch({
 y<-as.numeric(null_responses[[i]]);x<-robust_bootstrap_results[[i]]
 a<-lognormal_boundary_profile(y,X_null);b<-lognormal_boundary_profile(y,X_full)
 stopifnot(all(is.finite(c(a$logLik,b$logLik,a$raw_max_logLik,b$raw_max_logLik))))
 aa<-x$null_meta;bb<-x$full_meta
 competitive <- !is.finite(x$null_LL)||!is.finite(x$full_LL)||
  a$raw_max_logLik>x$null_LL+.001||b$raw_max_logLik>x$full_LL+.001
 mismatch <- (!is.null(aa)&&aa$kind=="LOGNORMAL_LIMIT"&&abs(a$logLik-x$null_LL)>.001)||
  (!is.null(bb)&&bb$kind=="LOGNORMAL_LIMIT"&&abs(b$logLik-x$full_LL)>.001)
 list(index=i,competitive=isTRUE(competitive),mismatch=isTRUE(mismatch),audit_error=FALSE,
   null_boundary_LL=a$logLik,full_boundary_LL=b$logLik,
   null_raw_boundary_LL=a$raw_max_logLik,full_raw_boundary_LL=b$raw_max_logLik)
},error=function(e)list(index=i,competitive=TRUE,mismatch=FALSE,audit_error=TRUE,
 message=conditionMessage(e)))
boundary_audit <- lapply(1:999,audit_boundary_response)
new_boundary_flags<-which(vapply(boundary_audit,function(x)x$competitive||x$mismatch||x$audit_error,logical(1)))
rescue_indices<-sort(unique(c(initial_bad,new_boundary_flags)))
cat("All-response boundary audit flags:",new_boundary_flags,"\n")
cat("Final same-response expanded retries:",rescue_indices,"\n")
if(length(rescue_indices)) {
 new<-robust_run(rescue_indices,TRUE)
 for(j in seq_along(rescue_indices)) {
  i<-rescue_indices[j];new[[j]]$previous_final_audit_result<-robust_bootstrap_results[[i]]
  new[[j]]$final_audit_retried<-TRUE;robust_bootstrap_results[[i]]<-new[[j]]
 }
}
# Recheck any rescued response against the same independent boundary audit.
for(i in rescue_indices)boundary_audit[[i]]<-audit_boundary_response(i)
remaining_boundary_flags<-which(vapply(boundary_audit,function(x)x$competitive||x$mismatch||x$audit_error,logical(1)))
for(i in remaining_boundary_flags)robust_bootstrap_results[[i]]$failed<-TRUE
cat("Remaining all-response boundary flags:",remaining_boundary_flags,"\n")
final_metadata<-metadata_rows(robust_bootstrap_results[1:999])
remaining_caps<-unique(final_metadata$index[!final_metadata$ordinary_ok])
for(i in remaining_caps)robust_bootstrap_results[[i]]$failed<-TRUE
bootstrap_summary<-summarize_bootstrap(999L)
cat("FINAL ALL-999 AUDITED SIMULATION RESULT\n")
print(bootstrap_summary,row.names=FALSE,digits=12)
cat("Remaining selected-fit quality flags:",remaining_caps,"\n")
cat("Selected model-family counts by full/null\n")
print(with(final_metadata,table(model,kind)))
retained_indices <- vapply(robust_bootstrap_results[1:999],function(x)as.integer(x$index),integer(1))
stopifnot(identical(retained_indices,seq_len(999L)))
cat("Simulation indices retained in exact order:",length(retained_indices),"\n")
cat("Additional final-audit rescue count:",length(rescue_indices),"\n")
cat("Ambiguity band around observed LR:",LR_ambiguity,"\n")
stopifnot(identical(serialize(orchard_data,NULL),orchard_inputs_before))
cat("ORCHARD_ALL999_FINAL_AUDIT_COMPLETE_STOCKS_UNCHANGED_NO_MANUSCRIPT_EDITS\n")
