organization_details_ui <- function(lang = get_lang()) {
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

          # Gender Identity card
          div(
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

          # Additional Demographics card
          div(
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
                  div(class = "text-secondary", labels$empty_established)
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
                  div(class = "text-secondary", labels$empty_emerging)
                }
              )
            )
          )
        )
      )
    )
  )
}
