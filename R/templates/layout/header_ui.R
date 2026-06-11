header_ui <- function() {
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
          `aria-label` = "Toggle navigation",
          tags$span(class = "navbar-toggler-icon")
        ),
        div(
          class = "navbar-brand navbar-brand-autodark d-none-navbar-horizontal pe-0 pe-md-3",
          a(
            href = route_link("/"),
            class = "nav-link",
            `aria-label` = "CPA Dashboard",
            tags$svg(
              xmlns = "http://www.w3.org/2000/svg",
              width = "32",
              height = "32",
              viewBox = "0 0 68 68",
              class = "navbar-brand-image me-2",
              tags$path(
                d = "M64.6 16.2C63 9.9 58.1 5 51.8 3.4 40 1.5 28 1.5 16.2 3.4 9.9 5 5 9.9 3.4 16.2 1.5 28 1.5 40 3.4 51.8 5 58.1 9.9 63 16.2 64.6c11.8 1.9 23.8 1.9 35.6 0C58.1 63 63 58.1 64.6 51.8c1.9-11.8 1.9-23.8 0-35.6zM33.3 36.3c-2.8 4.4-6.6 8.2-11.1 11-1.5.9-3.3.9-4.8.1s-2.4-2.3-2.5-4c0-1.7.9-3.3 2.4-4.1 2.3-1.4 4.4-3.2 6.1-5.3-1.8-2.1-3.8-3.8-6.1-5.3-2.3-1.3-3-4.2-1.7-6.4s4.3-2.9 6.5-1.6c4.5 2.8 8.2 6.5 11.1 10.9 1 1.4 1 3.3.1 4.7zM49.2 46H37.8c-2.1 0-3.8-1-3.8-3s1.7-3 3.8-3h11.4c2.1 0 3.8 1 3.8 3s-1.7 3-3.8 3z",
                fill = "#066fd1",
                style = "fill: var(--tblr-primary, #066fd1)"
              )
            ),
            "CPA Dashboard"
          )
        ),
        div(
          class = "navbar-nav flex-row order-md-last",
          div(
            class = "d-none d-md-flex",
            div(
              class = "nav-item",
              a(
                href = "?theme=dark",
                class = "nav-link px-0 hide-theme-dark",
                `data-bs-toggle` = "tooltip",
                `data-bs-placement` = "bottom",
                `aria-label` = "Enable dark mode",
                `data-bs-original-title` = "Enable dark mode",
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
                  tags$path(d = "M12 3c.132 0 .263 0 .393 0a7.5 7.5 0 0 0 7.92 12.446a9 9 0 1 1 -8.313 -12.454z")
                )
              ),
              a(
                href = "?theme=light",
                class = "nav-link px-0 hide-theme-light",
                `data-bs-toggle` = "tooltip",
                `data-bs-placement` = "bottom",
                `aria-label` = "Enable light mode",
                `data-bs-original-title` = "Enable light mode",
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
                  tags$path(d = "M12 12m-4 0a4 4 0 1 0 8 0a4 4 0 1 0 -8 0"),
                  tags$path(d = "M3 12h1m8 -9v1m8 8h1m-9 8v1m-6.4 -15.4l.7 .7m12.1 -.7l-.7 .7m0 11.4l.7 .7m-12.1 -.7l-.7 .7")
                )
              )
            ),
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
                  tags$span(class = "nav-link-title", " Theme Settings ")
                )
              ),
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
                tags$span(class = "nav-link-title", " Home ")
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
                tags$span(class = "nav-link-title", " Organizations ")
              )
            )
          )
        )
      )
    )
  )
}
