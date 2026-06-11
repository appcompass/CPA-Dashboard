organizations_ui <- function() {
  serving_icon <- tags$svg(
    xmlns = "http://www.w3.org/2000/svg",
    width = "24",
    height = "24",
    viewBox = "0 0 24 24",
    fill = "none",
    stroke = "currentColor",
    `stroke-width` = "2",
    `stroke-linecap` = "round",
    `stroke-linejoin` = "round",
    class = "icon icon-2",
    tags$path(d = "M20.942 13.021a9 9 0 1 0 -9.407 7.967"),
    tags$path(d = "M12 7v5l3 3"),
    tags$path(d = "M15 19l2 2l4 -4")
  )

  wellness_group <- function(title, value, checked = FALSE, include_children = TRUE) {
    checkbox <- function(checkbox_label, checkbox_checked = checked) {
      tags$label(
        class = "form-check mt-2",
        tags$input(
          type = "checkbox",
          class = "form-check-input",
          name = "form-type[]",
          value = "1",
          checked = if (checkbox_checked) NA else NULL
        ),
        tags$span(class = "form-check-label", checkbox_label)
      )
    }

    children <- if (!include_children) {
      NULL
    } else if (identical(title, "Physical wellness")) {
      tagList(
        checkbox("Fitness programs"),
        checkbox("Nutritional education"),
        checkbox("Health screenings"),
        checkbox("Other")
      )
    } else {
      checkbox("...")
    }

    tags$label(
      class = "form-check",
      tags$input(
        type = "checkbox",
        class = "form-check-input",
        name = "form-type[]",
        value = value,
        checked = if (checked) NA else NULL
      ),
      tags$span(class = "form-check-label", title, children)
    )
  }

  organization_card <- function(badges) {
    badge_class_map <- c(
      Physical = "text-blue",
      Emotional = "text-azure",
      Intellectual = "text-purple",
      Occupational = "text-red",
      Financial = "text-yellow",
      Social = "text-green",
      Environmental = "text-teal",
      Spiritual = "text-cyan"
    )

    badge_tags <- tagList(lapply(badges, function(badge) {
      tags$span(
        class = paste("badge badge-outline", badge_class_map[[badge]], "badge-sm"),
        badge
      )
    }))

    div(
      class = "space-y",
      div(
        class = "card",
        div(
          class = "row g-0",
          div(
            class = "col-auto",
            div(
              class = "card-body",
              div(
                class = "avatar avatar-md",
                style = "background-image: url(./static/jobs/job-1.jpg);"
              )
            )
          ),
          div(
            class = "col",
            div(
              class = "card-body ps-0",
              div(
                class = "row",
                div(
                  class = "col-md",
                  h3(
                    class = "mb-0",
                    a(href = route_link("organizations/details?id=1"), "Organization Name")
                  )
                ),
                div(class = "col-md-auto", h5("Established Areas of Wellness"))
              ),
              div(
                class = "row",
                div(
                  class = "col-md",
                  div(
                    class = "mt-3 list-inline list-inline-dots mb-0 text-secondary d-sm-block d-none",
                    div(class = "list-inline-item", serving_icon, "Serving youth in Greater Boston since 1998")
                  ),
                  div(
                    class = "mt-3 list mb-0 text-secondary d-block d-sm-none",
                    div(class = "list-item", serving_icon, "Serving youth in Greater Boston since 1998")
                  )
                ),
                div(class = "col-md-auto", div(class = "mt-3 badges-list", badge_tags))
              )
            )
          )
        )
      )
    )
  }

  tagList(
    div(
      class = "page-header d-print-none",
      `aria-label` = "Page header",
      div(
        class = "container-xl",
        div(
          class = "row g-2 align-items-center",
          div(class = "col", h2(class = "page-title", "Search Organizations")),
          div(
            class = "col-auto ms-auto d-print-none",
            div(
              class = "mb-3",
              div(
                class = "row g-2",
                div(
                  class = "col",
                  tags$input(
                    type = "text",
                    class = "form-control",
                    placeholder = "Search by name..."
                  )
                ),
                div(
                  class = "col-auto",
                  a(
                    href = "#",
                    class = "btn btn-2 btn-icon",
                    `aria-label` = "Button",
                    tags$svg(
                      xmlns = "http://www.w3.org/2000/svg",
                      width = "24",
                      height = "24",
                      viewBox = "0 0 24 24",
                      fill = "none",
                      stroke = "currentColor",
                      `stroke-width` = "2",
                      `stroke-linecap` = "round",
                      `stroke-linejoin` = "round",
                      class = "icon icon-2",
                      tags$path(d = "M10 10m-7 0a7 7 0 1 0 14 0a7 7 0 1 0 -14 0"),
                      tags$path(d = "M21 21l-6 -6")
                    )
                  )
                )
              )
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
          class = "row g-4",
          div(
            class = "col-md-3",
            tags$form(
              action = "./",
              method = "get",
              autocomplete = "off",
              novalidate = NA,
              class = "sticky-top",
              div(class = "form-label", "Established Areas"),
              div(
                class = "mb-4",
                wellness_group("Physical wellness", "1", checked = TRUE),
                wellness_group("Emotional wellness", "2"),
                wellness_group("Intellectual wellness", "3"),
                wellness_group("Occupational wellness", "4"),
                wellness_group("Financial wellness", "5"),
                wellness_group("Social wellness", "6"),
                wellness_group("Environmental wellness", "7", include_children = FALSE),
                wellness_group("Spiritual wellness", "8")
              ),
              div(class = "form-label", "Emerging Areas (private?)"),
              div(
                class = "mb-4",
                wellness_group("Physical wellness", "1"),
                wellness_group("Emotional wellness", "2"),
                wellness_group("Intellectual wellness", "3"),
                wellness_group("Occupational wellness", "4"),
                wellness_group("Financial wellness", "5"),
                wellness_group("Social wellness", "6"),
                wellness_group("Environmental wellness", "7", include_children = FALSE),
                wellness_group("Spiritual wellness", "8")
              ),
              div(
                class = "mt-5",
                tags$button(class = "btn btn-primary w-100", "Confirm Filter"),
                a(href = "#", class = "btn btn-link w-100", "Reset to defaults")
              )
            )
          ),
          div(
            class = "col-md-9",
            div(
              class = "row row-cards",
              organization_card(c(
                "Physical", "Emotional", "Intellectual", "Occupational",
                "Financial", "Social", "Environmental", "Spiritual"
              )),
              organization_card(c("Emotional", "Intellectual", "Social")),
              organization_card(c("Occupational", "Financial", "Social", "Environmental", "Spiritual")),
              organization_card(c("Physical", "Emotional", "Intellectual", "Environmental", "Spiritual")),
              organization_card(c("Physical", "Emotional", "Intellectual", "Occupational"))
            )
          )
        )
      )
    )
  )
}
