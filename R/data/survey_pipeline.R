# ---------------------------------------------------------------------------
# Survey data transform + access (name-based).
#
# The dashboard reads a CLEAN, NAMED schema produced from the raw Qualtrics
# export. The accessors below read by column NAME (never by position), so
# inserting columns into the survey no longer breaks them.
#
# This file produces the organization/demographic fields and the per-dimension
# wellness data (the established/emerging/wants state that drives the wheels, plus
# the services per dimension), serialized into the orgservices_json column. The
# barriers/resource_needs slots are left empty here and populated from the
# interview-coded data, joined on irb_participant_id.
# ---------------------------------------------------------------------------

# Qualtrics exports are not reliably UTF-8. One saved through Excel or exported on
# a Windows machine arrives as Windows-1252, where an em dash, curly apostrophe, or
# curly quote is a single byte (0x97, 0x92, 0x93/0x94) that is invalid UTF-8.
# read.csv() with no encoding argument treats the bytes as the native encoding and
# lets invalid sequences through without complaint, so the damage stays hidden
# until it reaches a rendered page. Detect instead, and be explicit.
#
# This only started mattering when `about` joined the clean schema: every other
# extracted column in the 2026-08-04 export was pure ASCII, so nothing exercised
# the gap before.
detect_export_encoding <- function(path) {
  size <- file.size(path)
  if (is.na(size) || size == 0) {
    return("UTF-8")
  }
  bytes <- readBin(path, what = "raw", n = size)
  # rawToChar rejects embedded NULs; drop them before testing validity.
  bytes <- bytes[bytes != as.raw(0)]
  if (!length(bytes)) {
    return("UTF-8")
  }
  if (!validUTF8(rawToChar(bytes))) {
    return("Windows-1252")
  }
  if (length(bytes) >= 3 &&
        identical(as.integer(bytes[1:3]), c(0xEFL, 0xBBL, 0xBFL))) {
    "UTF-8-BOM"
  } else {
    "UTF-8"
  }
}

# Read a raw Qualtrics export: row 1 = variable names, rows 2..header_rows =
# question text + ImportId metadata, data starts after. Returns a data frame
# with the original (exact) Qualtrics column names preserved.
#
# `file_encoding` defaults lazily, so detection runs only after the existence
# check below; pass it explicitly to override.
read_qualtrics_export <- function(path, header_rows = 3L,
                                  file_encoding = detect_export_encoding(path)) {
  if (!file.exists(path)) {
    stop(sprintf("Expected survey export at '%s'.", path), call. = FALSE)
  }
  raw <- read.csv(
    path,
    header = FALSE, stringsAsFactors = FALSE,
    check.names = FALSE, colClasses = "character", na.strings = character(0),
    fileEncoding = file_encoding
  )
  if (nrow(raw) <= header_rows) {
    stop("Survey export has header rows but no data rows.", call. = FALSE)
  }
  col_names <- as.character(unlist(raw[1, ], use.names = FALSE))
  data <- raw[-seq_len(header_rows), , drop = FALSE]
  colnames(data) <- col_names
  rownames(data) <- NULL
  data
}

# ---------------------------------------------------------------------------
# Publication consent.
#
# The survey asks each organization whether it may appear on the public
# dashboard. Consent is strictly opt-in: only an explicit "Yes" publishes. "No",
# a skipped answer, and any organization whose row predates the question are all
# withheld, because a missing answer is an absence of consent rather than
# permission to publish.
#
# The answer rides through the clean schema as `display_on_website` instead of
# being applied here. merge_survey_data() is cumulative and never drops an
# organization, so filtering at ingest would leave last week's consenting row
# sitting in the encrypted dataset -- still on display -- after the organization
# revoked. Applying it on the READ side (org_is_displayable(), survey_store.R)
# makes a Yes -> No -> Yes flip nothing more than three values of one column.
# ---------------------------------------------------------------------------

# Raw Qualtrics header for the consent question. Qualtrics names the column after
# the variable name set in the survey editor, so the exact string is a property
# of the instrument and cannot be derived from anything in this repo. These
# candidates are tried in order; CONFIRM the real name against the export header
# and move it to the front.
SURVEY_DISPLAY_COL_CANDIDATES <- c(
  "DisplayOnWebsite",
  "DisplayOrg",
  "Display on Website",
  "Yes/No (display organization on website)"
)

# Locate the consent column in a raw export. Falls back to any header that
# normalizes to something containing both "display" and "website", so a variable
# renamed in Qualtrics still lands instead of silently withholding every
# organization. Returns NA_character_ when the export carries no such column.
resolve_display_column <- function(raw_names) {
  raw_names <- as.character(raw_names)
  raw_names <- raw_names[!is.na(raw_names)]
  if (!length(raw_names)) {
    return(NA_character_)
  }
  for (candidate in SURVEY_DISPLAY_COL_CANDIDATES) {
    if (candidate %in% raw_names) {
      return(candidate)
    }
  }
  normalized <- tolower(gsub("[^A-Za-z0-9]", "", raw_names))
  hit <- which(
    grepl("display", normalized, fixed = TRUE) &
      grepl("website", normalized, fixed = TRUE)
  )
  if (length(hit)) raw_names[[hit[[1]]]] else NA_character_
}

# Normalize one consent answer to the stored vocabulary: "Yes", "No", or "" when
# the question was skipped or the answer is unrecognized. Prefix matching mirrors
# how build_orgservices_json() reads the <Dim>Gap columns, so a Qualtrics option
# worded "Yes, display our organization" still reads as consent.
clean_display_flag <- function(value) {
  value <- trimws(as.character(value %||% ""))
  if (!nzchar(value) || identical(toupper(value), "NA")) {
    return("")
  }
  if (grepl("^yes", value, ignore.case = TRUE)) {
    return("Yes")
  }
  if (grepl("^no", value, ignore.case = TRUE)) {
    return("No")
  }
  ""
}

# Raw export -> clean, named per-organization data frame (one row per org): the
# demographic / identity half of the dashboard schema.
#
# FINAL dashboard variable names (all survey-sourced); the arrow is the raw
# Qualtrics source column. Each demographic is a cleaned percentage range
# (clean_pct); years are wording-stripped (clean_lengthserve).
#   orgname          <- Organization
#   about            <- About Org (free-text organization blurb; may be empty,
#                      and may contain paragraph breaks)
#   display_on_website <- the publication-consent question (resolve_display_column);
#                      "Yes" / "No" / "" -- only "Yes" is ever published
#   lengthserve      <- YearsServed
#   pct_age_12_17    <- Age#1_1       (stakeholder spec writes this id hyphenated: pct_age_12-17)
#   pct_age_18_25    <- Age#1_2       (spec: pct_age_18-25)
#   pct_age_over26   <- Age#1_3
#   pct_women        <- Gender#1_1
#   pct_men          <- Gender#1_2
#   pct_gender       <- Gender#1_3    (another gender identity)
#   pct_disabilities <- OtherDem#1_1
#   pct_spiritual    <- OtherDem#1_2  (religious or spiritual practice)
#   pct_race_eth     <- OtherDem#1_3  (people of color)
#   pct_us_born      <- OtherDem#1_4
#   pct_queer        <- OtherDem#1_5  (LGBTQIA+)
# dashboard_id, irb_participant_id are keys (merge upsert / interview join), kept
# though they are not display variables. emp_pct_* mirror the Qualtrics #2 columns
# for employees and are youth-spec-out. orgservices_json (the wheel half) is
# appended after this by build_orgservices_json().
build_clean_survey <- function(raw) {
  get_col <- function(col) {
    if (col %in% names(raw)) as.character(raw[[col]]) else rep(NA_character_, nrow(raw))
  }
  pct <- function(col) unname(vapply(get_col(col), clean_pct, character(1)))

  # An absent (or renamed-past-recognition) column makes every value normalize to
  # "", so nothing is published. That is the intended strict-opt-in failure mode:
  # loud and empty rather than quietly publishing without consent.
  display_col <- resolve_display_column(names(raw))
  display_raw <- if (is.na(display_col)) rep(NA_character_, nrow(raw)) else get_col(display_col)

  clean <- data.frame(
    dashboard_id = trimws(get_col("Dashboard ID")),
    irb_participant_id = trimws(get_col("IRB Participant ID")),
    orgname = trimws(get_col("Organization")),
    website = trimws(get_col("Website Url")),
    about = trimws(get_col("About Org")),
    display_on_website = unname(vapply(display_raw, clean_display_flag, character(1))),
    lengthserve = unname(vapply(get_col("YearsServed"), clean_lengthserve, character(1))),

    # Youth served (rendered today).
    pct_age_12_17 = pct("Age#1_1"),
    pct_age_18_25 = pct("Age#1_2"),
    pct_age_over26 = pct("Age#1_3"),
    pct_women = pct("Gender#1_1"),
    pct_men = pct("Gender#1_2"),
    pct_gender = pct("Gender#1_3"),
    pct_disabilities = pct("OtherDem#1_1"),
    pct_spiritual = pct("OtherDem#1_2"),
    pct_race_eth = pct("OtherDem#1_3"),
    pct_us_born = pct("OtherDem#1_4"),
    pct_queer = pct("OtherDem#1_5"),

    # Employees (carried in parallel; not yet rendered. Drop this block for youth-only).
    emp_pct_age_12_17 = pct("Age#2_1"),
    emp_pct_age_18_25 = pct("Age#2_2"),
    emp_pct_age_over26 = pct("Age#2_3"),
    emp_pct_women = pct("Gender#2_1"),
    emp_pct_men = pct("Gender#2_2"),
    emp_pct_gender = pct("Gender#2_3"),
    emp_pct_disabilities = pct("OtherDem#2_1"),
    emp_pct_spiritual = pct("OtherDem#2_2"),
    emp_pct_race_eth = pct("OtherDem#2_3"),
    emp_pct_us_born = pct("OtherDem#2_4"),
    emp_pct_queer = pct("OtherDem#2_5"),
    stringsAsFactors = FALSE
  )

  clean$orgservices_json <- vapply(
    seq_len(nrow(raw)),
    function(i) build_orgservices_json(raw[i, , drop = FALSE]),
    character(1)
  )

  keep <- nzchar(clean$orgname) | nzchar(clean$dashboard_id)
  clean[keep, , drop = FALSE]
}

# Convenience: raw export path -> clean data frame.
transform_survey_export <- function(path) {
  build_clean_survey(read_qualtrics_export(path))
}

# Cumulative model: merge newly transformed rows into the existing accumulated
# dataset. New rows are appended; if an organization already exists (matched on
# dashboard_id, falling back to orgname) the most recent submission wins.
# Organizations are never removed once added.
merge_survey_data <- function(existing, new_rows) {
  if (is.null(existing) || !nrow(existing)) {
    return(new_rows)
  }
  if (is.null(new_rows) || !nrow(new_rows)) {
    return(existing)
  }

  all_cols <- union(names(existing), names(new_rows))
  for (col in setdiff(all_cols, names(existing))) existing[[col]] <- NA_character_
  for (col in setdiff(all_cols, names(new_rows))) new_rows[[col]] <- NA_character_
  existing <- existing[, all_cols, drop = FALSE]
  new_rows <- new_rows[, all_cols, drop = FALSE]

  combined <- rbind(existing, new_rows) # new rows last so they win on dedup

  did <- if ("dashboard_id" %in% names(combined)) trimws(as.character(combined$dashboard_id)) else rep("", nrow(combined))
  did[is.na(did)] <- ""
  onm <- if ("orgname" %in% names(combined)) trimws(as.character(combined$orgname)) else rep("", nrow(combined))
  onm[is.na(onm)] <- ""
  key <- ifelse(nzchar(did), did, onm)

  keep <- !duplicated(key, fromLast = TRUE)
  combined[keep, , drop = FALSE]
}

# Full pipeline step: raw export path -> merge into the running dataset (unless
# append = FALSE) -> encrypt to the path the app reads. Encrypt with the
# deployment's CPA_DATA_KEY or the live app cannot decrypt it.
build_encrypted_survey <- function(
  input_csv,
  output_enc = file.path("data", "survey_data.csv.enc"),
  passphrase = Sys.getenv("CPA_DATA_KEY"),
  key_env_var = "CPA_DATA_KEY",
  append = TRUE
) {
  if (missing(passphrase)) {
    passphrase <- Sys.getenv(key_env_var)
  }
  if (!nzchar(passphrase)) {
    stop(sprintf("Missing encryption key. Set %s.", key_env_var), call. = FALSE)
  }

  new_rows <- transform_survey_export(input_csv)
  combined <- new_rows

  if (isTRUE(append) && file.exists(output_enc)) {
    existing <- tryCatch(
      load_survey_data(encrypted_path = output_enc, passphrase = passphrase),
      error = function(e) NULL
    )
    if (!is.null(existing)) {
      combined <- merge_survey_data(existing, new_rows)
    }
  }

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  write.csv(combined, tmp, row.names = FALSE, na = "")
  encrypt_data_file(input_path = tmp, output_path = output_enc, passphrase = passphrase)
  invisible(output_enc)
}
