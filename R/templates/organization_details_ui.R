organization_details_ui <- function() {
  tagList(
    div(
      class = "page-header d-print-none", `aria-label` = "Page header",
      div(
        class = "container-xl",
        div(
          class = "row g-2 align-items-center",
          div(
            class = "col",
            h2(class = "page-title", "Organization Name"),
            div(class = "page-pretitle", "Serving youth in Greater Boston since 1998")
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
                h3(class = "card-title", "Age Breakdown")
              ),
              div(
                class = "card-body",
                h3(class = "card-title", "Youth served by your organization"),
                div(
                  class = "row",
                  div(
                    class = "col-12 col-sm d-flex flex-column",
                    div(
                      class = "row",
                      div(
                        class = "col-4",
                        div(class = "subheader", "12-17 yrs old"),
                        div(
                          class = "d-flex align-items-baseline",
                          div(class = "h3 me-2", "26%-60%")
                        )
                      ),
                      div(
                        class = "col-4",
                        div(class = "subheader", "18-25 yrs old"),
                        div(
                          class = "d-flex align-items-baseline",
                          div(class = "h3 me-2", "1%-5%")
                        )
                      ),
                      div(
                        class = "col-4",
                        div(class = "subheader", "26+ yrs old"),
                        div(
                          class = "d-flex align-items-baseline",
                          div(class = "h3 me-2", "1%-5%")
                        )
                      )
                    )
                  )
                ),
                h3(class = "card-title mt-5", "Employees of your organization"),
                div(
                  class = "row",
                  div(
                    class = "col-12 col-sm d-flex flex-column",
                    div(
                      class = "row",
                      div(
                        class = "col-4",
                        div(class = "subheader", "12-17 yrs old"),
                        div(
                          class = "d-flex align-items-baseline",
                          div(class = "h3 me-2", "1%-5%")
                        )
                      ),
                      div(
                        class = "col-4",
                        div(class = "subheader", "18-25 yrs old"),
                        div(
                          class = "d-flex align-items-baseline",
                          div(class = "h3 me-2", "26%-60%")
                        )
                      ),
                      div(
                        class = "col-4",
                        div(class = "subheader", "26+ yrs old"),
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
                h3(class = "card-title", "Established Areas of Wellness")
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
                h3(class = "card-title", "Emerging Areas of Wellness (Private)")
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
