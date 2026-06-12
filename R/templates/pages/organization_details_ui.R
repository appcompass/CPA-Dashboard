organization_details_ui <- function(lang = get_lang()) {
  organizations <- lang$organizations
  details_context <- get_organization_details_context(lang = lang)

  details <- details_context$details

  tagList(
    div(
      class = "page-header d-print-none", `aria-label` = "Page header",
      div(
        class = "container-xl",
        div(
          class = "row g-2 align-items-center",
          div(
            class = "col",
            h2(class = "page-title", details_context$org_name),
            div(
              class = "page-pretitle",
              if (!details_context$has_data || identical(details_context$years_served, "N/A")) {
                "Organization details"
              } else {
                sprintf("%s years serving youth in Greater Boston", details_context$years_served)
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

          # Age Breakdown card
          div(
            class = "col-sm-12 col-lg-6",
            div(
              class = "card",
              div(
                class = "card-header",
                h3(class = "card-title", details$card_age_title)
              ),
              div(
                class = "card-body",
                h3(class = "card-title", details$card_age_youth_title),
                div(
                  class = "row",
                  div(
                    class = "col-12 col-sm d-flex flex-column",
                    div(
                      class = "row",
                      div(
                        class = "col-4",
                        div(class = "subheader", details$age_12_17),
                        div(
                          class = "d-flex align-items-baseline",
                          div(class = "h3 me-2", details_context$age_youth$age_12_17)
                        )
                      ),
                      div(
                        class = "col-4",
                        div(class = "subheader", details$age_18_25),
                        div(
                          class = "d-flex align-items-baseline",
                          div(class = "h3 me-2", details_context$age_youth$age_18_25)
                        )
                      ),
                      div(
                        class = "col-4",
                        div(class = "subheader", details$age_26_plus),
                        div(
                          class = "d-flex align-items-baseline",
                          div(class = "h3 me-2", details_context$age_youth$age_26_plus)
                        )
                      )
                    )
                  )
                ),
                h3(class = "card-title mt-5", details$card_age_employee_title),
                div(
                  class = "row",
                  div(
                    class = "col-12 col-sm d-flex flex-column",
                    div(
                      class = "row",
                      div(
                        class = "col-4",
                        div(class = "subheader", details$age_12_17),
                        div(
                          class = "d-flex align-items-baseline",
                          div(class = "h3 me-2", details_context$age_employees$age_12_17)
                        )
                      ),
                      div(
                        class = "col-4",
                        div(class = "subheader", details$age_18_25),
                        div(
                          class = "d-flex align-items-baseline",
                          div(class = "h3 me-2", details_context$age_employees$age_18_25)
                        )
                      ),
                      div(
                        class = "col-4",
                        div(class = "subheader", details$age_26_plus),
                        div(
                          class = "d-flex align-items-baseline",
                          div(class = "h3 me-2", details_context$age_employees$age_26_plus)
                        )
                      )
                    )
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
                  div(class = "text-secondary", "No established wellness areas were reported.")
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
                  div(class = "text-secondary", "No emerging wellness areas were reported.")
                }
              )
            )
          )
        )
      )
    )
  )
}
