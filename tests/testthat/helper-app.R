library(shiny)
library(testthat)

project_root <- normalizePath(
  file.path(getwd(), "..", ".."),
  winslash = "/",
  mustWork = TRUE
)

source(file.path(project_root, "R", "helpers.R"), local = FALSE)
source(file.path(project_root, "R", "ui.R"), local = FALSE)
source(file.path(project_root, "R", "server.R"), local = FALSE)
