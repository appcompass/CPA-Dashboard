build_manifest_app_files <- function() {
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

  unique(app_files[file.exists(app_files)])
}

write_app_manifest <- function() {
  if (!requireNamespace("rsconnect", quietly = TRUE)) {
    install.packages("rsconnect", repos = "https://cloud.r-project.org")
  }

  rsconnect::writeManifest(
    appDir = ".",
    appPrimaryDoc = "app.R",
    appFiles = build_manifest_app_files()
  )
}

if (sys.nframe() == 0) {
  write_app_manifest()
}
