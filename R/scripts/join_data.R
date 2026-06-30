#!/usr/bin/env Rscript
#
# join_data.R
#
# Joins interview_data.json.enc (barriers, resource_needs, emerging, and
# other_services per dimension) into the clean survey data and exports
# master_data.xlsx.
#
# The survey data is loaded via load_survey_data() from data.R, which produces
# a clean named-column data frame with an orgservices_json column per org.
# The interview data is decrypted at runtime using the same CPA_DATA_KEY.
# Both sources are joined on irb_participant_id (preferred) with orgname as
# fallback, as documented in the Data Pipeline Guide (Section 7).
#
# Column naming convention in output follows wellness_[dimension]_[subcategory]
# to match DIMENSION_SUB_KEYS in the R codebase. Output columns per dimension:
#   [dim]_state          — established / emerging / wants / not_interested / none
#   [dim]_services       — pipe-separated services from survey orgservices_json
#   [dim]_barriers       — pipe-separated barriers from interview data
#   [dim]_resource_needs — pipe-separated resource needs from interview data
#   [dim]_emerging       — pipe-separated emerging initiatives from interview data
#   [dim]_other_services — pipe-separated approved new sub-keys from interview data
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

# Key interview data by irb_participant_id (preferred join key per Data Pipeline
# Guide Section 7), falling back to orgname if irb_participant_id is missing.
interview_lookup_id   <- list()
interview_lookup_name <- list()
for (i in interviews) {
  pid  <- trimws(as.character(i$irb_participant_id %||% ""))
  name <- trimws(as.character(i$orgname %||% ""))
  if (nzchar(pid))  interview_lookup_id[[pid]]   <- i$dimensions
  if (nzchar(name)) interview_lookup_name[[name]] <- i$dimensions
}
message(sprintf("  %d organisations in interview data", length(interview_lookup_id)))

# ── 3. Build master data frame ────────────────────────────────────────────────
message("Building master data frame...")

rows <- lapply(seq_len(nrow(survey)), function(i) {
  org_row <- survey[i, , drop = FALSE]
  orgname <- trimws(as.character(org_row[["orgname"]] %||% ""))
  pid     <- trimws(as.character(org_row[["irb_participant_id"]] %||% ""))

  # Parse orgservices_json — contains state and services per dimension from survey
  svc_json <- as.character(org_row[["orgservices_json"]] %||% "")
  orgservices <- tryCatch(
    jsonlite::fromJSON(svc_json, simplifyVector = FALSE),
    error = function(e) list()
  )

  # Look up interview dimensions — prefer irb_participant_id, fall back to orgname
  interview_dims <- if (nzchar(pid) && !is.null(interview_lookup_id[[pid]])) {
    interview_lookup_id[[pid]]
  } else {
    interview_lookup_name[[orgname]]
  }

  out <- data.frame(
    orgname              = orgname,
    irb_participant_id   = pid,
    lengthserve          = trimws(as.character(org_row[["lengthserve"]] %||% "")),
    stringsAsFactors     = FALSE
  )

  for (dim in DIMS) {
    svc  <- orgservices[[dim]]
    intv <- if (!is.null(interview_dims)) interview_dims[[dim]] else NULL

    # State and services come from quantitative survey (orgservices_json)
    out[[paste0(dim, "_state")]]    <- as.character(svc$state %||% "none")
    out[[paste0(dim, "_services")]] <- paste(unlist(svc$services %||% list()), collapse = " | ")

    # Barriers, resource_needs, emerging, and other_services from interview data
    out[[paste0(dim, "_barriers")]]       <- paste(unlist(intv$barriers       %||% list()), collapse = " | ")
    out[[paste0(dim, "_resource_needs")]] <- paste(unlist(intv$resource_needs %||% list()), collapse = " | ")
    out[[paste0(dim, "_emerging")]]       <- paste(unlist(intv$emerging       %||% list()), collapse = " | ")
    out[[paste0(dim, "_other_services")]] <- paste(unlist(intv$other_services %||% list()), collapse = " | ")
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
