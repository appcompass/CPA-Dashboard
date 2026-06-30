# The lab's full name. This exact English phrase is embedded in the translated
# `intro` of every language, so the dashboard highlights the CHANGE acronym by
# bolding the first letter of each word that spells it (the capitalized content
# words) while leaving the lowercase connectors ("inequity", "in", "and") plain.
CHANGE_FULL_NAME <- paste(
  "Challenging Health inequity in Adolescents and Nurturing Global",
  "Empowerment"
)
CHANGE_ACRONYM_WORDS <- c(
  "Challenging", "Health", "Adolescents", "Nurturing", "Global", "Empowerment"
)

# The full name as an HTML string, with each acronym word's first letter wrapped
# in <strong>. Built as a single string (rather than a tagList) so no whitespace
# is introduced between the bolded letter and the rest of its word.
render_change_full_name <- function() {
  words <- strsplit(CHANGE_FULL_NAME, " ", fixed = TRUE)[[1]]
  parts <- vapply(words, function(word) {
    if (word %in% CHANGE_ACRONYM_WORDS) {
      paste0("<strong>", substr(word, 1, 1), "</strong>", substring(word, 2))
    } else {
      word
    }
  }, character(1))
  paste(parts, collapse = " ")
}

# Render inline markdown links — `[text](url)` — into anchor tags that open in a
# new tab. Operates on already-HTML-escaped text: the link text is escaped (it
# came from the translated copy), and only the bracket/paren markdown syntax is
# rewritten into markup. URLs are restricted to http(s) so a translation string
# can't inject an unexpected scheme.
render_markdown_links <- function(escaped) {
  gsub(
    "\\[([^]]+)\\]\\((https?://[^)\\s]+)\\)",
    "<a href=\"\\2\" target=\"_blank\" rel=\"noopener noreferrer\">\\1</a>",
    escaped,
    perl = TRUE
  )
}

# Render the intro paragraph, bolding the CHANGE acronym within the embedded full
# name and turning the markdown "website" link into an anchor. The translated
# text is HTML-escaped first; only the known, metacharacter-free full name is
# swapped for its bolded markup and the markdown link syntax for an anchor.
render_intro <- function(text) {
  escaped <- htmltools::htmlEscape(text)
  with_name <- sub(CHANGE_FULL_NAME, render_change_full_name(), escaped, fixed = TRUE)
  HTML(render_markdown_links(with_name))
}

# Render a paragraph of translated copy that may contain markdown links, e.g. the
# CPA body's link to SAMHSA's 8 dimensions of wellness.
render_rich_text <- function(text) {
  HTML(render_markdown_links(htmltools::htmlEscape(text)))
}

# About page: who the CHANGE Lab is, its vision and mission, an explanation of
# the Community Partners Assessment (CPA), and how to get in touch. Narrative
# content sourced from changelabboston.com; the dashboard uses a project-specific
# contact email (changelabboston@gmail.com) in place of the lab coordinator's.
about_ui <- function(lang = get_lang()) {
  about <- lang$about

  # About copy, with English fallbacks so the page never renders blank if a
  # translation is missing a key (mirrors the home page's hp() helper).
  ap <- function(key, fallback) {
    value <- about[[key]]
    if (is.null(value) || !nzchar(value)) fallback else value
  }

  # `icon` is one or more tags$path() children for the inline SVG glyph shown
  # in a circular badge beside the card title.
  info_card <- function(icon, title, body) {
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
            h3(class = "h2 m-0", title)
          ),
          p(class = "text-secondary fs-3 lh-base m-0", body)
        )
      )
    )
  }

  tagList(
    # Header / intro
    div(
      class = "hero",
      div(
        class = "container text-center",
        tags$img(
          src = "/img/changelab-logo.png",
          alt = "CHANGE Lab logo",
          class = "mb-4",
          style = "max-width: 200px; height: auto;",
          # Hide gracefully until the logo asset is added to www/img/.
          onerror = "this.style.display='none'"
        ),
        h1(class = "hero-title", ap("page_heading", "About CHANGE Lab")),
        p(class = "hero-description hero-description-wide", render_intro(ap(
          "intro",
          paste(
            "Challenging Health inequity in Adolescents and Nurturing Global",
            "Empowerment (CHANGE) Lab is directed by Dr. Idia Thurston.",
            "Collectively known as butterflies, our lab brings together the",
            "principal investigator, research staff, and undergraduate",
            "volunteers. To learn more about our lab, please check out our",
            "[website](https://www.changelabboston.com/home)!"
          )
        )))
      )
    ),

    # Vision & Mission
    div(
      class = "section section-light",
      div(
        class = "container",
        div(
          class = "row g-4",
          info_card(
            tagList(
              tags$path(d = "M10 12a2 2 0 1 0 4 0a2 2 0 0 0 -4 0"),
              tags$path(d = "M21 12c-2.4 4 -5.4 6 -9 6c-3.6 0 -6.6 -2 -9 -6c2.4 -4 5.4 -6 9 -6c3.6 0 6.6 2 9 6")
            ),
            ap("vision_title", "Our Vision"),
            ap(
              "vision_body",
              "To support adolescents to have fair and just opportunities to be as healthy as possible."
            )
          ),
          info_card(
            tagList(
              tags$path(d = "M11 12a1 1 0 1 0 2 0a1 1 0 1 0 -2 0"),
              tags$path(d = "M12 7a5 5 0 1 0 5 5"),
              tags$path(d = "M13 3.055a9 9 0 1 0 7.941 7.945"),
              tags$path(d = "M15 6v3h3l3 -3h-3v-3l-3 3"),
              tags$path(d = "M15 9l-3 3")
            ),
            ap("mission_title", "Our Mission"),
            ap(
              "mission_body",
              paste(
                "To engage in community-academic partnerships to assess,",
                "co-develop, and disseminate health equity science, programs,",
                "and policy that support adolescents and their families."
              )
            )
          )
        )
      )
    ),

    # What is the CPA?
    div(
      class = "section",
      div(
        class = "container",
        div(
          class = "section-header",
          # CPA logo beside the heading, mirroring how the CHANGE Lab logo is
          # shown in the hero (PNG from www/img, hidden gracefully if missing).
          div(
            class = "d-flex align-items-center gap-3 flex-wrap",
            tags$img(
              src = "/img/cpa-logo.png",
              alt = "CPA logo",
              style = "max-width: 100px; height: auto;",
              onerror = "this.style.display='none'"
            ),
            # Sized to match the hero "About CHANGE Lab" section: hero-title
            # header and h2-sized (fs-2) body, a step up from the other sections.
            h2(class = "hero-title m-0", ap("cpa_title", "What is the CPA?"))
          )
        ),
        p(class = "text-secondary fs-2 lh-base", render_rich_text(ap(
          "cpa_body",
          paste(
            "The Community Partners Assessment (CPA) is how the CHANGE Lab",
            "identifies and connects with community-based organizations whose",
            "missions align with our own. Through outreach and conversational,",
            "semi-structured interviews, we learn about each organization's",
            "strengths, priorities, and needs along",
            "[SAMHSA's 8 dimensions of wellness](https://library.samhsa.gov/sites/default/files/sma16-4953.pdf):",
            "physical, emotional, intellectual, occupational, financial, social,",
            "environmental, and spiritual. We also gain their perspectives on the",
            "health and wellness of youth across their communities."
          )
        )))
      )
    ),

    # Connect with us
    div(
      class = "section section-light",
      div(
        class = "container",
        div(
          class = "section-header",
          h2(class = "section-title", ap("connect_title", "Connect with Us"))
        ),
        p(class = "text-secondary fs-3 lh-base", ap(
          "connect_body",
          "Have a question or want to partner with the CHANGE Lab? We'd love to hear from you."
        )),
        tags$ul(
          class = "list-unstyled fs-3 m-0",
          tags$li(
            class = "mb-2",
            tags$strong(ap("connect_email_label", "Email")), ": ",
            a(href = "mailto:changelabboston@gmail.com", "changelabboston@gmail.com")
          ),
          tags$li(
            tags$strong(ap("connect_address_label", "Visit")), ": ",
            ap(
              "connect_address",
              paste(
                "1165 Tremont St, Boston, MA 02120 — 3rd floor of",
                "International Village at Northeastern University (enter through",
                "the doors next to Juicy Greens)."
              )
            )
          )
        )
      )
    )
  )
}
