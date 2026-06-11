app_title <- "CHANGE Lab CPA Dashboard"

plot_palette <- c("#0F62FE", "#4589FF", "#78A9FF", "#A6C8FF")

load_app_csv_data <- function(path = file.path("data", "sample_data.csv")) {
  if (!file.exists(path)) {
    stop(sprintf("Expected data file at '%s'.", path), call. = FALSE)
  }

  read.csv(path, stringsAsFactors = FALSE)
}
