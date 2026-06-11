# When req() fails inside renderUI, testServer throws instead of returning NULL.
# safe_output captures that and returns NULL so we can assert the output is absent.
safe_output <- function(expr) tryCatch(expr, error = function(e) NULL)

test_that("app_server shows login nav link on non-login pages", {
  withr::local_dir(project_root)

  testServer(app_server, {
    session$flushReact()

    # Default page is "/"; [[1]] extracts the HTML string from the renderUI list
    html <- output$login_nav_link[[1]]
    expect_match(html, "Login", fixed = TRUE)
    expect_match(html, "btn-primary", fixed = TRUE)
  })
})

test_that("app_server hides login nav link on the login page", {
  withr::local_dir(project_root)

  testServer(app_server, {
    session$userData$shiny.router.page(
      list(path = "login", query = NULL, unparsed = "#!/login")
    )
    session$flushReact()

    expect_null(safe_output(output$login_nav_link))
  })
})

test_that("app_server renders organizations select on login page", {
  withr::local_dir(project_root)

  testServer(app_server, {
    session$userData$shiny.router.page(
      list(path = "login", query = NULL, unparsed = "#!/login")
    )
    session$flushReact()

    html <- output$organizations_list[[1]]
    expect_match(html, "form-select", fixed = TRUE)
    expect_match(html, "<option", fixed = TRUE)
  })
})

test_that("app_server hides organizations select on non-login pages", {
  withr::local_dir(project_root)

  testServer(app_server, {
    session$flushReact()

    # Default page is "/" so is_page("login") is FALSE — req() throws
    expect_null(safe_output(output$organizations_list))
  })
})
