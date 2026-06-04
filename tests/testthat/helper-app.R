library(shiny)

# Source app.R from the project root so that `ui` and `server` are available
# to all test files in this directory.
# Resolve the path robustly for local runs and CI.
source(normalizePath(file.path("..", "..", "app.R"), mustWork = TRUE))
