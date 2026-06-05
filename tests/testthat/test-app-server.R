test_that("app_server renders the sample preview and plot", {
  withr::local_dir(project_root)

  testServer(app_server, {
    session$flushReact()

    preview_html <- output$data_preview
    plot_output <- output$value_plot

    expect_match(preview_html, "<table", fixed = TRUE)
    expect_match(preview_html, "Baseline", fixed = TRUE)
    expect_type(plot_output, "list")
    expect_true(all(c("src", "width", "height") %in% names(plot_output)))
  })
})

test_that("app_server surfaces invalid dataset columns", {
  withr::local_dir(project_root)

  original_loader <- load_app_csv_data
  on.exit(assign("load_app_csv_data", original_loader, envir = .GlobalEnv), add = TRUE)

  assign(
    "load_app_csv_data",
    function(path = file.path("data", "sample_data.csv")) {
      data.frame(label = "Only one column", stringsAsFactors = FALSE)
    },
    envir = .GlobalEnv
  )

  testServer(app_server, {
    session$flushReact()

    expect_error(
      output$value_plot,
      "must contain 'category' and 'value' columns"
    )
  })
})
