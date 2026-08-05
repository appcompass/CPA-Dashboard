# Verifies the 14 new interview-derived sub-key labels do not accidentally
# capture real survey service strings via service_matches_label(), which is
# prefix-tolerant and matches word-by-word.
#
# This could not be checked offline: survey_data.csv is encrypted, so the actual
# stored service strings were unavailable. Run this once with CPA_DATA_KEY set.
#
#   Sys.setenv(CPA_DATA_KEY = "...")
#   source("check_label_collisions.R")
#
# Expected output: "0 new-key assignments" for every organization. Any non-zero
# result means a survey service string is now matching one of the new labels,
# which would silently tag an organization with a service it does not offer.

setwd(rprojroot::find_rstudio_root_file())
source("R/data.R")
source("R/lang.R")

NEW_KEYS <- c(
  "wellness_physical_meals", "wellness_physical_movement",
  "wellness_emotional_check_ins", "wellness_emotional_trauma_informed",
  "wellness_emotional_clinical_referral",
  "wellness_intellectual_creative_arts", "wellness_intellectual_social_justice",
  "wellness_occupational_stipend", "wellness_occupational_mock_interviews",
  "wellness_financial_emergency_fund", "wellness_financial_stipend_empowerment",
  "wellness_social_youth_council", "wellness_social_peer_mentoring",
  "wellness_spiritual_mindfulness_embedded"
)

survey <- load_survey_data()
en <- get_lang("en")
sub_label <- function(k) en$organizations[[k]] %||% en$wheel[[k]] %||% k

total <- 0L
for (i in seq_len(nrow(survey))) {
  row <- survey[i, ]
  svc <- parse_orgservices_json(row$orgservices_json)
  hit <- intersect(established_subcat_keys(svc), NEW_KEYS)
  if (length(hit)) {
    total <- total + length(hit)
    cat(sprintf(
      "  %-10s matched %s\n",
      row$irb_participant_id,
      paste(sprintf("%s (%s)", hit, vapply(hit, sub_label, character(1))), collapse = ", ")
    ))
  }
}

cat(sprintf(
  "\n%d new-key assignments from survey text across %d organizations.\n",
  total, nrow(survey)
))
cat(if (total == 0L) {
  "PASS: no survey service string collides with a new label.\n"
} else {
  paste0(
    "REVIEW: the matches above came from survey text, not from interview\n",
    "coding. Interview-derived keys should reach an organization only via\n",
    "other_services. Rename the colliding label, or confirm the match is real.\n"
  )
})
