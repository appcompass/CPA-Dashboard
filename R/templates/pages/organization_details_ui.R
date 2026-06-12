organization_details_ui <- function(lang = get_lang()) {
  details <- lang$organization_details

  tagList(
    div(
      class = "page-header d-print-none", `aria-label` = "Page header",
      div(
        class = "container-xl",
        div(
          class = "row g-2 align-items-center",
          div(
            class = "col",
            h2(class = "page-title", details$org_name_placeholder),
            div(class = "page-pretitle", details$org_subtitle)
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
                          div(class = "h3 me-2", "26%-60%")
                        )
                      ),
                      div(
                        class = "col-4",
                        div(class = "subheader", details$age_18_25),
                        div(
                          class = "d-flex align-items-baseline",
                          div(class = "h3 me-2", "1%-5%")
                        )
                      ),
                      div(
                        class = "col-4",
                        div(class = "subheader", details$age_26_plus),
                        div(
                          class = "d-flex align-items-baseline",
                          div(class = "h3 me-2", "1%-5%")
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
                          div(class = "h3 me-2", "1%-5%")
                        )
                      ),
                      div(
                        class = "col-4",
                        div(class = "subheader", details$age_18_25),
                        div(
                          class = "d-flex align-items-baseline",
                          div(class = "h3 me-2", "26%-60%")
                        )
                      ),
                      div(
                        class = "col-4",
                        div(class = "subheader", details$age_26_plus),
                        div(
                          class = "d-flex align-items-baseline",
                          div(class = "h3 me-2", "1%-5%")
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
                div(`data-active-categories` = "Physical, Intellectual, Occupational, Financial, Social")
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
                div(`data-active-categories` = "Emotional, Spiritual, Environmental")
              )
            )
          )
        )
      )
    )
  )
}
