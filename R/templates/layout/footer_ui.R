# Page footer: CHANGE Lab social links, contact email, and a copyright line.
footer_ui <- function() {
  # Inline-SVG icon wrapper matching the app's existing icon markup (24x24,
  # currentColor stroke). `paths` is one or more tags$path() children.
  social_icon <- function(...) {
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
      ...
    )
  }

  # A single footer social link: opens in a new tab, labelled for screen readers.
  social_link <- function(href, label, icon) {
    tags$li(
      class = "list-inline-item",
      a(
        href = href,
        class = "link-secondary",
        target = "_blank",
        rel = "noopener noreferrer",
        `aria-label` = label,
        title = label,
        icon
      )
    )
  }

  tags$footer(
    class = "footer footer-transparent d-print-none",
    div(
      class = "container-xl",
      div(
        class = "row text-center align-items-center flex-row-reverse",
        div(
          class = "col-lg-auto ms-lg-auto",
          tags$ul(
            class = "list-inline list-inline-dots mb-0",
            social_link(
              "https://bsky.app/profile/changelab.bsky.social",
              "CHANGE Lab on Bluesky",
              social_icon(
                tags$path(d = "M6.335 5.144c-1.654 -1.199 -4.335 -2.127 -4.335 .826c0 .59 .35 4.953 .556 5.661c.713 2.463 3.13 2.75 5.444 2.369c-4.045 .665 -4.889 3.208 -2.667 5.41c1.03 1.018 1.913 1.59 2.667 1.59c2 0 3.134 -2.769 3.5 -3.5c.333 -.667 .5 -1.167 .5 -1.5c0 .333 .167 .833 .5 1.5c.366 .731 1.5 3.5 3.5 3.5c.754 0 1.637 -.571 2.667 -1.59c2.222 -2.203 1.378 -4.746 -2.667 -5.41c2.314 .38 4.73 .094 5.444 -2.369c.206 -.708 .556 -5.072 .556 -5.661c0 -2.953 -2.68 -2.025 -4.335 -.826c-2.293 1.662 -4.76 5.048 -5.665 6.856c-.905 -1.808 -3.372 -5.194 -5.665 -6.856")
              )
            ),
            social_link(
              "https://www.linkedin.com/in/change-lab-b432722b0/",
              "CHANGE Lab on LinkedIn",
              social_icon(
                tags$path(d = "M8 11v5"),
                tags$path(d = "M8 8v.01"),
                tags$path(d = "M12 16v-5"),
                tags$path(d = "M16 16v-3a2 2 0 1 0 -4 0"),
                tags$path(d = "M3 7a4 4 0 0 1 4 -4h10a4 4 0 0 1 4 4v10a4 4 0 0 1 -4 4h-10a4 4 0 0 1 -4 -4l0 -10")
              )
            ),
            social_link(
              "https://www.instagram.com/changelabboston/",
              "CHANGE Lab on Instagram",
              social_icon(
                tags$path(d = "M4 8a4 4 0 0 1 4 -4h8a4 4 0 0 1 4 4v8a4 4 0 0 1 -4 4h-8a4 4 0 0 1 -4 -4l0 -8"),
                tags$path(d = "M9 12a3 3 0 1 0 6 0a3 3 0 0 0 -6 0"),
                tags$path(d = "M16.5 7.5v.01")
              )
            ),
            social_link(
              "https://www.changelabboston.com/home",
              "CHANGE Lab website",
              tags$img(
                src = "/img/changelab-logo.png",
                alt = "",
                # Inline height wins over Tabler's stylesheet img rules so the
                # logo stays sized instead of expanding to the column width.
                # Matches the navbar brand logo (2rem tall).
                style = "height: 2rem; width: auto; vertical-align: middle;",
                # Hide gracefully until the logo asset is added to www/img/.
                onerror = "this.style.display='none'"
              )
            )
          )
        ),
        div(
          class = "col-12 col-lg-auto mt-3 mt-lg-0",
          tags$ul(
            class = "list-inline list-inline-dots mb-0",
            tags$li(
              class = "list-inline-item",
              a(
                href = "mailto:changelabboston@gmail.com",
                class = "link-secondary",
                "changelabboston@gmail.com"
              )
            ),
            tags$li(
              class = "list-inline-item",
              sprintf("%s © CHANGE Lab", format(Sys.Date(), "%Y"))
            )
          )
        )
      )
    )
  )
}
