#!/usr/bin/env Rscript
# Supporting bulk-density model on the four common hedgerow depth intervals.
# Retains the selected Gaussian identity-link model, Type III Wald tests,
# sum-to-zero contrasts, core random intercept and unadjusted follow-ups.
suppressPackageStartupMessages({library(car);library(dplyr);library(emmeans);library(glmmTMB);library(readr)})
options(contrasts=c("contr.sum","contr.poly"))
script_arg <- grep("^--file=",commandArgs(FALSE),value=TRUE)
stopifnot(length(script_arg)==1L)
module_dir <- dirname(normalizePath(sub("^--file=","",script_arg),mustWork=TRUE))
args <- commandArgs(TRUE)
if(length(args)!=2L || args[[1]]!="--run-analysis") stop("Use --run-analysis NEW_OUTPUT_DIR")
# Resolve the output before fitting; reject source and frozen-result folders.
resolve_new_output <- function(path, repository) {
  path <- path.expand(path)
  if(!grepl("^(/|[A-Za-z]:[/\\\\])",path)) path <- file.path(getwd(),path)
  if(file.exists(path)||dir.exists(path)) stop("Output exists; choose a new directory.")
  ancestor <- path; rest <- character()
  while(!file.exists(ancestor) && !dir.exists(ancestor)) {
    parent <- dirname(ancestor)
    if(identical(parent,ancestor)) stop("Cannot resolve output path.")
    rest <- c(basename(ancestor),rest); ancestor <- parent
  }
  if(!dir.exists(ancestor)) stop("Output parent is a file.")
  resolved <- normalizePath(ancestor,winslash="/",mustWork=TRUE)
  for(part in rest) {
    if(part=="." || !nzchar(part)) next
    resolved <- if(part=="..") dirname(resolved) else file.path(resolved,part)
    if(file.exists(resolved)||dir.exists(resolved))
      resolved <- normalizePath(resolved,winslash="/",mustWork=TRUE)
  }
  protected <- file.path(repository,c("data","analysis","figures","reproducibility"))
  if(identical(resolved,repository) || any(vapply(protected,function(p)
    identical(resolved,p)||startsWith(resolved,paste0(p,"/")),logical(1))))
    stop("Choose a new output outside data, analysis, figures and reproducibility folders.")
  if(file.exists(resolved)||dir.exists(resolved)) stop("Output exists; choose a new directory.")
  resolved
}
repository <- normalizePath(file.path(module_dir,"..",".."),mustWork=TRUE)
output_dir <- resolve_new_output(args[[2]],repository)
input_path <- file.path(module_dir,"..","..","data","processed","sample_level_analysis_96_current.csv")
data_all <- read_csv(input_path,show_col_types=FALSE)
stopifnot(nrow(data_all)==96L)
d <- data_all |> filter(system=="hedgerows") |> mutate(
 depth_cm=factor(depth_cm,levels=c("0-10","10-20","20-50","50-75")),
 site_type=factor(site_type,levels=c("bare field margin","10-year-old hedgerow","30-year-old hedgerow")),core=factor(core))
stopifnot(nrow(d)==36L,n_distinct(d$core)==9L,all(d$effective_depth_bottom_cm<=75),all(table(d$site_type,d$depth_cm)==3L))
warnings_seen <- character()
# Default controls are retained from the selected supporting bulk-density code.
m <- withCallingHandlers(glmmTMB(bulk_density~depth_cm*site_type+(1|core),data=d,
 family=gaussian(link="identity"),na.action=na.fail),warning=function(w){warnings_seen<<-c(warnings_seen,conditionMessage(w));invokeRestart("muffleWarning")})
tn <- c(depth_cm="Depth",site_type="Comparison group","depth_cm:site_type"="Depth × comparison group")
omnibus <- as.data.frame(car::Anova(m,type=3)) |> tibble::rownames_to_column("term") |>
 filter(term %in% names(tn)) |> transmute(system="hedgerows",term=unname(tn[term]),statistic=Chisq,df=Df,p_value=`Pr(>Chisq)`)
em <- emmeans(m,~site_type|depth_cm)
means <- as.data.frame(summary(em)) |> mutate(system="hedgerows",response="bulk_density")
pairs_raw <- as.data.frame(summary(pairs(em,adjust="none"),infer=c(TRUE,TRUE)))
lo <- grep("lower.CL|asymp.LCL",names(pairs_raw),value=TRUE)[[1]]
hi <- grep("upper.CL|asymp.UCL",names(pairs_raw),value=TRUE)[[1]]
contrasts <- pairs_raw |> transmute(system="hedgerows",depth_cm=as.character(depth_cm),contrast=as.character(contrast),estimate,
 standard_error=SE,df,lower_95=.data[[lo]],upper_95=.data[[hi]],p_value=p.value,adjustment="none")
joint <- as.data.frame(joint_tests(m,by="depth_cm")) |> mutate(system="hedgerows",response="bulk_density")
# These averages support the Methods description of field-margin bulk density.
group_means <- as.data.frame(summary(emmeans(m,~site_type,weights="equal")))
group_pairs <- as.data.frame(summary(pairs(emmeans(m,~site_type,weights="equal"),adjust="none"),infer=c(TRUE,TRUE)))
diagnostics <- tibble(system="hedgerows",observations=nrow(d),cores=n_distinct(d$core),convergence_code=m$fit$convergence,
 positive_definite_hessian=isTRUE(m$sdr$pdHess),core_random_sd=as.numeric(attr(VarCorr(m)$cond$core,"stddev")[[1]]))
# The selected supporting code used convergence/Hessian checks, without DHARMa draws.
fit_details <- tibble(family="Gaussian(identity)",formula="bulk_density ~ depth_cm * site_type + (1 | core)",
 logLik=as.numeric(logLik(m)),AIC=AIC(m),warnings=paste(unique(warnings_seen),collapse=" | "),DHARMa_simulations=0L)
dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
write_csv(omnibus,file.path(output_dir,"bulk_density_omnibus.csv"))
write_csv(means,file.path(output_dir,"bulk_density_means.csv"))
write_csv(contrasts,file.path(output_dir,"bulk_density_contrasts.csv"))
write_csv(joint,file.path(output_dir,"bulk_density_joint_tests.csv"))
write_csv(group_means,file.path(output_dir,"bulk_density_equal_depth_means.csv"))
write_csv(group_pairs,file.path(output_dir,"bulk_density_equal_depth_contrasts.csv"))
write_csv(diagnostics,file.path(output_dir,"bulk_density_diagnostics.csv"))
write_csv(fit_details,file.path(output_dir,"bulk_density_fit_details.csv"))
saveRDS(m,file.path(output_dir,"bulk_density_model.rds"),compress="xz")
capture.output(sessionInfo(),file=file.path(output_dir,"R_session_info.txt"))
print(omnibus);print(diagnostics)
