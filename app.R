library(shiny)

ui <- fluidPage(
  tags$head(
    tags$script(src = "https://cdn.jsdelivr.net/npm/vue@3.4.38/dist/vue.global.prod.js"),
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
        const appInstance = app.mount('#vue-app');
        if (window.Shiny && window.Shiny.addCustomMessageHandler) {
          window.Shiny.addCustomMessageHandler('backendMessage', function(message) {
            if (appInstance) {
              appInstance.backendMessage = message;
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
  session$onFlushed(function() {
    session$sendCustomMessage("backendMessage", "Shiny backend connected")
  }, once = TRUE)

  output$backend_clicks <- renderText({
    clicks <- if (is.null(input$vue_clicks)) 0 else input$vue_clicks
    paste("Received from Vue:", clicks)
  })
}

shinyApp(ui = ui, server = server)
