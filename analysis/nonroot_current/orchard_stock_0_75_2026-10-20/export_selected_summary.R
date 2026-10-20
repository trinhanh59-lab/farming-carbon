# Read the isolated saved fit and expose its existing selected follow-up statistics.
# No model is fitted here, and no adjustment or new joint test is introduced.
suppressPackageStartupMessages({library(glmmTMB);library(emmeans);library(readr)})
a <- commandArgs(trailingOnly=TRUE)
stopifnot(length(a)==1L)
out <- normalizePath(a[[1]],mustWork=TRUE)
m <- readRDS(file.path(out,"nonroot_model_objects.rds"))[["orchards__cumulative_c_stock"]]
emm <- emmeans(m, ~ site_type | depth_cm, type="response")
write_csv(as.data.frame(summary(emm,type="response")),file.path(out,"orchard_stock_EMM_full.csv"))
pair <- as.data.frame(summary(pairs(emm,adjust="none"),infer=c(TRUE,TRUE),type="response"))
write_csv(pair,file.path(out,"orchard_stock_pairwise_full.csv"))
writeLines(capture.output(print(formula(m))),file.path(out,"orchard_stock_formula.txt"))
writeLines(capture.output(print(family(m))),file.path(out,"orchard_stock_family.txt"))
