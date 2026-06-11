library(shiny.router)

app_server <- function(input, output, session) {
  router_server()

  base_title <- "CHANGE Lab"
  route_titles <- c(
    "/" = "Home",
    "login" = "Login",
    "organizations" = "Organizations",
    "organizations/details" = "Organization Details"
  )

  observeEvent(get_page(session), {
    current_page <- get_page(session)

    if (identical(current_page, FALSE) || is.null(current_page) || !nzchar(current_page)) {
      current_page <- "/"
    }

    route_title <- unname(route_titles[[current_page]])
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
  }, ignoreNULL = FALSE)

  output$login_nav_link <- renderUI({
    req(!is_page("login"))
    login_nav_link_ui()
  })

  org_names <- get_org_names()

  output$organizations_list <- renderUI({
    req(is_page("login"))
    organizations_list_ui(org_names)
  })

  output$organization_details <- renderUI({
    req(is_page("organizations/details"))

    id <- get_query_param("id")
    req(!is.null(id), nzchar(id))
  })
}
