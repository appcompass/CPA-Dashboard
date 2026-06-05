app_server <- function(input, output, session) {
  dataset <- reactive({
    load_app_csv_data()
  })

  output$data_preview <- renderTable(
    {
      dataset()
    },
    striped = TRUE,
    bordered = FALSE,
    spacing = "m",
    width = "100%"
  )

  output$value_plot <- renderPlot({
    data <- dataset()

    if (!all(c("category", "value") %in% names(data))) {
      stop("The sample dataset must contain 'category' and 'value' columns.", call. = FALSE)
    }

    barplot(
      height = data$value,
      names.arg = data$category,
      col = rep_len(plot_palette, nrow(data)),
      border = NA,
      las = 2,
      ylim = c(0, max(data$value) * 1.15),
      main = "Sample data from data/sample_data.csv",
      ylab = "Value"
    )
  })
}
