app_ui <- function() {
  fluidPage(
    tags$head(
      tags$title(app_title),
      tags$link(rel = "stylesheet", type = "text/css", href = "css/styles.css"),
      tags$script(src = "js/app.js")
    ),
    div(
      class = "app-shell",
      div(
        class = "hero panel",
        includeHTML(file.path("www", "html", "intro.html"))
      ),
      fluidRow(
        column(
          width = 5,
          div(
            class = "panel",
            h2("Dataset preview"),
            p("Loaded directly from the dedicated data/ folder."),
            tableOutput("data_preview")
          )
        ),
        column(
          width = 7,
          div(
            class = "panel",
            h2("Values by category"),
            plotOutput("value_plot", height = "320px")
          )
        )
      ),
      div(
        class = "footer panel",
        includeHTML(file.path("www", "html", "footer.html"))
      )
    )
  )
}
