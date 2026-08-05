# ---------------------------------------------------------------------------
# App UI translations: one JSON file per locale under data/translations/,
# loaded once per process and also serialized for the client (app.js).
# ---------------------------------------------------------------------------

TRANSLATIONS_DIR <- file.path("data", "translations")

load_app_translations <- local({
  cached <- NULL

  function(dir = TRANSLATIONS_DIR) {
    if (!is.null(cached)) {
      return(cached)
    }

    if (!dir.exists(dir)) {
      stop(sprintf("Expected translations directory at '%s'.", dir), call. = FALSE)
    }

    assert_packages_installed("jsonlite")

    files <- list.files(dir, pattern = "\\.json$", full.names = TRUE)
    if (!length(files)) {
      stop(sprintf("No .json files found in translations directory '%s'.", dir), call. = FALSE)
    }

    loaded <- lapply(files, function(f) {
      content <- jsonlite::fromJSON(f, simplifyVector = FALSE)
      if (!is.list(content) || !length(content)) {
        stop(sprintf("Translations file '%s' is empty or invalid.", f), call. = FALSE)
      }
      content
    })
    # Name each entry by its locale code (filename without .json)
    names(loaded) <- tools::file_path_sans_ext(basename(files))

    cached <<- loaded
    cached
  }
})

# All translations as JSON for the client (window.APP_TRANSLATIONS in app.js),
# which uses them for the wellness wheel and theme-settings panel.
get_frontend_translations_json <- function() {
  assert_packages_installed("jsonlite")

  jsonlite::toJSON(
    load_app_translations(),
    auto_unbox = TRUE,
    pretty = FALSE,
    null = "null"
  )
}
