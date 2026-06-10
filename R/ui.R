library(shiny.router)

source(file.path("R", "templates", "home_ui.R"), local = TRUE)
source(file.path("R", "templates", "login_ui.R"), local = TRUE)
source(file.path("R", "templates", "organizations_ui.R"), local = TRUE)
source(file.path("R", "templates", "organization_details_ui.R"), local = TRUE)
source(file.path("R", "templates", "header_ui.R"), local = TRUE)

router <- router_ui(
  route("/", home_ui()),
  route("login", login_ui()),
  route("organizations", organizations_ui()),
  route("organizations/{id}", organization_details_ui())
)

app_ui <- htmlTemplate(
  "www/html/index.html",
  page_title = "My App", router = router, header = header_ui()
)
