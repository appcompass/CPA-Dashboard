# ---------------------------------------------------------------------------
# Data layer loader. R/data.R keeps its historical path (app.R, the Makefile,
# R/scripts/*, check_label_collisions.R, and the test helper all source it),
# but the implementation now lives in single-concern modules under R/data/,
# sourced here in order into the caller's environment (local = TRUE propagates
# it, exactly like R/ui.R does for templates):
#
#   utils.R                %||%, escape_regex, assert_packages_installed
#   crypto.R               "CPA2" authenticated payload format, file
#                          encrypt/decrypt, startup readiness check
#   dimensions.R           the 8 wellness dimensions: survey columns, label
#                          keys, wheel colors/icons, curated subcategories
#   demographics.R         demographic answer cleaning + display bands/meters
#   orgservices.R          the orgservices_json contract: build it from the
#                          survey, parse it back, match services to subcategories
#   survey_pipeline.R      raw Qualtrics export -> clean schema -> merge -> encrypt
#   survey_store.R         decrypt + read the survey artifact, org row lookups
#   interviews.R           interview-coded data + its de-associated translations
#   org_details_context.R  assemble everything the details page renders
#   translations.R         app translation files + frontend JSON payload
#
# Order matters only for readability: modules define functions and constants,
# and R resolves cross-module references lazily at call time.
# ---------------------------------------------------------------------------

source(file.path("R", "data", "utils.R"), local = TRUE, encoding = "UTF-8")
source(file.path("R", "data", "crypto.R"), local = TRUE, encoding = "UTF-8")
source(file.path("R", "data", "dimensions.R"), local = TRUE, encoding = "UTF-8")
source(file.path("R", "data", "demographics.R"), local = TRUE, encoding = "UTF-8")
source(file.path("R", "data", "orgservices.R"), local = TRUE, encoding = "UTF-8")
source(file.path("R", "data", "survey_pipeline.R"), local = TRUE, encoding = "UTF-8")
source(file.path("R", "data", "survey_store.R"), local = TRUE, encoding = "UTF-8")
source(file.path("R", "data", "interviews.R"), local = TRUE, encoding = "UTF-8")
source(file.path("R", "data", "org_details_context.R"), local = TRUE, encoding = "UTF-8")
source(file.path("R", "data", "translations.R"), local = TRUE, encoding = "UTF-8")
