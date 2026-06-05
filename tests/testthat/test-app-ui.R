test_that("app_ui includes the separated assets and outputs", {
  withr::local_dir(project_root)

  rendered <- htmltools::renderTags(app_ui())
  html <- rendered$html
  head_html <- rendered$head

  expect_match(head_html, "css/styles\\.css")
  expect_match(head_html, "js/app\\.js")
  expect_match(html, "Dataset preview", fixed = TRUE)
  expect_match(html, "Values by category", fixed = TRUE)
  expect_match(html, "data_preview", fixed = TRUE)
  expect_match(html, "value_plot", fixed = TRUE)
})

test_that("app.R builds a shiny app object", {
  withr::local_dir(project_root)

  app_env <- new.env(parent = globalenv())

  sys.source(file.path(project_root, "app.R"), envir = app_env)

  expect_true(inherits(app_env$app, "shiny.appobj"))
})
