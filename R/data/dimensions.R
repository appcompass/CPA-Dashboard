# ---------------------------------------------------------------------------
# The 8 wellness dimensions: raw survey column names, translation label keys,
# wheel colors/icons (mirroring js/app.js WHEEL_META), and the curated service
# subcategories. Constants only; the functions that consume them live in
# orgservices.R and the UI templates.
# ---------------------------------------------------------------------------

# 8 dimensions of wellbeing: dashboard key -> raw Qualtrics column names.
# text_col is the "Other (please specify)" free-text column (occupational and
# spiritual use *_6_TEXT because they carry an extra option).
SURVEY_DIMENSIONS <- list(
  list(
    key = "physical",
    services_col = "Physical",
    text_col = "Physical_5_TEXT",
    eore_col = "PhysicalEorE",
    gap_col = "PhysicalGap"
  ),
  list(
    key = "emotional",
    services_col = "Emotional",
    text_col = "Emotional_5_TEXT",
    eore_col = "EmotionalEorE",
    gap_col = "EmotionalGap"
  ),
  list(
    key = "intellectual",
    services_col = "Intellectual",
    text_col = "Intellectual_5_TEXT",
    eore_col = "IntellectualEorE",
    gap_col = "IntellectualGap"
  ),
  list(
    key = "occupational",
    services_col = "Occupational",
    text_col = "Occupational_6_TEXT",
    eore_col = "OccupationalEorE",
    gap_col = "OccupationalGap"
  ),
  list(
    key = "financial",
    services_col = "Financial",
    text_col = "Financial_5_TEXT",
    eore_col = "FinancialEorE",
    gap_col = "FinancialGap"
  ),
  list(
    key = "social",
    services_col = "Social",
    text_col = "Social_5_TEXT",
    eore_col = "SocialEorE",
    gap_col = "SocialGap"
  ),
  list(
    key = "environmental",
    services_col = "Environmental",
    text_col = "Environmental_5_TEXT",
    eore_col = "EnvironmentalEorE",
    gap_col = "EnvironmentalGap"
  ),
  list(
    key = "spiritual",
    services_col = "Spiritual",
    text_col = "Spiritual_6_TEXT",
    eore_col = "SpiritualEorE",
    gap_col = "SpiritualGap"
  )
)

# dashboard key -> translation label key (used to build data-active-categories).
DIMENSION_LABEL_KEYS <- c(
  physical = "wellness_physical", emotional = "wellness_emotional",
  intellectual = "wellness_intellectual",
  occupational = "wellness_occupational",
  financial = "wellness_financial", social = "wellness_social",
  environmental = "wellness_environmental", spiritual = "wellness_spiritual"
)

# Wellness-dimension colors, mirroring the wellness wheel (www/js/app.js
# WHEEL_META `color`). Single source of truth on the R side so the
# server-rendered organizations filter sidebar can color each dimension to match
# the wheel without duplicating hexes per call site. Keep in sync with the JS
# WHEEL_META colors if those ever change.
DIMENSION_WHEEL_COLORS <- c(
  physical = "#066fd1", emotional = "#4299e1", intellectual = "#ae3ec9",
  occupational = "#d63939", financial = "#f59f00", social = "#2fb344",
  environmental = "#0ca678", spiritual = "#17a2b8"
)

# Tabler outline icon name per wellness dimension, mirroring the wellness wheel
# (www/js/app.js WHEEL_META `icon`). Stored as the icon-specific path data so the
# UI can build a consistent <svg> wrapper; keep the path in sync with the JS
# WHEEL_META icons if those ever change.
DIMENSION_WHEEL_ICON_PATHS <- list(
  physical = list(
    name = "heartbeat",
    paths = c(
      "M19.5 13.572l-7.5 7.428l-2.896 -2.868m-6.117 -8.104a5 5 0 0 1 9.013 -3.022a5 5 0 1 1 7.5 6.572",
      "M3 13h2l2 3l2 -6l1 3h3"
    )
  ),
  emotional = list(
    name = "user-heart",
    paths = c(
      "M8 7a4 4 0 1 0 8 0a4 4 0 0 0 -8 0",
      "M6 21v-2a4 4 0 0 1 4 -4h.5",
      "M18 22l3.35 -3.284a2.143 2.143 0 0 0 .005 -3.071a2.242 2.242 0 0 0 -3.129 -.006l-.224 .22l-.223 -.22a2.242 2.242 0 0 0 -3.128 -.006a2.143 2.143 0 0 0 -.006 3.071l3.355 3.296"
    )
  ),
  intellectual = list(
    name = "school",
    paths = c(
      "M22 9l-10 -4l-10 4l10 4l10 -4v6",
      "M6 10.6v5.4a6 3 0 0 0 12 0v-5.4"
    )
  ),
  occupational = list(
    name = "briefcase-2",
    paths = c(
      "M3 9a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v9a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-9",
      "M8 7v-2a2 2 0 0 1 2 -2h4a2 2 0 0 1 2 2v2"
    )
  ),
  financial = list(
    name = "report-money",
    paths = c(
      "M9 5h-2a2 2 0 0 0 -2 2v12a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-12a2 2 0 0 0 -2 -2h-2",
      "M9 5a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2a2 2 0 0 1 -2 2h-2a2 2 0 0 1 -2 -2",
      "M14 11h-2.5a1.5 1.5 0 0 0 0 3h1a1.5 1.5 0 0 1 0 3h-2.5",
      "M12 17v1m0 -8v1"
    )
  ),
  social = list(
    name = "friends",
    paths = c(
      "M5 5a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
      "M5 22v-5l-1 -1v-4a1 1 0 0 1 1 -1h4a1 1 0 0 1 1 1v4l-1 1v5",
      "M15 5a2 2 0 1 0 4 0a2 2 0 1 0 -4 0",
      "M15 22v-4h-2l2 -6a1 1 0 0 1 1 -1h2a1 1 0 0 1 1 1l2 6h-2v4"
    )
  ),
  environmental = list(
    name = "world-map",
    paths = c(
      "M20 8h-2a2 2 0 0 0 -2 2a2 2 0 1 1 -4 0v-1a2 2 0 0 0 -2 -2h-1a2 2 0 0 1 -2 -2v-.5",
      "M3 12h3a2 2 0 0 1 2 2v.5a1.5 1.5 0 0 0 1.5 1.5a1.5 1.5 0 0 1 1.5 1.5v3.25",
      "M15 20.5v-3.5a2 2 0 0 1 2 -2h3.5",
      "M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0"
    )
  ),
  spiritual = list(
    name = "peace",
    paths = c(
      "M3 12a9 9 0 1 0 18 0a9 9 0 1 0 -18 0",
      "M12 3l0 18",
      "M12 12l6.3 6.3",
      "M12 12l-6.3 6.3"
    )
  )
)

# Service subcategories per dimension. TWO VOCABULARIES, deliberately kept apart
# because only one of them is safe to text-match:
#
#   DIMENSION_SUB_KEYS           SURVEY vocabulary. These are the Qualtrics
#                                multi-select options, so established_subcat_keys()
#                                matches their English labels against an org's
#                                stored service strings. `physical` uses
#                                wellness_physical_* names (labels under
#                                `organizations`); the other seven still use
#                                sub_<dim>_<n> names with real labels under `wheel`.
#                                Those names are LEGACY, NOT placeholders --
#                                sub_occupational_4 is "Job training". Renaming them
#                                is a separate migration; dropping one breaks service
#                                matching for its whole dimension.
#
#   DIMENSION_INTERVIEW_SUB_KEYS INTERVIEW vocabulary. Services the survey never
#                                asked about, coded from transcripts into
#                                interview_data.json.enc under `other_services`.
#                                These are NEVER text-matched. service_matches_label()
#                                is prefix-tolerant, so free-text survey answers would
#                                capture them -- "Mindfulness" matches
#                                wellness_spiritual_mindfulness_embedded, "Daily meals
#                                for teens" matches wellness_physical_meals -- tagging
#                                an org with a service no coder ever assigned it. They
#                                reach an org only as an explicit key in
#                                other_services. Keeping the two lists apart is what
#                                makes that a structural guarantee instead of a
#                                convention (see check_label_collisions.R).
#
#   DIMENSION_ALL_SUB_KEYS       The union, survey keys first. This is the display
#                                and filter taxonomy: sub-label order in the wheel and
#                                the checkbox rows in the organizations sidebar.
#                                Mirrors js/app.js WHEEL_META `subKeys` -- kept honest
#                                by test-app-data.R, which parses app.js and compares.
DIMENSION_SUB_KEYS <- list(
  physical = c("wellness_physical_fitness", "wellness_physical_nutrition", "wellness_physical_screenings"),
  emotional = c("sub_emotional_1", "sub_emotional_2", "sub_emotional_3"),
  intellectual = c("sub_intellectual_1", "sub_intellectual_2", "sub_intellectual_3"),
  occupational = c("sub_occupational_1", "sub_occupational_2", "sub_occupational_3", "sub_occupational_4"),
  financial = c("sub_financial_1", "sub_financial_2", "sub_financial_3"),
  social = c("sub_social_1", "sub_social_2", "sub_social_3"),
  environmental = c("sub_environmental_1", "sub_environmental_2", "sub_environmental_3"),
  spiritual = c("sub_spiritual_1", "sub_spiritual_2", "sub_spiritual_3", "sub_spiritual_4")
)

DIMENSION_INTERVIEW_SUB_KEYS <- list(
  physical = c("wellness_physical_meals", "wellness_physical_movement"),
  emotional = c("wellness_emotional_check_ins", "wellness_emotional_trauma_informed", "wellness_emotional_clinical_referral"),
  intellectual = c("wellness_intellectual_creative_arts", "wellness_intellectual_social_justice"),
  occupational = c("wellness_occupational_stipend", "wellness_occupational_mock_interviews"),
  financial = c("wellness_financial_emergency_fund", "wellness_financial_stipend_empowerment"),
  social = c("wellness_social_youth_council", "wellness_social_peer_mentoring"),
  # No environmental sub-keys exist yet; the interview taxonomy has none, so this
  # dimension can only ever show its survey services.
  environmental = character(0),
  spiritual = c("wellness_spiritual_mindfulness_embedded")
)

# Display/filter taxonomy: survey subcategories first, then interview-coded ones.
# Derived so the two vocabularies above stay the only places a key is declared.
DIMENSION_ALL_SUB_KEYS <- setNames(
  lapply(names(DIMENSION_LABEL_KEYS), function(key) {
    unique(c(DIMENSION_SUB_KEYS[[key]], DIMENSION_INTERVIEW_SUB_KEYS[[key]]))
  }),
  names(DIMENSION_LABEL_KEYS)
)

# Multi-selects are comma-joined, but some option labels themselves contain commas
# (only the Intellectual one here). Those are extracted before splitting so they
# are not shattered.
DIMENSION_COMMA_OPTIONS <- list(
  intellectual = "Educational workshops, e.g., STEM classes, etc"
)
