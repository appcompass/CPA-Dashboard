# ---------------------------------------------------------------------------
# The orgservices_json contract (per-dimension wellness state + services).
# Write side: parse_services + build_orgservices_json produce the column from
# the raw survey row. Read side: parse_orgservices_json + the category/
# subcategory helpers turn it back into what the wheels and filters render.
# ---------------------------------------------------------------------------

# Match a stored survey service string against a subcategory label, tolerant of
# trailing detail ("Educational workshops, e.g. ...") and minor word forms
# ("Nutrition" vs "Nutritional"). Both inputs should be lowercased/trimmed.
service_matches_label <- function(service, label) {
  if (!nzchar(service) || !nzchar(label)) {
    return(FALSE)
  }
  if (service == label || startsWith(service, label) || startsWith(label, service)) {
    return(TRUE)
  }
  sw <- strsplit(service, "\\s+")[[1]]
  lw <- strsplit(label, "\\s+")[[1]]
  length(sw) == length(lw) && length(sw) > 0 &&
    all(mapply(function(a, b) startsWith(a, b) || startsWith(b, a), sw, lw))
}

# Subcategory keys an organization provides as ESTABLISHED services. Each curated
# subcategory it matches is emitted by its key; an established service that
# matches no curated subcategory contributes nothing. Matching always uses
# English labels (the language the survey services are stored in) so the keys are
# stable regardless of the UI language.
established_subcat_keys <- function(orgservices) {
  en <- get_lang("en")
  sub_label <- function(key) en$organizations[[key]] %||% en$wheel[[key]] %||% key

  out <- character(0)
  for (key in names(DIMENSION_LABEL_KEYS)) {
    dim <- orgservices[[key]]
    if (is.null(dim) || !identical(dim$state, "established")) next
    services <- tolower(trimws(vapply(dim$services %||% list(), as.character, character(1))))
    services <- services[nzchar(services)]
    if (!length(services)) next

    curated_keys <- DIMENSION_SUB_KEYS[[key]]
    curated_labels <- tolower(trimws(vapply(curated_keys, sub_label, character(1))))
    for (service in services) {
      matched <- vapply(curated_labels, service_matches_label, logical(1), service = service)
      if (any(matched)) {
        out <- c(out, curated_keys[matched])
      }
    }
  }
  unique(out)
}

# Split a multi-select cell into clean service labels. "Other (please specify):"
# is replaced by the verbatim free text; "None" is dropped.
parse_services <- function(raw, other_text, dim_key) {
  raw <- trimws(as.character(raw %||% ""))
  if (!nzchar(raw) || identical(raw, "None")) {
    return(character(0))
  }

  extracted <- character(0)
  for (opt in DIMENSION_COMMA_OPTIONS[[dim_key]]) {
    pat <- paste0(escape_regex(opt), "\\.?")
    if (grepl(pat, raw)) {
      extracted <- c(extracted, opt)
      raw <- sub(pat, "", raw)
    }
  }
  raw <- gsub(",\\s*,", ",", raw)
  raw <- trimws(gsub("^,|,$", "", trimws(raw)))

  parts <- trimws(strsplit(raw, ",")[[1]])
  parts <- parts[nzchar(parts) & parts != "None"]

  is_other <- grepl("^Other \\(please specify\\)", parts)
  parts <- parts[!is_other]
  other_text <- trimws(as.character(other_text %||% ""))
  if (any(is_other) && nzchar(other_text) && !identical(other_text, "NA")) {
    parts <- c(parts, other_text)
  }
  unname(c(extracted, parts))
}

# Per-org nested object for the 8 dimensions, serialized into the orgservices_json
# column. Per dimension:
#   state          <- from the survey's <Dim>EorE / <Dim>Gap:
#                        EorE "Established"     -> "established"
#                        EorE "Emerging"        -> "emerging"
#                        else Gap starts "Yes"  -> "wants"
#                        else Gap starts "No"   -> "not_interested"
#                        else                   -> "none"
#   services       <- the <Dim> multi-select, "Other" swapped for its free text
#   barriers       <- empty []; filled from interview data (join on irb_participant_id)
#   resource_needs <- empty []; filled from interview data
build_orgservices_json <- function(row) {
  out <- list()
  for (d in SURVEY_DIMENSIONS) {
    eore <- trimws(as.character(row[[d$eore_col]] %||% ""))
    gap <- trimws(as.character(row[[d$gap_col]] %||% ""))

    state <- if (identical(eore, "Established")) {
      "established"
    } else if (identical(eore, "Emerging")) {
      "emerging"
    } else if (grepl("^Yes", gap)) {
      "wants"
    } else if (grepl("^No", gap)) {
      "not_interested"
    } else {
      "none"
    }

    services <- parse_services(row[[d$services_col]] %||% "", row[[d$text_col]] %||% "", d$key)
    out[[d$key]] <- list(
      state = state,
      services = as.list(services),
      barriers = list(),
      resource_needs = list()
    )
  }
  as.character(jsonlite::toJSON(out, auto_unbox = TRUE, null = "null"))
}

# Parse the orgservices_json column into a nested list.
parse_orgservices_json <- function(json_str) {
  json_str <- as.character(json_str %||% "")
  if (length(json_str) != 1 || !nzchar(json_str)) {
    return(list())
  }
  assert_packages_installed("jsonlite")
  tryCatch(jsonlite::fromJSON(json_str, simplifyVector = FALSE), error = function(e) list())
}

# Dimension label list for a given state, used to populate data-active-categories.
get_dimension_categories <- function(orgservices, lang, state_value) {
  organizations <- lang$organizations
  out <- character(0)
  for (key in names(DIMENSION_LABEL_KEYS)) {
    dim <- orgservices[[key]]
    if (!is.null(dim) && identical(dim$state, state_value)) {
      label <- organizations[[DIMENSION_LABEL_KEYS[[key]]]]
      if (!is.null(label) && nzchar(label)) {
        out <- c(out, label)
      }
    }
  }
  out
}

# Emerging dimension labels for the wheel: a dimension counts as emerging only
# when the survey marked its state "emerging". Looped once over
# DIMENSION_LABEL_KEYS so the order matches the rest of the wheel and labels stay
# de-duplicated.
get_emerging_dimension_categories <- function(orgservices, lang) {
  get_dimension_categories(orgservices, lang, "emerging")
}
