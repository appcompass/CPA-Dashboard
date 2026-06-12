organizations_ui <- function(lang = get_lang()) {
  organizations <- lang$organizations

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
    } else if (identical(title, organizations$wellness_physical)) {
      tagList(
        checkbox(organizations$wellness_physical_fitness),
        checkbox(organizations$wellness_physical_nutrition),
        checkbox(organizations$wellness_physical_screenings),
        checkbox(organizations$wellness_physical_other)
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

  wellness_items <- list(
    list(title = organizations$wellness_physical, value = "1"),
    list(title = organizations$wellness_emotional, value = "2"),
    list(title = organizations$wellness_intellectual, value = "3"),
    list(title = organizations$wellness_occupational, value = "4"),
    list(title = organizations$wellness_financial, value = "5"),
    list(title = organizations$wellness_social, value = "6"),
    list(title = organizations$wellness_environmental, value = "7", include_children = FALSE),
    list(title = organizations$wellness_spiritual, value = "8")
  )

  render_wellness_groups <- function(check_physical = FALSE) {
    tagList(lapply(wellness_items, function(item) {
      include_children <- if (is.null(item$include_children)) TRUE else item$include_children
      is_checked <- check_physical && identical(item$value, "1")
      wellness_group(item$title, item$value, checked = is_checked, include_children = include_children)
    }))
  }

  organization_card <- function(badges) {
    badge_class_map <- c(
      physical = "text-blue",
      emotional = "text-azure",
      intellectual = "text-purple",
      occupational = "text-red",
      financial = "text-yellow",
      social = "text-green",
      environmental = "text-teal",
      spiritual = "text-cyan"
    )

    badge_label_map <- c(
      physical = organizations$wellness_physical,
      emotional = organizations$wellness_emotional,
      intellectual = organizations$wellness_intellectual,
      occupational = organizations$wellness_occupational,
      financial = organizations$wellness_financial,
      social = organizations$wellness_social,
      environmental = organizations$wellness_environmental,
      spiritual = organizations$wellness_spiritual
    )

    badge_tags <- tagList(lapply(badges, function(badge) {
      tags$span(
        class = paste("badge badge-outline", badge_class_map[[badge]], "badge-sm"),
        badge_label_map[[badge]]
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
                    a(href = route_link("organizations/details?id=1"), lang$organization_details$org_name_placeholder)
                  )
                ),
                div(class = "col-md-auto", h5(organizations$card_established_areas_label))
              ),
              div(
                class = "row",
                div(
                  class = "col-md",
                  div(
                    class = "mt-3 list-inline list-inline-dots mb-0 text-secondary d-sm-block d-none",
                    div(class = "list-inline-item", serving_icon, organizations$card_serving_text)
                  ),
                  div(
                    class = "mt-3 list mb-0 text-secondary d-block d-sm-none",
                    div(class = "list-item", serving_icon, organizations$card_serving_text)
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
          div(class = "col", h2(class = "page-title", organizations$page_title)),
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
                    placeholder = organizations$search_placeholder
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
              div(class = "form-label", organizations$filter_established_label),
              div(
                class = "mb-4",
                render_wellness_groups(check_physical = TRUE)
              ),
              div(class = "form-label", organizations$filter_emerging_label),
              div(
                class = "mb-4",
                render_wellness_groups(check_physical = FALSE)
              ),
              div(
                class = "mt-5",
                tags$button(class = "btn btn-primary w-100", organizations$btn_confirm_filter),
                a(href = "#", class = "btn btn-link w-100", organizations$btn_reset_filter)
              )
            )
          ),
          div(
            class = "col-md-9",
            div(
              class = "row row-cards",
              organization_card(c(
                "physical", "emotional", "intellectual", "occupational",
                "financial", "social", "environmental", "spiritual"
              )),
              organization_card(c("emotional", "intellectual", "social")),
              organization_card(c("occupational", "financial", "social", "environmental", "spiritual")),
              organization_card(c("physical", "emotional", "intellectual", "environmental", "spiritual")),
              organization_card(c("physical", "emotional", "intellectual", "occupational"))
            )
          )
        )
      )
    )
  )
}
