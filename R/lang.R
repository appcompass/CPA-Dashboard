# Supported language codes with display names and Tabler flag icon CSS classes.
# Flag icons are sourced from tabler-files/tabler-1.4.0/dashboard/flags.html
# and rendered as: tags$span(class = paste("flag", SUPPORTED_LANGUAGES[code, "flag_icon"]))
# The APP_LANG environment variable selects the active language.
DEFAULT_LANG_CODE <- "en"

SUPPORTED_LANGUAGES <- data.frame(
  code = c(
    "en",
    "es-419",
    "ht",
    "zh-Hans",
    "vi",
    "yue",
    "pt-BR",
    "kea",
    "ru",
    "fr-FR",
    "ar",
    "so"
  ),
  label = c(
    "English",
    "Spanish (Latin American)",
    "Haitian Creole",
    "Simplified Chinese",
    "Vietnamese",
    "Cantonese",
    "Portuguese (Brazilian)",
    "Cabo Verdean Creole",
    "Russian",
    "French (European)",
    "Arabic (Standard)",
    "Somali"
  ),
  flag_icon = c(
    "flag-country-us", # English
    "flag-country-mx", # Spanish (Latin American)
    "flag-country-ht", # Haitian Creole
    "flag-country-cn", # Simplified Chinese
    "flag-country-vn", # Vietnamese
    "flag-country-hk", # Cantonese
    "flag-country-br", # Portuguese (Brazilian)
    "flag-country-cv", # Cabo Verdean Creole
    "flag-country-ru", # Russian
    "flag-country-fr", # French (European)
    "flag-country-sa", # Arabic (Standard)
    "flag-country-so" # Somali
  ),
  stringsAsFactors = FALSE,
  row.names = "code"
)

translations <- load_app_translations()

TRANSLATION_SOURCE <- c(
  "en" = "en",
  "es-419" = "es",
  "ht" = "ht",
  "zh-Hans" = "zh-Hans",
  "vi" = "vi",
  "yue" = "zh-Hans",
  "pt-BR" = "pt-BR",
  "kea" = "pt-BR",
  "ru" = "en",
  "fr-FR" = "fr",
  "ar" = "en",
  "so" = "en"
)

for (code in rownames(SUPPORTED_LANGUAGES)) {
  if (!is.null(translations[[code]])) {
    next
  }

  source_code <- unname(TRANSLATION_SOURCE[[code]])
  if (is.null(source_code) || !nzchar(source_code)) {
    source_code <- code
  }
  if (is.null(translations[[source_code]])) {
    source_code <- "en"
  }

  translations[[code]] <- translations[[source_code]]
}

missing_langs <- rownames(SUPPORTED_LANGUAGES)[
  vapply(rownames(SUPPORTED_LANGUAGES), function(code) is.null(translations[[code]]), logical(1))
]
if (length(missing_langs)) {
  stop(
    sprintf(
      "Missing translations for language code(s): %s",
      paste(missing_langs, collapse = ", ")
    ),
    call. = FALSE
  )
}

# Returns the translation list for the given language code.
# Falls back to DEFAULT_LANG_CODE if the code is not recognised.
# Set the APP_LANG environment variable to change the active language,
# e.g. Sys.setenv(APP_LANG = "es-419") before sourcing this file.
get_lang <- function(code = Sys.getenv("APP_LANG", unset = DEFAULT_LANG_CODE)) {
  if (!code %in% rownames(SUPPORTED_LANGUAGES)) {
    warning(sprintf(
      "Language '%s' is not supported. Supported codes: %s. Falling back to %s.",
      code,
      paste(rownames(SUPPORTED_LANGUAGES), collapse = ", "),
      DEFAULT_LANG_CODE
    ))
    code <- DEFAULT_LANG_CODE
  }
  translations[[code]]
}

lang <- get_lang()
