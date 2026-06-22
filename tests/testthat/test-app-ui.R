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
  expect_match(html, "Organizations", fixed = TRUE)
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
  expect_match(html, "Browse Organizations", fixed = TRUE)
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
