# Same-sample sensitivity audit, user selected October 14, 2026.
# Four stages under full and additive structures isolate adjacent choices.
# A: Gamma on mass + 0.00017 g.
# B: Gamma on 1000 * (mass + 0.00017 g) / volume.
# C: Tweedie on the same shifted density, diagnostic bridge only.
# D: Tweedie on unshifted density, the selected response.
# Depth coverage stays fixed, so this does not estimate the effect of adding
# the nine deepest hedgerow observations back into the analysis.
stopifnot(exists("fits"),exists("root_source"),exists("ri_full_check_all"),
  all(c("orchards","hedgerows_tight","annual vegetables") %in% names(ri_full_check_all)))
ss_source_before <- root_source
ss_primary_before <- lapply(fits,function(x) list(beta=fixef(x$primary)$cond,
  logLik=as.numeric(logLik(x$primary))))
ss_volume_check <- do.call(rbind,lapply(names(fits),function(s) {
  d <- fits[[s]]$data
  stopifnot(all(is.finite(d$root_weight)),all(d$root_weight>=0),
    all(d$volume_cm3>0),max(abs(d$density-1000*d$root_weight/d$volume_cm3))<1e-12)
  z <- aggregate(d$volume_cm3,list(depth=d$depth_factor),function(v)length(unique(v)))
  stopifnot(all(z$x==1))
  data.frame(system=s,n=nrow(d),cores=nlevels(d$core),layers=nrow(z),
    unique_volumes_per_layer=max(z$x),zeros=sum(d$density==0))
}))
ss_results <- list()
print(ss_volume_check,row.names=FALSE)
cat("SAME_SAMPLE_AUDIT_PREPARED\n")
