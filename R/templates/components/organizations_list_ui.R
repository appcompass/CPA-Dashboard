organizations_list_ui <- function(org_names) {
  org_options <- lapply(org_names, function(name) {
    tags$option(value = name, name)
  })

  tags$select(
    id = "organization_name",
    name = "organization_name",
    class = "form-select",
    org_options
  )
}
