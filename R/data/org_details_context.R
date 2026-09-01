# ---------------------------------------------------------------------------
# Assembles everything the organization details page renders for one org:
# resolved name, translated labels, demographic percentages, established /
# emerging wellness categories, and the login-gated interview items.
# ---------------------------------------------------------------------------

# A translation label by key, with a fallback when missing/empty.
get_organization_details_label <- function(details, key, fallback) {
  value <- details[[key]]
  if (is.null(value) || !nzchar(value)) fallback else value
}

# The demographic percentage columns the details page renders, in display
# order. Values were already cleaned by the transform (clean_pct), so each is
# read by name with get_named_value's standard "N/A" fallback.
ORGANIZATION_DETAILS_DEMOGRAPHIC_COLS <- c(
  "pct_age_12_17", "pct_age_18_25", "pct_age_over26",
  "pct_women", "pct_men", "pct_gender",
  "pct_disabilities", "pct_spiritual", "pct_race_eth",
  "pct_us_born", "pct_queer"
)

# Named list of the cleaned demographic percentages for one org row.
get_organization_details_demographics <- function(row) {
  values <- lapply(
    ORGANIZATION_DETAILS_DEMOGRAPHIC_COLS,
    function(col) get_named_value(row, col)
  )
  stats::setNames(values, ORGANIZATION_DETAILS_DEMOGRAPHIC_COLS)
}

# Details-page labels: output name -> translation key + English fallback.
# key_title intentionally reads the key_card_title translation key.
ORGANIZATION_DETAILS_LABEL_SPEC <- list(
  page_subtitle_fallback = c(key = "page_subtitle_fallback", fallback = "Organization details"),
  org_subtitle = c(key = "org_subtitle", fallback = "Serving youth in Greater Boston"),
  card_about_title = c(key = "card_about_title", fallback = "About"),
  card_age_title = c(key = "card_age_title", fallback = "Age Breakdown"),
  age_12_17 = c(key = "age_12_17", fallback = "12-17 yrs old"),
  age_18_25 = c(key = "age_18_25", fallback = "18-25 yrs old"),
  age_26_plus = c(key = "age_26_plus", fallback = "26+ yrs old"),
  card_gender_title = c(key = "card_gender_title", fallback = "Gender Identity"),
  gender_women = c(key = "gender_women", fallback = "Identifies as women"),
  gender_men = c(key = "gender_men", fallback = "Identifies as men"),
  gender_other = c(key = "gender_other", fallback = "Identifies as another gender identity"),
  card_other_demographics_title = c(key = "card_other_demographics_title", fallback = "Additional Demographics"),
  other_disabilities = c(key = "other_disabilities", fallback = "With one or more disabilities"),
  other_spiritual = c(key = "other_spiritual", fallback = "Identifies with a religious or spiritual practice"),
  other_race_eth = c(key = "other_race_eth", fallback = "People of color"),
  other_us_born = c(key = "other_us_born", fallback = "Born in the United States"),
  other_queer = c(key = "other_queer", fallback = "Identifies as LGBTQIA+"),
  card_barriers_resources_title = c(key = "card_barriers_resources_title", fallback = "Challenges & Resource Needs"),
  col_barriers_title = c(key = "col_barriers_title", fallback = "What to Keep in Mind"),
  col_barriers_description = c(
    key = "col_barriers_description",
    fallback = paste(
      "Important things to consider when establishing resources for the",
      "following dimensions."
    )
  ),
  col_resource_needs_title = c(key = "col_resource_needs_title", fallback = "Resource Needs"),
  col_resource_needs_description = c(
    key = "col_resource_needs_description",
    fallback = paste(
      "What the organization said it would need in order to establish or",
      "strengthen services in the following dimensions."
    )
  ),
  col_wants_title = c(key = "col_wants_title", fallback = "Areas of Interest"),
  col_wants_description = c(
    key = "col_wants_description",
    fallback = paste(
      "The following dimensions are areas that the organization identified as",
      "not established nor emerging but would like to potentially provide",
      "services for."
    )
  ),
  interview_empty = c(key = "interview_empty", fallback = "None reported."),
  band_none = c(key = "band_none", fallback = "None"),
  band_a_little = c(key = "band_a_little", fallback = "A little"),
  band_some = c(key = "band_some", fallback = "Some"),
  band_a_lot = c(key = "band_a_lot", fallback = "A lot"),
  band_not_reported = c(key = "band_not_reported", fallback = "Not reported"),
  key_title = c(key = "key_card_title", fallback = "Key"),
  key_not_reported_note = c(key = "key_not_reported_note", fallback = "no data provided")
)

# Resolve every details-page label against the active language, falling back to
# the English wording from the spec above.
build_organization_details_labels <- function(details) {
  lapply(ORGANIZATION_DETAILS_LABEL_SPEC, function(spec) {
    get_organization_details_label(details, spec[["key"]], spec[["fallback"]])
  })
}

# Everything the details page needs for one organization: resolved name, labels,
# demographic percentages, and the established/emerging wellness categories. When
# `org_name` is NULL it is read from the ?id query param.
get_organization_details_context <- function(
  lang = get_lang(),
  org_name = NULL,
  survey_data = load_organization_details_data()
) {
  details <- lang$organization_details
  if (is.null(org_name)) {
    org_name <- tryCatch(get_query_param("id"), error = function(e) NULL)
  }

  row <- get_organization_details_row(org_name = org_name, survey_data = survey_data)

  fallback_org_name <- if (!is.null(org_name) && length(org_name) &&
    nzchar(trimws(as.character(org_name[[1]])))) {
    trimws(as.character(org_name[[1]]))
  } else {
    "Organization Name"
  }

  # Only surface a website when it is a real http(s) URL. Survey free-text can be
  # blank or "N/A" (get_named_value already maps missing/blank/"NA" to ""), and
  # requiring an http/https scheme keeps anything non-navigable (or a javascript:
  # URL) out of the rendered link.
  website <- sanitize_org_website(get_named_value(row, "website", fallback = ""))

  orgservices <- parse_orgservices_json(get_named_value(row, "orgservices_json", ""))

  # Qualitative interview coding, grouped by dimension, for the logged-in-only
  # barriers / resource-needs card. Empty for orgs without an interview record.
  # Barriers and resource needs exclude any dimension the org marked as not an
  # organizational focus ("not_interested").
  interview_dims <- get_interview_dimensions(get_named_value(row, "irb_participant_id", ""))

  # Survey-matched services plus interview-coded other_services, so the wheel
  # shows offerings the survey instrument never asked about. Computed once: the
  # detail-text lookup is scoped to exactly the keys the wheel will render.
  established_subcats <- org_subcat_keys(orgservices, interview_dims)

  c(
    list(
      details = details,
      labels = build_organization_details_labels(details),
      orgname = get_named_value(row, "orgname", fallback = fallback_org_name),
      website = website,
      # Free-text organization blurb from the survey. Empty for orgs that left the
      # question blank; the details page omits the card entirely in that case.
      about = get_named_value(row, "about", fallback = ""),
      lengthserve = get_named_value(row, "lengthserve")
    ),
    get_organization_details_demographics(row),
    list(
      established_categories = get_dimension_categories(orgservices, lang, "established"),
      established_subcats = established_subcats,
      # Per-service detail text, keyed by sub-key. Empty until someone authors an
      # entry in data/service_details.json for this organization.
      subcat_details = get_service_details(
        get_named_value(row, "irb_participant_id", ""), established_subcats
      ),
      # Emerging wheel = survey-marked emerging dimensions only.
      emerging_categories = get_emerging_dimension_categories(orgservices, lang),
      # Dimensions the organization is neither established nor emerging in, but
      # answered "Yes" to the survey's <Dim>Gap question ("does your organization
      # WANT to provide ... services?"). build_orgservices_json() already stores
      # this as state "wants", so it needs no new survey column and no artifact
      # rebuild -- only the read side was missing. Unlike barriers/resource_needs
      # below, this is survey-derived, so it is present for organizations that
      # have no interview record at all.
      wants_categories = get_dimension_categories(orgservices, lang, "wants"),
      barriers = get_interview_dimension_items(interview_dims, "barriers", lang, orgservices = orgservices),
      resource_needs = get_interview_dimension_items(interview_dims, "resource_needs", lang, orgservices = orgservices),
      has_data = nrow(row) > 0
    )
  )
}
