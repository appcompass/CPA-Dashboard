library(testthat)
library(shiny)

test_that("shinyApp() returns a valid shiny.appobj", {
  app <- shinyApp(ui = ui, server = server)
  expect_s3_class(app, "shiny.appobj")
})

test_that("backend_clicks defaults to 0 when vue_clicks is not set", {
  testServer(server, {
    expect_equal(output$backend_clicks, "Received from Vue: 0")
  })
})

test_that("backend_clicks reflects the provided vue_clicks value", {
  testServer(server, {
    session$setInputs(vue_clicks = 5)
    expect_equal(output$backend_clicks, "Received from Vue: 5")
  })
})

test_that("backend_clicks handles multiple different vue_clicks values", {
  testServer(server, {
    session$setInputs(vue_clicks = 1)
    expect_equal(output$backend_clicks, "Received from Vue: 1")

    session$setInputs(vue_clicks = 42)
    expect_equal(output$backend_clicks, "Received from Vue: 42")
  })
})
