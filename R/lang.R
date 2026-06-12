# Supported language codes with display names and Tabler flag icon CSS classes.
# Flag icons are sourced from tabler-files/tabler-1.4.0/dashboard/flags.html
# and rendered as: tags$span(class = paste("flag", SUPPORTED_LANGUAGES[code, "flag_icon"]))
# The APP_LANG environment variable selects the active language (default: "en").
SUPPORTED_LANGUAGES <- data.frame(
  code = c(
    "en",
    "es",
    "pt-BR",
    "ht",
    "vi",
    "fr",
    "zh-Hans"
  ),
  label = c(
    "English",
    "Español",
    "Português (Brasil)",
    "Kreyol ayisyen",
    "Tiếng Việt",
    "Français",
    "简体中文"
  ),
  flag_icon = c(
    "flag-country-us", # English               → United States
    "flag-country-es", # Spanish               → Spain
    "flag-country-br", # Portuguese (Brazilian) → Brazil
    "flag-country-ht", # Haitian Creole        → Haiti
    "flag-country-vn", # Vietnamese            → Vietnam
    "flag-country-fr", # French                → France
    "flag-country-cn" # Simplified Chinese    → China
  ),
  stringsAsFactors = FALSE,
  row.names = "code"
)

translations <- load_app_translations()

missing_langs <- setdiff(rownames(SUPPORTED_LANGUAGES), names(translations))
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
# Falls back to English if the code is not recognised.
# Set the APP_LANG environment variable to change the active language,
# e.g. Sys.setenv(APP_LANG = "es") before sourcing this file.
get_lang <- function(code = Sys.getenv("APP_LANG", unset = "en")) {
  if (!code %in% rownames(SUPPORTED_LANGUAGES)) {
    warning(sprintf(
      "Language '%s' is not supported. Supported codes: %s. Falling back to English.",
      code, paste(rownames(SUPPORTED_LANGUAGES), collapse = ", ")
    ))
    code <- "en"
  }
  translations[[code]]
}

lang <- get_lang()
