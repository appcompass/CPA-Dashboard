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
        p(class = "hero-description hero-description-wide", hp(
          "hero_description",
          paste(
            "The Community Partners Assessment Dashboard is an interactive platform",
            "that visualizes the wellness services organizations across the greater",
            "Boston area provide for youth of color and their families. We define",
            "wellness across eight dimensions: physical, emotional, intellectual,",
            "occupational, financial, social, environmental, and spiritual. Explore",
            "different organizations by filtering for name, location, and wellness",
            "dimensions."
          )
        )),
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
        div(`data-active-categories` = wheel_categories)
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
              "Narrow the list by name and by established areas of wellness and their sub-services."
            )
          ),
          howto_step(
            "3",
            hp("howto_step3_title", "Explore wellness areas"),
            hp(
              "howto_step3_body",
              "Open an organization to see its wellness wheel and its established and emerging areas."
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
        )
      )
    )
  )
}
