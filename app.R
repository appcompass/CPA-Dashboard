library(shiny)

source(file.path("R", "helpers.R"), local = TRUE)
source(file.path("R", "data.R"), local = TRUE)
source(file.path("R", "ui.R"), local = TRUE)
source(file.path("R", "server.R"), local = TRUE)

app <- shinyApp(
  ui = app_ui,
  server = app_server
)

app
