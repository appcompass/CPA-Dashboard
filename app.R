library(shiny)

# addResourcePath("img", normalizePath(file.path("www", "img"), mustWork = TRUE))

source(file.path("R", "helpers.R"), local = TRUE)
source(file.path("R", "data.R"), local = TRUE)
source(file.path("R", "lang.R"), local = TRUE)
source(file.path("R", "ui.R"), local = TRUE)
source(file.path("R", "server.R"), local = TRUE)

dotenv_path <- ".env"
if (!nzchar(Sys.getenv("CPA_DATA_KEY")) && file.exists(dotenv_path)) {
  env_lines <- readLines(dotenv_path, warn = FALSE)
  key_line <- grep("^(export[[:space:]]+)?CPA_DATA_KEY=", env_lines, value = TRUE)
  if (length(key_line) > 0) {
    key_value <- sub("^(export[[:space:]]+)?CPA_DATA_KEY=", "", key_line[[1]])
    key_value <- trimws(key_value)
    key_value <- sub('^"(.*)"$', "\\1", key_value)
    key_value <- sub("^'(.*)'$", "\\1", key_value)
    if (nzchar(key_value)) {
      Sys.setenv(CPA_DATA_KEY = key_value)
    }
  }
}

assert_survey_data_startup_ready()

app <- shinyApp(
  ui = app_ui,
  server = app_server
)

app
