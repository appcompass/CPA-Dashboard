library(shiny.router)

app_server <- function(input, output, session) {
  router_server()

  # Coerce a raw URL ?lang= value to a supported code, falling back to the default.
  normalize_lang_code <- function(code) {
    if (is.null(code) || !length(code)) {
      return(DEFAULT_LANG_CODE)
    }

    code <- as.character(code[[1]])
    code <- sub("#.*$", "", code)
    code <- trimws(code)

    if (!nzchar(code) || !code %in% rownames(SUPPORTED_LANGUAGES)) {
      return(DEFAULT_LANG_CODE)
    }

    code
  }

  # Active UI language, kept in sync with the ?lang= query parameter.
  lang_code <- reactiveVal(DEFAULT_LANG_CODE)

  # URL -> state: adopt the language from the query string on load and navigation.
  observeEvent(session$clientData$url_search,
    {
      search <- session$clientData$url_search
      if (is.null(search) || !is.character(search) || length(search) != 1) {
        search <- ""
      }
      query <- shiny::parseQueryString(search)
      lang_code(normalize_lang_code(query$lang))
    },
    ignoreNULL = FALSE
  )

  # State -> URL: when the user picks a language, persist it to the query string
  # (preserving any other params and the hash) so the choice survives reloads.
  observeEvent(input$selected_lang, {
    selected_input <- input$selected_lang

    if (is.list(selected_input)) {
      selected <- normalize_lang_code(selected_input$code)
      search <- selected_input$search
      current_hash <- selected_input$hash
    } else {
      selected <- normalize_lang_code(selected_input)
      search <- session$clientData$url_search
      current_hash <- session$clientData$url_hash
    }

    lang_code(selected)

    if (is.null(search) || !is.character(search) || length(search) != 1) {
      search <- ""
    }

    query <- shiny::parseQueryString(search)
    query$lang <- selected

    query_names <- names(query)
    if (is.null(query_names) || !length(query_names)) {
      next_search <- paste0("?lang=", utils::URLencode(selected, reserved = TRUE))
    } else {
      query_parts <- vapply(
        query_names,
        function(key) {
          paste0(
            utils::URLencode(key, reserved = TRUE),
            "=",
            utils::URLencode(as.character(query[[key]]), reserved = TRUE)
          )
        },
        character(1)
      )
      next_search <- paste0("?", paste(query_parts, collapse = "&"))
    }

    if (is.null(current_hash) || !is.character(current_hash) || length(current_hash) != 1) {
      current_hash <- ""
    }

    next_url <- paste0(next_search, current_hash)

    shiny::updateQueryString(
      next_url,
      mode = "replace",
      session = session
    )
  })

  # Keep the document <title> in sync with the active route and language.
  observeEvent(list(get_page(session), lang_code()),
    {
      lang <- get_lang(lang_code())

      current_page <- get_page(session)

      if (identical(current_page, FALSE) || is.null(current_page) || !nzchar(current_page)) {
        current_page <- "/"
      }

      route_titles <- c(
        "/" = lang$header$nav_home,
        "about" = lang$header$nav_about %||% "About",
        "login" = lang$login_nav_link$label,
        "organizations" = lang$header$nav_organizations,
        "organizations/details" = lang$organization_details$org_name_placeholder
      )

      route_title <- unname(route_titles[[current_page]])
      base_title <- lang$app$page_title
      if (is.null(route_title) || !nzchar(route_title)) {
        route_title <- base_title
      }

      full_title <- if (identical(route_title, base_title)) {
        base_title
      } else {
        paste(route_title, base_title, sep = " | ")
      }

      shiny::removeUI(
        selector = "head > title",
        multiple = TRUE,
        immediate = TRUE,
        session = session
      )
      shiny::insertUI(
        selector = "head",
        where = "beforeEnd",
        ui = shiny::tags$title(full_title),
        immediate = TRUE,
        session = session
      )
    },
    ignoreNULL = FALSE
  )

  output$lang_change_nav_link <- renderUI({
    lang_change_nav_link_ui(active_code = lang_code())
  })

  output$header <- renderUI({
    header_ui(get_lang(lang_code()))
  })

  output$theme_toggle_nav_link <- renderUI({
    theme_toggle_nav_link_ui(
      search = session$clientData$url_search,
      hash = session$clientData$url_hash,
      lang = get_lang(lang_code())
    )
  })

  output$login_nav_link <- renderUI({
    req(!is_page("login"), !authenticated())
    login_nav_link_ui(get_lang(lang_code()))
  })

  # Loaded once and shared by the login org picker and login validation below.
  # Consent-gated: an organization that did not answer "Yes" to the publication
  # question is absent from both, so it cannot be selected and there is no stored
  # Dashboard ID for it to authenticate against.
  survey_data <- load_displayable_survey_data()
  org_names <- get_org_names(survey_data)
  org_dashboard_ids <- get_org_dashboard_ids(survey_data)

  output$organizations_list <- renderUI({
    req(is_page("login"))
    organizations_list_ui(org_names)
  })

  login_message <- reactiveVal(NULL)
  # Session-wide flag: once any organization logs in, the full (private) detail
  # sections are unlocked across every organization's dashboard.
  authenticated <- reactiveVal(FALSE)

  # Validate the submitted Organization ID against the Dashboard ID stored for the
  # selected organization. On success, route to that organization's dashboard.
  observeEvent(input$login_submit, {
    payload <- input$login_submit
    org <- trimws(as.character(payload$org %||% ""))
    entered_id <- trimws(as.character(payload$id %||% ""))
    login <- get_lang(lang_code())$login

    if (!nzchar(org) || !nzchar(entered_id)) {
      login_message(login$error_required %||%
        "Please select an organization and enter your Organization ID.")
      return()
    }

    expected_id <- if (org %in% names(org_dashboard_ids)) org_dashboard_ids[[org]] else ""

    if (nzchar(expected_id) && identical(tolower(entered_id), tolower(expected_id))) {
      login_message(NULL)
      authenticated(TRUE)
      change_page(
        paste0("organizations/details?id=", utils::URLencode(org, reserved = TRUE)),
        session = session
      )
    } else {
      login_message(login$error_invalid %||%
        "That Organization ID does not match the selected organization.")
    }
  })

  output$login_message <- renderUI({
    msg <- login_message()
    if (is.null(msg) || !nzchar(msg)) {
      return(NULL)
    }
    div(class = "alert alert-danger mb-3", role = "alert", msg)
  })

  output$page_home <- renderUI({
    home_ui(get_lang(lang_code()))
  })

  output$page_about <- renderUI({
    about_ui(get_lang(lang_code()))
  })

  output$page_login <- renderUI({
    login_ui(get_lang(lang_code()))
  })

  output$page_organizations <- renderUI({
    organizations_ui(get_lang(lang_code()))
  })

  output$page_organization_details <- renderUI({
    organization_details_ui(get_lang(lang_code()), logged_in = authenticated())
  })
}
