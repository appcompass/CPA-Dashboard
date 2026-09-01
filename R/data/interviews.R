# ---------------------------------------------------------------------------
# Interview-coded data (barriers / resource_needs / emerging / other_services
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

# Subcategory keys an organization provides according to its interview coding,
# read from `other_services` -- the sub-keys a human coder assigned from the
# transcript. Never inferred from text, so nothing lands on an org that a coder
# did not put there. Gated two ways:
#   * only dimensions the SURVEY marked "established", mirroring
#     established_subcat_keys(). The only consumers are the established wheel and
#     the established filter group, so a service coded in an emerging or
#     not_interested dimension has nowhere to render, and emitting it would make
#     the org match an "established" filter it does not belong in.
#   * only keys declared in DIMENSION_ALL_SUB_KEYS for that dimension, so a typo
#     or a retired key never reaches the DOM as an unlabelled sub-key. Validating
#     against the union (not just the interview list) lets a coder legitimately
#     add a SURVEY-vocabulary service the org forgot to check off.
interview_subcat_keys <- function(orgservices, interview_dims) {
  if (is.null(interview_dims) || !length(interview_dims)) {
    return(character(0))
  }
  out <- character(0)
  for (key in names(DIMENSION_LABEL_KEYS)) {
    dim <- orgservices[[key]]
    if (is.null(dim) || !identical(dim$state, "established")) next
    coded <- trimws(as.character(unlist(interview_dims[[key]][["other_services"]] %||% list())))
    coded <- coded[nzchar(coded)]
    if (!length(coded)) next
    out <- c(out, intersect(coded, DIMENSION_ALL_SUB_KEYS[[key]]))
  }
  unique(out)
}

# Every subcategory an organization provides as an established service: matched
# from its survey answers, plus coded from its interview. Both places that expose
# subcategories to the client -- the details-page wheel (data-active-subcats) and
# the organizations list cards (data-established-subcats) -- go through here, so
# the wheel and the filter can never disagree about what an org offers.
org_subcat_keys <- function(orgservices, interview_dims) {
  unique(c(
    established_subcat_keys(orgservices),
    interview_subcat_keys(orgservices, interview_dims)
  ))
}

# Per-service detail text for the established wheel: a sentence or two about how
# THIS organization delivers a service the wheel already lists (e.g. that its job
# training is blue-collar). Lives UNENCRYPTED and English-only in
# data/service_details.json, hand-authored one organization at a time, because the
# editing loop is frequent and small and a .enc file would make every edit an
# unreviewable binary diff. Missing file, malformed JSON, or missing entries all
# degrade to no detail text rather than failing. Cached for the process.
#
# Shape: { "service_details": { "<irb_id>": { "<dim>": { "<sub_key>": "text" } } } }
# Cached PER PATH rather than once for the process. A single shared cache would make
# the path argument meaningless after the first call: whichever caller ran first
# would fix the value, and a later call with a different path would silently get the
# earlier file back.
load_service_details <- local({
  cache <- list()
  function(path = file.path("data", "service_details.json")) {
    key <- as.character(path)[[1]]
    if (!is.null(cache[[key]])) {
      return(cache[[key]])
    }
    value <- tryCatch(
      {
        if (!file.exists(path) || !requireNamespace("jsonlite", quietly = TRUE)) {
          list()
        } else {
          raw <- jsonlite::fromJSON(path, simplifyVector = FALSE)
          raw$service_details %||% list()
        }
      },
      error = function(e) list()
    )
    cache[[key]] <<- value
    value
  }
})

# Detail text for one organization, flattened to sub_key -> text.
#
# subcat_keys is the org's rendered subcategory set (org_subcat_keys()). Anything
# outside it is dropped, so text authored for a service the org does not show
# cannot leak into the DOM, and stale text survives harmlessly in the file if a
# service is later removed. Blank or whitespace-only text is dropped too, which is
# what makes an unwritten service render no box at all.
get_service_details <- function(irb_id, subcat_keys,
                                details = load_service_details()) {
  irb_id <- trimws(as.character(irb_id %||% ""))
  if (!nzchar(irb_id) || !length(subcat_keys)) {
    return(list())
  }
  record <- details[[irb_id]]
  if (is.null(record) || !length(record)) {
    return(list())
  }

  out <- list()
  for (key in names(DIMENSION_LABEL_KEYS)) {
    entries <- record[[key]]
    if (is.null(entries) || !length(entries)) next
    for (sub_key in names(entries)) {
      if (!sub_key %in% subcat_keys) next
      text <- trimws(as.character(entries[[sub_key]] %||% ""))
      if (nzchar(text)) {
        out[[sub_key]] <- text
      }
    }
  }
  out
}

# Serialize detail text for the wheel's data-subcat-details attribute, or NULL when
# there is none. NULL matters: Shiny omits NULL attributes entirely, so createWheel
# sees no attribute and skips the detail path rather than parsing an empty object.
subcat_details_attr <- function(subcat_details) {
  if (is.null(subcat_details) || !length(subcat_details)) {
    return(NULL)
  }
  assert_packages_installed("jsonlite")
  as.character(jsonlite::toJSON(subcat_details, auto_unbox = TRUE))
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
# trailing "\u2014 <explanation>" tail (e.g. "... \u2014 embedded informally only") does
# not defeat the match. Matching is deliberately an exact set of canonical
# clauses (not a fuzzy pattern) so a real barrier that merely mentions "focus"
# or begins with "Not" -- e.g. "Not enough staff power ...", "Bandwidth \u2014
# financial literacy is not core mission ..." -- is never dropped. Resolution is
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
