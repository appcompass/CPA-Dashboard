# Render one column of the barriers / resource-needs card: a dimension sub-heading
# followed by a bullet list of its items, repeated per dimension. Falls back to a
# muted "none reported" line when the org has no entries for this field.
render_interview_items_column <- function(groups, empty_text) {
  if (!length(groups)) {
    return(div(class = "text-secondary", empty_text))
  }
  lapply(groups, function(group) {
    div(
      class = "mb-3",
      div(class = "fw-bold", group$label),
      tags$ul(
        class = "mb-0",
        lapply(group$items, function(item) tags$li(item))
      )
    )
  })
}

# ---------------------------------------------------------------------------
# Demographic value rendering: a qualitative word plus a six-slot figure meter.
# pct_band() (in data.R) collapses a percentage range to a band; this layer
# turns that band into the translated word and the little-people meter.
# ---------------------------------------------------------------------------

# Default meter accent. Threaded through every helper so a per-card color (or a
# per-dimension one later) is a one-argument change rather than a rewrite.
DEMOGRAPHIC_METER_COLOR <- "#066fd1"

# The standing-figure silhouette, drawn once and reused. fill and stroke are
# inherited by the child shapes, so a filled figure is a solid fill and an empty
# one is a grey outline, toggled entirely from the parent <svg> style.
# Person pictogram from human_figure.svg (SVG Repo). Its viewBox has a negative
# origin, carried verbatim below. vector-effect keeps the outline (empty state)
# a constant 1.5px regardless of the figure's coordinate space.
.DEMOGRAPHIC_PERSON_SHAPES <- paste0(
  '<path vector-effect="non-scaling-stroke" d="M-362.9,157.9c11.3,0,20.5,9.2,20.5,20.5s-9.2,20.5-20.5,20.5s-20.5-9.2-20.5-20.5S-374.2,157.9-362.9,157.9z M-337.1,204.2 h-51.2c-14.2,0-25.6,11.4-25.6,25.6v62.6c0,4.9,3.9,9,9,9s9-3.9,9-9v-57.5c0-1.4,1.2-2.6,2.6-2.6c1.4,0,2.6,1.2,2.6,2.6v155.2 c0,7.7,5.7,14,12.8,14s12.8-6.3,12.8-14v-88.5c0-1.4,1.2-2.6,2.6-2.6s2.6,1.2,2.6,2.6v88.5c0,7.7,5.7,14,12.8,14s12.8-6.3,12.8-14 V234.9c0-1.4,1.2-2.6,2.6-2.6c1.4,0,2.6,1.2,2.6,2.6v57.6c0,4.9,3.9,9,9,9s9-3.9,9-9v-62.7C-311.5,215.6-323.2,204.2-337.1,204.2z"/>'
)

demographic_person_svg <- function(filled, color = DEMOGRAPHIC_METER_COLOR, height = 22) {
  style <- if (isTRUE(filled)) {
    sprintf("fill:%s;", color)
  } else {
    "fill:none;stroke:#adb5bd;stroke-width:1.5;"
  }
  sprintf(
    paste0(
      '<svg viewBox="-421 153 117 256" height="%d" role="img" aria-hidden="true" ',
      'style="%s display:block;" xmlns="http://www.w3.org/2000/svg">%s</svg>'
    ),
    height, style, .DEMOGRAPHIC_PERSON_SHAPES
  )
}

# The meter markup for one band: six figures, the first N filled. A band of
# "not_reported" has no meter (returns ""), so a genuine "no data" row is
# visibly different from a "None" row (six empty outlines).
demographic_meter_html <- function(band, color = DEMOGRAPHIC_METER_COLOR) {
  if (identical(band, "not_reported")) {
    return("")
  }
  n <- band_filled_count(band)
  slots <- vapply(seq_len(6), function(i) demographic_person_svg(i <= n, color), character(1))
  paste0(
    '<span class="d-inline-flex align-items-end" style="gap:3px;margin-top:.35rem;">',
    paste0(slots, collapse = ""),
    "</span>"
  )
}

# One demographic value: the qualitative word, then the meter beneath it.
demographic_value_ui <- function(value, labels, color = DEMOGRAPHIC_METER_COLOR) {
  band <- pct_band(value)
  word <- labels[[paste0("band_", band)]] %||% value
  tagList(
    div(class = "h3 mb-0", word),
    HTML(demographic_meter_html(band, color))
  )
}

# The static key/legend card, rendered on every organization page regardless of
# login. Shows each band's word, its percentage range, and its meter so a reader
# can decode both the words and the figures. Sized to sit beside the always-
# public Age card and fill the empty half when logged out.
demographic_key_ui <- function(labels, color = DEMOGRAPHIC_METER_COLOR) {
  band_row <- function(band, range_text) {
    div(
      class = "d-flex align-items-center justify-content-between py-1",
      div(
        span(class = "fw-bold", labels[[paste0("band_", band)]]),
        span(class = "text-secondary ms-2", range_text)
      ),
      HTML(demographic_meter_html(band, color))
    )
  }
  div(
    class = "col-sm-12 col-lg-6",
    div(
      class = "card",
      div(
        class = "card-header",
        h3(class = "card-title", labels$key_title)
      ),
      div(
        class = "card-body",
        band_row("none", "0%"),
        band_row("a_little", "1%-25%"),
        band_row("some", "26%-60%"),
        band_row("a_lot", "61%-100%"),
        div(
          class = "text-secondary pt-2 mt-1 border-top",
          sprintf("%s: %s", labels$band_not_reported, labels$key_not_reported_note)
        )
      )
    )
  )
}

# Single organization dashboard. Age breakdown and the wellness wheels are always
# shown; the gender and additional-demographics cards, the barriers/resource-needs
# card, and the emerging-areas card are gated behind `logged_in`.
organization_details_ui <- function(lang = get_lang(), logged_in = FALSE) {
  organizations <- lang$organizations
  details_context <- get_organization_details_context(lang = lang)

  details <- details_context$details
  labels <- details_context$labels

  tagList(
    div(
      class = "page-header d-print-none", `aria-label` = "Page header",
      div(
        class = "container-xl",
        div(
          class = "row g-2 align-items-center",
          div(
            class = "col",
            h2(
              class = "page-title",
              # Link the org name to its website when the survey provides a valid
              # one; otherwise render the name as plain text. External link, so
              # open in a new tab with noopener/noreferrer.
              if (nzchar(details_context$website %||% "")) {
                a(
                  href = details_context$website,
                  target = "_blank",
                  rel = "noopener noreferrer",
                  details_context$orgname
                )
              } else {
                details_context$orgname
              }
            ),
            div(
              class = "page-pretitle",
              if (!details_context$has_data || identical(details_context$lengthserve, "N/A")) {
                labels$page_subtitle_fallback
              } else {
                sprintf(
                  "%s - %s",
                  details_context$lengthserve,
                  labels$org_subtitle
                )
              }
            )
          )
        )
      )
    ),
    div(
      class = "page-body",
      div(
        class = "container-xl",
        div(
          class = "row row-deck row-cards",

          # Youth Ages Breakdown card
          div(
            class = "col-sm-12 col-lg-6",
            div(
              class = "card",
              div(
                class = "card-header",
                h3(class = "card-title", labels$card_age_title)
              ),
              div(
                class = "card-body",
                div(
                  class = "row row-cards",
                  div(
                    class = "col-4",
                    div(class = "text-secondary", labels$age_12_17),
                    demographic_value_ui(details_context$pct_age_12_17, labels)
                  ),
                  div(
                    class = "col-4",
                    div(class = "text-secondary", labels$age_18_25),
                    demographic_value_ui(details_context$pct_age_18_25, labels)
                  ),
                  div(
                    class = "col-4",
                    div(class = "text-secondary", labels$age_26_plus),
                    demographic_value_ui(details_context$pct_age_over26, labels)
                  )
                )
              )
            )
          ),

          # Demographic key / legend card (always shown; fills the half beside Age when logged out)
          demographic_key_ui(labels),

          # Gender Identity card (restricted to logged-in organizations)
          if (logged_in) div(
            class = "col-sm-12 col-lg-6",
            div(
              class = "card",
              div(
                class = "card-header",
                h3(class = "card-title", labels$card_gender_title)
              ),
              div(
                class = "card-body",
                div(
                  class = "row row-cards",
                  div(
                    class = "col-4",
                    div(class = "text-secondary", labels$gender_women),
                    demographic_value_ui(details_context$pct_women, labels)
                  ),
                  div(
                    class = "col-4",
                    div(class = "text-secondary", labels$gender_men),
                    demographic_value_ui(details_context$pct_men, labels)
                  ),
                  div(
                    class = "col-4",
                    div(class = "text-secondary", labels$gender_other),
                    demographic_value_ui(details_context$pct_gender, labels)
                  )
                )
              )
            )
          ),

          # Additional Demographics card (restricted to logged-in organizations)
          if (logged_in) div(
            class = "col-12",
            div(
              class = "card",
              div(
                class = "card-header",
                h3(class = "card-title", labels$card_other_demographics_title)
              ),
              div(
                class = "card-body",
                div(
                  class = "row row-cards",
                  div(
                    class = "col-4",
                    div(class = "text-secondary", labels$other_disabilities),
                    demographic_value_ui(details_context$pct_disabilities, labels)
                  ),
                  div(
                    class = "col-4",
                    div(class = "text-secondary", labels$other_spiritual),
                    demographic_value_ui(details_context$pct_spiritual, labels)
                  ),
                  div(
                    class = "col-4 mt-3",
                    div(class = "text-secondary", labels$other_race_eth),
                    demographic_value_ui(details_context$pct_race_eth, labels)
                  ),
                  div(
                    class = "col-4 mt-3",
                    div(class = "text-secondary", labels$other_us_born),
                    demographic_value_ui(details_context$pct_us_born, labels)
                  ),
                  div(
                    class = "col-6 mt-3",
                    div(class = "text-secondary", labels$other_queer),
                    demographic_value_ui(details_context$pct_queer, labels)
                  )
                )
              )
            )
          ),

          # Established Areas of Wellness card (hidden when the org has none)
          if (length(details_context$established_categories)) div(
            class = "col-12",
            div(
              class = "card",
              div(
                class = "card-header",
                h3(class = "card-title", details$card_established_title)
              ),
              div(
                class = "card-body",
                div(
                  `data-active-categories` = paste(details_context$established_categories, collapse = ", "),
                  `data-active-subcats` = paste(details_context$established_subcats, collapse = ","),
                  # Omitted entirely (NULL) when this org has no authored detail
                  # text, so createWheel renders labels exactly as before.
                  `data-subcat-details` = subcat_details_attr(details_context$subcat_details)
                )
              )
            )
          ),

          # Emerging Areas of Wellness card (logged-in only; hidden when the org has none)
          if (logged_in && length(details_context$emerging_categories)) div(
            class = "col-12",
            div(
              class = "card",
              div(
                class = "card-header",
                h3(class = "card-title", details$card_emerging_title)
              ),
              div(
                class = "card-body",
                div(`data-active-categories` = paste(details_context$emerging_categories, collapse = ", "))
              )
            )
          ),

          # Barriers & Resource Needs card (logged-in only; hidden when the org
          # has no interview-coded entries). Two columns: barriers | resource needs.
          if (logged_in && (length(details_context$barriers) || length(details_context$resource_needs))) div(
            class = "col-12",
            div(
              class = "card",
              div(
                class = "card-header",
                h3(class = "card-title", labels$card_barriers_resources_title)
              ),
              div(
                class = "card-body",
                div(
                  class = "row",
                  div(
                    class = "col-6",
                    h4(labels$col_barriers_title),
                    render_interview_items_column(details_context$barriers, labels$interview_empty)
                  ),
                  div(
                    class = "col-6",
                    h4(labels$col_resource_needs_title),
                    render_interview_items_column(details_context$resource_needs, labels$interview_empty)
                  )
                )
              )
            )
          )
        )
      )
    )
  )
}
