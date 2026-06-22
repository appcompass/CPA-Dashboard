# Generates manifest.json (the file list + package deps) for Posit Connect /
# Connect Cloud deployment. Run via `make manifest`.

# The app files to bundle; non-existent entries are dropped before writing.
build_manifest_app_files <- function() {
  app_files <- c(
    "app.R",
    "Makefile",
    "README.md",
    # Sourced by app.R, in order.
    "R/data.R",
    "R/lang.R",
    "R/ui.R",
    "R/server.R",
    list.files("R/templates", recursive = TRUE, full.names = TRUE),
    list.files("www/css", recursive = TRUE, full.names = TRUE),
    list.files("www/js", recursive = TRUE, full.names = TRUE),
    list.files("data/translations", recursive = TRUE, full.names = TRUE),
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
