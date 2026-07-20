user_library <- file.path(
  Sys.getenv("USERPROFILE"),
  "Documents",
  "R",
  "win-library",
  paste0(R.version$major, ".", R.version$minor)
)
if (Sys.getenv("USERPROFILE") != "" && dir.exists(user_library)) {
  .libPaths(c(user_library, .libPaths()))
}

required_packages <- c("readr", "jsonlite", "dplyr", "stringr")
missing_packages <- required_packages[!vapply(required_packages, requireNamespace, logical(1), quietly = TRUE)]
if (length(missing_packages) > 0) {
  stop("Missing R packages: ", paste(missing_packages, collapse = ", "), call. = FALSE)
}

suppressPackageStartupMessages({
  library(readr)
  library(jsonlite)
  library(dplyr)
  library(stringr)
})

detect_project_root <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- grep("^--file=", args, value = TRUE)
  if (length(file_arg) == 1) {
    script_path <- normalizePath(sub("^--file=", "", file_arg), winslash = "/", mustWork = TRUE)
    return(normalizePath(file.path(dirname(script_path), ".."), winslash = "/", mustWork = TRUE))
  }
  normalizePath(getwd(), winslash = "/", mustWork = TRUE)
}

project_root <- detect_project_root()
processed_dir <- file.path(project_root, "data", "processed")
figures_dir <- file.path(project_root, "figures")

fail <- function(message) stop(message, call. = FALSE)
check_file <- function(path, min_bytes = 1) {
  if (!file.exists(path)) fail(paste("Missing file:", path))
  if (file.info(path)$size < min_bytes) fail(paste("File is too small:", path))
}

expected_files <- c(
  file.path(processed_dir, "occupation_rank_q1_2026.csv"),
  file.path(processed_dir, "top15_gender_composition.csv"),
  file.path(processed_dir, "top15_gender_gap.csv"),
  file.path(processed_dir, "descriptive_model_terms.csv"),
  file.path(processed_dir, "analysis_summary.json"),
  file.path(processed_dir, "occupation_wage_anatomy.csv"),
  file.path(processed_dir, "occupation_access_anatomy.csv"),
  file.path(processed_dir, "deep_anatomy_highlights.json"),
  file.path(processed_dir, "inequality_decomposition_theil.json"),
  file.path(processed_dir, "inequality_decomposition_groups.csv"),
  file.path(figures_dir, "top20_occupations_income.png"),
  file.path(figures_dir, "top15_gender_composition.png"),
  file.path(figures_dir, "wage_anatomy_map.png"),
  file.path(figures_dir, "distribution_ladder_selected_occupations.png"),
  file.path(figures_dir, "access_vs_internal_gender_gap.png"),
  file.path(figures_dir, "access_representation_quadrants.png"),
  file.path(figures_dir, "theil_inequality_decomposition.png")
)
invisible(lapply(expected_files, check_file, min_bytes = 100))

rank <- read_csv(file.path(processed_dir, "occupation_rank_q1_2026.csv"), show_col_types = FALSE)
gap <- read_csv(file.path(processed_dir, "top15_gender_gap.csv"), show_col_types = FALSE)
model_terms <- read_csv(file.path(processed_dir, "descriptive_model_terms.csv"), show_col_types = FALSE)
anatomy <- read_csv(file.path(processed_dir, "occupation_wage_anatomy.csv"), show_col_types = FALSE)
access_anatomy <- read_csv(file.path(processed_dir, "occupation_access_anatomy.csv"), show_col_types = FALSE)
summary <- fromJSON(file.path(processed_dir, "analysis_summary.json"))
deep_summary <- fromJSON(file.path(processed_dir, "deep_anatomy_highlights.json"))
theil_summary <- fromJSON(file.path(processed_dir, "inequality_decomposition_theil.json"))

required_rank_cols <- c(
  "occupation", "occupation_label", "workers", "avg_income", "avg_income_low",
  "avg_income_upp", "median_income", "sample_n", "rank"
)
missing_rank_cols <- setdiff(required_rank_cols, names(rank))
if (length(missing_rank_cols) > 0) {
  fail(paste("Ranking is missing columns:", paste(missing_rank_cols, collapse = ", ")))
}

required_gap_cols <- c("avg_income_Homem", "avg_income_Mulher", "gap_women_vs_men")
missing_gap_cols <- setdiff(required_gap_cols, names(gap))
if (length(missing_gap_cols) > 0) {
  fail(paste("Gender gap file is missing columns:", paste(missing_gap_cols, collapse = ", ")))
}

required_anatomy_cols <- c(
  "occupation", "occupation_label", "mean_income", "p10", "p50", "p90",
  "gini_within", "top10_income_share", "mean_median_ratio", "wage_anatomy_type"
)
missing_anatomy_cols <- setdiff(required_anatomy_cols, names(anatomy))
if (length(missing_anatomy_cols) > 0) {
  fail(paste("Wage anatomy is missing columns:", paste(missing_anatomy_cols, collapse = ", ")))
}

required_access_cols <- c(
  "women_location_quotient", "race_location_quotient",
  "p50_premium_vs_overall", "access_profile"
)
missing_access_cols <- setdiff(required_access_cols, names(access_anatomy))
if (length(missing_access_cols) > 0) {
  fail(paste("Access anatomy is missing columns:", paste(missing_access_cols, collapse = ", ")))
}

if (nrow(rank) < 200) fail("Expected at least 200 occupations after sample filter.")
if (summary$rows_analytic < 200000) fail("Expected at least 200,000 analytic rows.")
if (summary$occupations_after_filter != nrow(rank)) fail("Summary occupation count does not match ranking rows.")
if (!all(rank$sample_n >= summary$min_sample)) fail("Ranking contains occupations below min_sample.")
if (nrow(anatomy) < 200) fail("Expected at least 200 occupations in the deep wage anatomy.")
if (deep_summary$occupations_after_filter != nrow(anatomy)) {
  fail("Deep anatomy occupation count does not match anatomy rows.")
}
if (is.null(theil_summary$occupation$between_share) || theil_summary$occupation$between_share <= 0) {
  fail("Theil decomposition is missing a positive occupation between-share.")
}
if (!any(model_terms$model == "weighted_lm_with_occupation_fixed_effects_sensitivity")) {
  fail("Model terms do not include occupation fixed-effects sensitivity model.")
}

summary_text <- paste(
  readLines(file.path(processed_dir, "analysis_summary.json"), encoding = "UTF-8", warn = FALSE),
  collapse = "\n"
)
if (str_detect(summary_text, "MÃ|Ã©|Ã§|Ã£")) {
  fail("Detected likely mojibake/encoding corruption in outputs.")
}

large_repo_files <- list.files(project_root, recursive = TRUE, full.names = TRUE)
large_repo_files <- large_repo_files[file.info(large_repo_files)$size > 50 * 1024 * 1024]
if (length(large_repo_files) > 0) {
  fail(paste("Large raw/cache files should not be in the repo:", paste(large_repo_files, collapse = "; ")))
}

cat("All output checks passed.\n")
