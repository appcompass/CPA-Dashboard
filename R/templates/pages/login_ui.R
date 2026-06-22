# Login page: organization picker + Organization ID. The form posts its values
# to Shiny (input$login_submit), which validates them in server.R.
login_ui <- function(lang = get_lang()) {
  login <- lang$login

  tagList(
    div(
      class = "page page-center py-8",
      div(
        class = "container container-tight py-8",
        div(
          class = "card card-md",
          div(
            class = "card-body",
            h2(class = "h2 text-center mb-4", login$heading),
            tags$form(
              id = "login_form",
              action = "./",
              method = "get",
              autocomplete = "off",
              novalidate = NA,
              # Read the two fields straight from the DOM and hand them to Shiny on
              # submit; return false so the browser does not also do a GET navigation.
              onsubmit = paste0(
                "Shiny.setInputValue('login_submit', {",
                "org: (document.getElementById('organization_name') || {value: ''}).value, ",
                "id: (document.getElementById('organization_id') || {value: ''}).value",
                "}, {priority: 'event'}); return false;"
              ),
              uiOutput("login_message"),
              div(
                class = "mb-3",
                tags$label(class = "form-label", login$label_organization_name),
                uiOutput("organizations_list")
              ),
              div(
                class = "mb-2",
                tags$label(
                  class = "form-label",
                  login$label_organization_id,
                ),
                div(
                  class = "input-group input-group-flat",
                  tags$input(
                    id = "organization_id",
                    type = "text",
                    class = "form-control",
                    placeholder = login$placeholder_org_id,
                    autocomplete = "off"
                  ),
                )
              ),
              div(
                class = "form-footer",
                tags$button(type = "submit", class = "btn btn-primary w-100", login$btn_sign_in)
              )
            )
          ),
        ),
      )
    )
  )
}
