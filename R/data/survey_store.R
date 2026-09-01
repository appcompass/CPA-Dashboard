# ---------------------------------------------------------------------------
# Reading the encrypted survey artifact and looking up organizations in it.
# All accessors read by column NAME (never by position).
# ---------------------------------------------------------------------------

# Read the clean CSV (single header row, named columns).
#
# encoding = "UTF-8" is load-bearing. build_encrypted_survey() writes the
# artifact as UTF-8, but read.csv() with no encoding argument assumes the R
# process's NATIVE encoding and leaves the strings marked "unknown". That is
# harmless on a UTF-8 workstation and silently wrong wherever the deployed
# process runs under a C/POSIX locale: the curly quotes and em dashes in `about`
# become bytes R cannot interpret, and the first conversion on the way to the
# page renders each one as a literal <e2><80><99> escape.
#
# `encoding` MARKS the strings as UTF-8 without re-encoding them. `fileEncoding`
# would be wrong here -- it converts to native, which under a C locale is exactly
# where the characters get lost. Every other text source in the app arrives via
# jsonlite::fromJSON, which marks UTF-8 already; this CSV was the only read path
# that did not, which is why the translations rendered fine and `about` did not.
read_clean_survey <- function(path) {
  read.csv(
    path,
    header = TRUE, stringsAsFactors = FALSE,
    check.names = FALSE, colClasses = "character", na.strings = character(0),
    encoding = "UTF-8"
  )
}

# Decrypt the survey artifact and return the clean data frame.
load_survey_data <- function(
  encrypted_path = file.path("data", "survey_data.csv.enc"),
  passphrase = Sys.getenv("CPA_DATA_KEY"),
  key_env_var = "CPA_DATA_KEY"
) {
  if (!file.exists(encrypted_path)) {
    stop(sprintf("Expected encrypted survey data file at '%s'.", encrypted_path), call. = FALSE)
  }
  assert_packages_installed("openssl", "digest")
  if (missing(passphrase)) {
    passphrase <- Sys.getenv(key_env_var)
  }
  if (!nzchar(passphrase)) {
    stop(
      sprintf(
        "Found encrypted data at '%s' but no decryption key was provided. Set %s.",
        encrypted_path, key_env_var
      ),
      call. = FALSE
    )
  }

  encrypted_raw <- readBin(encrypted_path, what = "raw", n = file.info(encrypted_path)$size)
  plain_raw <- decrypt_data_raw(encrypted_raw, passphrase)

  temp_path <- tempfile(fileext = ".csv")
  on.exit(unlink(temp_path), add = TRUE)
  writeBin(plain_raw, temp_path)

  read_clean_survey(temp_path)
}

# ---------------------------------------------------------------------------
# Publication consent (read side).
#
# The clean schema carries the survey's consent answer in `display_on_website`
# (written by build_clean_survey(); survey_pipeline.R explains why the filter is
# applied here rather than at ingest). Every public surface reads through
# load_displayable_survey_data(), so an organization that has not consented has
# no card on /organizations, no entry in the login picker, no dashboard_id to
# authenticate against, and no row to resolve from a hand-typed ?id= URL.
# ---------------------------------------------------------------------------

# Clean-schema column holding the consent answer.
SURVEY_DISPLAY_COL <- "display_on_website"

# Per-row publication consent as a logical vector. Strictly opt-in: a row is
# published only when the column exists AND holds an explicit "Yes". A dataset
# with no such column at all -- an artifact built before the question was added
# -- yields all FALSE, because no consent on record is not consent. Rebuild the
# artifact from an export that carries the column to restore the listings.
org_is_displayable <- function(survey_data) {
  if (is.null(survey_data) || !nrow(survey_data)) {
    return(logical(0))
  }
  if (!(SURVEY_DISPLAY_COL %in% names(survey_data))) {
    return(rep(FALSE, nrow(survey_data)))
  }
  flags <- vapply(
    as.character(survey_data[[SURVEY_DISPLAY_COL]]),
    clean_display_flag,
    character(1)
  )
  unname(flags == "Yes")
}

# The consenting subset, keeping the column structure so a fully withheld dataset
# still renders the app's empty state instead of erroring.
filter_displayable_orgs <- function(survey_data) {
  if (is.null(survey_data) || !nrow(survey_data)) {
    return(survey_data)
  }
  survey_data[org_is_displayable(survey_data), , drop = FALSE]
}

# The public view of the survey artifact: decrypt, then drop everything that has
# not consented. load_survey_data() stays the RAW reader for the transform
# pipeline and the offline scripts -- build_encrypted_survey() in particular MUST
# see withheld rows, or each merge would delete them from the dataset and a later
# "Yes" could never bring the organization back.
load_displayable_survey_data <- function(
  encrypted_path = file.path("data", "survey_data.csv.enc"),
  passphrase = Sys.getenv("CPA_DATA_KEY"),
  key_env_var = "CPA_DATA_KEY"
) {
  filter_displayable_orgs(
    load_survey_data(
      encrypted_path = encrypted_path,
      passphrase = passphrase,
      key_env_var = key_env_var
    )
  )
}

# Same clean source, consent-gated; kept as a separate name because callers
# reference it. The details page resolves an org through this, so a withheld
# organization is unreachable even by URL.
load_organization_details_data <- function(
  encrypted_path = file.path("data", "survey_data.csv.enc"),
  passphrase = Sys.getenv("CPA_DATA_KEY"),
  key_env_var = "CPA_DATA_KEY"
) {
  load_displayable_survey_data(
    encrypted_path = encrypted_path,
    passphrase = passphrase,
    key_env_var = key_env_var
  )
}

# Sorted, de-duplicated list of non-empty organization names. Defaults to the
# consent-gated view; the offline scripts pass the raw frame explicitly when they
# need every organization.
get_org_names <- function(survey_data = load_displayable_survey_data()) {
  col <- if ("orgname" %in% names(survey_data)) survey_data[["orgname"]] else survey_data[[1]]
  names <- sort(unique(trimws(col)))
  names[nzchar(names)]
}

# orgname -> dashboard_id lookup, used by the login form to validate the entered
# Organization ID against the Dashboard ID stored for the selected organization.
get_org_dashboard_ids <- function(survey_data = load_displayable_survey_data()) {
  empty <- stats::setNames(character(0), character(0))
  if (is.null(survey_data) || !nrow(survey_data)) {
    return(empty)
  }
  org_col <- if ("orgname" %in% names(survey_data)) survey_data[["orgname"]] else survey_data[[1]]
  orgname <- trimws(as.character(org_col))
  dashboard_id <- if ("dashboard_id" %in% names(survey_data)) {
    trimws(as.character(survey_data[["dashboard_id"]]))
  } else {
    rep("", length(orgname))
  }
  dashboard_id[is.na(dashboard_id)] <- ""
  keep <- nzchar(orgname)
  stats::setNames(dashboard_id[keep], orgname[keep])
}

# Read a named scalar from a single-row data frame, with a fallback.
get_named_value <- function(row, col, fallback = "N/A") {
  if (is.null(row) || !nrow(row) || !(col %in% names(row))) {
    return(fallback)
  }
  value <- trimws(as.character(row[[col]][[1]]))
  if (!nzchar(value) || identical(value, "NA")) fallback else value
}

# Return a survey-provided website only when it is a navigable http(s) URL,
# else "". Guards against blanks, the "N/A" placeholder some orgs give, and any
# non-http scheme (e.g. javascript:) that should never become a live link.
sanitize_org_website <- function(url) {
  url <- trimws(as.character(url %||% ""))
  if (!nzchar(url) || toupper(url) %in% c("NA", "N/A")) {
    return("")
  }
  if (grepl("^https?://", url, ignore.case = TRUE)) url else ""
}

# The single data row for `org_name`, or the first non-empty org when unmatched.
get_organization_details_row <- function(
  org_name = NULL,
  survey_data = load_organization_details_data()
) {
  name_col <- if ("orgname" %in% names(survey_data)) survey_data[["orgname"]] else survey_data[[1]]
  org_names <- trimws(as.character(name_col))

  selected_org <- NULL
  if (!is.null(org_name) && length(org_name)) {
    selected_org <- trimws(as.character(org_name[[1]]))
    if (!nzchar(selected_org)) {
      selected_org <- NULL
    }
  }

  # Org card links pass the name URL-encoded (e.g. "Big%20Brothers..."). Match
  # the id as-is first; if it doesn't match, retry against a URL-decoded form so
  # an encoded id still resolves. tryCatch keeps a malformed `%` sequence from
  # erroring. Only when neither form matches do we fall back to the first org.
  matched_index <- NA_integer_
  if (!is.null(selected_org)) {
    if (selected_org %in% org_names) {
      matched_index <- match(selected_org, org_names)
    } else {
      decoded_org <- tryCatch(utils::URLdecode(selected_org), error = function(e) NA_character_)
      if (!is.na(decoded_org) && decoded_org %in% org_names) {
        matched_index <- match(decoded_org, org_names)
      }
    }
  }

  selected_row_index <- if (!is.na(matched_index)) {
    matched_index
  } else {
    non_empty_rows <- which(nzchar(org_names))
    if (!length(non_empty_rows)) NA_integer_ else non_empty_rows[[1]]
  }

  if (is.na(selected_row_index)) {
    return(survey_data[0, , drop = FALSE])
  }

  survey_data[selected_row_index, , drop = FALSE]
}
