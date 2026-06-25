# Top navigation bar: brand, primary nav (Home/Organizations), and the language,
# theme, and login controls (each rendered by its own component via server.R).
header_ui <- function(lang = get_lang()) {
  header <- lang$header
  app <- lang$app

  tagList(
    tags$header(
      class = "navbar navbar-expand-md d-print-none",
      div(
        class = "container-xl",
        tags$button(
          class = "navbar-toggler",
          type = "button",
          `data-bs-toggle` = "collapse",
          `data-bs-target` = "#navbar-menu",
          `aria-controls` = "navbar-menu",
          `aria-expanded` = "false",
          `aria-label` = header$toggle_nav_aria,
          tags$span(class = "navbar-toggler-icon")
        ),
        div(
          class = "navbar-brand d-none-navbar-horizontal pe-0 pe-md-3",
          a(
            href = route_link("/"),
            class = "nav-link",
            `aria-label` = app$title,
            tags$img(
              src = "/img/changelab-logo.png",
              alt = "",
              class = "navbar-brand-image me-2",
              # Inline height keeps the logo navbar-sized regardless of Tabler's
              # stylesheet img rules; width auto preserves the aspect ratio.
              style = "height: 2rem; width: auto;"
            ),
            app$title
          )
        ),
        div(
          class = "navbar-nav flex-row order-md-last",
          div(
            class = "d-none d-md-flex",
            uiOutput("theme_toggle_nav_link"),
            tags$ul(
              class = "navbar-nav",
              tags$li(
                class = "nav-item",
                a(
                  class = "nav-link",
                  href = "#",
                  `data-bs-toggle` = "offcanvas",
                  `data-bs-target` = "#offcanvasSettings",
                  tags$span(
                    class = "nav-link-icon d-md-none d-lg-inline-block",
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
                      class = "icon icon-1",
                      tags$path(d = "M10.325 4.317c.426 -1.756 2.924 -1.756 3.35 0a1.724 1.724 0 0 0 2.573 1.066c1.543 -.94 3.31 .826 2.37 2.37a1.724 1.724 0 0 0 1.065 2.572c1.756 .426 1.756 2.924 0 3.35a1.724 1.724 0 0 0 -1.066 2.573c.94 1.543 -.826 3.31 -2.37 2.37a1.724 1.724 0 0 0 -2.572 1.065c-.426 1.756 -2.924 1.756 -3.35 0a1.724 1.724 0 0 0 -2.573 -1.066c-1.543 .94 -3.31 -.826 -2.37 -2.37a1.724 1.724 0 0 0 -1.065 -2.572c-1.756 -.426 -1.756 -2.924 0 -3.35a1.724 1.724 0 0 0 1.066 -2.573c-.94 -1.543 .826 -3.31 2.37 -2.37c1 .608 2.296 .07 2.572 -1.065z"),
                      tags$path(d = "M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0")
                    )
                  ),
                  tags$span(class = "nav-link-title", paste0(" ", header$nav_theme_settings, " "))
                )
              ),
              uiOutput("lang_change_nav_link"),
              uiOutput("login_nav_link")
            )
          )
        ),
        div(
          class = "collapse navbar-collapse",
          id = "navbar-menu",
          tags$ul(
            class = "navbar-nav",
            tags$li(
              class = "nav-item",
              a(
                class = "nav-link",
                href = route_link("/"),
                tags$span(
                  class = "nav-link-icon d-md-none d-lg-inline-block",
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
                    class = "icon icon-1",
                    tags$path(d = "M5 12l-2 0l9 -9l9 9l-2 0"),
                    tags$path(d = "M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-7"),
                    tags$path(d = "M9 21v-6a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v6")
                  )
                ),
                tags$span(class = "nav-link-title", paste0(" ", header$nav_home, " "))
              )
            ),
            tags$li(
              class = "nav-item",
              a(
                class = "nav-link",
                href = route_link("/about"),
                tags$span(
                  class = "nav-link-icon d-md-none d-lg-inline-block",
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
                    class = "icon icon-1",
                    tags$path(d = "M10 13a2 2 0 1 0 4 0a2 2 0 0 0 -4 0"),
                    tags$path(d = "M8 21v-1a2 2 0 0 1 2 -2h4a2 2 0 0 1 2 2v1"),
                    tags$path(d = "M15 5a2 2 0 1 0 4 0a2 2 0 0 0 -4 0"),
                    tags$path(d = "M17 10h2a2 2 0 0 1 2 2v1"),
                    tags$path(d = "M5 5a2 2 0 1 0 4 0a2 2 0 0 0 -4 0"),
                    tags$path(d = "M3 13v-1a2 2 0 0 1 2 -2h2")
                  )
                ),
                tags$span(
                  class = "nav-link-title",
                  paste0(" ", header$nav_about %||% "About", " ")
                )
              )
            ),
            tags$li(
              class = "nav-item",
              a(
                class = "nav-link",
                href = route_link("/organizations"),
                tags$span(
                  class = "nav-link-icon d-md-none d-lg-inline-block",
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
                    class = "icon icon-1",
                    tags$path(d = "M5 12l-2 0l9 -9l9 9l-2 0"),
                    tags$path(d = "M5 12v7a2 2 0 0 0 2 2h10a2 2 0 0 0 2 -2v-7"),
                    tags$path(d = "M9 21v-6a2 2 0 0 1 2 -2h2a2 2 0 0 1 2 2v6")
                  )
                ),
                tags$span(class = "nav-link-title", paste0(" ", header$nav_organizations, " "))
              )
            )
          )
        )
      )
    )
  )
}
