test_that("load_app_csv_data reads the sample dataset", {
  withr::local_dir(project_root)

  data <- load_app_csv_data()

  expect_s3_class(data, "data.frame")
  expect_named(data, c("category", "value"))
  expect_equal(nrow(data), 4L)
  expect_equal(data$category[[1]], "Baseline")
  expect_equal(data$value[[4]], 27)
})

test_that("load_app_csv_data fails clearly for a missing file", {
  withr::local_dir(project_root)

  expect_error(
    load_app_csv_data(tempfile(fileext = ".csv")),
    "Expected data file"
  )
})
