organization_details_ui <- function(lang = get_lang()) {
  organizations <- lang$organizations
  details_context <- get_organization_details_context(lang = lang)

  details <- details_context$details

  detail_label <- function(key, fallback) {
    value <- details[[key]]
    if (is.null(value) || !nzchar(value)) {
      fallback
    } else {
      value
    }
  }

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
                detail_label("page_subtitle_fallback", "Organization details")
              } else {
                sprintf(
                  "%s - %s",
                  details_context$lengthserve,
                  detail_label("org_subtitle", "Serving youth in Greater Boston")
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
                h3(class = "card-title", detail_label("card_age_title", "Age Breakdown"))
              ),
              div(
                class = "card-body",
                div(
                  class = "row row-cards",
                  div(
                    class = "col-4",
                    div(class = "text-secondary", detail_label("age_12_17", "12-17 yrs old")),
                    div(class = "h3", details_context$pct_age_12_17)
                  ),
                  div(
                    class = "col-4",
                    div(class = "text-secondary", detail_label("age_18_25", "18-25 yrs old")),
                    div(class = "h3", details_context$pct_age_18_25)
                  ),
                  div(
                    class = "col-4",
                    div(class = "text-secondary", detail_label("age_26_plus", "26+ yrs old")),
                    div(class = "h3", details_context$pct_age_over26)
                  )
                )
              )
            )
          ),

          # Gender Identity card
          div(
            class = "col-sm-12 col-lg-6",
            div(
              class = "card",
              div(
                class = "card-header",
                h3(class = "card-title", detail_label("card_gender_title", "Gender Identity"))
              ),
              div(
                class = "card-body",
                div(
                  class = "row row-cards",
                  div(
                    class = "col-4",
                    div(class = "text-secondary", detail_label("gender_women", "Identifies as women")),
                    div(class = "h3", details_context$pct_women)
                  ),
                  div(
                    class = "col-4",
                    div(class = "text-secondary", detail_label("gender_men", "Identifies as men")),
                    div(class = "h3", details_context$pct_men)
                  ),
                  div(
                    class = "col-4",
                    div(class = "text-secondary", detail_label("gender_other", "Identifies as another gender identity")),
                    div(class = "h3", details_context$pct_gender)
                  )
                )
              )
            )
          ),

          # Additional Demographics card
          div(
            class = "col-12",
            div(
              class = "card",
              div(
                class = "card-header",
                h3(class = "card-title", detail_label("card_other_demographics_title", "Additional Demographics"))
              ),
              div(
                class = "card-body",
                div(
                  class = "row row-cards",
                  div(
                    class = "col-4",
                    div(class = "text-secondary", detail_label("other_disabilities", "With one or more disabilities")),
                    div(class = "h3", details_context$pct_disabilities)
                  ),
                  div(
                    class = "col-4",
                    div(class = "text-secondary", detail_label("other_spiritual", "Identifies with a religious or spiritual practice")),
                    div(class = "h3", details_context$pct_spiritual)
                  ),
                  div(
                    class = "col-4 mt-3",
                    div(class = "text-secondary", detail_label("other_race_eth", "People of color")),
                    div(class = "h3", details_context$pct_race_eth)
                  ),
                  div(
                    class = "col-4 mt-3",
                    div(class = "text-secondary", detail_label("other_us_born", "Born in the United States")),
                    div(class = "h3", details_context$pct_us_born)
                  ),
                  div(
                    class = "col-6 mt-3",
                    div(class = "text-secondary", detail_label("other_queer", "Identifies as LGBTQIA+")),
                    div(class = "h3", details_context$pct_queer)
                  )
                )
              )
            )
          ),

          # Established Areas of Wellness card
          div(
            class = "col-12",
            div(
              class = "card",
              div(
                class = "card-header",
                h3(class = "card-title", details$card_established_title)
              ),
              div(
                class = "card-body",
                if (length(details_context$established_categories)) {
                  div(`data-active-categories` = paste(details_context$established_categories, collapse = ", "))
                } else {
                  div(class = "text-secondary", detail_label("empty_established", "No established wellness areas were reported."))
                }
              )
            )
          ),

          # Emerging Areas of Wellness card
          div(
            class = "col-12",
            div(
              class = "card",
              div(
                class = "card-header",
                h3(class = "card-title", details$card_emerging_title)
              ),
              div(
                class = "card-body",
                if (length(details_context$emerging_categories)) {
                  div(`data-active-categories` = paste(details_context$emerging_categories, collapse = ", "))
                } else {
                  div(class = "text-secondary", detail_label("empty_emerging", "No emerging wellness areas were reported."))
                }
              )
            )
          )
        )
      )
    )
  )
}
