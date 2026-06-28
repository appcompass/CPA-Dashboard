#!/usr/bin/env Rscript
#
# join_data.R
#
# Joins interview_data.json.enc (barriers, resource_needs, emerging per dimension)
# into the clean survey data and exports master_data.xlsx.
#
# The survey data is loaded via load_survey_data() from data.R, which produces
# a clean named-column data frame with an orgservices_json column per org.
# The interview data is decrypted at runtime using the same CPA_DATA_KEY.
# Both sources are joined on irb_participant_id (the survey carries it and the
# dashboard joins on it too). orgname is NOT used as the key: it is free text
# entered separately on each side and a one-character difference silently drops
# an org. See DECISIONS.
#
# Output layout: orgname, irb_participant_id, lengthserve, then five fields per
# wellness dimension as <dimension>_<field>, where <field> is one of state,
# services (from the survey's orgservices_json) and barriers, resource_needs,
# emerging (from the interview data). Dimensions are DIMS below. NB this is the
# xlsx column layout only; it is NOT the survey service-subcategory taxonomy
# (DIMENSION_SUB_KEYS) and does not use the wellness_<dim>_<sub> keys.
#
# Usage:
#   export CPA_DATA_KEY=your-key-here
#   Rscript R/scripts/join_data.R
#
# Output: data/master_data.xlsx

suppressWarnings(suppressMessages({
  source(file.path("R", "data.R"), local = FALSE)
}))

if (!nzchar(Sys.getenv("CPA_DATA_KEY"))) {
  stop("CPA_DATA_KEY is not set. Run: export CPA_DATA_KEY=your-key", call. = FALSE)
}
if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Run: install.packages('jsonlite')")
if (!requireNamespace("writexl",  quietly = TRUE)) stop("Run: install.packages('writexl')")

# 8 wellness dimensions — must match keys in orgservices_json and interview data
DIMS <- c("physical", "emotional", "social", "intellectual",
          "environmental", "occupational", "financial", "spiritual")

# ── 1. Load survey data ───────────────────────────────────────────────────────
message("Loading survey data...")
survey <- load_survey_data()
message(sprintf("  %d organisations loaded", nrow(survey)))

# ── 2. Load and decrypt interview data ───────────────────────────────────────
# Decrypt and load interview data from encrypted file.
# Encryption uses the same CPA_DATA_KEY environment variable as the survey data.
# The unencrypted interview_data.json is listed in .gitignore and must never be committed.
interview_enc_path <- file.path("data", "interview_data.json.enc")
if (!file.exists(interview_enc_path)) {
  stop(sprintf("Expected encrypted interview data at '%s'.", interview_enc_path), call. = FALSE)
}

message("Loading interview data...")
interview_plain_path <- decrypt_data_file(
  encrypted_path = interview_enc_path,
  output_path = tempfile(fileext = ".json")
)
raw_interviews <- jsonlite::fromJSON(interview_plain_path, simplifyVector = FALSE)
interviews <- raw_interviews$interviews

# Key interview data by irb_participant_id for the join. This is the controlled
# study code (YSP01, ...) that both the survey and the dashboard key on, so the
# match is exact. orgname is kept only as a human-readable label in the output.
survey_irb_ids <- trimws(as.character(survey[["irb_participant_id"]]))
interview_lookup <- list()
unmatched <- character(0)
for (i in interviews) {
  irb   <- trimws(as.character(i$irb_participant_id %||% ""))
  name  <- trimws(as.character(i$orgname %||% ""))
  label <- if (nzchar(name)) name else "<unnamed>"

  if (!nzchar(irb)) {
    # No key at all: this record cannot be joined under any scheme.
    unmatched <- c(unmatched, sprintf("%s (no irb_participant_id)", label))
    next
  }
  if (!(irb %in% survey_irb_ids)) {
    # Has a key, but no survey row carries it.
    unmatched <- c(unmatched, sprintf("%s (irb %s, no matching survey org)", label, irb))
  }
  interview_lookup[[irb]] <- i$dimensions
}
message(sprintf("  %d interview record(s) keyed by irb_participant_id", length(interview_lookup)))

# Loud on drops. Any interview record that cannot reach a survey row (blank irb,
# or an irb no survey row carries) is reported here instead of vanishing into an
# empty column that looks identical to "nothing coded".
if (length(unmatched) > 0) {
  warning(
    sprintf(
      "%d interview record(s) will NOT appear in master_data.xlsx:\n    %s",
      length(unmatched),
      paste(unmatched, collapse = "\n    ")
    ),
    call. = FALSE
  )
}

# ── 3. Build master data frame ────────────────────────────────────────────────
message("Building master data frame...")

rows <- lapply(seq_len(nrow(survey)), function(i) {
  org_row <- survey[i, , drop = FALSE]
  orgname <- trimws(as.character(org_row[["orgname"]] %||% ""))
  irb_id  <- trimws(as.character(org_row[["irb_participant_id"]] %||% ""))

  # Parse orgservices_json column — contains state and services per dimension
  svc_json <- as.character(org_row[["orgservices_json"]] %||% "")
  orgservices <- tryCatch(
    jsonlite::fromJSON(svc_json, simplifyVector = FALSE),
    error = function(e) list()
  )

  # Interview dimensions for this org, keyed by irb_participant_id.
  # NULL when the org has no interview, or carries no irb to match on.
  interview_dims <- if (nzchar(irb_id)) interview_lookup[[irb_id]] else NULL

  out <- data.frame(
    orgname            = orgname,
    irb_participant_id = irb_id,
    lengthserve        = trimws(as.character(org_row[["lengthserve"]] %||% "")),
    stringsAsFactors = FALSE
  )

  for (dim in DIMS) {
    svc  <- orgservices[[dim]]
    intv <- if (!is.null(interview_dims)) interview_dims[[dim]] else NULL

    # State and services come from quantitative survey (orgservices_json)
    out[[paste0(dim, "_state")]]    <- as.character(svc$state %||% "none")
    out[[paste0(dim, "_services")]] <- paste(unlist(svc$services %||% list()), collapse = " | ")

    # Barriers, resource_needs, and emerging come from qualitative interview data
    out[[paste0(dim, "_barriers")]]       <- paste(unlist(intv$barriers       %||% list()), collapse = " | ")
    out[[paste0(dim, "_resource_needs")]] <- paste(unlist(intv$resource_needs %||% list()), collapse = " | ")
    out[[paste0(dim, "_emerging")]]       <- paste(unlist(intv$emerging       %||% list()), collapse = " | ")
  }
  out
})

master <- do.call(rbind, rows)
master <- master[nzchar(master$orgname), ]
message(sprintf("  %d organisations | %d columns", nrow(master), ncol(master)))

# ── 4. Write Excel ────────────────────────────────────────────────────────────
out_path <- file.path("data", "master_data.xlsx")
writexl::write_xlsx(master, out_path)
message(sprintf("Done -> %s", out_path))
