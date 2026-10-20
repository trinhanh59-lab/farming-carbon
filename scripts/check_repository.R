#!/usr/bin/env Rscript
# Check source syntax, frozen file checksums and installed packages.
# This script never fits models, runs simulations or changes publication data.
script_arg <- grep("^--file=", commandArgs(trailingOnly = FALSE), value = TRUE)
stopifnot(length(script_arg) == 1L)
repo <- normalizePath(file.path(dirname(sub("^--file=", "", script_arg)), ".."), mustWork = TRUE)
checksums_path <- file.path(repo, "reproducibility", "FILE_CHECKSUMS.csv")
checksums <- read.csv(checksums_path, stringsAsFactors = FALSE)
paths <- file.path(repo, checksums$file)
if (any(!file.exists(paths))) stop("A supplied file is missing: ", paste(checksums$file[!file.exists(paths)], collapse = ", "))
# MD5 checks accidental file changes with base R; SHA-256 is recorded alongside it.
observed_md5 <- unname(tools::md5sum(paths))
if (any(observed_md5 != checksums$md5)) stop("A supplied file changed: ", paste(checksums$file[observed_md5 != checksums$md5], collapse = ", "))
if (any(file.info(paths)$size != checksums$bytes)) stop("A supplied file size changed.")
cat("Frozen file checksums: PASS (", nrow(checksums), " files)\n", sep = "")
# parse() checks R grammar without evaluating the analysis.
r_files <- list.files(repo, pattern = "\\.[Rr]$", recursive = TRUE, full.names = TRUE)
r_files <- r_files[!grepl("/results/|/outputs_rerun/", r_files)]
for (path in r_files) parse(file = path)
cat("R source syntax: PASS (", length(r_files), " files)\n", sep = "")
requirements <- read.csv(file.path(repo, "reproducibility", "REQUIRED_PACKAGES.csv"), stringsAsFactors = FALSE)
installed <- installed.packages()
missing <- setdiff(requirements$package, rownames(installed))
cat("Current R: ", R.version.string, "\n", sep = "")
if (length(missing)) {
  cat("Packages still needed for analysis or figure execution: ", paste(missing, collapse = ", "), "\n", sep = "")
} else {
  cat("Required package names: all installed.\n")
}
cat("Recorded versions are in reproducibility/RECORDED_PACKAGE_VERSIONS.csv.\n")
cat("These checks do not establish an end-to-end rerun or reproduce fitted results.\n")
