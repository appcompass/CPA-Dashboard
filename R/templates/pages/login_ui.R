login_ui <- function() {
  tagList(
    div(
      class = "page page-center py-8",
      div(
        class = "container container-tight py-8",
        div(
          class = "card card-md",
          div(
            class = "card-body",
            h2(class = "h2 text-center mb-4", "Login to your account"),
            tags$form(
              action = "./",
              method = "get",
              autocomplete = "off",
              novalidate = NA,
              div(
                class = "mb-3",
                tags$label(class = "form-label", "Organization Name"),
                uiOutput("organizations_list")
              ),
              div(
                class = "mb-2",
                tags$label(
                  class = "form-label",
                  "Organization ID",
                ),
                div(
                  class = "input-group input-group-flat",
                  tags$input(
                    type = "text",
                    class = "form-control",
                    placeholder = "Your organization ID",
                    autocomplete = "off"
                  ),
                )
              ),
              div(
                class = "form-footer",
                tags$button(type = "submit", class = "btn btn-primary w-100", "Sign in")
              )
            )
          ),
        ),
      )
    )
  )
}
