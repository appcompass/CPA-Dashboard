library(shiny.router)

# layout
source(file.path("R", "templates", "layout", "header_ui.R"), local = TRUE)

# pages
source(file.path("R", "templates", "pages", "home_ui.R"), local = TRUE)
source(file.path("R", "templates", "pages", "login_ui.R"), local = TRUE)
source(file.path("R", "templates", "pages", "organizations_ui.R"), local = TRUE)
source(file.path("R", "templates", "pages", "organization_details_ui.R"), local = TRUE)

# components
source(file.path("R", "templates", "components", "login_nav_link_ui.R"), local = TRUE)
source(file.path("R", "templates", "components", "organizations_list_ui.R"), local = TRUE)

router <- router_ui(
  route("/", home_ui()),
  route("login", login_ui()),
  route("organizations", organizations_ui()),
  route("organizations/details", organization_details_ui())
)

app_ui <- htmlTemplate(
  "www/html/index.html",
  page_title = "CHANGE Lab",
  router = router,
  header = header_ui()
)
