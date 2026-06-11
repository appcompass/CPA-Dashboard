if (!requireNamespace("rsconnect", quietly = TRUE)) {
  install.packages("rsconnect", repos = "https://cloud.r-project.org")
}

app_files <- c(
  "app.R",
  "Makefile",
  "README.md",
  "R/helpers.R",
  "R/data.R",
  "R/ui.R",
  "R/server.R",
  list.files("R/templates", recursive = TRUE, full.names = TRUE),
  list.files("www/css", recursive = TRUE, full.names = TRUE),
  list.files("www/html", recursive = TRUE, full.names = TRUE),
  list.files("www/js", recursive = TRUE, full.names = TRUE),
  file.path("data", "sample_data.csv"),
  file.path("data", "survey_data.csv.enc")
)

app_files <- unique(app_files[file.exists(app_files)])

rsconnect::writeManifest(
  appDir = ".",
  appPrimaryDoc = "app.R",
  appFiles = app_files
)
