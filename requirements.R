packages <- c(
  "PNADcIBGE",
  "survey",
  "srvyr",
  "tidyverse",
  "janitor",
  "scales",
  "broom",
  "gt",
  "readxl",
  "jsonlite",
  "glue",
  "IRkernel"
)

user_library <- file.path(
  Sys.getenv("USERPROFILE"),
  "Documents",
  "R",
  "win-library",
  paste0(R.version$major, ".", R.version$minor)
)

if (Sys.getenv("USERPROFILE") != "") {
  dir.create(user_library, recursive = TRUE, showWarnings = FALSE)
  .libPaths(c(user_library, .libPaths()))
}

missing <- packages[!packages %in% rownames(installed.packages())]

if (length(missing) > 0) {
  install.packages(missing, repos = "https://cloud.r-project.org")
}

IRkernel::installspec(user = TRUE)

cat("R project dependencies are ready.\n")
