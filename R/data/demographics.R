# ---------------------------------------------------------------------------
# Demographic survey answers, end to end: cleaning the raw values for storage
# (clean_pct / clean_lengthserve) and collapsing the cleaned percentages back
# into the qualitative bands and figure meters the details page renders
# (pct_band / band_filled_count).
# ---------------------------------------------------------------------------

# Demographic answers: keep the "(x%-y%)" range, drop the qualitative prefix.
# None -> 0%, Don't know -> em dash, blank -> N/A.
clean_pct <- function(x) {
  x <- trimws(as.character(x %||% ""))
  if (!nzchar(x) || identical(x, "NA")) {
    return("N/A")
  }
  if (identical(x, "None")) {
    return("0%")
  }
  if (x %in% c("Don't know", "Dont know", "Don\u2019t know")) {
    return("\u2014")
  }
  inside <- regmatches(x, regexpr("\\(([^)]*)\\)", x))
  if (length(inside) && nzchar(inside)) {
    return(gsub("[()]", "", inside))
  }
  x
}

# Years-served: strip wording so the value is automation-friendly text-free.
# "8+ years" -> "8+", "4-7 years" -> "4-7", "Less than 1 year" -> "<1",
# "More than 10 years" -> ">10". Blank stays blank.
clean_lengthserve <- function(x) {
  x <- trimws(as.character(x %||% ""))
  if (!nzchar(x) || identical(x, "NA")) {
    return("")
  }
  x <- sub("\\s*years?\\s*$", "", x, ignore.case = TRUE)
  x <- trimws(x)
  x <- sub("^less than\\s*", "<", x, ignore.case = TRUE)
  x <- sub("^more than\\s*", ">", x, ignore.case = TRUE)
  trimws(x)
}

# Map a cleaned demographic percentage string to a qualitative band. The survey
# collects these as prefixed ranges ("A lot (61%-100%)"); clean_pct keeps the
# range, and this collapses the range's upper bound back to the band the
# dashboard displays. "Don't know" (the em dash) and blank / N/A become
# "not_reported". Buckets mirror the survey instrument:
#   0%        -> none
#   1%-25%    -> a_little
#   26%-60%   -> some
#   61%-100%  -> a_lot
pct_band <- function(value) {
  v <- trimws(as.character(value %||% ""))
  if (!nzchar(v) || v %in% c("NA", "N/A") || v %in% c("\u2014", "\u2013", "-")) {
    return("not_reported")
  }
  nums <- suppressWarnings(as.integer(regmatches(v, gregexpr("[0-9]+", v))[[1]]))
  nums <- nums[!is.na(nums)]
  if (!length(nums)) {
    return("not_reported")
  }
  upper <- max(nums)
  if (upper <= 0) {
    "none"
  } else if (upper <= 25) {
    "a_little"
  } else if (upper <= 60) {
    "some"
  } else {
    "a_lot"
  }
}

# Number of filled figures (out of a fixed six) for each band's meter. A band of
# "not_reported" renders no meter, so it is intentionally absent here.
band_filled_count <- function(band) {
  switch(band,
    none = 0L,
    a_little = 1L,
    some = 3L,
    a_lot = 6L,
    0L
  )
}
