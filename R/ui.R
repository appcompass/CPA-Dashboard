library(shiny.router)

# layout
source(file.path("R", "templates", "layout", "header_ui.R"), local = TRUE)

# pages
source(file.path("R", "templates", "pages", "home_ui.R"), local = TRUE)
source(file.path("R", "templates", "pages", "login_ui.R"), local = TRUE)
source(file.path("R", "templates", "pages", "organizations_ui.R"), local = TRUE)
source(file.path("R", "templates", "pages", "organization_details_ui.R"), local = TRUE)

# components
source(file.path("R", "templates", "components", "lang_change_nav_link_ui.R"), local = TRUE)
source(file.path("R", "templates", "components", "theme_toggle_nav_link_ui.R"), local = TRUE)
source(file.path("R", "templates", "components", "login_nav_link_ui.R"), local = TRUE)
source(file.path("R", "templates", "components", "organizations_list_ui.R"), local = TRUE)

router <- router_ui(
  route("/", home_ui()),
  route("login", uiOutput("page_login")),
  route("organizations", uiOutput("page_organizations")),
  route("organizations/details", uiOutput("page_organization_details"))
)

app_ui <- htmlTemplate(
  "www/html/index.html",
  page_title = "CHANGE Lab",
  router = router,
  header = uiOutput("header"),
  frontend_translations_script = tags$script(
    HTML(sprintf("window.APP_TRANSLATIONS = %s;", get_frontend_translations_json()))
  )
)
