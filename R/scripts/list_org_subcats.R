#!/usr/bin/env Rscript
#
# list_org_subcats.R
#
# Prints, per organization, exactly which service subcategories its established
# wellness wheel renders today. This is the context block to paste into a
# transcript-coding chat alongside the coding prompt, so the coder writes detail
# text only for keys that can actually appear on screen.
#
# Deriving it from the live code matters: the rendered set is
# org_subcat_keys() = survey services matched to labels by established_subcat_keys()
# UNION interview-coded other_services, both gated to dimensions the survey marked
# "established". None of that is reproducible by eye from the spreadsheet, and a
# key outside the set silently renders nothing.
#
#   Rscript R/scripts/list_org_subcats.R YSP04     # one organization
#   Rscript R/scripts/list_org_subcats.R           # every organization
#
# Or from the R console, which is the usual route on Windows where Rscript may not
# be on PATH. Sourcing alone defines the functions without running anything:
#
#   source("R/scripts/list_org_subcats.R"); main("YSP04")
#
# Requires CPA_DATA_KEY (read from .env by the Makefile, or set it in the session).

if (requireNamespace("rprojroot", quietly = TRUE)) {
  setwd(rprojroot::find_rstudio_root_file())
}
source("R/data.R")
source("R/lang.R")

en <- get_lang("en")
sub_label <- function(key) en$organizations[[key]] %||% en$wheel[[key]] %||% key

# Dimension keys grouped by the survey state that drives the wheels.
states_by_value <- function(orgservices) {
  out <- list()
  for (key in names(DIMENSION_LABEL_KEYS)) {
    state <- orgservices[[key]]$state %||% "none"
    out[[state]] <- c(out[[state]], key)
  }
  out
}

print_keys <- function(keys, indent = "    ") {
  for (key in keys) {
    cat(sprintf("%s%-42s %s\n", indent, key, sub_label(key)))
  }
}

report_org <- function(org_name, survey) {
  row <- get_organization_details_row(org_name = org_name, survey_data = survey)
  irb <- get_named_value(row, "irb_participant_id", "")
  orgservices <- parse_orgservices_json(get_named_value(row, "orgservices_json", ""))
  interview_dims <- get_interview_dimensions(irb)

  rendered <- org_subcat_keys(orgservices, interview_dims)
  states <- states_by_value(orgservices)

  cat(strrep("=", 78), "\n", sep = "")
  cat("ORGANIZATION: ", org_name, "\n", sep = "")
  cat("IRB PARTICIPANT ID: ", if (nzchar(irb)) irb else "(none)", "\n", sep = "")

  cat("\nDIMENSION STATES (from the quantitative survey)\n")
  for (state in c("established", "emerging", "wants", "not_interested", "none")) {
    dims <- states[[state]]
    cat(sprintf(
      "  %-15s %s\n", state,
      if (length(dims)) paste(dims, collapse = ", ") else "(none)"
    ))
  }

  cat("\nSUB-KEYS THIS WHEEL RENDERS -- the ONLY keys detail text may use\n")
  any_rendered <- FALSE
  for (key in names(DIMENSION_LABEL_KEYS)) {
    keys <- intersect(DIMENSION_ALL_SUB_KEYS[[key]], rendered)
    if (!length(keys)) next
    any_rendered <- TRUE
    cat("  ", key, "\n", sep = "")
    print_keys(keys)
  }
  if (!any_rendered) cat("  (none -- no established dimension has a matched service)\n")

  cat("\nAVAILABLE BUT NOT CURRENTLY SHOWN -- propose these as other_services additions\n")
  any_avail <- FALSE
  for (key in names(DIMENSION_LABEL_KEYS)) {
    if (!identical(orgservices[[key]]$state, "established")) next
    keys <- setdiff(DIMENSION_ALL_SUB_KEYS[[key]], rendered)
    if (!length(keys)) next
    any_avail <- TRUE
    cat("  ", key, "\n", sep = "")
    print_keys(keys)
  }
  if (!any_avail) cat("  (none)\n")

  cat("\nALREADY CODED BUT GATED OUT -- dimension is not established, so these never render\n")
  any_gated <- FALSE
  for (key in names(DIMENSION_LABEL_KEYS)) {
    if (identical(orgservices[[key]]$state, "established")) next
    coded <- as.character(unlist(interview_dims[[key]][["other_services"]] %||% list()))
    coded <- coded[nzchar(trimws(coded))]
    if (!length(coded)) next
    any_gated <- TRUE
    cat(sprintf(
      "  %s (%s): %s\n", key,
      orgservices[[key]]$state %||% "none", paste(coded, collapse = ", ")
    ))
  }
  if (!any_gated) cat("  (none)\n")
  cat("\n")
}

main <- function(args = commandArgs(trailingOnly = TRUE)) {
  survey <- load_survey_data()
  org_names <- get_org_names(survey)

  if (length(args)) {
    wanted <- trimws(args)
    ids <- vapply(
      org_names,
      function(nm) {
        get_named_value(
          get_organization_details_row(org_name = nm, survey_data = survey),
          "irb_participant_id", ""
        )
      },
      character(1)
    )
    # Accept either an IRB participant id or an exact organization name.
    matched <- org_names[ids %in% wanted | org_names %in% wanted]
    if (!length(matched)) {
      stop(sprintf("No organization matched: %s", paste(wanted, collapse = ", ")), call. = FALSE)
    }
    org_names <- matched
  }

  for (org_name in org_names) report_org(org_name, survey)
}

if (sys.nframe() == 0) {
  main()
}
