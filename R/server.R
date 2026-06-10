library(shiny.router)

app_server <- function(input, output, session) {
  router_server()

  output$organization_details <- renderUI({
    req(is_page("organizations/{id}"))

    id <- get_query_param("id")
  })
}
