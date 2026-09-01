render_html <- function(ui) {
  as.character(htmltools::renderTags(ui)$html)
}

# ---- app bootstrap ----

test_that("every source() call in the boot path declares encoding = \"UTF-8\"", {
  withr::local_dir(project_root)

  # R parses a source file in the PROCESS's native encoding unless told
  # otherwise. Under a C/POSIX locale -- which is what the deployed process gets
  # -- the non-ASCII literals in the boot path become bytes R cannot interpret
  # and reach the page as <c2><a9> style escapes: the copyright sign in
  # footer_ui.R, the em dashes in home_ui.R's English fallback copy, and the
  # language endonyms in R/lang.R (Simplified Chinese, Vietnamese, Arabic,
  # Russian, ...).
  #
  # Declaring the encoding at each site makes parsing independent of whatever
  # locale the app boots under. Note this is deliberately NOT
  # options(encoding = "UTF-8"): that would also change the default for file()
  # connections, and read_clean_survey() would then re-encode the decrypted
  # artifact to native on the way in -- reintroducing the very bug it fixes.
  for (f in c("app.R", file.path("R", "data.R"), file.path("R", "ui.R"))) {
    calls <- grep("^\\s*source\\(", readLines(f, warn = FALSE), value = TRUE)
    expect_gt(length(calls), 0L)
    expect_equal(
      calls[!grepl('encoding = "UTF-8"', calls, fixed = TRUE)],
      character(0)
    )
  }
})

test_that("non-ASCII UI literals survive parsing intact", {
  # Canary for the language endonyms, the one place the app renders non-ASCII
  # from R source with no other test over it. The footer's copyright sign is
  # already covered by "footer_ui renders social links and contact email".
  expect_true(all(validUTF8(SUPPORTED_LANGUAGES$label)))
  expect_true("\u7b80\u4f53\u4e2d\u6587" %in% SUPPORTED_LANGUAGES$label)
  expect_false(any(grepl("<c2>", SUPPORTED_LANGUAGES$label, fixed = TRUE)))
})

test_that("app.R builds a shiny app object", {
  withr::local_dir(project_root)

  app_env <- new.env(parent = globalenv())
  sys.source(file.path(project_root, "app.R"), envir = app_env)

  expect_true(inherits(app_env$app, "shiny.appobj"))
})

# ---- layout ----

test_that("header_ui renders navbar with brand and nav links", {
  withr::local_dir(project_root)

  html <- render_html(header_ui())

  expect_match(html, "navbar", fixed = TRUE)
  expect_match(html, "CPA Dashboard", fixed = TRUE)
  expect_match(html, "Home", fixed = TRUE)
  expect_match(html, "About", fixed = TRUE)
  expect_match(html, "Organizations", fixed = TRUE)
})

test_that("footer_ui renders social links and contact email", {
  withr::local_dir(project_root)

  html <- render_html(footer_ui())

  expect_match(html, "bsky.app/profile/changelab", fixed = TRUE)
  expect_match(html, "linkedin.com/in/change-lab", fixed = TRUE)
  expect_match(html, "instagram.com/changelabboston", fixed = TRUE)
  expect_match(html, "changelabboston.com", fixed = TRUE)
  expect_match(html, "changelabboston@gmail.com", fixed = TRUE)
  expect_match(html, "\u00a9 CHANGE Lab", fixed = TRUE)
})

# ---- pages ----

test_that("home_ui renders hero, dimensions, purpose and how-to sections", {
  withr::local_dir(project_root)

  html <- render_html(home_ui())

  expect_match(html, "Community Partners Assessment Dashboard", fixed = TRUE)
  expect_match(html, "hero-title", fixed = TRUE)
  expect_match(html, "Eight Dimensions of Wellness", fixed = TRUE)
  expect_match(html, "Our Purpose", fixed = TRUE)
  expect_match(html, "How to use the dashboard", fixed = TRUE)
  expect_match(html, "It is not a ranking, report card, or evaluation tool", fixed = TRUE)
  expect_match(html, "See the full profile", fixed = TRUE)
  expect_match(html, "changelabboston@gmail.com", fixed = TRUE)
  expect_match(html, "Make it yours", fixed = TRUE)
  expect_match(html, "Browse Organizations", fixed = TRUE)
})

test_that("home_ui hero description renders the SAMHSA link and italic citation", {
  withr::local_dir(project_root)

  html <- render_html(home_ui())

  # The wellness-dimensions copy links out to SAMHSA's eight-dimensions PDF as a
  # real anchor (markdown link converted to HTML), not raw markdown brackets.
  expect_match(
    html,
    paste0(
      "<a href=\"https://library.samhsa.gov/sites/default/files/",
      "sma16-4953.pdf\""
    ),
    fixed = TRUE
  )
  expect_match(html, ">SAMHSA's eight dimensions</a>", fixed = TRUE)
  expect_false(
    grepl("[SAMHSA's eight dimensions](https", html, fixed = TRUE)
  )
  # The Swarbrick citation's journal name + volume render as italics.
  expect_match(
    html,
    "<em>Psychiatric Rehabilitation Journal, 29</em>",
    fixed = TRUE
  )
})

test_that("about_ui renders lab info, vision/mission, CPA and contact", {
  withr::local_dir(project_root)

  html <- render_html(about_ui())

  expect_match(html, "About CHANGE Lab", fixed = TRUE)
  expect_match(html, "Our Vision", fixed = TRUE)
  expect_match(html, "Our Mission", fixed = TRUE)
  expect_match(html, "What is the CPA?", fixed = TRUE)
  expect_match(html, "Connect with Us", fixed = TRUE)
  expect_match(html, "changelabboston@gmail.com", fixed = TRUE)
})

test_that("about_ui bolds the CHANGE acronym and not the connector words", {
  withr::local_dir(project_root)

  html <- render_html(about_ui())

  # Each acronym word's first letter is bolded, with no space splitting it.
  expect_match(html, "<strong>C</strong>hallenging", fixed = TRUE)
  expect_match(html, "<strong>H</strong>ealth", fixed = TRUE)
  expect_match(html, "<strong>A</strong>dolescents", fixed = TRUE)
  expect_match(html, "<strong>N</strong>urturing", fixed = TRUE)
  expect_match(html, "<strong>G</strong>lobal", fixed = TRUE)
  expect_match(html, "<strong>E</strong>mpowerment", fixed = TRUE)
  # Connector words stay plain (not bolded).
  expect_false(grepl("<strong>i</strong>nequity", html, fixed = TRUE))
  expect_false(grepl("<strong>i</strong>n ", html, fixed = TRUE))
  expect_false(grepl("<strong>a</strong>nd", html, fixed = TRUE))
})

test_that("about_ui links the CHANGE Lab website and shows the CPA logo", {
  withr::local_dir(project_root)

  html <- render_html(about_ui())

  # The intro's "website" markdown link renders as an anchor to changelabboston.
  expect_match(
    html,
    "<a href=\"https://www.changelabboston.com/home\"",
    fixed = TRUE
  )
  expect_match(html, ">website</a>", fixed = TRUE)

  # The CPA logo sits beside the "What is the CPA?" heading.
  expect_match(html, "/img/cpa-logo.png", fixed = TRUE)
})

test_that("about_ui links SAMHSA's 8 dimensions of wellness in the CPA body", {
  withr::local_dir(project_root)

  html <- render_html(about_ui())

  expect_match(
    html,
    "<a href=\"https://library.samhsa.gov/sites/default/files/sma16-4953.pdf\"",
    fixed = TRUE
  )
  expect_match(html, "8 dimensions of wellness</a>", fixed = TRUE)
  # The eight named dimensions appear in the body.
  expect_match(
    html,
    "physical, emotional, intellectual, occupational, financial, social, environmental, and spiritual",
    fixed = TRUE
  )
})

test_that("about_ui and home_ui invite orgs to request page edits", {
  withr::local_dir(project_root)

  # Stakeholder ask: organizations should be told they can email the lab to get
  # their own page corrected, on both the About and Home entry points.
  about_html <- render_html(about_ui())
  expect_match(about_html, "new information about your organization", fixed = TRUE)
  expect_match(about_html, "changelabboston@gmail.com", fixed = TRUE)

  home_html <- render_html(home_ui())
  expect_match(home_html, "edits or updates to your organization", fixed = TRUE)
  expect_match(home_html, "changelabboston@gmail.com", fixed = TRUE)
})

test_that("the edit-request invitation is translated into every language", {
  withr::local_dir(project_root)

  en_connect <- get_lang("en")$about$connect_body
  en_contact <- get_lang("en")$home$howto_login_contact

  for (code in rownames(SUPPORTED_LANGUAGES)) {
    lang <- get_lang(code)
    connect <- as.character(lang$about$connect_body %||% "")
    contact <- as.character(lang$home$howto_login_contact %||% "")

    expect_true(nzchar(trimws(connect)), info = paste(code, "connect_body"))
    expect_true(nzchar(trimws(contact)), info = paste(code, "howto_login_contact"))

    # The email <a> is appended after this string in home_ui.R, so the trailing
    # space is load-bearing: without it the link runs into the sentence.
    expect_true(endsWith(contact, " "), info = paste(code, "trailing space"))

    if (!identical(code, "en")) {
      expect_false(identical(connect, en_connect), info = paste(code, "connect untranslated"))
      expect_false(identical(contact, en_contact), info = paste(code, "contact untranslated"))
    }
  }
})

test_that("about_ui sizes the section descriptions per stakeholder feedback", {
  withr::local_dir(project_root)

  html <- render_html(about_ui())

  # Patrice's feedback: these descriptions were too small. Vision, mission, and
  # the Connect body use the home page body size (fs-3 lh-base); the CPA section
  # is bumped further to match the hero (hero-title header + fs-2 body).
  vision_mission <- lengths(regmatches(
    html, gregexpr("text-secondary fs-3 lh-base m-0", html)
  ))
  connect_body <- lengths(regmatches(
    html, gregexpr('text-secondary fs-3 lh-base"', html)
  ))
  expect_equal(vision_mission, 2L) # vision + mission card bodies
  expect_equal(connect_body, 1L) # connect section body only

  # The CPA header now uses hero-title (matching the "About CHANGE Lab" hero),
  # so the page carries two hero-title headings; the CPA body uses fs-2. The CPA
  # heading also carries m-0 (it sits in a flex row beside the CPA logo), so the
  # class token is matched regardless of any additional classes.
  hero_titles <- lengths(regmatches(html, gregexpr('class="hero-title', html)))
  expect_equal(hero_titles, 2L)
  expect_match(html, "text-secondary fs-2 lh-base", fixed = TRUE)
})

test_that("login_ui renders login form fields", {
  withr::local_dir(project_root)

  html <- render_html(login_ui())

  expect_match(html, "Login to your account", fixed = TRUE)
  expect_match(html, "Organization Name", fixed = TRUE)
  expect_match(html, "Organization ID", fixed = TRUE)
  expect_match(html, "Sign in", fixed = TRUE)
  expect_match(html, "organizations_list", fixed = TRUE)
})

test_that("organizations_ui renders search page and filter panel", {
  withr::local_dir(project_root)

  html <- render_html(organizations_ui())

  expect_match(html, "Search Organizations", fixed = TRUE)
  expect_match(html, "organizations-search", fixed = TRUE)
  expect_match(html, "Established Areas", fixed = TRUE)
  expect_match(html, "organizations-filter", fixed = TRUE)
})

test_that("organizations_ui colors and icons the wellness dimension filters", {
  withr::local_dir(project_root)

  html <- render_html(organizations_ui())

  # Each dimension's parent filter label carries the wheel color and an icon.
  # Color comes from the shared DIMENSION_WHEEL_COLORS source of truth.
  for (color in unname(DIMENSION_WHEEL_COLORS)) {
    expect_match(html, color, fixed = TRUE)
  }
  # The parent rows use the dimension icon wrapper class.
  expect_match(html, "filter-dimension-icon", fixed = TRUE)
  # Sanity: a known Tabler dimension icon is present in the sidebar markup.
  expect_match(html, "icon-tabler-heartbeat", fixed = TRUE)
})

test_that("organization_details_ui renders detail cards", {
  withr::local_dir(project_root)

  detail_data <- load_organization_details_data()
  skip_if(
    nrow(detail_data) == 0,
    "No organization in the local dataset has consented to publication."
  )
  first_org_name <- trimws(detail_data[["orgname"]][1])
  first_org_years <- trimws(detail_data[["lengthserve"]][1])

  html <- render_html(organization_details_ui())

  expect_match(html, first_org_name, fixed = TRUE)
  expect_match(html, first_org_years, fixed = TRUE)
  expect_match(html, "Age Breakdown", fixed = TRUE)
  # Established/Emerging cards render only when the org has those areas; the
  # first org reliably has established areas. Gender/demographics are gated to
  # logged-in users, so they are absent here.
  expect_match(html, "Established Areas of Wellness", fixed = TRUE)
  expect_false(grepl("Gender Identity", html, fixed = TRUE))
})

test_that("organization_details_ui gates gender and demographics behind login", {
  withr::local_dir(project_root)

  logged_out <- render_html(organization_details_ui(logged_in = FALSE))
  logged_in <- render_html(organization_details_ui(logged_in = TRUE))

  # Age breakdown is always public.
  expect_match(logged_out, "Age Breakdown", fixed = TRUE)
  # Gender + additional demographics are hidden when logged out, shown when in.
  expect_false(grepl("Gender Identity", logged_out, fixed = TRUE))
  expect_false(grepl("Additional Demographics", logged_out, fixed = TRUE))
  expect_match(logged_in, "Gender Identity", fixed = TRUE)
  expect_match(logged_in, "Additional Demographics", fixed = TRUE)
})

test_that("organization_details_ui gates emerging areas and barriers/resource needs behind login", {
  withr::local_dir(project_root)

  # Pick an org that is survey-marked emerging in at least one dimension AND has
  # interview-sourced barriers/resource needs, so both private cards render. The
  # emerging wheel is survey-only, so the default first org may have no emerging
  # areas; drive the UI to a known-emerging org via the "id" query param.
  detail_data <- load_organization_details_data()
  skip_if(
    nrow(detail_data) == 0,
    "No organization in the local dataset has consented to publication."
  )
  lang <- get_lang("en")
  emerging_org <- NULL
  for (i in seq_len(nrow(detail_data))) {
    os <- parse_orgservices_json(
      get_named_value(detail_data[i, ], "orgservices_json", "")
    )
    if (length(get_emerging_dimension_categories(os, lang))) {
      emerging_org <- trimws(detail_data[["orgname"]][i])
      break
    }
  }
  expect_false(is.null(emerging_org))
  testthat::local_mocked_bindings(
    get_query_param = function(field = NULL, ...) {
      if (is.null(field) || identical(field, "id")) emerging_org else NULL
    },
    .package = "shiny.router"
  )

  logged_out <- render_html(organization_details_ui(logged_in = FALSE))
  logged_in <- render_html(organization_details_ui(logged_in = TRUE))

  # Established areas stay public; emerging areas and the interview-sourced
  # barriers/resource-needs card are private.
  expect_match(logged_out, "Established Areas of Wellness", fixed = TRUE)
  expect_false(grepl("Emerging Areas of Wellness", logged_out, fixed = TRUE))
  expect_false(grepl("Challenges &amp; Resource Needs", logged_out, fixed = TRUE))

  expect_match(logged_in, "Emerging Areas of Wellness", fixed = TRUE)
  expect_match(logged_in, "Challenges &amp; Resource Needs", fixed = TRUE)
  expect_match(logged_in, "Resource Needs", fixed = TRUE)
})

test_that("organization_details_ui links the org name to its website, or renders plain text", {
  withr::local_dir(project_root)

  original_ctx <- get_organization_details_context
  on.exit(
    assign("get_organization_details_context", original_ctx, envir = globalenv()),
    add = TRUE
  )

  # With a website: the org name is wrapped in an external anchor.
  assign("get_organization_details_context", function(...) {
    ctx <- original_ctx(...)
    ctx$orgname <- "Linked Org"
    ctx$website <- "https://example.org/"
    ctx
  }, envir = globalenv())
  linked <- render_html(organization_details_ui(logged_in = TRUE))
  expect_match(linked, 'href="https://example.org/"', fixed = TRUE)
  expect_match(linked, 'rel="noopener noreferrer"', fixed = TRUE)
  # Underlined at rest (via .org-website-link, not :hover) and carrying the
  # link symbol the advisory council asked for, hidden from screen readers
  # because the anchor is already named by the organization.
  expect_match(linked, 'class="org-website-link"', fixed = TRUE)
  expect_match(linked, ORG_WEBSITE_LINK_SYMBOL, fixed = TRUE)
  # The name is the anchor's own text, immediately followed by the symbol.
  # Matched with \\s* rather than as a literal: the anchor gained a tag child,
  # so htmltools now pretty-prints its contents across indented lines.
  expect_match(
    linked,
    '>\\s*Linked Org\\s*<span class="org-website-link-icon" aria-hidden="true">'
  )

  # Without a website: the name renders as plain text, not a link.
  assign("get_organization_details_context", function(...) {
    ctx <- original_ctx(...)
    ctx$orgname <- "Plain Org"
    ctx$website <- ""
    ctx
  }, envir = globalenv())
  plain <- render_html(organization_details_ui(logged_in = TRUE))
  expect_match(plain, "Plain Org", fixed = TRUE)
  expect_false(grepl(">Plain Org</a>", plain, fixed = TRUE))
  # No anchor means no link affordance either.
  expect_false(grepl("org-website-link", plain, fixed = TRUE))
  expect_false(grepl(ORG_WEBSITE_LINK_SYMBOL, plain, fixed = TRUE))
})

test_that("static assets are cache-busted so edits actually reach the browser", {
  withr::local_dir(project_root)

  # main_ui() puts the stylesheet inside tags$head(), and renderTags() lifts
  # head content into $head rather than $html -- so render_html() alone shows
  # no <link>, <title> or <meta> at all, even though Shiny serves them fine.
  # Both halves have to be checked or this measures the wrong thing.
  rendered <- htmltools::renderTags(main_ui(div()))
  markup <- paste(
    c(as.character(rendered$head), as.character(rendered$html)),
    collapse = "\n"
  )

  # Without a changing query string a CSS edit is invisible to any returning
  # visitor, which is indistinguishable from the change never having shipped.
  expect_match(markup, "/css/styles.css\\?v=[0-9]+")
  expect_match(markup, "/js/app.js\\?v=[0-9]+")
  expect_false(grepl("?v=NA", markup, fixed = TRUE))
  expect_gt(asset_version("www", "css", "styles.css"), 0L)
  expect_equal(asset_version("www", "css", "does-not-exist.css"), 0L)
})

test_that("the always-underlined rule is in the stylesheet, not left to :hover", {
  withr::local_dir(project_root)

  # The council's complaint was specifically that the underline appeared only on
  # hover. Tabler's `a { text-decoration: none }` is still in force, so the
  # override has to exist in our own stylesheet for the link to read as a link.
  css <- paste(
    readLines(file.path("www", "css", "styles.css"), warn = FALSE),
    collapse = "\n"
  )
  expect_match(css, ".org-website-link", fixed = TRUE)
  rule <- sub(
    "\\}.*", "",
    sub(".*\\.org-website-link,", "", css)
  )
  expect_match(rule, "text-decoration: underline", fixed = TRUE)
})

test_that("organization_details_ui shows the About card to logged-out visitors", {
  withr::local_dir(project_root)

  detail_data <- load_organization_details_data()
  skip_if(
    nrow(detail_data) == 0,
    "No organization in the local dataset has consented to publication."
  )
  ctx <- get_organization_details_context()
  skip_if(
    !nzchar(ctx$about %||% ""),
    "The first published organization has no About text in the local dataset."
  )
  labels <- ctx$labels

  # logged_in = FALSE: the About blurb is public, unlike the emerging card.
  html <- render_html(organization_details_ui(logged_in = FALSE))

  expect_match(html, labels$card_about_title, fixed = TRUE)
  expect_match(html, "white-space: pre-line", fixed = TRUE)

  # It sits above the Age Breakdown card, per the stakeholder request.
  about_at <- regexpr(labels$card_about_title, html, fixed = TRUE)
  age_at <- regexpr(labels$card_age_title, html, fixed = TRUE)
  expect_gt(about_at, 0L)
  expect_gt(age_at, 0L)
  expect_lt(about_at, age_at)
})

test_that("organization_details_ui explains the established wellness card", {
  withr::local_dir(project_root)

  detail_data <- load_organization_details_data()
  skip_if(
    nrow(detail_data) == 0,
    "No organization in the local dataset has consented to publication."
  )
  en <- get_lang("en")$organization_details

  html <- render_html(organization_details_ui())

  # Collapsed by default and rendered as a native <details>, so it needs no JS.
  expect_match(html, "<details", fixed = TRUE)
  expect_match(html, en$card_definition_toggle, fixed = TRUE)
  expect_match(html, substr(en$card_established_description, 1, 60), fixed = TRUE)

  # The wheel mount still carries its data attribute alongside the new sibling.
  expect_match(html, "data-active-categories", fixed = TRUE)
})

test_that("the challenges card explains itself, logged in only", {
  withr::local_dir(project_root)

  detail_data <- load_organization_details_data()
  skip_if(
    nrow(detail_data) == 0,
    "No organization in the local dataset has consented to publication."
  )
  en <- get_lang("en")$organization_details

  # Ask the data layer whether this org has anything to show, rather than
  # grepping the rendered HTML: the card title contains a literal "&", which
  # reaches the page as "&amp;" and would make the guard skip unconditionally.
  ctx <- get_organization_details_context(lang = get_lang("en"))
  skip_if(
    !length(ctx$barriers) && !length(ctx$resource_needs),
    "The first consenting organization has no interview-coded entries."
  )

  # Escaped for the same reason -- the description opens with the section name.
  intro <- htmltools::htmlEscape(
    substr(en$card_barriers_resources_description, 1, 60)
  )
  note <- htmltools::htmlEscape(substr(en$card_barriers_resources_note, 1, 60))

  # Both paragraphs render, and the scope note is its own <p> rather than being
  # run together with the explanation.
  html <- render_html(organization_details_ui(logged_in = TRUE))
  expect_match(html, intro, fixed = TRUE)
  expect_match(html, note, fixed = TRUE)

  # The card is logged-in only, so its description must not leak to visitors.
  expect_false(grepl(intro, render_html(organization_details_ui()), fixed = TRUE))
})

test_that("wellness_definition_ui renders one paragraph per element", {
  one <- render_html(wellness_definition_ui("Toggle", "Only paragraph"))
  expect_equal(lengths(regmatches(one, gregexpr("<p", one, fixed = TRUE))), 1L)
  expect_match(one, 'class="text-secondary mt-2 mb-0"', fixed = TRUE)

  two <- render_html(wellness_definition_ui("Toggle", c("First", "Second")))
  expect_equal(lengths(regmatches(two, gregexpr("<p", two, fixed = TRUE))), 2L)
  expect_match(two, ">First</p>", fixed = TRUE)
  expect_match(two, ">Second</p>", fixed = TRUE)

  # Blank entries are dropped rather than rendering an empty paragraph, and an
  # all-blank vector still yields nothing at all.
  sparse <- render_html(wellness_definition_ui("Toggle", c("Kept", "", "  ")))
  expect_equal(lengths(regmatches(sparse, gregexpr("<p", sparse, fixed = TRUE))), 1L)
  expect_null(wellness_definition_ui("Toggle", c("", "  ")))
})

test_that("the emerging definition is gated behind login with its card", {
  withr::local_dir(project_root)

  detail_data <- load_organization_details_data()
  skip_if(
    nrow(detail_data) == 0,
    "No organization in the local dataset has consented to publication."
  )
  en <- get_lang("en")$organization_details
  emerging_snippet <- substr(en$card_emerging_description, 1, 60)

  expect_false(grepl(emerging_snippet, render_html(organization_details_ui()), fixed = TRUE))
})

test_that("every supported language carries the wellness definition copy", {
  withr::local_dir(project_root)

  for (code in rownames(SUPPORTED_LANGUAGES)) {
    details <- get_lang(code)$organization_details
    for (key in c(
      "card_definition_toggle",
      "card_established_description",
      "card_emerging_description",
      "card_barriers_resources_description",
      "card_barriers_resources_note"
    )) {
      expect_true(
        nzchar(trimws(as.character(details[[key]] %||% ""))),
        info = paste(code, key)
      )
    }
  }
})

test_that("wellness_definition_ui renders nothing without body text", {
  expect_null(wellness_definition_ui("What does this mean?", ""))
  expect_null(wellness_definition_ui("What does this mean?", NULL))
})

test_that("organization_details_ui renders the first org when no id is supplied", {
  withr::local_dir(project_root)

  detail_data <- load_organization_details_data()
  skip_if(
    nrow(detail_data) == 0,
    "No organization in the local dataset has consented to publication."
  )
  first_org_name <- trimws(detail_data[["orgname"]][1])

  html <- render_html(organization_details_ui())

  expect_match(html, first_org_name, fixed = TRUE)
})

# ---- components ----

test_that("login_nav_link_ui renders a link to the login route", {
  withr::local_dir(project_root)

  html <- render_html(login_nav_link_ui())

  expect_match(html, "Login", fixed = TRUE)
  expect_match(html, "btn-primary", fixed = TRUE)
  expect_match(html, "login", fixed = TRUE)
})

test_that("organizations_list_ui renders a select with provided names", {
  withr::local_dir(project_root)

  orgs <- c("Alpha Org", "Beta Org", "Gamma Org")
  html <- render_html(organizations_list_ui(orgs))

  expect_match(html, "form-select", fixed = TRUE)
  expect_match(html, "Alpha Org", fixed = TRUE)
  expect_match(html, "Beta Org", fixed = TRUE)
  expect_match(html, "Gamma Org", fixed = TRUE)
})

test_that("organizations_list_ui renders empty select for empty input", {
  withr::local_dir(project_root)

  html <- render_html(organizations_list_ui(character(0)))

  expect_match(html, "form-select", fixed = TRUE)
  expect_false(grepl("<option", html, fixed = TRUE))
})

test_that("demographic_meter_html renders a six-slot meter, none for not_reported", {
  count_occurrences <- function(x, pat) {
    m <- gregexpr(pat, x, fixed = TRUE)[[1]]
    if (length(m) == 1 && m[[1]] == -1L) 0L else length(m)
  }
  expect_equal(count_occurrences(demographic_meter_html("none"), "<svg"), 6L)
  expect_equal(count_occurrences(demographic_meter_html("a_lot"), "<svg"), 6L)
  # filled figures carry a solid fill; A lot fills all six, A little only one
  expect_equal(count_occurrences(demographic_meter_html("a_lot"), "fill:#066fd1"), 6L)
  expect_equal(count_occurrences(demographic_meter_html("a_little"), "fill:#066fd1"), 1L)
  expect_identical(demographic_meter_html("not_reported"), "")
})

test_that("organization_details_ui shows the demographic key card whether logged in or out", {
  withr::local_dir(project_root)
  for (state in c(FALSE, TRUE)) {
    html <- render_html(organization_details_ui(logged_in = state))
    expect_match(html, "Key", fixed = TRUE)
    expect_match(html, "A little", fixed = TRUE)
    expect_match(html, "A lot", fixed = TRUE)
    expect_match(html, "61%-100%", fixed = TRUE)
    expect_match(html, "<svg", fixed = TRUE)
  }
})
