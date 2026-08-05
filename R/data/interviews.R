# ---------------------------------------------------------------------------
# Interview-coded data (barriers / resource_needs / emerging per dimension),
# decrypted at runtime and joined to the survey on irb_participant_id. This is
# OPTIONAL supplemental data: when the encrypted file or the key is absent, the
# loader returns an empty lookup and the dashboard simply renders no
# interview-derived content rather than failing.
# ---------------------------------------------------------------------------

# irb_participant_id -> per-dimension interview list. Decrypted once and cached
# for the process, mirroring load_app_translations.
load_interview_data <- local({
  cached <- NULL
  function(
    encrypted_path = file.path("data", "interview_data.json.enc"),
    passphrase = Sys.getenv("CPA_DATA_KEY"),
    key_env_var = "CPA_DATA_KEY"
  ) {
    if (!is.null(cached)) {
      return(cached)
    }
    lookup <- tryCatch(
      {
        if (!file.exists(encrypted_path) || !nzchar(passphrase) ||
          !requireNamespace("jsonlite", quietly = TRUE)) {
          list()
        } else {
          plain_path <- decrypt_data_file(
            encrypted_path = encrypted_path,
            output_path = tempfile(fileext = ".json"),
            passphrase = passphrase,
            key_env_var = key_env_var
          )
          on.exit(unlink(plain_path), add = TRUE)
          raw <- jsonlite::fromJSON(plain_path, simplifyVector = FALSE)
          out <- list()
          for (iv in raw$interviews %||% list()) {
            key <- trimws(as.character(iv$irb_participant_id %||% ""))
            if (nzchar(key)) {
              out[[key]] <- iv$dimensions
            }
          }
          out
        }
      },
      error = function(e) list()
    )
    cached <<- lookup
    cached
  }
})

# The per-dimension interview list for one organization, keyed by its
# irb_participant_id, or NULL when the org was not interviewed.
get_interview_dimensions <- function(irb_id, interview_data = load_interview_data()) {
  irb_id <- trimws(as.character(irb_id %||% ""))
  if (!nzchar(irb_id)) {
    return(NULL)
  }
  interview_data[[irb_id]]
}

# Interview content is stored in the encrypted file as opaque keys; the actual
# text (in every language) lives in the UNENCRYPTED data/interview_translations.json,
# keyed by those keys. This keeps the sensitive organization<->statement linkage
# encrypted while the de-associated text + translations travel with the i18n data.
# Shape: { "<key>": { "en": "...", "es-419": "...", ... }, ... }. Cached.
load_interview_translations <- local({
  cached <- NULL
  function(path = file.path("data", "interview_translations.json")) {
    if (!is.null(cached)) {
      return(cached)
    }
    cached <<- tryCatch(
      {
        if (!file.exists(path) || !requireNamespace("jsonlite", quietly = TRUE)) {
          list()
        } else {
          jsonlite::fromJSON(path, simplifyVector = FALSE)
        }
      },
      error = function(e) list()
    )
    cached
  }
})

# Resolve one interview-content key to text in lang_code, falling back to English
# and then to the raw key (so a missing translation degrades visibly but safely).
translate_interview_item <- function(key, lang_code, content = load_interview_translations()) {
  entry <- content[[key]]
  if (is.null(entry)) {
    return(key)
  }
  value <- entry[[lang_code]] %||% entry[["en"]]
  if (is.null(value) || !nzchar(value)) key else value
}

# Interview items for one field ("barriers" or "resource_needs"), grouped by
# dimension and translated into the active language. Returns an ordered list of
# list(label, items) for the dimensions that have any non-empty entries; dimension
# order follows DIMENSION_LABEL_KEYS so it lines up with the wheels. Empty when the
# org was not interviewed.
# Canonical English phrasings that mark a dimension as "not a focus / not our
# mission" rather than describing a real barrier or resource need. These are
# de-emphasis placeholders, not challenges, so they are dropped from the
# Challenges & Resource Needs card for every organization and dimension.
#
# Matching is on the clause BEFORE any em-dash, lowercased and trimmed, so a
# trailing "— <explanation>" tail (e.g. "... — embedded informally only") does
# not defeat the match. Matching is deliberately an exact set of canonical
# clauses (not a fuzzy pattern) so a real barrier that merely mentions "focus"
# or begins with "Not" — e.g. "Not enough staff power ...", "Bandwidth —
# financial literacy is not core mission ..." — is never dropped. Resolution is
# always via the English text so the decision is independent of display
# language. Add a new clause here if a future import introduces another wording.
INTERVIEW_NOT_A_FOCUS_PLACEHOLDERS <- c(
  "not a core programmatic focus",
  "not the organization's stated focus",
  "not an organizational focus",
  "not a core organizational offering",
  "not part of organizational mission",
  "not a central focus"
)

# TRUE when an interview key's English text is a "not a focus" placeholder.
is_not_a_focus_placeholder <- function(key, content = load_interview_translations()) {
  text <- translate_interview_item(key, "en", content)
  head <- tolower(trimws(strsplit(text, "\u2014", fixed = TRUE)[[1]][[1]]))
  head %in% INTERVIEW_NOT_A_FOCUS_PLACEHOLDERS
}

get_interview_dimension_items <- function(interview_dims, field, lang, orgservices = NULL) {
  organizations <- lang$organizations
  lang_code <- lang$lang_code %||% DEFAULT_LANG_CODE
  content <- load_interview_translations()
  out <- list()
  for (key in names(DIMENSION_LABEL_KEYS)) {
    # When orgservices is supplied, drop dimensions the org marked as not an
    # organizational focus ("not_interested") so their items are excluded.
    if (!is.null(orgservices) && identical(orgservices[[key]]$state, "not_interested")) {
      next
    }
    keys <- as.character(unlist(interview_dims[[key]][[field]] %||% list()))
    keys <- keys[nzchar(trimws(keys))]
    # Drop "not a focus / not our mission" placeholder entries; they describe the
    # absence of a focus rather than an actual barrier or resource need. See
    # INTERVIEW_NOT_A_FOCUS_PLACEHOLDERS.
    keys <- keys[vapply(keys, function(k) {
      !is_not_a_focus_placeholder(k, content)
    }, logical(1))]
    if (length(keys)) {
      items <- vapply(
        keys, function(k) translate_interview_item(k, lang_code, content), character(1)
      )
      label <- organizations[[DIMENSION_LABEL_KEYS[[key]]]]
      out[[length(out) + 1L]] <- list(
        label = if (!is.null(label) && nzchar(label)) label else key,
        items = unname(items)
      )
    }
  }
  out
}
