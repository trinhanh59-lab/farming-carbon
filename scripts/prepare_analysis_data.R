#!/usr/bin/env Rscript
# Data-only preparation from the recorded July 20 working-source transformations.
# Retains the historical inputs and applies the recorded October 16 annual masses.
# Reads source XLSX files; writes CSV data and validation records only. No model fits.
# Reproducing a working value does not independently validate its original field
# or handwritten record. In particular, the working moisture source already
# contains sample 108's recorded 104.40 g working source-cell value. This script does not
# apply that prior correction again or resolve the same-core evidence question.
# Usage: Rscript --vanilla prepare_analysis_data.R ROOT_DIR NEW_OUTPUT_DIR [RAW_DIR]
# Sources default to data/Original_Source_Workbooks.zip; RAW_DIR keeps legacy loose-folder support.

suppressPackageStartupMessages({
  library(dplyr)
  library(janitor)
  library(tidyr)
  library(stringr)
  library(readr)
})
if (!requireNamespace("openxlsx", quietly=TRUE) || !requireNamespace("digest", quietly=TRUE))
  stop("Install the recorded openxlsx and digest dependencies before preparation.")
options(stringsAsFactors=FALSE)
args <- commandArgs(trailingOnly=TRUE)
if (length(args)<2L || length(args)>3L)
  stop("Usage: prepare_analysis_data.R ROOT_DIR NEW_OUTPUT_DIR [RAW_DIR]")
ROOT_DIR <- normalizePath(args[[1]], mustWork=TRUE)
OUTPUT_DIR <- path.expand(args[[2]])
if (!grepl("^(/|[A-Za-z]:[/\\\\])", OUTPUT_DIR)) OUTPUT_DIR <- file.path(getwd(), OUTPUT_DIR)
if (file.exists(OUTPUT_DIR) || dir.exists(OUTPUT_DIR)) stop("Output exists; choose a new directory.")
# Open original source workbooks from the current ZIP, or an explicitly supplied
# legacy directory. Only temporary files are extracted; source bytes stay intact.
resolve_source_workbooks <- function(repository, raw_dir = NULL) {
  if (!is.null(raw_dir)) {
    path <- normalizePath(raw_dir, mustWork = TRUE)
    if (!dir.exists(path)) stop("RAW_DIR must be an existing source directory.")
    return(list(directory = path, cleanup = NULL))
  }
  archive <- file.path(repository, "data/Original_Source_Workbooks.zip")
  if (!file.exists(archive)) {
    path <- normalizePath(file.path(repository, "data/source_measurements"), mustWork = TRUE)
    if (!dir.exists(path)) stop("The source ZIP or restored source directory is required.")
    return(list(directory = path, cleanup = NULL))
  }
  expected <- read.csv(file.path(repository, "data/source_measurements/SOURCE_FILES.csv"),
    stringsAsFactors = FALSE, check.names = FALSE)
  stopifnot(nrow(expected) == 23L, !anyDuplicated(expected$file),
    all(startsWith(expected$file, "data/source_measurements/")),
    all(grepl("\\.xlsx$", expected$file)))
  entries <- utils::unzip(archive, list = TRUE)$Name
  unsafe <- vapply(entries, function(entry) {
    parts <- strsplit(entry, "/", fixed = TRUE)[[1]]
    !nzchar(entry) || startsWith(entry, "/") ||
      grepl("^[A-Za-z]:", entry) || grepl("\\\\", entry) ||
      grepl("[[:cntrl:]]", entry) || any(parts %in% c("", ".", ".."))
  }, logical(1))
  if (any(unsafe) || anyDuplicated(tolower(entries)))
    stop("Unsafe or duplicate source ZIP member path; nothing was extracted.")
  if (!setequal(entries, c("FILE_MANIFEST.csv", expected$file)))
    stop("The source ZIP must contain exactly the 23 recorded workbooks and manifest.")
  temporary <- tempfile("farming-carbon-sources-")
  if (!dir.create(temporary)) stop("Cannot create isolated source directory.")
  success <- FALSE
  on.exit(if (!success) unlink(temporary, recursive = TRUE), add = TRUE)
  utils::unzip(archive, files = c("FILE_MANIFEST.csv", expected$file), exdir = temporary)
  extracted <- file.path(temporary, c("FILE_MANIFEST.csv", expected$file))
  resolved <- normalizePath(extracted, mustWork = TRUE)
  if (any(nzchar(Sys.readlink(extracted))) || any(!file_test("-f", extracted)) ||
      any(!startsWith(resolved, paste0(normalizePath(temporary), "/"))))
    stop("Source ZIP members must be regular files inside the temporary directory.")
  manifest <- read.csv(extracted[1], stringsAsFactors = FALSE, check.names = FALSE)
  stopifnot(all(c("path", "bytes", "sha256", "md5") %in% names(manifest)),
    nrow(manifest) == 23L, !anyDuplicated(manifest$path),
    setequal(manifest$path, expected$file))
  index <- match(expected$file, manifest$path)
  paths <- extracted[-1]
  actual_sha <- vapply(paths, function(path)
    digest::digest(file = path, algo = "sha256", serialize = FALSE), character(1))
  stopifnot(identical(as.numeric(file.info(paths)$size), as.numeric(expected$bytes)),
    identical(as.numeric(manifest$bytes[index]), as.numeric(expected$bytes)),
    identical(unname(actual_sha), expected$sha256),
    identical(manifest$sha256[index], expected$sha256),
    identical(unname(tools::md5sum(paths)), manifest$md5[index]))
  # Keep the token alive for the script; cleanup also runs on normal/error exit.
  cleanup <- new.env(parent = emptyenv())
  cleanup$directory <- temporary
  reg.finalizer(cleanup, function(token) unlink(token$directory, recursive = TRUE), onexit = TRUE)
  success <- TRUE
  list(directory = file.path(temporary, "data/source_measurements"), cleanup = cleanup)
}

source_inputs <- resolve_source_workbooks(ROOT_DIR, if (length(args) == 3L) args[[3]] else NULL)
DATA_DIR <- source_inputs$directory
# Resolve a future output path without creating it, including any .. components.
resolve_future <- function(path) {
  ancestor <- path; rest <- character()
  while(!file.exists(ancestor) && !dir.exists(ancestor)) {
    parent <- dirname(ancestor)
    if(identical(parent,ancestor)) stop("Cannot resolve output path.")
    rest <- c(basename(ancestor),rest); ancestor <- parent
  }
  if(!dir.exists(ancestor)) stop("Output parent is a file.")
  result <- normalizePath(ancestor, mustWork=TRUE)
  for(x in rest) {
    if(x=="." || !nzchar(x)) next
    result <- if(x=="..") dirname(result) else file.path(result,x)
    if(file.exists(result) || dir.exists(result))
      result <- normalizePath(result,winslash="/",mustWork=TRUE)
  }
  result
}
protect_output <- function(path) {
  output <- resolve_future(path)
  for(protected in c(DATA_DIR,file.path(ROOT_DIR,"data"),file.path(ROOT_DIR,"analysis"),file.path(ROOT_DIR,"figures"),file.path(ROOT_DIR,"reproducibility"))) {
    protected <- normalizePath(protected,winslash="/",mustWork=TRUE)
    if(identical(output,protected)||startsWith(output,paste0(protected,"/")))
      stop("Choose an output directory outside source data, analysis, figures and reproducibility folders.")
  }
  output
}
OUTPUT_DIR <- protect_output(OUTPUT_DIR)
assert_true <- function(condition, message) if(!isTRUE(condition)) stop(message,call.=FALSE)
assert_unique <- function(data, keys, label) {
  if(anyDuplicated(as.data.frame(data[keys]))) stop(label," has duplicate keys: ",paste(keys,collapse=", "))
}
log_message <- function(...) cat(...,"\n")
# Intermediate checks are held in memory until every comparison passes.
check_exports <- list()
write_csv_stable <- function(data, filename) check_exports[[filename]] <<- data
read.xlsx <- openxlsx::read.xlsx
metadata_fresno <- read.xlsx(file.path(DATA_DIR,"metadata/metadata - final.xlsx"))
metadata_hedgerows <- read.xlsx(file.path(DATA_DIR,"metadata/metadata - hedgerows - final.xlsx"))
moisture_fresno <- read.xlsx(file.path(DATA_DIR,"soil moisture/soil moisture - Fresno.xlsx"),startRow=9)
moisture_hedgerows <- read.xlsx(file.path(DATA_DIR,"soil moisture/soil moisture - hedgerows.xlsx"),startRow=10)
hedgerows_c14 <- read.xlsx(file.path(DATA_DIR,"14C/HRDY_21Nov2024.xlsx"))
annual_c14 <- read.xlsx(file.path(DATA_DIR,"14C/IKON-LAHE_21Nov_2024.xlsx"))
orchards_c14 <- read.xlsx(file.path(DATA_DIR,"14C/MAS_21Nov_2024.xlsx"))
depth_increments <- read.xlsx(file.path(DATA_DIR,"metadata/depth increments.xlsx"))
cores_fresno <- read.xlsx(file.path(DATA_DIR,"core cutting/core measurements copy.xlsx"),startRow=3)
cores_hedgerows <- read.xlsx(file.path(DATA_DIR,"core cutting/core measurements - hedgerows.xlsx"),startRow=2)
roots_fresno <- read.xlsx(file.path(DATA_DIR,"roots/Envelope Weight - Fresno.xlsx"))
roots_hedgerows <- read.xlsx(file.path(DATA_DIR,"roots/Davis - Root Envelope.xlsx"))

metadata_fresno_clean <- metadata_fresno %>%
  mutate(
    sample_id = as.character(sample_id),
    sample_code = as.character(sample_code),
    site_name = as.character(site_name),
    sampling_point = as.character(sampling_point),
    increment_number = as.integer(increment_number),
    depth_cm = as.character(depth_cm),
    project_id = as.character(project_id),
    years_in_management = as.character(years_in_management)
  )

metadata_hedgerows_clean <- metadata_hedgerows %>%
  mutate(
    sample_id = as.character(sample_id),
    sample_code = as.character(sample_code),
    site_name = as.character(site_name),
    sampling_point = as.character(sampling_point),
    increment_number = as.integer(increment_number),
    depth_cm = as.character(depth_cm),
    project_id = as.character(project_id)
  )

metadata_backbone <- bind_rows(
  metadata_fresno_clean %>%
    filter(core_id == "A", sampling_point %in% c("1", "3", "5")),
  metadata_hedgerows_clean
) %>%
  filter(!str_detect(site_name, "JOMA"))

assert_true(nrow(metadata_backbone) == 111L, "Expected 111 retained metadata rows.")
assert_unique(metadata_backbone, "sample_id", "Retained metadata")
assert_unique(metadata_backbone, "sample_code", "Retained metadata")
assert_unique(
  metadata_backbone,
  c("project_id", "site_name", "sampling_point", "depth_cm"),
  "Retained metadata"
)
assert_true(!anyNA(metadata_backbone$sample_code), "sample_code contains missing values.")

# -----------------------------------------------------------------------------
# Radiocarbon and elemental measurements
# -----------------------------------------------------------------------------

clean_c14 <- function(data) {
  data %>%
    clean_names() %>%
    separate(
      col = sample_name,
      into = c("sample_id", "site_name", "sampling_point", "increment_number", "suffix"),
      remove = FALSE
    ) %>%
    mutate(
      sample_id = as.character(sample_id),
      site_name = as.character(site_name),
      sampling_point = as.character(sampling_point),
      increment_number = as.integer(gsub("A", "", increment_number)),
      cn_ratio = c_percent / n_percent
    ) %>%
    dplyr::select(
      sample_id, site_name, sampling_point, increment_number,
      depth_top, depth_bottom, depth_mid,
      del14c, c_percent, n_percent, cn_ratio
    )
}

c14 <- bind_rows(
  clean_c14(annual_c14),
  clean_c14(orchards_c14),
  clean_c14(hedgerows_c14)
)
assert_unique(c14, "sample_id", "Radiocarbon table")
assert_unique(
  c14,
  c("sample_id", "site_name", "sampling_point", "increment_number"),
  "Radiocarbon table"
)

# -----------------------------------------------------------------------------
# Root biomass
# -----------------------------------------------------------------------------

root_correction_raw <- -1.4427
root_correction_value <- 0.0086

roots_fresno_clean <- roots_fresno %>%
  clean_names() %>%
  rename(sample_id = envelope_number, root_weight = r_weight) %>%
  transmute(
    sample_id = as.character(sample_id),
    root_weight_raw = as.numeric(root_weight),
    root_weight = if_else(
      root_weight_raw == root_correction_raw,
      root_correction_value,
      root_weight_raw
    )
  ) %>%
  filter(!is.na(sample_id), sample_id != "NA")

roots_hedgerows_clean <- roots_hedgerows %>%
  clean_names() %>%
  rename(sample_id = envelope_number, root_weight = r_weight) %>%
  transmute(
    sample_id = as.character(sample_id),
    root_weight_raw = as.numeric(root_weight),
    root_weight = root_weight_raw
  ) %>%
  filter(!is.na(sample_id), sample_id != "NA")

roots <- bind_rows(roots_fresno_clean, roots_hedgerows_clean)
assert_unique(roots, "sample_id", "Root-biomass table")


clean_moisture <- function(data) {
  data %>%
    mutate(
      soil_water_g = (field_moist_soil_g + tin_g) - dry_tin_soil_g,
      gwc = soil_water_g / (dry_tin_soil_g - tin_g),
      total_dry_soil_g = bag_field_moist_soil_g / (1 + gwc)
    ) %>%
    rename(sample_id = id) %>%
    transmute(
      sample_id = as.character(sample_id),
      soil_water_g,
      gwc,
      total_dry_soil_g
    ) %>%
    filter(!is.na(sample_id), sample_id != "NA")
}

moisture <- bind_rows(
  clean_moisture(moisture_fresno),
  clean_moisture(moisture_hedgerows)
)
assert_unique(moisture, "sample_id", "Soil-moisture table")

depth_volume <- depth_increments %>%
  transmute(
    project_id = as.character(project_id),
    depth_cm = as.character(depth_cm),
    depth_total_cm = as.numeric(depth_total_cm),
    volume_cm3 = depth_total_cm * (1.905 ^ 2) * pi
  )
assert_unique(depth_volume, c("project_id", "depth_cm"), "Depth-volume table")

core_fresno <- cores_fresno[1:7] %>%
  filter(!is.na(site_name), core_id %in% c("A", "-")) %>%
  transmute(
    site_name = as.character(site_name),
    sampling_point = as.character(sampling_point),
    core_deficit = if_else(hole_depth < 100, as.numeric(hole_depth) - 100, NA_real_)
  )

core_hedgerows <- cores_hedgerows[1:7] %>%
  filter(!is.na(site_name), str_detect(site_name, "HRDY")) %>%
  transmute(
    site_name = as.character(site_name),
    sampling_point = as.character(transect),
    core_deficit = if_else(hole_cm < 100, as.numeric(hole_cm) - 100, NA_real_)
  )

core_adjust <- bind_rows(core_fresno, core_hedgerows) %>%
  mutate(core_deficit = coalesce(core_deficit, 0))
assert_unique(core_adjust, c("site_name", "sampling_point"), "Core-adjustment table")

# -----------------------------------------------------------------------------
# Canonical sample-level dataset
# -----------------------------------------------------------------------------

log_message("Joining the 111-row sample backbone to one-row lookup tables")

df_full <- metadata_backbone %>%
  left_join(
    c14,
    by = c("sample_id", "site_name", "sampling_point", "increment_number"),
    relationship = "many-to-one"
  ) %>%
  left_join(moisture, by = "sample_id", relationship = "many-to-one") %>%
  left_join(
    depth_volume,
    by = c("project_id", "depth_cm"),
    relationship = "many-to-one"
  ) %>%
  left_join(roots, by = "sample_id", relationship = "many-to-one") %>%
  left_join(
    core_adjust,
    by = c("site_name", "sampling_point"),
    relationship = "many-to-one"
  ) %>%
  mutate(
    core_deficit = coalesce(core_deficit, 0),
    nominal_depth_top_cm = as.numeric(sub("-.*$", "", depth_cm)),
    nominal_depth_bottom_cm = as.numeric(sub("^.*-", "", depth_cm)),
    recovered_depth_cm = 100 + core_deficit,
    effective_depth_bottom_cm = pmin(
      nominal_depth_bottom_cm,
      recovered_depth_cm
    ),
    depth_total_cm = pmax(
      effective_depth_bottom_cm - nominal_depth_top_cm,
      0
    ),
    volume_cm3 = depth_total_cm * (1.905 ^ 2) * pi,
    bulk_density = total_dry_soil_g / volume_cm3,
    layer_c_stock = c_percent * bulk_density * depth_total_cm,
    site_type = case_when(
      site_name == "HRDY1" ~ "30-year-old hedgerow",
      site_name == "HRDY2" ~ "10-year-old hedgerow",
      site_name == "HRDY3" ~ "bare field margin",
      site_name == "IKON" ~ "monoculture",
      site_name == "LAHE" ~ "polyculture",
      site_name == "MAS1" ~ "60-year-old orchard",
      site_name == "MAS2" ~ "20-year-old orchard",
      TRUE ~ NA_character_
    ),
    system = case_when(
      project_id == "CD" ~ "annual vegetables",
      project_id == "OR" ~ "orchards",
      project_id == "HE" ~ "hedgerows",
      TRUE ~ NA_character_
    ),
    core = interaction(site_name, sampling_point, drop = TRUE)
  )

assert_true(nrow(df_full) == 111L, "A lookup join changed the 111-row sample grain.")
assert_unique(df_full, "sample_id", "Joined sample-level dataset")
assert_unique(df_full, "sample_code", "Joined sample-level dataset")
assert_unique(
  df_full,
  c("system", "site_name", "sampling_point", "depth_cm"),
  "Joined sample-level dataset"
)
assert_true(!anyNA(df_full$system), "At least one retained sample has no system label.")
assert_true(!anyNA(df_full$site_type), "At least one retained sample has no treatment label.")
assert_true(all(df_full$depth_total_cm > 0), "At least one layer has nonpositive recovered thickness.")

depth_crosscheck <- df_full %>%
  filter(!is.na(depth_top), !is.na(depth_bottom)) %>%
  summarise(
    top_mismatch_n = sum(depth_top != nominal_depth_top_cm),
    bottom_mismatch_n = sum(depth_bottom != nominal_depth_bottom_cm)
  )
write_csv_stable(depth_crosscheck, "depth_label_crosscheck.csv")
assert_true(
  depth_crosscheck$top_mismatch_n == 0L & depth_crosscheck$bottom_mismatch_n == 0L,
  "Depth labels disagree with the radiocarbon workbook depth bounds."
)

depth_levels <- c(
  "0-10", "10-20", "20-30", "20-50", "30-40",
  "40-50", "50-75", "50-100", "75-100"
)
treatment_levels <- c(
  "monoculture", "polyculture",
  "20-year-old orchard", "60-year-old orchard",
  "bare field margin", "10-year-old hedgerow", "30-year-old hedgerow"
)

df_full <- df_full %>%
  mutate(
    depth_cm = factor(depth_cm, levels = depth_levels),
    site_type = factor(site_type, levels = treatment_levels),
    system = factor(
      system,
      levels = c("annual vegetables", "orchards", "hedgerows")
    )
  )

# Orchard inference is restricted to 0-75 cm. Exclude 75-100 cm before any
# cumulative stock calculation so the omitted layer cannot affect retained rows.
df_analysis <- df_full %>%
  filter(!(system == "orchards" & depth_cm == "75-100")) %>%
  arrange(system, site_name, sampling_point, nominal_depth_top_cm) %>%
  group_by(system, site_name, site_type, sampling_point, core) %>%
  mutate(cumulative_c_stock = cumsum(layer_c_stock)) %>%
  ungroup()

assert_true(nrow(df_analysis) == 105L, "Expected 105 rows after orchard 75-100 exclusion.")
assert_unique(df_analysis, "sample_id", "Analysis dataset")
assert_unique(
  df_analysis,
  c("system", "site_name", "sampling_point", "depth_cm"),
  "Analysis dataset"
)

expected_system_rows <- c(
  "annual vegetables" = 36L,
  "orchards" = 24L,
  "hedgerows" = 45L
)
observed_system_rows <- table(as.character(df_analysis$system))
assert_true(
  identical(as.integer(observed_system_rows[names(expected_system_rows)]), unname(expected_system_rows)),
  "System row counts do not match 36 annual, 24 orchard, and 45 hedgerow samples."
)

cell_counts <- df_analysis %>%
  count(system, site_type, depth_cm, .drop = TRUE, name = "n")
assert_true(all(cell_counts$n == 3L), "Every treatment-by-depth cell should contain three cores.")

required_responses <- c(
  "root_weight", "c_percent", "cn_ratio", "layer_c_stock", "del14c"
)
missing_response_counts <- df_analysis %>%
  summarise(across(all_of(required_responses), ~ sum(is.na(.x)))) %>%
  pivot_longer(everything(), names_to = "response", values_to = "missing_n")
write_csv_stable(missing_response_counts, "missing_response_counts.csv")
assert_true(
  all(missing_response_counts$missing_n == 0L),
  "A manuscript response contains missing data after the orchard exclusion."
)
assert_true(all(df_analysis$root_weight >= 0), "Root biomass contains a negative value.")
assert_true(all(df_analysis$c_percent > 0), "C concentration contains a nonpositive value.")
assert_true(all(df_analysis$cn_ratio > 0), "C:N contains a nonpositive value.")
assert_true(all(df_analysis$layer_c_stock > 0), "Layer C stock contains a nonpositive value.")



# Compare the reconstructed historical data before any annual working correction.
# The raw root subtraction at sample143 is preserved in root_weight_raw; 0.0086g
# is the recorded working replacement already present in the selected CSVs.
assert_true(sum(roots$root_weight_raw==root_correction_raw,na.rm=TRUE)==1L,
            "Expected one recorded impossible negative root subtraction.")
assert_true(identical(roots$sample_id[which(roots$root_weight_raw==root_correction_raw)],"143"),
            "The recorded negative-root correction must belong to sample143.")
validation <- list()
compare_data <- function(actual, expected, label, columns=names(expected), key="sample_id") {
  assert_true(all(columns %in% names(actual)),paste(label,"missing actual columns"))
  assert_unique(actual,key,paste(label,"actual")); assert_unique(expected,key,paste(label,"expected"))
  assert_true(nrow(actual)==nrow(expected),paste(label,"row count mismatch"))
  index <- match(as.character(expected[[key]]),as.character(actual[[key]]))
  assert_true(!anyNA(index),paste(label,"missing keys")); actual <- actual[index,,drop=FALSE]
  maximum <- 0
  for(column in columns) {
    x <- actual[[column]]; y <- expected[[column]]
    if(is.numeric(x) && is.numeric(y)) {
      assert_true(identical(is.na(x),is.na(y)),paste(label,column,"missingness differs"))
      keep <- !is.na(x)
      if(any(keep)) {
        error <- abs(x[keep]-y[keep]); maximum <- max(maximum,error)
        assert_true(all(error<=1e-10+1e-12*abs(y[keep])),paste(label,column,"numeric values differ"))
      }
    } else {
      x <- as.character(x);y <- as.character(y);x[is.na(x)]<-"";y[is.na(y)]<-""
      equal <- x==y
      # This mixed numeric/control-label column is exported by Sheets with
      # numeric text such as40.0; the raw metadata contains40. Same value only.
      if(column=="years_in_management") {
        xn <- suppressWarnings(as.numeric(x));yn <- suppressWarnings(as.numeric(y))
        numeric_pair <- is.finite(xn)&is.finite(yn)
        equal[numeric_pair] <- xn[numeric_pair]==yn[numeric_pair]
      }
      assert_true(all(equal),paste(label,column,"text values differ"))
    }
  }
  validation[[label]] <<- tibble(check=label,rows=nrow(expected),columns=length(columns),maximum_absolute_numeric_error=maximum,status="PASS")
}
historical_full <- read_csv(file.path(ROOT_DIR,"analysis/selected_reference_2026-07-30/data/sample_level_full_111.csv"),show_col_types=FALSE)
historical_analysis <- read_csv(file.path(ROOT_DIR,"analysis/selected_reference_2026-07-30/data/sample_level_analysis_105.csv"),show_col_types=FALSE)
compare_data(df_full,historical_full,"historical111_reconstructed_from_working_sources")
compare_data(df_analysis,historical_analysis,"historical105_reconstructed_from_working_sources")

# The current annual CSV is the explicit author-reviewed working-mass record.
# It is not substituted for the raw laboratory measurements.
annual <- read_csv(file.path(ROOT_DIR,"analysis/corrected_annual_gamma_2026-10-16/input/annual_corrected_root_profiles.csv"),show_col_types=FALSE)
assert_true(nrow(annual)==36L,"Expected36 annual input rows.")
assert_unique(annual,"sample_id","Annual correction record")
old_index <- match(annual$sample_id,as.numeric(as.character(df_full$sample_id)))
assert_true(!anyNA(old_index),"An annual correction is missing from the111 raw rows.")
assert_true(all(abs(df_full$root_weight_raw[old_index]-annual$root_mass_original_g)<1e-10),"Annual original masses differ from raw source masses.")
assert_true(all(abs(df_full$volume_cm3[old_index]-annual$volume_cm3)<1e-9),"Annual source volumes differ.")
changed <- abs(annual$root_mass_current_g-annual$root_mass_original_g)>1e-12
assert_true(sum(changed)==18L,"Expected exactly18 annual working-mass corrections.")
assert_true(sum(annual$root_mass_current_g==0)==9L,"Expected9 recorded no-recovery annual zeros.")
current_full <- df_full
current_full$root_weight[old_index] <- annual$root_mass_current_g
current_analysis <- current_full %>%
  filter(!(system=="orchards" & depth_cm=="75-100")) %>%
  arrange(system,site_name,sampling_point,nominal_depth_top_cm) %>%
  group_by(system,site_name,site_type,sampling_point,core) %>%
  mutate(cumulative_c_stock=cumsum(layer_c_stock)) %>% ungroup()
# All other historical scientific columns must remain unchanged.
compare_data(current_full,historical_full,"current111_nonroot_columns_unchanged",setdiff(names(historical_full),"root_weight"))
compare_data(current_analysis,historical_analysis,"current105_nonroot_columns_unchanged",setdiff(names(historical_analysis),"root_weight"))
# The 105-row table is retained as the historical orchard-restricted input.
# Current primary analyses additionally exclude the nine deepest hedgerow rows.
# Filtering these terminal increments does not change any shallower cumulative sum.
current_primary <- current_analysis %>%
  filter(system!="hedgerows" | nominal_depth_bottom_cm<=75)
assert_true(nrow(current_primary)==96L,"Expected96 current primary rows.")
assert_true(identical(as.integer(table(factor(as.character(current_primary$system),
  levels=c("annual vegetables","orchards","hedgerows")))),c(36L,24L,36L)),
  "Expected36 annual,24 orchard and36 hedgerow primary observations.")
assert_unique(current_primary,"sample_id","Current96 primary input")
frozen_primary <- read_csv(file.path(ROOT_DIR,"data/processed/sample_level_analysis_96_current.csv"),show_col_types=FALSE)
compare_data(current_primary,frozen_primary,"current96_primary_scope_and_values")
annual_actual <- current_full[old_index,] %>% transmute(sample_id=as.numeric(as.character(sample_id)),sample_code,core=as.character(core),management=as.character(site_type),volume_cm3,root_mass_original_g=root_weight_raw,root_mass_current_g=root_weight)
compare_data(annual_actual,annual,"current36_annual_module_input",names(annual_actual))
assert_true(max(abs(1000*annual_actual$root_mass_current_g/annual_actual$volume_cm3-annual$root_density_mg_cm3))<1e-10,"Annual density arithmetic differs.")
perennial <- read_csv(file.path(ROOT_DIR,"analysis/current_perennial_root/input/perennial_root_input.csv"),show_col_types=FALSE)
perennial_actual <- current_full %>% filter(system %in% c("orchards","hedgerows"),nominal_depth_bottom_cm<=75) %>%
  transmute(sample_code,system=as.character(system),site_type=as.character(site_type),core=as.character(core),top_cm=nominal_depth_top_cm,bottom_cm=nominal_depth_bottom_cm,root_weight_raw,root_weight,volume_cm3)
compare_data(perennial_actual,perennial,"current60_perennial_module_input",key="sample_code")
# Current orchard measurements are covered by the 96-row input comparison above
# and the publication-workbook comparison below. The superseded covariance
# archive is not an input to current data preparation.
# Full111 preserves its historical105 inclusion flags for byte-stable history.
# The separately keyed scope table records the current96 inclusion decision.
current_full <- current_full %>% left_join(current_analysis %>% select(sample_id,cumulative_c_stock),by="sample_id",relationship="one-to-one") %>%
  mutate(analysis_included=if_else(system=="orchards" & depth_cm=="75-100","no","yes"),
    exclusion_reason=if_else(analysis_included=="no","Orchard 75-100 cm increment excluded so all orchard responses use the common 0-75 cm depth range.",NA_character_))
publication <- read.xlsx(file.path(ROOT_DIR,"data/Supplementary_Data.xlsx"),sheet="Sample data")
compare_data(current_full,publication,"current111_publication_workbook_measurements",
  setdiff(names(publication),c("analysis_included","exclusion_reason")))
current_scope <- current_full %>% transmute(
  sample_id,sample_code,system=as.character(system),depth_cm=as.character(depth_cm),
  historical_105_included=analysis_included,
  current_primary_96_included=if_else(sample_id %in% current_primary$sample_id,"yes","no"),
  current_root_96_included=current_primary_96_included,
  current_exclusion_reason=case_when(
    system=="orchards" & nominal_depth_bottom_cm>75 ~
      "Orchard 75-100 cm increment excluded so all orchard responses use the common 0-75 cm depth range.",
    system=="hedgerows" & nominal_depth_bottom_cm>75 ~
      "Hedgerow 75-100 cm excluded from 0-75 cm models.",
    TRUE ~ NA_character_))
workbook_scope <- current_scope %>% transmute(sample_id,
  analysis_included=current_primary_96_included,exclusion_reason=current_exclusion_reason)
compare_data(workbook_scope,publication,"current96_publication_workbook_scope",
  c("sample_id","analysis_included","exclusion_reason"))
assert_true(sum(current_scope$current_primary_96_included=="yes")==96L &&
  sum(current_scope$current_primary_96_included=="no")==15L,"Current scope flags differ.")
# The source compilation already contains the corrected CAMS142/143 values.
# Do not guess or apply another14C correction here.
assert_true(current_full$del14c[as.character(current_full$sample_id)=="142"]==-11.5 && current_full$del14c[as.character(current_full$sample_id)=="143"]==13.2,"Compiled sample142/143 values differ from selected records.")

raw_relative <- c("metadata/metadata - final.xlsx","metadata/metadata - hedgerows - final.xlsx","soil moisture/soil moisture - Fresno.xlsx","soil moisture/soil moisture - hedgerows.xlsx","14C/HRDY_21Nov2024.xlsx","14C/IKON-LAHE_21Nov_2024.xlsx","14C/MAS_21Nov_2024.xlsx","metadata/depth increments.xlsx","core cutting/core measurements copy.xlsx","core cutting/core measurements - hedgerows.xlsx","roots/Envelope Weight - Fresno.xlsx","roots/Davis - Root Envelope.xlsx")
input_manifest <- tibble(file=raw_relative,bytes=as.numeric(file.info(file.path(DATA_DIR,raw_relative))$size),sha256=vapply(file.path(DATA_DIR,raw_relative),function(path)digest::digest(file=path,algo="sha256"),character(1)))
provenance <- read.xlsx(file.path(ROOT_DIR,"data/Supplementary_Data.xlsx"),sheet="Provenance")
for(i in seq_len(nrow(input_manifest))) {
  row <- provenance[which(provenance$file==basename(input_manifest$file[[i]])),,drop=FALSE]
  assert_true(nrow(row)==1L && row$sha256==input_manifest$sha256[[i]] && as.numeric(row$bytes)==input_manifest$bytes[[i]],paste("Raw source differs from recorded provenance:",input_manifest$file[[i]]))
}
correction_ledger <- bind_rows(
  tibble(sample_id=143,raw_root_weight_g=root_correction_raw,working_root_weight_g=root_correction_value,basis="Recorded working replacement of impossible source subtraction; not independent handwritten verification"),
  annual[changed,] %>% transmute(sample_id,raw_root_weight_g=root_mass_original_g,working_root_weight_g=root_mass_current_g,basis="Author-reviewed October16 annual working-mass record"))
# Only after every check passes do we create a fresh output directory.
OUTPUT_DIR <- protect_output(OUTPUT_DIR)
assert_true(!file.exists(OUTPUT_DIR) && !dir.exists(OUTPUT_DIR),"Output now exists; choose a new directory.")
dir.create(OUTPUT_DIR,recursive=TRUE,showWarnings=FALSE)
write_csv(current_full,file.path(OUTPUT_DIR,"sample_level_full_111_current.csv"),na="")
write_csv(current_analysis,file.path(OUTPUT_DIR,"sample_level_analysis_105_current.csv"),na="")
write_csv(current_primary,file.path(OUTPUT_DIR,"sample_level_analysis_96_current.csv"),na="")
write_csv(current_scope,file.path(OUTPUT_DIR,"sample_level_scope_111_current.csv"),na="")
write_csv(correction_ledger,file.path(OUTPUT_DIR,"root_working_correction_ledger.csv"),na="")
write_csv(input_manifest,file.path(OUTPUT_DIR,"source_measurement_manifest.csv"),na="")
write_csv(bind_rows(validation),file.path(OUTPUT_DIR,"preparation_validation.csv"),na="")
for(name in names(check_exports)) write_csv(check_exports[[name]],file.path(OUTPUT_DIR,name),na="")
cat("PASS: 12 working source workbooks -> retained111/105 tables and current96 primary input; 19 recorded root working corrections; measurement values, current workbook scope and module inputs match.\n")
cat("No models, simulations, document creation or workbook creation performed.\n")
cat("New CSV directory:",OUTPUT_DIR,"\n")
