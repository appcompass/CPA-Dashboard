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

test_that("login validates the Organization ID against the Dashboard ID", {
  withr::local_dir(project_root)

  testServer(app_server, {
    session$flushReact()
    # Derive a real org + its dashboard id from the loaded lookup, so the test
    # holds for both the local dataset and the CI fixture.
    org <- names(org_dashboard_ids)[[1]]
    valid_id <- unname(org_dashboard_ids[[1]])

    # Wrong ID: stays logged out with the mismatch message.
    session$setInputs(login_submit = list(org = org, id = "definitely-wrong-id"))
    expect_false(authenticated())
    expect_match(login_message(), "does not match", fixed = TRUE)

    # Missing fields: prompts for both.
    session$setInputs(login_submit = list(org = "", id = ""))
    expect_false(authenticated())
    expect_match(login_message(), "select an organization", fixed = TRUE)

    # Correct ID (case-insensitive): authenticates and clears the message.
    session$setInputs(login_submit = list(org = org, id = toupper(valid_id)))
    expect_true(authenticated())
    expect_null(login_message())
  })
})

test_that("app_server hides the login nav link once authenticated", {
  withr::local_dir(project_root)

  testServer(app_server, {
    session$flushReact()
    expect_match(output$login_nav_link[[1]], "Login", fixed = TRUE)

    authenticated(TRUE)
    session$flushReact()
    expect_null(safe_output(output$login_nav_link))
  })
})
