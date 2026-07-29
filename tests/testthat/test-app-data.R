# ---- load_survey_data (clean named schema) ----

test_that("load_survey_data returns a data frame with an orgname column", {
  withr::local_dir(project_root)
  data <- load_survey_data()
  expect_s3_class(data, "data.frame")
  expect_gt(nrow(data), 0L)
  expect_true("orgname" %in% names(data))
  expect_true(any(nzchar(trimws(data[["orgname"]]))))
})

test_that("load_survey_data fails clearly for a missing file", {
  withr::local_dir(project_root)
  expect_error(
    load_survey_data(encrypted_path = tempfile(fileext = ".enc")),
    "Expected encrypted survey data file"
  )
})

test_that("load_survey_data reads an encrypted clean file when present", {
  withr::local_dir(project_root)
  plain <- tempfile(fileext = ".csv")
  enc <- tempfile(fileext = ".enc")
  passphrase <- "test-key"
  writeLines(c("orgname,lengthserve", "Org A,8+", "Org B,4-7"), plain)
  encrypt_data_file(input_path = plain, output_path = enc, passphrase = passphrase)
  data <- load_survey_data(encrypted_path = enc, passphrase = passphrase)
  expect_equal(nrow(data), 2L)
  expect_equal(data[["orgname"]], c("Org A", "Org B"))
})

test_that("load_survey_data fails for encrypted file when key is missing", {
  withr::local_dir(project_root)
  plain <- tempfile(fileext = ".csv")
  enc <- tempfile(fileext = ".enc")
  writeLines(c("orgname,lengthserve", "Org A,8+"), plain)
  encrypt_data_file(input_path = plain, output_path = enc, passphrase = "secret")
  expect_error(
    load_survey_data(encrypted_path = enc, passphrase = ""),
    "Found encrypted data"
  )
})

# ---- get_org_names ----

test_that("get_org_names returns a sorted unique character vector", {
  withr::local_dir(project_root)
  orgs <- get_org_names()
  expect_type(orgs, "character")
  expect_gt(length(orgs), 0L)
  expect_equal(orgs, sort(unique(orgs)))
  expect_true(all(nzchar(orgs)))
})

test_that("get_org_names trims whitespace and drops blanks", {
  fake <- data.frame(
    orgname = c("  Alpha Org ", "Beta Org", "", "  ", "Alpha Org"),
    stringsAsFactors = FALSE
  )
  expect_equal(get_org_names(fake), c("Alpha Org", "Beta Org"))
})

test_that("get_org_names deduplicates names", {
  fake <- data.frame(orgname = c("Org A", "Org B", "Org A"), stringsAsFactors = FALSE)
  expect_equal(get_org_names(fake), c("Org A", "Org B"))
})

# ---- demographic cleaning ----

test_that("clean_pct keeps the range and maps the sentinels", {
  expect_equal(clean_pct("A lot (61%-100%)"), "61%-100%")
  expect_equal(clean_pct("Some (26%-60%)"), "26%-60%")
  expect_equal(clean_pct("A little (1%-25%)"), "1%-25%")
  expect_equal(clean_pct("None"), "0%")
  expect_equal(clean_pct("Don't know"), "\u2014")
  expect_equal(clean_pct(""), "N/A")
  expect_equal(clean_pct(NA), "N/A")
})

# ---- years-served cleaning (text-free for downstream automation) ----

test_that("clean_lengthserve strips wording", {
  expect_equal(clean_lengthserve("8+ years"), "8+")
  expect_equal(clean_lengthserve("4-7 years"), "4-7")
  expect_equal(clean_lengthserve("1-3 years"), "1-3")
  expect_equal(clean_lengthserve("Less than 1 year"), "<1")
  expect_equal(clean_lengthserve("More than 10 years"), ">10")
  expect_equal(clean_lengthserve(""), "")
})

# ---- raw export -> clean scalar schema ----

test_that("read_qualtrics_export drops the 3 header rows and preserves names", {
  raw_csv <- tempfile(fileext = ".csv")
  writeLines(c(
    "Dashboard ID,Organization,YearsServed,Age#1_1",
    "DID,Org,Years,Age q",
    '{"ImportId":"a"},{"ImportId":"b"},{"ImportId":"c"},{"ImportId":"d"}',
    "D1,Org Alpha ,8+ years,A lot (61%-100%)"
  ), raw_csv)
  raw <- read_qualtrics_export(raw_csv)
  expect_equal(nrow(raw), 1L)
  expect_equal(trimws(raw[["Organization"]][1]), "Org Alpha")
  expect_true("Age#1_1" %in% names(raw))
})

test_that("build_clean_survey emits the named schema including orgservices_json", {
  vals <- c("D1", "Org Alpha ", "8+ years", "A lot (61%-100%)")
  cols <- c("Dashboard ID", "Organization", "YearsServed", "Age#1_1")
  raw <- as.data.frame(as.list(setNames(vals, cols)), stringsAsFactors = FALSE, check.names = FALSE)
  clean <- build_clean_survey(raw)
  expect_equal(clean$orgname, "Org Alpha")
  expect_equal(clean$lengthserve, "8+")
  expect_equal(clean$pct_age_12_17, "61%-100%")
  expect_true("orgservices_json" %in% names(clean))
  parsed <- jsonlite::fromJSON(clean$orgservices_json[1], simplifyVector = FALSE)
  expect_length(parsed, 8L)
  expect_equal(parsed$emotional$state, "none")
})

# ---- per-dimension services + state (orgservices) ----

test_that("parse_services splits canonical comma-joined selections", {
  expect_equal(
    parse_services("Mental health support groups,Crisis intervention,Counseling services", "", "emotional"),
    c("Mental health support groups", "Crisis intervention", "Counseling services")
  )
})

test_that("parse_services preserves the comma-containing Intellectual option", {
  out <- parse_services("Educational workshops, e.g., STEM classes, etc,Tutoring", "", "intellectual")
  expect_true("Educational workshops, e.g., STEM classes, etc" %in% out)
  expect_true("Tutoring" %in% out)
  expect_length(out, 2L)
})

test_that("parse_services replaces Other with the verbatim free text", {
  out <- parse_services("Tutoring,Other (please specify):", "Chess club", "intellectual")
  expect_true("Chess club" %in% out)
  expect_false(any(grepl("Other", out)))
})

test_that("parse_services returns empty for None or blank", {
  expect_length(parse_services("None", "", "social"), 0L)
  expect_length(parse_services("", "", "social"), 0L)
})

test_that("build_orgservices_json derives state from EorE then Gap", {
  cols <- c(
    "EmotionalEorE", "EmotionalGap", "Emotional", "Emotional_5_TEXT",
    "PhysicalEorE", "PhysicalGap", "Physical", "Physical_5_TEXT",
    "SocialEorE", "SocialGap", "Social", "Social_5_TEXT",
    "FinancialEorE", "FinancialGap", "Financial", "Financial_5_TEXT"
  )
  vals <- c(
    "Established", "", "Counseling services", "",
    "Emerging", "", "Fitness programs", "",
    "", "Yes", "None", "",
    "", "No, please share why:", "None", ""
  )
  row <- as.data.frame(as.list(setNames(vals, cols)), stringsAsFactors = FALSE, check.names = FALSE)
  parsed <- jsonlite::fromJSON(build_orgservices_json(row), simplifyVector = FALSE)
  expect_equal(parsed$emotional$state, "established")
  expect_equal(parsed$physical$state, "emerging")
  expect_equal(parsed$social$state, "wants")
  expect_equal(parsed$financial$state, "not_interested")
  expect_equal(parsed$intellectual$state, "none")
  expect_equal(parsed$emotional$services[[1]], "Counseling services")
  expect_length(parsed$social$services, 0L)
})

# ---- cumulative append / merge ----

test_that("merge_survey_data appends new orgs and dedups by dashboard_id (newest wins)", {
  existing <- data.frame(
    dashboard_id = c("D1", "D2"), orgname = c("A", "B"),
    pct_women = c("0%", "26%-60%"), stringsAsFactors = FALSE
  )
  new_rows <- data.frame(
    dashboard_id = c("D2", "D3"), orgname = c("B", "C"),
    pct_women = c("61%-100%", "1%-25%"), stringsAsFactors = FALSE
  )
  merged <- merge_survey_data(existing, new_rows)
  expect_equal(sort(merged$dashboard_id), c("D1", "D2", "D3"))
  expect_equal(merged$pct_women[merged$dashboard_id == "D2"], "61%-100%")
  expect_equal(nrow(merged), 3L)
})

test_that("merge_survey_data falls back to orgname when dashboard_id is blank", {
  existing <- data.frame(dashboard_id = "", orgname = "A", pct_women = "0%", stringsAsFactors = FALSE)
  new_rows <- data.frame(dashboard_id = "", orgname = "A", pct_women = "26%-60%", stringsAsFactors = FALSE)
  merged <- merge_survey_data(existing, new_rows)
  expect_equal(nrow(merged), 1L)
  expect_equal(merged$pct_women, "26%-60%")
})

test_that("merge_survey_data returns new rows when there is no existing data", {
  new_rows <- data.frame(dashboard_id = "D1", orgname = "A", stringsAsFactors = FALSE)
  expect_equal(nrow(merge_survey_data(NULL, new_rows)), 1L)
  expect_equal(nrow(merge_survey_data(new_rows[0, ], new_rows)), 1L)
})

test_that("build_encrypted_survey accumulates across two weekly runs", {
  write_raw_export <- function(path, dashboard_id, organization, yearsserved, age11) {
    writeLines(c(
      "Dashboard ID,Organization,YearsServed,Age#1_1",
      "DID,Org,Years,Age q",
      '{"ImportId":"a"},{"ImportId":"b"},{"ImportId":"c"},{"ImportId":"d"}',
      paste(dashboard_id, organization, yearsserved, age11, sep = ",")
    ), path)
  }
  key <- "append-test-key"
  enc <- tempfile(fileext = ".enc")

  r1 <- tempfile(fileext = ".csv")
  write_raw_export(
    r1, c("D1", "D2"), c("Org A", "Org B"),
    c("8+ years", "4-7 years"), c("A lot (61%-100%)", "None")
  )
  build_encrypted_survey(input_csv = r1, output_enc = enc, passphrase = key, append = TRUE)
  wk1 <- load_survey_data(encrypted_path = enc, passphrase = key)
  expect_equal(nrow(wk1), 2L)

  r2 <- tempfile(fileext = ".csv")
  write_raw_export(
    r2, c("D2", "D3"), c("Org B", "Org C"),
    c("8+ years", "1-3 years"), c("Some (26%-60%)", "A little (1%-25%)")
  )
  build_encrypted_survey(input_csv = r2, output_enc = enc, passphrase = key, append = TRUE)
  wk2 <- load_survey_data(encrypted_path = enc, passphrase = key)

  expect_equal(sort(wk2$orgname), c("Org A", "Org B", "Org C"))
  expect_equal(wk2$lengthserve[wk2$orgname == "Org B"], "8+")
  expect_equal(wk2$pct_age_12_17[wk2$orgname == "Org B"], "26%-60%")
})

# ---- name-based row + value access ----

test_that("get_organization_details_row matches by orgname", {
  data <- data.frame(
    orgname = c("Org A", "Org B"), lengthserve = c("1", "2"),
    stringsAsFactors = FALSE
  )
  row <- get_organization_details_row("Org B", data)
  expect_equal(row$orgname, "Org B")
  expect_equal(row$lengthserve, "2")
})

test_that("get_organization_details_row resolves raw and URL-encoded multi-word ids", {
  data <- data.frame(
    orgname = c("Apprentice Learning", "Big Brothers Big Sisters"),
    lengthserve = c("1", "2"),
    stringsAsFactors = FALSE
  )

  # Raw multi-word id resolves to the right org (regression guard).
  raw <- get_organization_details_row("Big Brothers Big Sisters", data)
  expect_equal(raw$orgname, "Big Brothers Big Sisters")

  # URL-encoded id (as built by the org cards' href) ALSO resolves to that org,
  # not the first-org fallback. This fails before the encode-robust fix.
  encoded_id <- utils::URLencode("Big Brothers Big Sisters", reserved = TRUE)
  encoded <- get_organization_details_row(encoded_id, data)
  expect_equal(encoded$orgname, "Big Brothers Big Sisters")

  # A genuinely unknown id still falls back to the first non-empty org.
  unknown <- get_organization_details_row("No Such Org", data)
  expect_equal(unknown$orgname, "Apprentice Learning")

  # NULL and empty ids still fall back to the first non-empty org.
  expect_equal(get_organization_details_row(NULL, data)$orgname, "Apprentice Learning")
  expect_equal(get_organization_details_row("", data)$orgname, "Apprentice Learning")
})

test_that("get_named_value reads by column name with a fallback", {
  row <- data.frame(orgname = "Org A", pct_women = "26%-60%", stringsAsFactors = FALSE)
  expect_equal(get_named_value(row, "pct_women"), "26%-60%")
  expect_equal(get_named_value(row, "missing_col", "N/A"), "N/A")
})

# ---- login dashboard-id lookup ----

test_that("get_org_dashboard_ids maps org names to their dashboard ids", {
  data <- data.frame(
    orgname = c("Org A", "Org B", "  "),
    dashboard_id = c("D1", "D2", "D9"),
    stringsAsFactors = FALSE
  )
  ids <- get_org_dashboard_ids(data)
  expect_equal(unname(ids[["Org A"]]), "D1")
  expect_equal(unname(ids[["Org B"]]), "D2")
  # blank organization names are dropped
  expect_false(any(!nzchar(names(ids))))
})

test_that("get_org_dashboard_ids returns an empty vector for empty data", {
  empty <- get_org_dashboard_ids(
    data.frame(orgname = character(0), dashboard_id = character(0))
  )
  expect_length(empty, 0L)
})

# ---- wellness category mapping + details context ----

test_that("get_dimension_categories maps states to translated dimension labels", {
  cols <- c("EmotionalEorE", "Emotional", "PhysicalEorE", "Physical")
  vals <- c("Established", "Counseling services", "Emerging", "Fitness programs")
  row <- as.data.frame(as.list(setNames(vals, cols)), stringsAsFactors = FALSE, check.names = FALSE)
  os <- parse_orgservices_json(build_orgservices_json(row))
  lang <- get_lang("en")

  expect_equal(get_dimension_categories(os, lang, "established"), "Emotional wellness")
  expect_equal(get_dimension_categories(os, lang, "emerging"), "Physical wellness")
  expect_length(get_dimension_categories(os, lang, "wants"), 0L)
})

test_that("translate_interview_item resolves keys with language and English fallback", {
  content <- list(
    iv_0001 = list(en = "Limited green space", "es-419" = "Espacio verde limitado"),
    iv_0002 = list(en = "Only English text") # no es-419 translation
  )

  # Active language hit.
  expect_equal(
    translate_interview_item("iv_0001", "es-419", content), "Espacio verde limitado"
  )
  # Missing translation for the language falls back to English.
  expect_equal(translate_interview_item("iv_0002", "es-419", content), "Only English text")
  # Unknown key degrades to the raw key rather than erroring.
  expect_equal(translate_interview_item("iv_9999", "es-419", content), "iv_9999")
})

test_that("get_interview_dimension_items excludes barriers for not_interested dimensions", {
  # Unknown interview keys degrade to their raw text, so we can assert on labels.
  interview_dims <- list(
    physical = list(barriers = list("Physical barrier"), resource_needs = list()),
    emotional = list(barriers = list("Emotional barrier"), resource_needs = list())
  )
  # Physical marked "No, ..." gap (not an organizational focus) -> not_interested;
  # Emotional is established and therefore kept.
  cols <- c("PhysicalGap", "EmotionalEorE", "Emotional")
  vals <- c("No, this is not a focus for us", "Established", "Counseling")
  row <- as.data.frame(as.list(setNames(vals, cols)), stringsAsFactors = FALSE, check.names = FALSE)
  os <- parse_orgservices_json(build_orgservices_json(row))
  lang <- get_lang("en")

  expect_equal(os$physical$state, "not_interested")

  filtered <- get_interview_dimension_items(interview_dims, "barriers", lang, orgservices = os)
  labels <- vapply(filtered, function(x) x$label, character(1))
  expect_false("Physical wellness" %in% labels) # not_interested -> excluded
  expect_true("Emotional wellness" %in% labels) # established -> kept

  # Without orgservices the legacy behavior is unchanged (no exclusion).
  unfiltered <- get_interview_dimension_items(interview_dims, "barriers", lang)
  expect_true("Physical wellness" %in% vapply(unfiltered, function(x) x$label, character(1)))
})

test_that("get_organization_details_context excludes resource needs for not_interested dimensions", {
  # Unknown interview keys degrade to their raw text, so we can assert on labels.
  interview_dims <- list(
    physical = list(barriers = list(), resource_needs = list("Physical resource need"))
  )
  # Physical marked "No, ..." gap (not an organizational focus) -> not_interested.
  cols <- c("PhysicalGap")
  vals <- c("No, this is not a focus for us")
  row <- as.data.frame(as.list(setNames(vals, cols)), stringsAsFactors = FALSE, check.names = FALSE)
  os <- parse_orgservices_json(build_orgservices_json(row))
  lang <- get_lang("en")

  expect_equal(os$physical$state, "not_interested")

  filtered <- get_interview_dimension_items(interview_dims, "resource_needs", lang, orgservices = os)
  labels <- vapply(filtered, function(x) x$label, character(1))
  expect_false("Physical wellness" %in% labels) # not_interested -> excluded

  original_get_interview_dimensions <- get_interview_dimensions
  assign("get_interview_dimensions", function(...) interview_dims, envir = globalenv())
  on.exit(
    assign("get_interview_dimensions", original_get_interview_dimensions, envir = globalenv()),
    add = TRUE
  )
  survey_data <- build_clean_survey(
    as.data.frame(
      list(
        "Organization" = "Test Org",
        "IRB Participant ID" = "P01",
        "PhysicalGap" = "No, this is not a focus for us"
      ),
      stringsAsFactors = FALSE, check.names = FALSE
    )
  )
  ctx <- get_organization_details_context(lang, "Test Org", survey_data)
  expect_false("Physical wellness" %in% vapply(ctx$resource_needs, function(x) x$label, character(1)))

  # Without orgservices the legacy behavior is unchanged (no exclusion).
  unfiltered <- get_interview_dimension_items(interview_dims, "resource_needs", lang)
  expect_true("Physical wellness" %in% vapply(unfiltered, function(x) x$label, character(1)))
})

test_that("is_not_a_focus_placeholder matches the placeholder family but not real barriers", {
  content <- list(
    p1 = list(en = "Not a core programmatic focus \u2014 embedded informally only"),
    p2 = list(en = "Not the organization's stated focus"),
    p3 = list(en = "Not an organizational focus"),
    p4 = list(en = "Not an organizational focus \u2014 referrals made to other orgs"),
    p5 = list(en = "Not a core organizational offering"),
    p6 = list(en = "Not part of organizational mission"),
    p7 = list(en = "Not part of organizational mission \u2014 previous attempts were unsustainable"),
    p8 = list(en = "Not a central focus \u2014 shows up informally but not programmatically"),
    r1 = list(en = "Not enough staff power for structured physical programming"),
    r2 = list(en = "Bandwidth \u2014 financial literacy is not core mission, relies heavily on partners"),
    r3 = list(en = "Organizational focus is job-readiness, not emotional support"),
    r4 = list(en = "Quiet space for youth who need calm environment to focus")
  )

  for (k in paste0("p", 1:8)) {
    expect_true(is_not_a_focus_placeholder(k, content), info = k)
  }
  for (k in paste0("r", 1:4)) {
    expect_false(is_not_a_focus_placeholder(k, content), info = k)
  }
})

test_that("get_interview_dimension_items drops not-a-focus placeholders, keeps real items", {
  content <- list(
    ph_only = list(en = "Not an organizational focus"),
    real_1 = list(en = "Staff turnover disrupts programming"),
    real_2 = list(en = "Language access gaps"),
    ph_mixed = list(en = "Not a central focus \u2014 shows up informally")
  )
  original_loader <- load_interview_translations
  assign("load_interview_translations", function(...) content, envir = globalenv())
  on.exit(
    assign("load_interview_translations", original_loader, envir = globalenv()),
    add = TRUE
  )

  # physical: only a placeholder -> the whole dimension drops out.
  # emotional: a placeholder + two real barriers -> dimension kept, placeholder gone.
  interview_dims <- list(
    physical = list(barriers = list("ph_only"), resource_needs = list()),
    emotional = list(
      barriers = list("ph_mixed", "real_1", "real_2"),
      resource_needs = list()
    )
  )
  lang <- get_lang("en")

  out <- get_interview_dimension_items(interview_dims, "barriers", lang)
  labels <- vapply(out, function(x) x$label, character(1))

  expect_false("Physical wellness" %in% labels) # placeholder-only dimension removed
  expect_true("Emotional wellness" %in% labels)

  emotional_items <- out[[which(labels == "Emotional wellness")]]$items
  expect_setequal(emotional_items, c("Staff turnover disrupts programming", "Language access gaps"))
  expect_false(any(grepl("central focus", emotional_items)))
})

test_that("col_barriers_title label resolves to 'What to Keep in Mind - Important things to consider when establishing resources for the following dimensions'", {
  ctx <- get_organization_details_context(
    lang = get_lang("en"), org_name = "Nonexistent Org",
    survey_data = build_clean_survey(
      as.data.frame(
        list("Organization" = "Other"), stringsAsFactors = FALSE, check.names = FALSE
      )
    )
  )
  expect_equal(ctx$labels$col_barriers_title, "What to Keep in Mind - Important things to consider when establishing resources for the following dimensions")
  expect_equal(ctx$labels$col_resource_needs_title, "Resource Needs")
})

test_that("get_emerging_dimension_categories returns survey-marked emerging dimensions only", {
  # Physical is survey-emerging; Occupational is survey-established. Interview
  # coding is no longer consulted, so only the survey-emerging dimension counts.
  cols <- c("PhysicalEorE", "Physical", "OccupationalEorE", "Occupational")
  vals <- c("Emerging", "Fitness programs", "Established", "Job training")
  row <- as.data.frame(as.list(setNames(vals, cols)), stringsAsFactors = FALSE, check.names = FALSE)
  os <- parse_orgservices_json(build_orgservices_json(row))
  lang <- get_lang("en")

  out <- get_emerging_dimension_categories(os, lang)
  expect_true("Physical wellness" %in% out) # survey-marked emerging
  expect_false("Occupational wellness" %in% out) # survey-established, not emerging
  expect_equal(out, "Physical wellness") # de-duplicated, survey-only
})

test_that("get_organization_details_context exposes demographics and wellness categories", {
  cols <- c(
    "Dashboard ID", "Organization", "YearsServed", "Age#1_1",
    "EmotionalEorE", "Emotional", "PhysicalEorE", "Physical"
  )
  vals <- c(
    "Org01", "Test Org", "8+ years", "A lot (61%-100%)",
    "Established", "Counseling services", "Emerging", "Fitness programs"
  )
  raw <- as.data.frame(as.list(setNames(vals, cols)), stringsAsFactors = FALSE, check.names = FALSE)
  clean <- build_clean_survey(raw)

  ctx <- get_organization_details_context(
    lang = get_lang("en"), org_name = "Test Org", survey_data = clean
  )

  expect_true(ctx$has_data)
  expect_equal(ctx$orgname, "Test Org")
  expect_equal(ctx$lengthserve, "8+")
  expect_equal(ctx$pct_age_12_17, "61%-100%")
  expect_true("Emotional wellness" %in% ctx$established_categories)
  expect_true("Physical wellness" %in% ctx$emerging_categories)
  expect_false("Physical wellness" %in% ctx$established_categories)
})

test_that("get_organization_details_context exposes established_subcats matching the org's services", {
  cols <- c(
    "Dashboard ID", "Organization",
    "IntellectualEorE", "Intellectual",
    "SocialEorE", "Social"
  )
  vals <- c(
    "Org01", "Test Org",
    "Established", "Tutoring,Some bespoke offering",
    "Established", "Mentoring"
  )
  raw <- as.data.frame(as.list(setNames(vals, cols)), stringsAsFactors = FALSE, check.names = FALSE)
  clean <- build_clean_survey(raw)

  ctx <- get_organization_details_context(
    lang = get_lang("en"), org_name = "Test Org", survey_data = clean
  )

  orgservices <- parse_orgservices_json(build_orgservices_json(raw))
  expect_type(ctx$established_subcats, "character")
  expect_equal(ctx$established_subcats, established_subcat_keys(orgservices))
})

# ---- service -> subcategory matching ----

test_that("service_matches_label handles exact, truncated, and word-form matches", {
  expect_true(service_matches_label("fitness programs", "fitness programs"))
  # stored service carries extra detail beyond the curated label
  expect_true(service_matches_label(
    "educational workshops, e.g., stem classes, etc", "educational workshops"
  ))
  # minor word-form difference ("Nutrition" vs "Nutritional")
  expect_true(service_matches_label("nutrition education", "nutritional education"))
  expect_false(service_matches_label("mentoring", "tutoring"))
  expect_false(service_matches_label("", "tutoring"))
})

test_that("established_subcat_keys maps established services to subcategory keys", {
  cols <- c(
    "IntellectualEorE", "Intellectual",
    "SocialEorE", "Social",
    "PhysicalEorE", "Physical"
  )
  vals <- c(
    "Established", "Tutoring,Some bespoke offering", # curated + free-text
    "Established", "Mentoring",
    "Emerging", "Fitness programs" # emerging, so excluded
  )
  row <- as.data.frame(as.list(setNames(vals, cols)), stringsAsFactors = FALSE, check.names = FALSE)
  os <- parse_orgservices_json(build_orgservices_json(row))

  keys <- established_subcat_keys(os)
  expect_true("sub_intellectual_3" %in% keys) # Tutoring
  # The bespoke free-text service matches no curated subcategory, so it emits
  # nothing (the "Other" catch-all has been removed).
  expect_false("intellectual_other" %in% keys)
  expect_true("sub_social_1" %in% keys) # Mentoring
  # Physical is only emerging here, so no physical keys are emitted.
  expect_false("wellness_physical_fitness" %in% keys)
  expect_false("physical_other" %in% keys)
})

test_that("established_subcat_keys returns nothing when there are no services", {
  cols <- c("IntellectualEorE", "Intellectual")
  vals <- c("Established", "") # established state but no listed services
  row <- as.data.frame(as.list(setNames(vals, cols)), stringsAsFactors = FALSE, check.names = FALSE)
  os <- parse_orgservices_json(build_orgservices_json(row))
  expect_length(established_subcat_keys(os), 0L)
})

# ---- encryption helpers ----

test_that("encrypt_data_raw and decrypt_data_raw are inverse operations", {
  withr::local_dir(project_root)
  original <- charToRaw("hello encrypted world")
  passphrase <- "unit-test-passphrase"
  encrypted <- encrypt_data_raw(original, passphrase)
  decrypted <- decrypt_data_raw(encrypted, passphrase)
  expect_false(identical(encrypted, original))
  expect_equal(rawToChar(decrypted), "hello encrypted world")
})

test_that("decrypt_data_raw fails for tampered authenticated payload", {
  withr::local_dir(project_root)
  passphrase <- "unit-test-passphrase"
  encrypted <- encrypt_data_raw(charToRaw("hello encrypted world"), passphrase)
  encrypted[[length(encrypted)]] <- as.raw(bitwXor(as.integer(encrypted[[length(encrypted)]]), 1L))
  expect_error(decrypt_data_raw(encrypted, passphrase), "authentication failed")
})

test_that("decrypt_data_raw supports legacy unauthenticated payload format", {
  withr::local_dir(project_root)
  passphrase <- "legacy-passphrase"
  key <- derive_data_key(passphrase)
  iv <- openssl::rand_bytes(16)
  plain <- charToRaw("legacy ciphertext")
  ciphertext <- openssl::aes_cbc_encrypt(plain, key = key, iv = iv)
  legacy_payload <- c(iv, ciphertext)
  expect_warning(out <- decrypt_data_raw(legacy_payload, passphrase), "legacy unauthenticated payload")
  expect_equal(rawToChar(out), "legacy ciphertext")
})

test_that("encrypt_data_file fails clearly when key is missing", {
  withr::local_dir(project_root)
  plain <- tempfile(fileext = ".csv")
  writeLines(c("orgname,lengthserve", "Org A,8+"), plain)
  expect_error(
    encrypt_data_file(input_path = plain, output_path = tempfile(fileext = ".enc"), passphrase = ""),
    "Missing encryption key"
  )
})

test_that("assert_survey_data_startup_ready succeeds with encrypted file", {
  withr::local_dir(project_root)
  plain <- tempfile(fileext = ".csv")
  enc <- tempfile(fileext = ".enc")
  writeLines(c("orgname,lengthserve", "Org A,8+"), plain)
  encrypt_data_file(input_path = plain, output_path = enc, passphrase = "secret")
  expect_true(assert_survey_data_startup_ready(encrypted_path = enc, passphrase = "secret"))
})

test_that("assert_survey_data_startup_ready fails for encrypted file without key", {
  withr::local_dir(project_root)
  plain <- tempfile(fileext = ".csv")
  enc <- tempfile(fileext = ".enc")
  writeLines(c("orgname,lengthserve", "Org A,8+"), plain)
  encrypt_data_file(input_path = plain, output_path = enc, passphrase = "secret")
  expect_error(
    assert_survey_data_startup_ready(encrypted_path = enc, passphrase = "", key_env_var = "CPA_DATA_KEY"),
    "CPA_DATA_KEY is not set"
  )
})

test_that("pct_band maps cleaned percentage ranges to the survey bands", {
  expect_equal(pct_band("0%"), "none")
  expect_equal(pct_band("1%-25%"), "a_little")
  expect_equal(pct_band("26%-60%"), "some")
  expect_equal(pct_band("61%-100%"), "a_lot")
  expect_equal(pct_band("100%"), "a_lot")
})

test_that("pct_band treats the don't-know dash and blanks as not reported", {
  expect_equal(pct_band("\u2014"), "not_reported")
  expect_equal(pct_band("N/A"), "not_reported")
  expect_equal(pct_band(""), "not_reported")
  expect_equal(pct_band(NA), "not_reported")
})

test_that("band_filled_count fills 0/1/3/6 of the six meter slots", {
  expect_equal(band_filled_count("none"), 0L)
  expect_equal(band_filled_count("a_little"), 1L)
  expect_equal(band_filled_count("some"), 3L)
  expect_equal(band_filled_count("a_lot"), 6L)
})
