# Guards against "translated nowhere" regressions: every user-facing language
# must carry exactly the same keys as the English source, and every interview
# content item must be translated into every supported language.

flatten_keys <- function(x, prefix = "") {
  if (is.list(x) && !is.null(names(x)) && length(x)) {
    unlist(lapply(names(x), function(n) {
      flatten_keys(x[[n]], paste0(prefix, if (nzchar(prefix)) "." else "", n))
    }))
  } else {
    prefix
  }
}

test_that("every supported language has the same keys as English", {
  withr::local_dir(project_root)

  en_keys <- flatten_keys(
    jsonlite::fromJSON("data/translations/en.json", simplifyVector = FALSE)
  )
  codes <- rownames(SUPPORTED_LANGUAGES)

  for (code in codes) {
    path <- file.path("data", "translations", paste0(code, ".json"))
    expect_true(file.exists(path), info = paste("missing file for", code))
    keys <- flatten_keys(jsonlite::fromJSON(path, simplifyVector = FALSE))
    expect_setequal(keys, en_keys)
  }
})

test_that("interview content is translated into every supported language", {
  withr::local_dir(project_root)

  path <- file.path("data", "interview_translations.json")
  expect_true(file.exists(path))
  content <- jsonlite::fromJSON(path, simplifyVector = FALSE)
  codes <- rownames(SUPPORTED_LANGUAGES)

  expect_gt(length(content), 0)
  for (key in names(content)) {
    entry <- content[[key]]
    missing <- setdiff(codes, names(entry))
    expect_length(missing, 0)
    empties <- Filter(function(v) !nzchar(trimws(as.character(v %||% ""))), entry)
    expect_length(empties, 0)
  }
})
