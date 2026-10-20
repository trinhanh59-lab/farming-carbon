# Run the recovered final orchard sensitivity method as a new reproduction.
# The original saved results remain under saved_results/.
.orchard_canonical_output_path <- function(path) {
 if(length(path)!=1L||is.na(path)||!nzchar(path)) stop("Choose one output directory.")
 path <- path.expand(path)
 if(!grepl("^(/|[A-Za-z]:[/\\\\])",path)) path <- file.path(getwd(),path)
 ancestor <- path; remaining <- character()
 while(!file.exists(ancestor)&&!dir.exists(ancestor)) {
  parent <- dirname(ancestor)
  if(identical(parent,ancestor)) stop("Cannot resolve the output directory ancestor.")
  remaining <- c(basename(ancestor),remaining);ancestor <- parent
 }
 if(length(remaining)&&!dir.exists(ancestor)) stop("Output directory ancestor is a file.")
 resolved <- normalizePath(ancestor,winslash="/",mustWork=TRUE)
 for(component in remaining) {
  if(component=="."||!nzchar(component)) next
  resolved <- if(component=="..") dirname(resolved) else file.path(resolved,component)
  if(file.exists(resolved)||dir.exists(resolved))
   resolved <- normalizePath(resolved,winslash="/",mustWork=TRUE)
 }
 resolved
}
.orchard_output_directory <- function(module_dir,output_dir=NULL) {
 module_dir <- normalizePath(module_dir,winslash="/",mustWork=TRUE)
 if(is.null(output_dir)) output_dir <- file.path(module_dir,"outputs_rerun")
 output_dir <- .orchard_canonical_output_path(output_dir)
 protected_names <- c("saved_results", "inputs", "R", "environment",
  list.files(module_dir, pattern = "^reproduction_", full.names = FALSE))
 protected <- vapply(protected_names, function(name)
  normalizePath(file.path(module_dir,name),winslash="/",mustWork=TRUE),character(1))
 for(directory in protected)
  if(identical(output_dir,directory)||startsWith(output_dir,paste0(directory,"/")))
   stop("Choose an output directory outside saved_results/, inputs/, R/, environment/ and reproduction_*/.")
 if(identical(output_dir,module_dir)) stop("Use a separate output directory.")
 if(file.exists(output_dir)&&!dir.exists(output_dir)) stop("Output directory is an existing file.")
 if(dir.exists(output_dir)&&length(list.files(output_dir,all.files=TRUE,no..=TRUE)))
  stop("Output directory must be new or empty; existing output files are protected.")
 output_dir
}
run_orchard_correlation <- function(module_dir, output_dir=NULL) {
 module_dir <- normalizePath(module_dir,winslash="/",mustWork=TRUE)
 output_dir <- .orchard_output_directory(module_dir,output_dir)
 if(as.character(getRversion())!="4.6.1") stop("Recorded R version is 4.6.1; establish that environment before running.")
 expected <- c(glmmTMB="1.1.15.2",numDeriv="2016.8-1.1",digest="0.6.39",
   TMB="1.9.25",Matrix="1.7-6",RTMB="2.0")
 for(pkg in names(expected)) {
  if(!requireNamespace(pkg,quietly=TRUE)) stop(paste("Missing recorded package:",pkg,expected[[pkg]]))
  if(utils::packageVersion(pkg)!=numeric_version(expected[[pkg]]))
   stop(paste("Recorded version required:",pkg,expected[[pkg]]))
 }
 dir.create(output_dir,recursive=TRUE,showWarnings=FALSE)
 oldwd <- getwd(); on.exit(setwd(oldwd),add=TRUE);setwd(output_dir)
 grDevices::pdf(file.path(output_dir,"profile_diagnostics.pdf"),width=10,height=6)
 plot_device <- grDevices::dev.cur();on.exit(grDevices::dev.off(plot_device),add=TRUE)
 logcon <- file(file.path(output_dir,"analysis_log.txt"),open="wt")
 sink(logcon,split=TRUE);on.exit({sink();close(logcon)},add=TRUE)
 library(glmmTMB)
 options(warn=1)
 saveRDS(list(RNGkind=RNGkind(),random_seed=if(exists(".Random.seed",envir=.GlobalEnv,inherits=FALSE))get(".Random.seed",envir=.GlobalEnv,inherits=FALSE)else NULL),
  file.path(output_dir,"rng_state_before_analysis.rds"))
 analysis_env <- new.env(parent=.GlobalEnv)
 analysis_env$module_dir <- module_dir;analysis_env$output_dir <- output_dir
 steps <- c("00_inputs.R","01_observed_generator_fit.R","02_profile_diagnostics.R",
  "03_final_boundary_functions.R","04_new_reproduction_driver.R",
  "05_final_all_index_audit.R","06_export_new_reproduction.R")
 for(step in steps) sys.source(file.path(module_dir,"R",step),envir=analysis_env)
 invisible(output_dir)
}
if(sys.nframe()==0L) {
 argv <- commandArgs(trailingOnly=FALSE)
 script <- sub("^--file=","",argv[grep("^--file=",argv)][1])
 if(is.na(script)) stop("Run with Rscript or call run_orchard_correlation(module_dir, output_dir).")
 args <- commandArgs(trailingOnly=TRUE)
 if(length(args)>1L) stop("Usage: Rscript --vanilla run_new_reproduction.R [new-output-directory]")
 run_orchard_correlation(dirname(normalizePath(script,mustWork=TRUE)),
   if(length(args))args[[1]]else NULL)
}
