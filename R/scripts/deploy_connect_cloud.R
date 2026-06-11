required_env <- c(
  "POSIT_CONNECT_ACCOUNT",
  "RSCLOUD_CLIENT_ID",
  "RSCLOUD_CLIENT_SECRET",
  "CPA_DATA_KEY"
)

missing_env <- required_env[!nzchar(Sys.getenv(required_env))]
if (length(missing_env) > 0) {
  stop(
    sprintf(
      "Missing required environment variables for deploy: %s",
      paste(missing_env, collapse = ", ")
    ),
    call. = FALSE
  )
}

if (!requireNamespace("rsconnect", quietly = TRUE)) {
  install.packages("rsconnect", repos = "https://cloud.r-project.org")
}

source(file.path("R", "scripts", "write_manifest.R"), local = TRUE)

account_name <- Sys.getenv("POSIT_CONNECT_ACCOUNT")
client_id <- Sys.getenv("RSCLOUD_CLIENT_ID")
client_secret <- Sys.getenv("RSCLOUD_CLIENT_SECRET")
app_name <- Sys.getenv("POSIT_CONNECT_APP_NAME", "cpa-dashboard")
app_title <- Sys.getenv("POSIT_CONNECT_APP_TITLE", "CPA Dashboard")

rsconnect::connectCloudClientCredentials(
  clientId = client_id,
  clientSecret = client_secret,
  accountName = account_name,
  name = account_name,
  quiet = TRUE
)

app_files <- build_manifest_app_files()

rsconnect::writeManifest(
  appDir = ".",
  appPrimaryDoc = "app.R",
  appFiles = app_files
)

rsconnect::deployApp(
  appDir = ".",
  appFiles = app_files,
  appPrimaryDoc = "app.R",
  appName = app_name,
  appTitle = app_title,
  account = account_name,
  envVars = c("CPA_DATA_KEY"),
  forceUpdate = TRUE,
  launch.browser = FALSE,
  logLevel = "normal"
)
