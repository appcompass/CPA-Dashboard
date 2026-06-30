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
            h2(class = "page-title", details_context$orgname),
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
                    div(class = "h3", details_context$pct_age_12_17)
                  ),
                  div(
                    class = "col-4",
                    div(class = "text-secondary", labels$age_18_25),
                    div(class = "h3", details_context$pct_age_18_25)
                  ),
                  div(
                    class = "col-4",
                    div(class = "text-secondary", labels$age_26_plus),
                    div(class = "h3", details_context$pct_age_over26)
                  )
                )
              )
            )
          ),

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
                    div(class = "h3", details_context$pct_women)
                  ),
                  div(
                    class = "col-4",
                    div(class = "text-secondary", labels$gender_men),
                    div(class = "h3", details_context$pct_men)
                  ),
                  div(
                    class = "col-4",
                    div(class = "text-secondary", labels$gender_other),
                    div(class = "h3", details_context$pct_gender)
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
                    div(class = "h3", details_context$pct_disabilities)
                  ),
                  div(
                    class = "col-4",
                    div(class = "text-secondary", labels$other_spiritual),
                    div(class = "h3", details_context$pct_spiritual)
                  ),
                  div(
                    class = "col-4 mt-3",
                    div(class = "text-secondary", labels$other_race_eth),
                    div(class = "h3", details_context$pct_race_eth)
                  ),
                  div(
                    class = "col-4 mt-3",
                    div(class = "text-secondary", labels$other_us_born),
                    div(class = "h3", details_context$pct_us_born)
                  ),
                  div(
                    class = "col-6 mt-3",
                    div(class = "text-secondary", labels$other_queer),
                    div(class = "h3", details_context$pct_queer)
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
                  `data-active-subcats` = paste(details_context$established_subcats, collapse = ",")
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
