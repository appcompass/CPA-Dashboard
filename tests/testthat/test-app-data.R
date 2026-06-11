# ---- load_survey_data ----

test_that("load_survey_data returns a data frame with organization column", {
  withr::local_dir(project_root)

  data <- load_survey_data()

  expect_s3_class(data, "data.frame")
  expect_gt(nrow(data), 0L)
  expect_true(any(nzchar(trimws(data[[1]]))))
})

test_that("load_survey_data fails clearly for a missing file", {
  withr::local_dir(project_root)

  expect_error(
    load_survey_data(tempfile(fileext = ".csv")),
    "Expected survey data file"
  )
})

# ---- get_org_names ----

test_that("get_org_names returns a sorted character vector of unique names", {
  withr::local_dir(project_root)

  orgs <- get_org_names()

  expect_type(orgs, "character")
  expect_gt(length(orgs), 0L)
  expect_equal(orgs, sort(unique(orgs)))
  expect_true(all(nzchar(orgs)))
})

test_that("get_org_names trims whitespace and removes blank entries", {
  fake <- data.frame(V1 = c("  Alpha Org ", "Beta Org", "", "  ", "Alpha Org"),
                     stringsAsFactors = FALSE)

  orgs <- get_org_names(fake)

  expect_equal(orgs, c("Alpha Org", "Beta Org"))
})

test_that("get_org_names deduplicates names", {
  fake <- data.frame(V1 = c("Org A", "Org B", "Org A"),
                     stringsAsFactors = FALSE)

  expect_equal(get_org_names(fake), c("Org A", "Org B"))
})

test_that("get_org_names returns empty vector for all-blank input", {
  fake <- data.frame(V1 = c("", "  "), stringsAsFactors = FALSE)

  expect_equal(get_org_names(fake), character(0))
})
