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
source(file.path(project_root, "R", "lang.R"), local = FALSE)
source(file.path(project_root, "R", "ui.R"), local = FALSE)
source(file.path(project_root, "R", "server.R"), local = FALSE)

# --------------------------------------------------------------------------
# CI fallback for forked PRs.
# GitHub withholds repository secrets (CPA_DATA_KEY) from pull requests opened
# from forks, so the real encrypted dataset can't be decrypted there and every
# data-dependent test would error. When (and only when) we're running in CI with
# no key available, provision a small throwaway encrypted fixture and a test key
# so the suite can run. This is guarded to CI, so it never overwrites a real
# local data file on a developer's machine.
# --------------------------------------------------------------------------
if (!nzchar(Sys.getenv("CPA_DATA_KEY")) && nzchar(Sys.getenv("CI"))) {
  Sys.setenv(CPA_DATA_KEY = "ci-fixture-key")

  .fixture_raw <- tempfile(fileext = ".csv")
  writeLines(c(
    "Dashboard ID,Organization,YearsServed,Age#1_1,Emotional,EmotionalEorE,Physical,PhysicalEorE",
    "id,org,years,age,emotional,eore,physical,peore",
    '{"ImportId":"a"},{"ImportId":"b"},{"ImportId":"c"},{"ImportId":"d"},{"ImportId":"e"},{"ImportId":"f"},{"ImportId":"g"},{"ImportId":"h"}',
    "CI1,CI Test Org A,8+ years,A lot (61%-100%),Counseling services,Established,,",
    "CI2,CI Test Org B,4-7 years,Some (26%-60%),,,Fitness programs,Emerging"
  ), .fixture_raw)

  .fixture_clean <- tempfile(fileext = ".csv")
  write.csv(
    transform_survey_export(.fixture_raw),
    .fixture_clean,
    row.names = FALSE, na = ""
  )
  encrypt_data_file(
    input_path = .fixture_clean,
    output_path = file.path(project_root, "data", "survey_data.csv.enc"),
    passphrase = Sys.getenv("CPA_DATA_KEY")
  )
}
