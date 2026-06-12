render_html <- function(ui) {
  as.character(htmltools::renderTags(ui)$html)
}

ensure_survey_data_csv <- function() {
  survey_csv <- file.path(project_root, "data", "survey_data.csv")
  if (file.exists(survey_csv)) {
    return(survey_csv)
  }

  decrypt_data_file(
    encrypted_path = file.path(project_root, "data", "survey_data.csv.enc"),
    output_path = survey_csv
  )
  withr::defer(unlink(survey_csv), envir = testthat::teardown_env())

  survey_csv
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

test_that("home_ui renders welcome heading", {
  withr::local_dir(project_root)

  html <- render_html(home_ui())

  expect_match(html, "Welcome to the CPA Dashboard", fixed = TRUE)
  expect_match(html, "home page", fixed = TRUE)
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
  expect_match(html, "Established Areas", fixed = TRUE)
  expect_match(html, "Confirm Filter", fixed = TRUE)
})

test_that("organization_details_ui renders detail cards", {
  withr::local_dir(project_root)

  detail_data <- read.csv(ensure_survey_data_csv(), skip = 1, stringsAsFactors = FALSE)
  first_org_name <- trimws(detail_data[[1]][1])
  first_org_years <- trimws(detail_data[[2]][1])

  html <- render_html(organization_details_ui())

  expect_match(html, first_org_name, fixed = TRUE)
  expect_match(html, first_org_years, fixed = TRUE)
  expect_match(html, "Age Breakdown", fixed = TRUE)
  expect_match(html, "Established Areas of Wellness", fixed = TRUE)
  expect_match(html, "Emerging Areas of Wellness", fixed = TRUE)
})

test_that("organization_details_ui renders the first org when no id is supplied", {
  withr::local_dir(project_root)

  detail_data <- read.csv(ensure_survey_data_csv(), skip = 1, stringsAsFactors = FALSE)
  first_org_name <- trimws(detail_data[[1]][1])

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
