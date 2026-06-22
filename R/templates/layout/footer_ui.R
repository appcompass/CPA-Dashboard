footer_ui <- function() {
  tags$footer(
    class = "footer footer-transparent d-print-none",
    div(
      class = "container-xl",
      div(
        class = "row text-center align-items-center flex-row-reverse",
        div(class = "col-lg-auto ms-lg-auto"),
        div(
          class = "col-12 col-lg-auto mt-3 mt-lg-0",
          tags$ul(
            class = "list-inline list-inline-dots mb-0",
            tags$li(
              class = "list-inline-item",
              sprintf("%s © CHANGE Lab", format(Sys.Date(), "%Y"))
            )
          )
        )
      )
    )
  )
}
