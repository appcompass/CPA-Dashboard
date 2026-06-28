#!/usr/bin/env Rscript

# Transform a raw Qualtrics quantitative-survey export and merge it into the
# clean, encrypted artifact the dashboard reads (data/survey_data.csv.enc).
#
# Cumulative model: each run APPENDS the new file's organizations to whatever is
# already in the encrypted dataset. If an organization already exists (matched on
# dashboard_id, falling back to orgname when it is blank) the newest submission
# wins; organizations are never removed. To rebuild from scratch instead, delete
# data/survey_data.csv.enc before running.
#
# Usage:
#   Rscript R/scripts/transform_survey.R [path/to/raw_export.csv] [path/to/output.csv.enc]
#
# If no input path is given, the newest *.csv in data/incoming/ is used (so the
# weekly drop can be picked up automatically). Requires CPA_DATA_KEY to be set to
# the SAME key the deployment uses -- otherwise the live app cannot decrypt the
# result.

suppressWarnings(suppressMessages({
  source(file.path("R", "data.R"), local = FALSE)
}))

args <- commandArgs(trailingOnly = TRUE)

default_incoming_dir <- file.path("data", "incoming")
default_output <- file.path("data", "survey_data.csv.enc")

find_latest_csv <- function(dir) {
  if (!dir.exists(dir)) {
    return(NA_character_)
  }
  csvs <- list.files(dir, pattern = "\\.csv$", full.names = TRUE, ignore.case = TRUE)
  if (!length(csvs)) {
    return(NA_character_)
  }
  csvs[order(file.info(csvs)$mtime, decreasing = TRUE)][[1]]
}

input_csv <- if (length(args) >= 1 && nzchar(args[[1]])) {
  args[[1]]
} else {
  latest <- find_latest_csv(default_incoming_dir)
  if (is.na(latest)) {
    stop(
      sprintf(
        "No input CSV given and none found in '%s'. Pass the raw export path explicitly.",
        default_incoming_dir
      ),
      call. = FALSE
    )
  }
  message(sprintf("Using newest export: %s", latest))
  latest
}

output_enc <- if (length(args) >= 2 && nzchar(args[[2]])) args[[2]] else default_output

if (!nzchar(Sys.getenv("CPA_DATA_KEY"))) {
  stop(
    "CPA_DATA_KEY is not set. Export the deployment key (from Zia) before running:\n",
    "  export CPA_DATA_KEY=\"...\"",
    call. = FALSE
  )
}

# Report the append math as a sanity check.
new_rows <- transform_survey_export(input_csv)
n_existing <- 0L
if (file.exists(output_enc)) {
  existing <- tryCatch(load_survey_data(encrypted_path = output_enc), error = function(e) NULL)
  if (!is.null(existing)) n_existing <- nrow(existing)
}
message(sprintf("Existing dataset: %d organizations.", n_existing))
message(sprintf("New file: %d organizations, %d columns.", nrow(new_rows), ncol(new_rows)))

dir.create(dirname(output_enc), showWarnings = FALSE, recursive = TRUE)
build_encrypted_survey(input_csv = input_csv, output_enc = output_enc, append = TRUE)

combined <- load_survey_data(encrypted_path = output_enc)
message(sprintf("After append (dedup by dashboard_id): %d organizations.", nrow(combined)))
message(sprintf("Wrote encrypted dataset -> %s", output_enc))
message("Commit and push this .enc file. Do NOT commit the raw export or the key.")
