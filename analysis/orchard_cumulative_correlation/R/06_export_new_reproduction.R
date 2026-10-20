# Persist the EXISTING 999 results for independent recounting.
# This cell does not fit models, simulate data, or modify stock calculations.
stopifnot(exists("robust_bootstrap_results"),exists("boundary_audit"),
 identical(serialize(orchard_data,NULL),orchard_inputs_before))
export_rr <- robust_bootstrap_results[seq_len(999L)]
field_num <- function(m,n)if(is.null(m[[n]]))NA_real_ else as.numeric(m[[n]])
field_logical <- function(m,n)if(is.null(m[[n]]))NA else as.logical(m[[n]])
field_character <- function(m,n)if(is.null(m[[n]]))NA_character_ else as.character(m[[n]])
selected_cap_flag <- function(m) {
 if(is.null(m))return(NA)
 if(m$kind=="LOGNORMAL_LIMIT")return(FALSE)
 shape <- is.finite(m$gamma_shape)&&m$gamma_shape>=shape_cap*.99
 rate <- m$kind%in%c("OU","RI_OU")&&
  (m$range_cm<=10/exp(4.9)||m$range_cm>=10/exp(-11.9))
 core <- m$kind%in%c("RI","RI_OU")&&
  (m$core_SD<=exp(-11.9)||m$core_SD>=exp(.99))
 ou <- m$kind%in%c("OU","RI_OU")&&
  (m$OU_SD<=exp(-11.9)||m$OU_SD>=exp(.99))
 isTRUE(shape)||isTRUE(rate)||isTRUE(core)||isTRUE(ou)
}
# Boundary fields below describe the FINAL post-rescue audit state.
audit_export <- do.call(rbind,lapply(seq_len(999L),function(i) {
 x<-export_rr[[i]];a<-x$null_meta;b<-x$full_meta;d<-boundary_audit[[i]]
 ambiguous <- !x$failed&&abs(x$LR-observed_robust_LR)<=LR_ambiguity
 eligible <- !x$failed&&!ambiguous
 meta_a<-final_metadata[final_metadata$index==i&final_metadata$model=="null",]
 meta_b<-final_metadata[final_metadata$index==i&final_metadata$model=="full",]
 data.frame(index=as.integer(x$index),failed=x$failed,LR=x$LR,
  candidate_LR_not_valid_if_failed=2*(x$full_LL-x$null_LL),
  delta_from_observed=if(x$failed)NA_real_ else x$LR-observed_robust_LR,
  numerical_ambiguity=ambiguous,eligible_for_tail=eligible,
  definite_exceedance=eligible&&x$LR>observed_robust_LR,
  definite_nonexceedance=eligible&&x$LR<observed_robust_LR,
  unresolved=x$failed||ambiguous,
  null_LL=x$null_LL,full_LL=x$full_LL,
  null_kind=field_character(a,"kind"),full_kind=field_character(b,"kind"),
  null_shape=field_num(a,"gamma_shape"),full_shape=field_num(b,"gamma_shape"),
  null_core_SD=field_num(a,"core_SD"),full_core_SD=field_num(b,"core_SD"),
  null_OU_SD=field_num(a,"OU_SD"),full_OU_SD=field_num(b,"OU_SD"),
  null_range_cm=field_num(a,"range_cm"),full_range_cm=field_num(b,"range_cm"),
  null_convergence=field_num(a,"convergence"),full_convergence=field_num(b,"convergence"),
  null_pdHess=field_logical(a,"pdHess"),full_pdHess=field_logical(b,"pdHess"),
  null_gradient=field_num(a,"gradient"),full_gradient=field_num(b,"gradient"),
  null_selected_quality_valid=meta_a$ordinary_ok,full_selected_quality_valid=meta_b$ordinary_ok,
  null_selected_numerical_cap=selected_cap_flag(a),full_selected_numerical_cap=selected_cap_flag(b),
  null_objective_gap=x$null_gap,full_objective_gap=x$full_gap,
  null_raw_max_LL=x$null_LL+x$null_gap,full_raw_max_LL=x$full_LL+x$full_gap,
  boundary_competitive=isTRUE(d$competitive),boundary_mismatch=isTRUE(d$mismatch),
  boundary_audit_error=isTRUE(d$audit_error),
  null_boundary_LL=field_num(d,"null_boundary_LL"),full_boundary_LL=field_num(d,"full_boundary_LL"),
  null_boundary_raw_max_LL=field_num(d,"null_raw_boundary_LL"),
  full_boundary_raw_max_LL=field_num(d,"full_raw_boundary_LL"),
  failure_reason=paste(c(if(x$failed&&x$null_gap>.001)"null_higher_unvalidated_likelihood",
   if(x$failed&&x$full_gap>.001)"full_higher_unvalidated_likelihood",
   if(isTRUE(x$failed&&2*(x$full_LL-x$null_LL)< -1e-5))"negative_nested_LR",
   if(x$failed&&(!meta_a$ordinary_ok||!meta_b$ordinary_ok))"selected_fit_quality",
   if(isTRUE(d$audit_error))"boundary_audit_error",
   if(isTRUE(d$competitive))"boundary_raw_max_competitive",
   if(isTRUE(d$mismatch))"boundary_selected_LL_mismatch"),collapse="|"),
  initial_fast_retry=isTRUE(x$retried),final_audit_retry=isTRUE(x$final_audit_retried),
  stringsAsFactors=FALSE)
}))
stopifnot(nrow(audit_export)==999L, identical(audit_export$index,seq_len(999L)))
# Save this new reproduction without overwriting the frozen saved evidence.
old_export_digits <- getOption("digits"); options(digits=17)
audit_csv_lines <- capture.output(write.table(audit_export,file="",sep=",",
 row.names=FALSE,col.names=TRUE,quote=TRUE,na="NA",qmethod="double"))
options(digits=old_export_digits)
audit_csv_text <- paste0(paste(audit_csv_lines,collapse="\n"),"\n")
writeBin(charToRaw(audit_csv_text), file.path(output_dir,"new_reproduction_all999_fit_audit.csv"))
write.csv(bootstrap_summary,file.path(output_dir,"new_reproduction_summary.csv"),row.names=FALSE)
write.csv(refined_diagnostic,file.path(output_dir,"new_reproduction_profile_diagnostic_20000.csv"),row.names=FALSE)
writeLines(capture.output(sessionInfo()),file.path(output_dir,"session_info.txt"))
saveRDS(list(orchard_data=orchard_data, null_responses=null_responses[1:999],
 full_fit=full_fit, null_fit=null_fit, final_observed_null=final_observed_null,
 final_observed_full=final_observed_full, results=robust_bootstrap_results[1:999],
 boundary_audit=boundary_audit, final_metadata=final_metadata,
 refined_features=refined_features, bootstrap_summary=bootstrap_summary),
 file.path(output_dir,"new_reproduction_fit_cache.rds"))
comparison <- data.frame(metric=c("observed_LR","definite_exceedances","definite_nonexceedances",
 "failed_refits","numerically_ambiguous","full_shape_infinity","null_shape_infinity","smoothness_count"),
 frozen=c(8.7784597675772034,123,871,4,1,671,683,524),
 new_reproduction=c(observed_robust_LR,sum(audit_export$definite_exceedance),
 sum(audit_export$definite_nonexceedance),sum(audit_export$failed),
 sum(audit_export$numerical_ambiguity),sum(audit_export$full_kind=="LOGNORMAL_LIMIT"),
 sum(audit_export$null_kind=="LOGNORMAL_LIMIT"),k_smooth))
comparison$difference <- comparison$new_reproduction-comparison$frozen
write.csv(comparison,file.path(output_dir,"comparison_to_frozen_counts.csv"),row.names=FALSE)
cat("New reproduction saved. Inspect comparison_to_frozen_counts.csv; do not substitute differing results into the paper automatically.\n")
stopifnot(identical(serialize(orchard_data,NULL),orchard_inputs_before))
