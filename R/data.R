load_survey_data <- function(path = file.path("data", "survey_data.csv")) {
  if (!file.exists(path)) {
    stop(sprintf("Expected survey data file at '%s'.", path), call. = FALSE)
  }

  read.csv(path, skip = 2, header = FALSE, stringsAsFactors = FALSE)
}

get_org_names <- function(survey_data = load_survey_data()) {
  names <- sort(unique(trimws(survey_data[[1]])))
  names[nzchar(names)]
}
