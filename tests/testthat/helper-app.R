library(shiny)
library(testthat)

project_root <- normalizePath(
  file.path(getwd(), "..", ".."),
  winslash = "/",
  mustWork = TRUE
)

old_wd <- setwd(project_root)
on.exit(setwd(old_wd), add = TRUE)

dotenv_path <- file.path(project_root, ".env")
if (!nzchar(Sys.getenv("CPA_DATA_KEY")) && file.exists(dotenv_path)) {
  env_lines <- readLines(dotenv_path, warn = FALSE)
  key_line <- grep("^(export[[:space:]]+)?CPA_DATA_KEY=", env_lines, value = TRUE)
  if (length(key_line) > 0) {
    key_value <- sub("^(export[[:space:]]+)?CPA_DATA_KEY=", "", key_line[[1]])
    key_value <- trimws(key_value)
    key_value <- sub('^"(.*)"$', "\\1", key_value)
    key_value <- sub("^'(.*)'$", "\\1", key_value)
    if (nzchar(key_value)) {
      Sys.setenv(CPA_DATA_KEY = key_value)
    }
  }
}

source(file.path(project_root, "R", "helpers.R"), local = FALSE)
source(file.path(project_root, "R", "data.R"), local = FALSE)
source(file.path(project_root, "R", "ui.R"), local = FALSE)
source(file.path(project_root, "R", "server.R"), local = FALSE)
