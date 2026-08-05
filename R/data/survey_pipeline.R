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

# Read a raw Qualtrics export: row 1 = variable names, rows 2..header_rows =
# question text + ImportId metadata, data starts after. Returns a data frame
# with the original (exact) Qualtrics column names preserved.
read_qualtrics_export <- function(path, header_rows = 3L) {
  if (!file.exists(path)) {
    stop(sprintf("Expected survey export at '%s'.", path), call. = FALSE)
  }
  raw <- read.csv(
    path,
    header = FALSE, stringsAsFactors = FALSE,
    check.names = FALSE, colClasses = "character", na.strings = character(0)
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

# Raw export -> clean, named per-organization data frame (one row per org): the
# demographic / identity half of the dashboard schema.
#
# FINAL dashboard variable names (all survey-sourced); the arrow is the raw
# Qualtrics source column. Each demographic is a cleaned percentage range
# (clean_pct); years are wording-stripped (clean_lengthserve).
#   orgname          <- Organization
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

  clean <- data.frame(
    dashboard_id = trimws(get_col("Dashboard ID")),
    irb_participant_id = trimws(get_col("IRB Participant ID")),
    orgname = trimws(get_col("Organization")),
    website = trimws(get_col("Website Url")),
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
