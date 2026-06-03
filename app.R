library(shiny)

ui <- fluidPage(
  tags$head(
    tags$script(src = "https://unpkg.com/vue@3/dist/vue.global.prod.js"),
    tags$script(HTML("
      document.addEventListener('DOMContentLoaded', function () {
        const { createApp } = Vue;
        const app = createApp({
          data() {
            return {
              title: 'CPA Dashboard',
              clicks: 0,
              backendMessage: 'Waiting for Shiny...'
            };
          },
          methods: {
            sendClick() {
              this.clicks += 1;
              if (window.Shiny && window.Shiny.setInputValue) {
                window.Shiny.setInputValue('vue_clicks', this.clicks, {priority: 'event'});
              }
            }
          }
        });
        window.vueApp = app.mount('#vue-app');
        if (window.Shiny && window.Shiny.addCustomMessageHandler) {
          window.Shiny.addCustomMessageHandler('backendMessage', function(message) {
            if (window.vueApp) {
              window.vueApp.backendMessage = message;
            }
          });
        }
      });
    "))
  ),
  tags$div(
    id = "vue-app",
    tags$h2("{{ title }}"),
    tags$p("Backend says: {{ backendMessage }}"),
    tags$p("Vue click count: {{ clicks }}"),
    tags$button(type = "button", "@click" = "sendClick", "Send click to Shiny")
  ),
  hr(),
  tags$p("Shiny backend click count:"),
  textOutput("backend_clicks")
)

server <- function(input, output, session) {
  observe({
    session$sendCustomMessage("backendMessage", "Shiny backend connected")
  }, once = TRUE)

  output$backend_clicks <- renderText({
    clicks <- if (is.null(input$vue_clicks)) 0 else input$vue_clicks
    paste("Received from Vue:", clicks)
  })
}

shinyApp(ui = ui, server = server)
