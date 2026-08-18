# Render the hero description, turning the two pieces of inline markup the copy
# uses — a single markdown link [text](https://…) and markdown italics _text_ —
# into HTML. The translated prose is HTML-escaped first; only these known,
# hand-authored constructs are then converted to <a>/<em>, mirroring about_ui's
# controlled render_intro() approach. Links are restricted to https:// URLs.
render_hero_description <- function(text) {
  escaped <- htmltools::htmlEscape(text)
  # Convert italics first, while the text is still plain: the markdown link
  # syntax carries no underscores, so this can't disturb it — whereas doing it
  # after would let an emitted attribute like target="_blank" capture a stray _.
  with_italics <- gsub("_([^_]+)_", "<em>\\1</em>", escaped, perl = TRUE)
  with_links <- gsub(
    "\\[([^]]+)\\]\\((https://[^)\\s]+)\\)",
    "<a href=\"\\2\" target=\"_blank\" rel=\"noopener noreferrer\">\\1</a>",
    with_italics,
    perl = TRUE
  )
  HTML(with_links)
}

# Landing page: hero intro, the eight wellness dimensions shown as the wellness
# wheel, the project's purpose, and a "how to use the dashboard" walkthrough.
home_ui <- function(lang = get_lang()) {
  home <- lang$home
  organizations <- lang$organizations

  # Home copy, with English fallbacks so the page never renders blank if a
  # translation is missing a key.
  hp <- function(key, fallback) {
    value <- home[[key]]
    if (is.null(value) || !nzchar(value)) fallback else value
  }

  # All eight wellness dimensions, labelled from the shared translation scope.
  # These labels populate the wellness wheel (see www/js/app.js createWheel, which
  # matches them against its dimension tokens).
  dimension_keys <- c(
    "wellness_physical", "wellness_emotional", "wellness_intellectual",
    "wellness_occupational", "wellness_financial", "wellness_social",
    "wellness_environmental", "wellness_spiritual"
  )
  dimension_labels <- vapply(dimension_keys, function(key) {
    organizations[[key]] %||% ""
  }, character(1))
  wheel_categories <- paste(dimension_labels[nzchar(dimension_labels)], collapse = ", ")

  howto_step <- function(number, title, body) {
    div(
      class = "col-sm-6 col-lg-3",
      div(
        class = "row g-3",
        div(
          class = "col-auto",
          div(class = "shape shape-md bg-primary-lt text-primary fw-bold", number)
        ),
        div(
          class = "col",
          h3(class = "h3 mb-1", title),
          p(class = "text-secondary m-0", body)
        )
      )
    )
  }

  # A visually distinct callout (icon + heading + body, with an optional footer)
  # used below the numbered steps for the login and customization notes. `icon`
  # is one or more tags$path() children for the inline SVG glyph.
  howto_callout <- function(icon, title, body, footer = NULL) {
    div(
      class = "col-md-6",
      div(
        class = "card h-100",
        div(
          class = "card-body",
          div(
            class = "d-flex align-items-center mb-2",
            tags$span(
              class = "shape shape-md bg-primary-lt text-primary me-3",
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
                icon
              )
            ),
            h3(class = "h3 m-0", title)
          ),
          p(class = "text-secondary mb-0", body),
          footer
        )
      )
    )
  }

  tagList(
    # Hero / intro
    div(
      class = "hero",
      div(
        class = "container",
        h1(class = "hero-title", hp(
          "hero_title",
          "Community Partners Assessment Dashboard"
        )),
        p(
          class = "hero-description hero-description-wide",
          render_hero_description(hp(
            "hero_description",
            paste(
              "The Community Partners Assessment (CPA) Dashboard is an interactive",
              "platform that visualizes the different wellness services and",
              "programs that organizations across the greater Boston area provide",
              "for youth of color and their families! We define wellness along",
              "[SAMHSA's eight dimensions](https://library.samhsa.gov/sites/default/files/sma16-4953.pdf):",
              "physical, emotional, intellectual, occupational, financial, social,",
              "environmental, and spiritual (Adapted from Swarbrick, M. (2006). A",
              "Wellness Approach. _Psychiatric Rehabilitation Journal, 29_(4),",
              "311–314.). Explore organizations by filtering for name,",
              "wellness dimensions, and more!"
            )
          ))
        ),
        div(
          class = "mt-4",
          a(
            href = route_link("/organizations"),
            class = "btn btn-primary btn-lg",
            hp("cta_browse", "Browse Organizations")
          )
        )
      )
    ),

    # Eight dimensions overview
    div(
      class = "section section-light",
      div(
        class = "container",
        div(
          class = "section-header",
          h2(class = "section-title", hp(
            "dimensions_title", "Eight Dimensions of Wellness"
          )),
          div(class = "section-description", hp(
            "dimensions_description",
            "We define wellness across eight dimensions."
          ))
        ),
        # Same interactive wellness wheel as the organization details page,
        # showing all eight dimensions (rendered by createWheel in app.js).
        div(
          `data-active-categories` = wheel_categories,
          `data-wheel-centered` = "true",
          `data-wheel-size` = 600
        )
      )
    ),

    # Purpose
    div(
      class = "section",
      div(
        class = "container-narrow text-center",
        h2(class = "section-title", hp("purpose_title", "Our Purpose")),
        p(class = "text-secondary fs-3 lh-base", hp(
          "purpose_body",
          paste(
            "The goal of this dashboard is to serve as a networking hub for",
            "organizations to connect with each other to uplift youth of color and",
            "their families in the greater Boston area. Users can discover",
            "organizations' areas of expertise to build connections, ask for",
            "guidance, and for referrals. Through surveying and interviewing",
            "organizations, we hope to present our findings to the community and",
            "create a site that prioritizes diverse representation and inclusion of",
            "all domains of wellness to better support the multicultural needs of",
            "youth of color in Boston and beyond."
          )
        ))
      )
    ),

    # How to use the dashboard
    div(
      class = "section section-light",
      div(
        class = "container",
        div(
          class = "section-header",
          h2(class = "section-title", hp(
            "howto_title", "How to use the dashboard"
          )),
          div(class = "section-description", hp(
            "howto_disclaimer",
            paste(
              "This dashboard celebrates what each organization offers. It is not",
              "a ranking, report card, or evaluation tool. Wellness areas are",
              "self-reported and shown to spark connection and referrals — not to",
              "compare or rank organizations."
            )
          ))
        ),
        div(
          class = "row g-4",
          howto_step(
            "1",
            hp("howto_step1_title", "Browse organizations"),
            hp(
              "howto_step1_body",
              "View the partner organizations serving youth of color and their families across Greater Boston."
            )
          ),
          howto_step(
            "2",
            hp("howto_step2_title", "Search and filter"),
            hp(
              "howto_step2_body",
              "Narrow the list by name and by an organization's areas of wellness and their sub-services."
            )
          ),
          howto_step(
            "3",
            hp("howto_step3_title", "Explore wellness areas"),
            hp(
              "howto_step3_body",
              "Open an organization to see its wellness wheel, its established strengths, and the areas it's growing into."
            )
          ),
          howto_step(
            "4",
            hp("howto_step4_title", "Connect and refer"),
            hp(
              "howto_step4_body",
              "Discover each organization's expertise to build connections, seek guidance, and make referrals."
            )
          )
        ),
        div(
          class = "row g-4 mt-2",
          howto_callout(
            tagList(
              tags$path(d = "M5 13a2 2 0 0 1 2 -2h10a2 2 0 0 1 2 2v6a2 2 0 0 1 -2 2h-10a2 2 0 0 1 -2 -2v-6"),
              tags$path(d = "M11 16a1 1 0 1 0 2 0a1 1 0 0 0 -2 0"),
              tags$path(d = "M8 11v-4a4 4 0 1 1 8 0v4")
            ),
            hp("howto_login_title", "See the full profile — log in"),
            hp(
              "howto_login_body",
              paste(
                "The public view shows a summary of each organization. Verified",
                "organization members can log in to view and update complete",
                "profile details — contact information, full service descriptions,",
                "and more. Logging in keeps your organization's information",
                "accurate so partners can reach you and refer to you."
              )
            ),
            footer = p(
              class = "text-secondary mt-3 mb-0",
              hp(
                "howto_login_contact",
                paste0(
                  "Need a password, having trouble logging in, or need us to ",
                  "make any edits or updates to your organization's page? Contact "
                )
              ),
              a(
                href = "mailto:changelabboston@gmail.com",
                "changelabboston@gmail.com"
              )
            )
          ),
          howto_callout(
            tagList(
              tags$path(d = "M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0"),
              tags$path(d = "M3.6 9h16.8"),
              tags$path(d = "M3.6 15h16.8"),
              tags$path(d = "M11.5 3a17 17 0 0 0 0 18"),
              tags$path(d = "M12.5 3a17 17 0 0 1 0 18")
            ),
            hp("howto_customize_title", "Make it yours"),
            hp(
              "howto_customize_body",
              paste(
                "Switch the dashboard into any of our supported languages using",
                "the language selector in the navigation — your choice carries",
                "across the site."
              )
            )
          )
        )
      )
    )
  )
}
