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
  # Each language's name in its own language (endonym), shown in the language
  # selector. Regional qualifiers are kept (and localized) where they were
  # present, to distinguish variants.
  #
  # Written as \uXXXX escapes rather than literal glyphs, and this file is kept
  # pure ASCII throughout. R reads a source file in the process's NATIVE
  # encoding; under the C/POSIX locale the deployed container runs in, the first
  # non-ASCII byte truncates the read and silently drops the rest of the file.
  # These labels used to sit at line 27 and took the whole app down with an
  # unterminated string. An escape is plain ASCII in the file and the parser
  # turns it into a UTF-8-marked string in any locale. Escapes are zero-padded
  # to four hex digits, so a following hex character can never be absorbed.
  label = c(
    "English",
    "Espa\u00f1ol (Latinoam\u00e9rica)",      # Espanol (Latinoamerica)
    "Krey\u00f2l Ayisyen",                    # Kreyol Ayisyen
    "\u7b80\u4f53\u4e2d\u6587",              # Simplified Chinese
    "Ti\u1ebfng Vi\u1ec7t",                   # Tieng Viet
    "\u7cb5\u8a9e",                          # Cantonese
    "Portugu\u00eas (Brasil)",                # Portugues (Brasil)
    "Kabuverdianu",
    "\u0420\u0443\u0441\u0441\u043a\u0438\u0439",  # Russkiy
    "Fran\u00e7ais (Europe)",                 # Francais (Europe)
    "\u0627\u0644\u0639\u0631\u0628\u064a\u0629",  # al-Arabiyyah
    "Soomaali"
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

# Fallback source file for each supported code when it has no translation file of
# its own (e.g. a regional variant reuses its base language; the rest fall to en).
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

# Stamp each language list with its own code so downstream code (e.g. the dynamic
# interview-content lookup) can resolve the active language from the lang object,
# which otherwise carries only translated strings.
for (code in rownames(SUPPORTED_LANGUAGES)) {
  if (!is.null(translations[[code]])) {
    translations[[code]][["lang_code"]] <- code
  }
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
