#!/usr/bin/env Rscript
#
# merge_service_details.R
#
# Combines one JSON file per organization in data/service_details/ into the single
# data/service_details.json the app reads at runtime.
#
# Why a build step rather than having the loader read the directory: the app ships
# a manifest with an explicit file list, so one merged file is one manifest entry
# that cannot silently go missing, and the deployed artifact is a single reviewed
# file. The cost is that the merged file can drift from its sources, which is what
# the "data/service_details.json matches its per-organization sources" test in
# tests/testthat/test-app-data.R exists to catch.
#
# Each source file is named <IRB_PARTICIPANT_ID>.json and holds either
#
#   { "YSP02": { "physical": { "wellness_physical_fitness": "..." } } }
#
# or the bare dimension map, in which case the id comes from the filename:
#
#   { "physical": { "wellness_physical_fitness": "..." } }
#
#   Rscript R/scripts/merge_service_details.R
#
# Or from the R console, the usual route on Windows:
#
#   source("R/scripts/merge_service_details.R"); merge_service_details()

if (requireNamespace("rprojroot", quietly = TRUE)) {
  setwd(rprojroot::find_rstudio_root_file())
}
# Only load the app if the taxonomy is not already in scope, so the test suite can
# source this file without paying for a second full load.
if (!exists("DIMENSION_ALL_SUB_KEYS")) {
  source("R/data.R")
}

SERVICE_DETAILS_DIR <- file.path("data", "service_details")
SERVICE_DETAILS_FILE <- file.path("data", "service_details.json")
SERVICE_DETAILS_WORD_LIMIT <- 40L

# Read every per-organization source file and return irb_id -> dimension -> sub_key
# -> text, with dimensions in wheel order and organizations sorted by id so the
# merged output is deterministic.
read_service_detail_sources <- function(dir = SERVICE_DETAILS_DIR) {
  # Treat "no sources" as an error, never as "merge to empty". Silently writing a
  # blank file would delete every organization already coded.
  if (!dir.exists(dir)) {
    return(list(details = list(), problems = sprintf("%s does not exist", dir)))
  }
  paths <- sort(list.files(dir, pattern = "\\.json$", full.names = TRUE))
  if (!length(paths)) {
    return(list(details = list(), problems = sprintf("no .json files in %s", dir)))
  }
  problems <- character(0)
  out <- list()

  for (path in paths) {
    stem <- sub("\\.json$", "", basename(path))
    # Accept what a coding chat actually produces. The prompt asks for a fragment
    # -- '"YSP01": { ... }' -- which is not a JSON document, and pasted output often
    # carries markdown fences, a trailing comma, or a UTF-8 BOM. Normalise all of
    # that here rather than making a human hand-edit every file.
    text <- paste(readLines(path, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
    text <- sub("^\ufeff", "", text)
    text <- gsub("```[a-zA-Z]*", "", text, fixed = FALSE)
    text <- trimws(text)
    text <- sub(",\\s*$", "", text)
    if (!startsWith(text, "{") && !startsWith(text, "[")) {
      text <- paste0("{", text, "}")
    }
    parsed <- tryCatch(
      jsonlite::fromJSON(text, simplifyVector = FALSE),
      error = function(e) {
        problems <<- c(problems, sprintf("%s: not valid JSON (%s)", path, conditionMessage(e)))
        NULL
      }
    )
    if (is.null(parsed) || !length(parsed)) next

    nms <- names(parsed)
    if (is.null(nms) || !length(nms)) {
      problems <- c(problems, sprintf("%s: top level is not a JSON object", path))
      next
    }
    # A bare dimension map means the id lives in the filename.
    if (all(nms %in% names(DIMENSION_LABEL_KEYS))) {
      parsed <- setNames(list(parsed), stem)
    }

    for (irb in names(parsed)) {
      if (!identical(irb, stem)) {
        problems <- c(problems, sprintf(
          "%s: contains id %s but the filename says %s", path, irb, stem
        ))
      }
      if (!is.null(out[[irb]])) {
        problems <- c(problems, sprintf("%s: %s already defined in another file", path, irb))
        next
      }

      record <- parsed[[irb]]
      ordered <- list()
      for (dim_key in names(DIMENSION_LABEL_KEYS)) {
        entries <- record[[dim_key]]
        if (is.null(entries) || !length(entries)) next
        kept <- list()
        for (sub_key in names(entries)) {
          text <- trimws(as.character(entries[[sub_key]] %||% ""))
          if (!nzchar(text)) next
          if (!sub_key %in% DIMENSION_ALL_SUB_KEYS[[dim_key]]) {
            problems <- c(problems, sprintf(
              "%s: %s is not a %s sub-key", path, sub_key, dim_key
            ))
            next
          }
          words <- length(strsplit(text, "\\s+")[[1]])
          if (words > SERVICE_DETAILS_WORD_LIMIT) {
            problems <- c(problems, sprintf(
              "%s: %s is %d words, over the %d limit", path, sub_key, words,
              SERVICE_DETAILS_WORD_LIMIT
            ))
          }
          kept[[sub_key]] <- text
        }
        if (length(kept)) ordered[[dim_key]] <- kept
      }

      unknown <- setdiff(names(record), names(DIMENSION_LABEL_KEYS))
      if (length(unknown)) {
        problems <- c(problems, sprintf(
          "%s: unknown dimension(s) %s", path, paste(unknown, collapse = ", ")
        ))
      }
      if (length(ordered)) out[[irb]] <- ordered
    }
  }

  if (length(out)) {
    out <- out[order(names(out))]
  }
  list(details = out, problems = problems)
}

# Rewrite data/service_details.json from the per-organization sources, preserving
# the _readme and _example blocks that document the format.
merge_service_details <- function(dir = SERVICE_DETAILS_DIR,
                                  target = SERVICE_DETAILS_FILE,
                                  quiet = FALSE) {
  assert_packages_installed("jsonlite")
  result <- read_service_detail_sources(dir)

  if (length(result$problems)) {
    for (p in result$problems) message("  ! ", p)
    stop(
      sprintf("%d problem(s) in %s; nothing written.", length(result$problems), dir),
      call. = FALSE
    )
  }

  existing <- if (file.exists(target)) {
    jsonlite::fromJSON(target, simplifyVector = FALSE)
  } else {
    list()
  }
  out <- list()
  if (!is.null(existing[["_readme"]])) out[["_readme"]] <- existing[["_readme"]]
  if (!is.null(existing[["_example"]])) out[["_example"]] <- existing[["_example"]]
  out[["service_details"]] <- result$details

  json <- jsonlite::toJSON(out, auto_unbox = TRUE, pretty = 2)
  con <- file(target, "wb")
  on.exit(close(con), add = TRUE)
  writeLines(as.character(json), con, sep = "\r\n")

  if (!quiet) {
    n_orgs <- length(result$details)
    n_entries <- sum(vapply(
      result$details, function(r) sum(lengths(r)), integer(1)
    ))
    message(sprintf("Wrote %s: %d organization(s), %d entries.", target, n_orgs, n_entries))
    for (irb in names(result$details)) {
      message(sprintf(
        "  %-8s %2d entries across %d dimension(s)", irb,
        sum(lengths(result$details[[irb]])), length(result$details[[irb]])
      ))
    }
  }
  invisible(result$details)
}

if (sys.nframe() == 0) {
  merge_service_details()
}
