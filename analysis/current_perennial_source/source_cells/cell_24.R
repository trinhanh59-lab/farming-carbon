# Independently check the manually constructed contrasts with emmeans.
# emmeans averages fitted log means equally across the same depth intervals.
ss_emmeans_checks <- list()
for(s in names(ss_results)) {
  z <- ss_results[[s]]
  for(k in names(z$records)) {
    rr <- z$records[[k]];if(!rr$regular)next
    ee <- emmeans(rr$model,~site_type,weights="equal",component="cond")
    pp <- as.data.frame(summary(pairs(ee,adjust="none"),type="link"))
    ours <- subset(z$summary$pairs,stage==rr$stage & structure==rr$structure)
    stopifnot(nrow(pp)==nrow(ours))
    ss_emmeans_checks[[paste(s,k)]] <- data.frame(system=s,stage=rr$stage,
      structure=rr$structure,estimate_gap=max(abs(pp$estimate-ours$log_ratio)),
      SE_gap=max(abs(pp$SE-ours$SE)))
  }
}
ss_emmeans_checks <- do.call(rbind,ss_emmeans_checks)
stopifnot(max(ss_emmeans_checks$estimate_gap)<1e-7,max(ss_emmeans_checks$SE_gap)<1e-7)
ss_all_tests <- do.call(rbind,lapply(ss_results,function(z)z$summary$tests))
ss_all_pairs <- do.call(rbind,lapply(ss_results,function(z)z$summary$pairs))
ss_all_layers <- do.call(rbind,lapply(ss_results,function(z)z$layers))
ss_all_normalization <- do.call(rbind,lapply(ss_results,function(z)z$summary$normalization_checks))
# Check every fitted within-layer field contrast, not only the profile summary.
ss_layer_checks <- do.call(rbind,lapply(names(ss_results),function(s)do.call(rbind,
  lapply(c("additive","full"),function(st) {
    z <- subset(ss_results[[s]]$layers,structure==st)
    a <- subset(z,stage=="A_mass_gamma");b <- subset(z,stage=="B_shift_gamma")
    stopifnot(identical(a$comparison,b$comparison),identical(a$depth,b$depth))
    data.frame(system=s,structure=st,log_ratio_gap=max(abs(a$log_ratio-b$log_ratio)),
      SE_gap=max(abs(a$SE-b$SE)))
  }))))
stopifnot(max(ss_layer_checks$log_ratio_gap)<1e-5,max(ss_layer_checks$SE_gap)<1e-5,
  identical(root_source,ss_source_before),identical(ss_primary_before,lapply(fits,
    function(x)list(beta=fixef(x$primary)$cond,logLik=as.numeric(logLik(x$primary))))))
# Record a bounded source readback for comparison against the live online Sheet.
ss_input_readback <- root_source[c("sample_code","root_weight","volume_cm3","density")]
ss_verification <- list(emmeans=ss_emmeans_checks,layers=ss_layer_checks,
  volume_check=ss_volume_check,source_preserved=TRUE,primary_preserved=TRUE)
print(ss_layer_checks,digits=6,row.names=FALSE)
cat("SAME_SAMPLE_VERIFICATION_JSON_BEGIN\n")
cat(toJSON(ss_verification,dataframe="rows",auto_unbox=TRUE,digits=16,na="null"))
cat("\nSAME_SAMPLE_VERIFICATION_JSON_END\n")
# A ratio of 1 means equal fitted responses. Bars show 95% Wald intervals.
# Shifted stages are diagnostic responses, not final root-density estimates.
ss_focal <- subset(ss_all_pairs,system!="hedgerows" |
  comparison=="10-year-old hedgerow / 30-year-old hedgerow")
ss_focal$comparison_label <- ifelse(ss_focal$system=="annual vegetables","Annual: monoculture/polyculture",
  ifelse(ss_focal$system=="orchards","Orchard: 20-year/60-year","Hedgerow: 10-year/30-year"))
ss_focal$comparison_label <- factor(ss_focal$comparison_label,
  levels=c("Annual: monoculture/polyculture","Orchard: 20-year/60-year","Hedgerow: 10-year/30-year"))
ss_stage_labels <- c(A_mass_gamma="A. Gamma, shifted mass",B_shift_gamma="B. Gamma, shifted density",
  C_shift_tweedie="C. Tweedie, shifted density",D_raw_tweedie="D. Tweedie, unshifted density")
ss_focal$stage_label <- factor(ss_stage_labels[ss_focal$stage],levels=rev(ss_stage_labels))
ss_focal$structure <- factor(ss_focal$structure,levels=c("additive","full"),
  labels=c("Additive","Full interaction"))
ss_missing <- subset(ss_all_tests,!regular)
ss_missing$comparison_label <- factor(ifelse(ss_missing$system=="annual vegetables","Annual: monoculture/polyculture",
  ifelse(ss_missing$system=="orchards","Orchard: 20-year/60-year","Hedgerow: 10-year/30-year")),
  levels=levels(ss_focal$comparison_label))
ss_missing$stage_label <- factor(ss_stage_labels[ss_missing$stage],levels=rev(ss_stage_labels))
ss_missing$structure <- factor(ss_missing$structure,levels=c("additive","full"),labels=levels(ss_focal$structure))
ss_missing$note <- ifelse(ss_missing$boundary,"All-zero cell boundary","Gamma-limit boundary")
options(repr.plot.width=10,repr.plot.height=8)
ss_comparison_plot <- ggplot(ss_focal,aes(x=ratio,y=stage_label))+
  geom_vline(xintercept=1,linetype="dashed",colour="grey55",linewidth=.4)+
  geom_segment(aes(x=lower_95,xend=upper_95,yend=stage_label),colour="grey35",linewidth=.6)+
  geom_point(colour="#245A81",size=2)+
  geom_text(data=ss_missing,aes(x=1,y=stage_label,label=note),inherit.aes=FALSE,
    colour="grey40",size=3)+
  scale_x_log10(breaks=c(.01,.1,1,10,100))+
  facet_grid(comparison_label~structure)+
  labs(x="Field ratio (log scale), 95% Wald interval",y=NULL)+
  theme_bw(base_size=11)+theme(panel.grid.minor=element_blank(),panel.grid.major.y=element_blank(),
    strip.background=element_rect(fill="grey95"),strip.text.y=element_text(angle=0))
print(ss_comparison_plot)
cat("SAME_SAMPLE_AUDIT_VERIFIED_AND_COMPLETE\n")
