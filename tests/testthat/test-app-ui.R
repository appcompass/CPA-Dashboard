render_html <- function(ui) {
  as.character(htmltools::renderTags(ui)$html)
}

# ---- app bootstrap ----

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
  expect_match(html, "© CHANGE Lab", fixed = TRUE)
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
  expect_match(linked, ">Linked Org</a>", fixed = TRUE)
  expect_match(linked, 'rel="noopener noreferrer"', fixed = TRUE)

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
})

test_that("organization_details_ui renders the first org when no id is supplied", {
  withr::local_dir(project_root)

  detail_data <- load_organization_details_data()
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
