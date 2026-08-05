# ---------------------------------------------------------------------------
# Tiny generic helpers shared across the data modules.
# ---------------------------------------------------------------------------

# NULL / empty / single-NA coalescing operator used throughout the data layer.
`%||%` <- function(a, b) {
  if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a
}

# Escape regex metacharacters so a string can be matched literally in a pattern.
escape_regex <- function(s) gsub("([][{}()*+?.\\^$|])", "\\\\\\1", s)

# Stop with the standard install hint when any of the given packages is not
# installed. Shared by every function that needs openssl/digest/jsonlite at
# call time (assert_survey_data_startup_ready keeps its own, more specific
# startup-check messages).
assert_packages_installed <- function(...) {
  for (pkg in c(...)) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      stop(sprintf("Package '%s' is required. Run make install.", pkg), call. = FALSE)
    }
  }
  invisible(TRUE)
}
