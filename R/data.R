# ---------------------------------------------------------------------------
# Encrypted survey data. The dataset is stored as an authenticated "v2" payload:
# magic ("CPA2") + IV + AES-256-CBC ciphertext + HMAC-SHA256 tag, with separate
# encryption and MAC keys derived from the CPA_DATA_KEY passphrase.
# ---------------------------------------------------------------------------

# Marks v2 (authenticated) payloads; absence means a legacy unauthenticated file.
DATA_ENCRYPTION_MAGIC <- charToRaw("CPA2")

# Master key = SHA-256 of the passphrase (also the legacy single-key value).
derive_data_key <- function(passphrase) {
  if (!nzchar(passphrase)) {
    stop("Data encryption key is empty.", call. = FALSE)
  }

  openssl::sha256(charToRaw(passphrase))
}

# Separate encryption and MAC keys derived from the master key (key separation).
derive_data_keys <- function(passphrase) {
  master_key <- derive_data_key(passphrase)

  list(
    enc_key = openssl::sha256(c(charToRaw("enc"), master_key)),
    mac_key = openssl::sha256(c(charToRaw("mac"), master_key))
  )
}

# Constant-time byte comparison so MAC verification doesn't leak via timing.
raw_equal_ct <- function(a, b) {
  if (length(a) != length(b)) {
    return(FALSE)
  }

  diff <- 0L
  for (i in seq_along(a)) {
    diff <- bitwOr(diff, bitwXor(as.integer(a[[i]]), as.integer(b[[i]])))
  }

  diff == 0L
}

compute_data_mac <- function(payload, mac_key) {
  digest::hmac(key = mac_key, object = payload, algo = "sha256", raw = TRUE)
}

is_v2_payload <- function(encrypted_raw) {
  length(encrypted_raw) >= length(DATA_ENCRYPTION_MAGIC) &&
    identical(encrypted_raw[seq_along(DATA_ENCRYPTION_MAGIC)], DATA_ENCRYPTION_MAGIC)
}

# Authenticate then decrypt a v2 payload; legacy payloads decrypt with a warning.
decrypt_data_raw <- function(encrypted_raw, passphrase) {
  if (length(encrypted_raw) <= 16) {
    stop("Encrypted data is invalid or corrupted.", call. = FALSE)
  }

  keys <- derive_data_keys(passphrase)

  if (is_v2_payload(encrypted_raw)) {
    min_len <- length(DATA_ENCRYPTION_MAGIC) + 16 + 32
    if (length(encrypted_raw) <= min_len) {
      stop("Encrypted data is invalid or corrupted.", call. = FALSE)
    }

    mac_len <- 32
    mac_start <- length(encrypted_raw) - mac_len + 1

    payload <- encrypted_raw[seq_len(mac_start - 1)]
    received_mac <- encrypted_raw[mac_start:length(encrypted_raw)]
    expected_mac <- compute_data_mac(payload, keys$mac_key)

    if (!raw_equal_ct(received_mac, expected_mac)) {
      stop(
        "Encrypted data authentication failed. Data may be corrupted or tampered.",
        call. = FALSE
      )
    }

    offset <- length(DATA_ENCRYPTION_MAGIC)
    iv <- payload[(offset + 1):(offset + 16)]
    ciphertext <- payload[(offset + 17):length(payload)]

    return(openssl::aes_cbc_decrypt(ciphertext, key = keys$enc_key, iv = iv))
  }

  # Backward compatibility for legacy payloads: iv (16 bytes) + ciphertext.
  # Legacy format has no authentication, so this path should only be used
  # to migrate old encrypted files.
  warning("Decrypting legacy unauthenticated payload. Re-encrypt with make encrypt-data.", call. = FALSE)

  iv <- encrypted_raw[1:16]
  ciphertext <- encrypted_raw[-(1:16)]

  legacy_key <- derive_data_key(passphrase)
  openssl::aes_cbc_decrypt(ciphertext, key = legacy_key, iv = iv)
}

# Build a v2 payload: magic + IV + AES-CBC ciphertext, with an HMAC tag appended.
encrypt_data_raw <- function(plain_raw, passphrase) {
  keys <- derive_data_keys(passphrase)
  iv <- openssl::rand_bytes(16)
  ciphertext <- openssl::aes_cbc_encrypt(plain_raw, key = keys$enc_key, iv = iv)
  payload <- c(DATA_ENCRYPTION_MAGIC, iv, ciphertext)
  mac <- compute_data_mac(payload, keys$mac_key)

  c(payload, mac)
}

encrypt_data_file <- function(
  input_path,
  output_path = paste0(input_path, ".enc"),
  passphrase = Sys.getenv("CPA_DATA_KEY"),
  key_env_var = "CPA_DATA_KEY"
) {
  if (!requireNamespace("openssl", quietly = TRUE)) {
    stop("Package 'openssl' is required. Run make install.", call. = FALSE)
  }
  if (!requireNamespace("digest", quietly = TRUE)) {
    stop("Package 'digest' is required. Run make install.", call. = FALSE)
  }

  if (missing(passphrase)) {
    passphrase <- Sys.getenv(key_env_var)
  }

  if (missing(input_path) || !nzchar(input_path)) {
    stop("Missing input_path for encryption.", call. = FALSE)
  }

  if (!file.exists(input_path)) {
    stop(sprintf("Expected data file at '%s'.", input_path), call. = FALSE)
  }
  if (!nzchar(passphrase)) {
    stop(
      sprintf("Missing encryption key. Set %s environment variable.", key_env_var),
      call. = FALSE
    )
  }

  plain_raw <- readBin(input_path, what = "raw", n = file.info(input_path)$size)
  encrypted_raw <- encrypt_data_raw(plain_raw, passphrase)
  writeBin(encrypted_raw, output_path)

  invisible(output_path)
}

decrypt_data_file <- function(
  encrypted_path = file.path("data", "survey_data.csv.enc"),
  output_path = tempfile(fileext = ".csv"),
  passphrase = Sys.getenv("CPA_DATA_KEY"),
  key_env_var = "CPA_DATA_KEY"
) {
  if (!requireNamespace("openssl", quietly = TRUE)) {
    stop("Package 'openssl' is required. Run make install.", call. = FALSE)
  }
  if (!requireNamespace("digest", quietly = TRUE)) {
    stop("Package 'digest' is required. Run make install.", call. = FALSE)
  }

  if (missing(passphrase)) {
    passphrase <- Sys.getenv(key_env_var)
  }

  if (!file.exists(encrypted_path)) {
    stop(sprintf("Expected encrypted data file at '%s'.", encrypted_path), call. = FALSE)
  }
  if (!nzchar(passphrase)) {
    stop(
      sprintf("Missing decryption key. Set %s environment variable.", key_env_var),
      call. = FALSE
    )
  }

  encrypted_raw <- readBin(encrypted_path, what = "raw", n = file.info(encrypted_path)$size)
  plain_raw <- decrypt_data_raw(encrypted_raw, passphrase)
  writeBin(plain_raw, output_path)

  invisible(output_path)
}

assert_survey_data_startup_ready <- function(
  encrypted_path = file.path("data", "survey_data.csv.enc"),
  key_env_var = "CPA_DATA_KEY",
  passphrase = Sys.getenv(key_env_var)
) {
  if (!file.exists(encrypted_path)) {
    stop(
      sprintf(
        "Startup check failed: expected encrypted survey data file at '%s'.",
        encrypted_path
      ),
      call. = FALSE
    )
  }

  if (!requireNamespace("openssl", quietly = TRUE)) {
    stop(
      "Startup check failed: package 'openssl' is required to decrypt survey data.",
      call. = FALSE
    )
  }
  if (!requireNamespace("digest", quietly = TRUE)) {
    stop(
      "Startup check failed: package 'digest' is required to verify encrypted survey data.",
      call. = FALSE
    )
  }

  if (!nzchar(passphrase)) {
    stop(
      sprintf(
        "Startup check failed: encrypted survey data detected at '%s' but %s is not set.",
        encrypted_path,
        key_env_var
      ),
      call. = FALSE
    )
  }

  invisible(TRUE)
}

# ---------------------------------------------------------------------------
# Survey data transform + access (name-based).
#
# The dashboard reads a CLEAN, NAMED schema produced from the raw Qualtrics
# export. The accessors below read by column NAME (never by position), so
# inserting columns into the survey no longer breaks them.
#
# This file produces the organization/demographic fields and the per-dimension
# wellness data (the established/emerging/wants state that drives the wheels, plus
# the services per dimension), serialized into the orgservices_json column. The
# barriers/resource_needs slots are left empty here and populated from the
# interview-coded data, joined on irb_participant_id.
# ---------------------------------------------------------------------------

`%||%` <- function(a, b) {
  if (is.null(a) || length(a) == 0 || (length(a) == 1 && is.na(a))) b else a
}

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

# Escape regex metacharacters so a string can be matched literally in a pattern.
escape_regex <- function(s) gsub("([][{}()*+?.\\^$|])", "\\\\\\1", s)

# 8 dimensions of wellbeing: dashboard key -> raw Qualtrics column names.
# text_col is the "Other (please specify)" free-text column (occupational and
# spiritual use *_6_TEXT because they carry an extra option).
SURVEY_DIMENSIONS <- list(
  list(
    key = "physical",
    services_col = "Physical",
    text_col = "Physical_5_TEXT",
    eore_col = "PhysicalEorE",
    gap_col = "PhysicalGap"
  ),
  list(
    key = "emotional",
    services_col = "Emotional",
    text_col = "Emotional_5_TEXT",
    eore_col = "EmotionalEorE",
    gap_col = "EmotionalGap"
  ),
  list(
    key = "intellectual",
    services_col = "Intellectual",
    text_col = "Intellectual_5_TEXT",
    eore_col = "IntellectualEorE",
    gap_col = "IntellectualGap"
  ),
  list(
    key = "occupational",
    services_col = "Occupational",
    text_col = "Occupational_6_TEXT",
    eore_col = "OccupationalEorE",
    gap_col = "OccupationalGap"
  ),
  list(
    key = "financial",
    services_col = "Financial",
    text_col = "Financial_5_TEXT",
    eore_col = "FinancialEorE",
    gap_col = "FinancialGap"
  ),
  list(
    key = "social",
    services_col = "Social",
    text_col = "Social_5_TEXT",
    eore_col = "SocialEorE",
    gap_col = "SocialGap"
  ),
  list(
    key = "environmental",
    services_col = "Environmental",
    text_col = "Environmental_5_TEXT",
    eore_col = "EnvironmentalEorE",
    gap_col = "EnvironmentalGap"
  ),
  list(
    key = "spiritual",
    services_col = "Spiritual",
    text_col = "Spiritual_6_TEXT",
    eore_col = "SpiritualEorE",
    gap_col = "SpiritualGap"
  )
)

# dashboard key -> translation label key (used to build data-active-categories).
DIMENSION_LABEL_KEYS <- c(
  physical = "wellness_physical", emotional = "wellness_emotional",
  intellectual = "wellness_intellectual",
  occupational = "wellness_occupational",
  financial = "wellness_financial", social = "wellness_social",
  environmental = "wellness_environmental", spiritual = "wellness_spiritual"
)

# Sub-categories under each wellness dimension, mirroring the wellness wheel
# taxonomy (www/js/app.js WHEEL_META). Used both to render the filter sidebar and
# to match an organization's stored services to a subcategory. "wellness_physical_
# other" is the shared "Other" label key.
DIMENSION_SUB_KEYS <- list(
  physical = c("wellness_physical_fitness", "wellness_physical_nutrition", "wellness_physical_screenings", "wellness_physical_other"),
  emotional = c("sub_emotional_1", "sub_emotional_2", "sub_emotional_3", "wellness_physical_other"),
  intellectual = c("sub_intellectual_1", "sub_intellectual_2", "sub_intellectual_3", "wellness_physical_other"),
  occupational = c("sub_occupational_1", "sub_occupational_2", "sub_occupational_3", "sub_occupational_4", "wellness_physical_other"),
  financial = c("sub_financial_1", "sub_financial_2", "sub_financial_3", "wellness_physical_other"),
  social = c("sub_social_1", "sub_social_2", "sub_social_3", "wellness_physical_other"),
  environmental = c("sub_environmental_1", "sub_environmental_2", "sub_environmental_3", "wellness_physical_other"),
  spiritual = c("sub_spiritual_1", "sub_spiritual_2", "sub_spiritual_3", "sub_spiritual_4", "wellness_physical_other")
)

# Match a stored survey service string against a subcategory label, tolerant of
# trailing detail ("Educational workshops, e.g. ...") and minor word forms
# ("Nutrition" vs "Nutritional"). Both inputs should be lowercased/trimmed.
service_matches_label <- function(service, label) {
  if (!nzchar(service) || !nzchar(label)) {
    return(FALSE)
  }
  if (service == label || startsWith(service, label) || startsWith(label, service)) {
    return(TRUE)
  }
  sw <- strsplit(service, "\\s+")[[1]]
  lw <- strsplit(label, "\\s+")[[1]]
  length(sw) == length(lw) && length(sw) > 0 &&
    all(mapply(function(a, b) startsWith(a, b) || startsWith(b, a), sw, lw))
}

# Subcategory keys an organization provides as ESTABLISHED services. Each curated
# subcategory it matches is emitted by its key; any established service that
# matches no curated subcategory contributes a dimension-specific "<dimension>_
# other" key (the "Other" catch-all). Matching always uses English labels (the
# language the survey services are stored in) so the keys are stable regardless
# of the UI language.
established_subcat_keys <- function(orgservices) {
  en <- get_lang("en")
  sub_label <- function(key) en$organizations[[key]] %||% en$wheel[[key]] %||% key

  out <- character(0)
  for (key in names(DIMENSION_LABEL_KEYS)) {
    dim <- orgservices[[key]]
    if (is.null(dim) || !identical(dim$state, "established")) next
    services <- tolower(trimws(vapply(dim$services %||% list(), as.character, character(1))))
    services <- services[nzchar(services)]
    if (!length(services)) next

    curated_keys <- setdiff(DIMENSION_SUB_KEYS[[key]], "wellness_physical_other")
    curated_labels <- tolower(trimws(vapply(curated_keys, sub_label, character(1))))
    has_other <- FALSE
    for (service in services) {
      matched <- vapply(curated_labels, service_matches_label, logical(1), service = service)
      if (any(matched)) {
        out <- c(out, curated_keys[matched])
      } else {
        has_other <- TRUE
      }
    }
    if (has_other) {
      out <- c(out, paste0(key, "_other"))
    }
  }
  unique(out)
}

# Multi-selects are comma-joined, but some option labels themselves contain commas
# (only the Intellectual one here). Those are extracted before splitting so they
# are not shattered.
DIMENSION_COMMA_OPTIONS <- list(
  intellectual = "Educational workshops, e.g., STEM classes, etc"
)

# Split a multi-select cell into clean service labels. "Other (please specify):"
# is replaced by the verbatim free text; "None" is dropped.
parse_services <- function(raw, other_text, dim_key) {
  raw <- trimws(as.character(raw %||% ""))
  if (!nzchar(raw) || identical(raw, "None")) {
    return(character(0))
  }

  extracted <- character(0)
  for (opt in DIMENSION_COMMA_OPTIONS[[dim_key]]) {
    pat <- paste0(escape_regex(opt), "\\.?")
    if (grepl(pat, raw)) {
      extracted <- c(extracted, opt)
      raw <- sub(pat, "", raw)
    }
  }
  raw <- gsub(",\\s*,", ",", raw)
  raw <- trimws(gsub("^,|,$", "", trimws(raw)))

  parts <- trimws(strsplit(raw, ",")[[1]])
  parts <- parts[nzchar(parts) & parts != "None"]

  is_other <- grepl("^Other \\(please specify\\)", parts)
  parts <- parts[!is_other]
  other_text <- trimws(as.character(other_text %||% ""))
  if (any(is_other) && nzchar(other_text) && !identical(other_text, "NA")) {
    parts <- c(parts, other_text)
  }
  unname(c(extracted, parts))
}

# Per-org nested object for the 8 dimensions, serialized to a JSON string carried
# in the orgservices_json column. state is derived from EorE/Gap; services from
# the multi-select; barriers/resource_needs are empty slots populated from the
# interview-coded data.
build_orgservices_json <- function(row) {
  out <- list()
  for (d in SURVEY_DIMENSIONS) {
    eore <- trimws(as.character(row[[d$eore_col]] %||% ""))
    gap <- trimws(as.character(row[[d$gap_col]] %||% ""))

    state <- if (identical(eore, "Established")) {
      "established"
    } else if (identical(eore, "Emerging")) {
      "emerging"
    } else if (grepl("^Yes", gap)) {
      "wants"
    } else if (grepl("^No", gap)) {
      "not_interested"
    } else {
      "none"
    }

    services <- parse_services(row[[d$services_col]] %||% "", row[[d$text_col]] %||% "", d$key)
    out[[d$key]] <- list(
      state = state,
      services = as.list(services),
      barriers = list(),
      resource_needs = list()
    )
  }
  as.character(jsonlite::toJSON(out, auto_unbox = TRUE, null = "null"))
}

# Read a raw Qualtrics export: row 1 = variable names, rows 2..header_rows =
# question text + ImportId metadata, data starts after. Returns a data frame
# with the original (exact) Qualtrics column names preserved.
read_qualtrics_export <- function(path, header_rows = 3L) {
  if (!file.exists(path)) {
    stop(sprintf("Expected survey export at '%s'.", path), call. = FALSE)
  }
  raw <- read.csv(
    path,
    header = FALSE, stringsAsFactors = FALSE,
    check.names = FALSE, colClasses = "character", na.strings = character(0)
  )
  if (nrow(raw) <= header_rows) {
    stop("Survey export has header rows but no data rows.", call. = FALSE)
  }
  col_names <- as.character(unlist(raw[1, ], use.names = FALSE))
  data <- raw[-seq_len(header_rows), , drop = FALSE]
  colnames(data) <- col_names
  rownames(data) <- NULL
  data
}

# Raw export data frame -> clean, named per-organization data frame (one row per
# org). This is the organization/demographic portion of the dashboard schema.
build_clean_survey <- function(raw) {
  get_col <- function(col) {
    if (col %in% names(raw)) as.character(raw[[col]]) else rep(NA_character_, nrow(raw))
  }
  pct <- function(col) unname(vapply(get_col(col), clean_pct, character(1)))

  clean <- data.frame(
    dashboard_id = trimws(get_col("Dashboard ID")),
    irb_participant_id = trimws(get_col("IRB Participant ID")),
    orgname = trimws(get_col("Organization")),
    lengthserve = unname(vapply(get_col("YearsServed"), clean_lengthserve, character(1))),

    # Youth served (rendered today).
    pct_age_12_17 = pct("Age#1_1"),
    pct_age_18_25 = pct("Age#1_2"),
    pct_age_over26 = pct("Age#1_3"),
    pct_women = pct("Gender#1_1"),
    pct_men = pct("Gender#1_2"),
    pct_gender = pct("Gender#1_3"),
    pct_disabilities = pct("OtherDem#1_1"),
    pct_spiritual = pct("OtherDem#1_2"),
    pct_race_eth = pct("OtherDem#1_3"),
    pct_us_born = pct("OtherDem#1_4"),
    pct_queer = pct("OtherDem#1_5"),

    # Employees (carried in parallel; not yet rendered. Drop this block for youth-only).
    emp_pct_age_12_17 = pct("Age#2_1"),
    emp_pct_age_18_25 = pct("Age#2_2"),
    emp_pct_age_over26 = pct("Age#2_3"),
    emp_pct_women = pct("Gender#2_1"),
    emp_pct_men = pct("Gender#2_2"),
    emp_pct_gender = pct("Gender#2_3"),
    emp_pct_disabilities = pct("OtherDem#2_1"),
    emp_pct_spiritual = pct("OtherDem#2_2"),
    emp_pct_race_eth = pct("OtherDem#2_3"),
    emp_pct_us_born = pct("OtherDem#2_4"),
    emp_pct_queer = pct("OtherDem#2_5"),
    stringsAsFactors = FALSE
  )

  clean$orgservices_json <- vapply(
    seq_len(nrow(raw)),
    function(i) build_orgservices_json(raw[i, , drop = FALSE]),
    character(1)
  )

  keep <- nzchar(clean$orgname) | nzchar(clean$dashboard_id)
  clean[keep, , drop = FALSE]
}

# Convenience: raw export path -> clean data frame.
transform_survey_export <- function(path) {
  build_clean_survey(read_qualtrics_export(path))
}

# Cumulative model: merge newly transformed rows into the existing accumulated
# dataset. New rows are appended; if an organization already exists (matched on
# dashboard_id, falling back to orgname) the most recent submission wins.
# Organizations are never removed once added.
merge_survey_data <- function(existing, new_rows) {
  if (is.null(existing) || !nrow(existing)) {
    return(new_rows)
  }
  if (is.null(new_rows) || !nrow(new_rows)) {
    return(existing)
  }

  all_cols <- union(names(existing), names(new_rows))
  for (col in setdiff(all_cols, names(existing))) existing[[col]] <- NA_character_
  for (col in setdiff(all_cols, names(new_rows))) new_rows[[col]] <- NA_character_
  existing <- existing[, all_cols, drop = FALSE]
  new_rows <- new_rows[, all_cols, drop = FALSE]

  combined <- rbind(existing, new_rows) # new rows last so they win on dedup

  did <- if ("dashboard_id" %in% names(combined)) trimws(as.character(combined$dashboard_id)) else rep("", nrow(combined))
  did[is.na(did)] <- ""
  onm <- if ("orgname" %in% names(combined)) trimws(as.character(combined$orgname)) else rep("", nrow(combined))
  onm[is.na(onm)] <- ""
  key <- ifelse(nzchar(did), did, onm)

  keep <- !duplicated(key, fromLast = TRUE)
  combined[keep, , drop = FALSE]
}

# Full pipeline step: raw export path -> merge into the running dataset (unless
# append = FALSE) -> encrypt to the path the app reads. Encrypt with the
# deployment's CPA_DATA_KEY or the live app cannot decrypt it.
build_encrypted_survey <- function(
  input_csv,
  output_enc = file.path("data", "survey_data.csv.enc"),
  passphrase = Sys.getenv("CPA_DATA_KEY"),
  key_env_var = "CPA_DATA_KEY",
  append = TRUE
) {
  if (missing(passphrase)) {
    passphrase <- Sys.getenv(key_env_var)
  }
  if (!nzchar(passphrase)) {
    stop(sprintf("Missing encryption key. Set %s.", key_env_var), call. = FALSE)
  }

  new_rows <- transform_survey_export(input_csv)
  combined <- new_rows

  if (isTRUE(append) && file.exists(output_enc)) {
    existing <- tryCatch(
      load_survey_data(encrypted_path = output_enc, passphrase = passphrase),
      error = function(e) NULL
    )
    if (!is.null(existing)) {
      combined <- merge_survey_data(existing, new_rows)
    }
  }

  tmp <- tempfile(fileext = ".csv")
  on.exit(unlink(tmp), add = TRUE)
  write.csv(combined, tmp, row.names = FALSE, na = "")
  encrypt_data_file(input_path = tmp, output_path = output_enc, passphrase = passphrase)
  invisible(output_enc)
}

# Read the clean CSV (single header row, named columns).
read_clean_survey <- function(path) {
  read.csv(
    path,
    header = TRUE, stringsAsFactors = FALSE,
    check.names = FALSE, colClasses = "character", na.strings = character(0)
  )
}

# Decrypt the survey artifact and return the clean data frame.
load_survey_data <- function(
  encrypted_path = file.path("data", "survey_data.csv.enc"),
  passphrase = Sys.getenv("CPA_DATA_KEY"),
  key_env_var = "CPA_DATA_KEY"
) {
  if (!file.exists(encrypted_path)) {
    stop(sprintf("Expected encrypted survey data file at '%s'.", encrypted_path), call. = FALSE)
  }
  if (!requireNamespace("openssl", quietly = TRUE)) {
    stop("Package 'openssl' is required. Run make install.", call. = FALSE)
  }
  if (!requireNamespace("digest", quietly = TRUE)) {
    stop("Package 'digest' is required. Run make install.", call. = FALSE)
  }
  if (missing(passphrase)) {
    passphrase <- Sys.getenv(key_env_var)
  }
  if (!nzchar(passphrase)) {
    stop(
      sprintf(
        "Found encrypted data at '%s' but no decryption key was provided. Set %s.",
        encrypted_path, key_env_var
      ),
      call. = FALSE
    )
  }

  encrypted_raw <- readBin(encrypted_path, what = "raw", n = file.info(encrypted_path)$size)
  plain_raw <- decrypt_data_raw(encrypted_raw, passphrase)

  temp_path <- tempfile(fileext = ".csv")
  on.exit(unlink(temp_path), add = TRUE)
  writeBin(plain_raw, temp_path)

  read_clean_survey(temp_path)
}

# Same clean source; kept as a separate name because callers reference it.
load_organization_details_data <- function(
  encrypted_path = file.path("data", "survey_data.csv.enc"),
  passphrase = Sys.getenv("CPA_DATA_KEY"),
  key_env_var = "CPA_DATA_KEY"
) {
  load_survey_data(encrypted_path = encrypted_path, passphrase = passphrase, key_env_var = key_env_var)
}

# Sorted, de-duplicated list of non-empty organization names.
get_org_names <- function(survey_data = load_survey_data()) {
  col <- if ("orgname" %in% names(survey_data)) survey_data[["orgname"]] else survey_data[[1]]
  names <- sort(unique(trimws(col)))
  names[nzchar(names)]
}

# orgname -> dashboard_id lookup, used by the login form to validate the entered
# Organization ID against the Dashboard ID stored for the selected organization.
get_org_dashboard_ids <- function(survey_data = load_survey_data()) {
  empty <- stats::setNames(character(0), character(0))
  if (is.null(survey_data) || !nrow(survey_data)) {
    return(empty)
  }
  org_col <- if ("orgname" %in% names(survey_data)) survey_data[["orgname"]] else survey_data[[1]]
  orgname <- trimws(as.character(org_col))
  dashboard_id <- if ("dashboard_id" %in% names(survey_data)) {
    trimws(as.character(survey_data[["dashboard_id"]]))
  } else {
    rep("", length(orgname))
  }
  dashboard_id[is.na(dashboard_id)] <- ""
  keep <- nzchar(orgname)
  stats::setNames(dashboard_id[keep], orgname[keep])
}

# Read a named scalar from a single-row data frame, with a fallback.
get_named_value <- function(row, col, fallback = "N/A") {
  if (is.null(row) || !nrow(row) || !(col %in% names(row))) {
    return(fallback)
  }
  value <- trimws(as.character(row[[col]][[1]]))
  if (!nzchar(value) || identical(value, "NA")) fallback else value
}

# The single data row for `org_name`, or the first non-empty org when unmatched.
get_organization_details_row <- function(
  org_name = NULL,
  survey_data = load_organization_details_data()
) {
  name_col <- if ("orgname" %in% names(survey_data)) survey_data[["orgname"]] else survey_data[[1]]
  org_names <- trimws(as.character(name_col))

  selected_org <- NULL
  if (!is.null(org_name) && length(org_name)) {
    selected_org <- trimws(as.character(org_name[[1]]))
    if (!nzchar(selected_org)) {
      selected_org <- NULL
    }
  }

  selected_row_index <- if (!is.null(selected_org) && selected_org %in% org_names) {
    match(selected_org, org_names)
  } else {
    non_empty_rows <- which(nzchar(org_names))
    if (!length(non_empty_rows)) NA_integer_ else non_empty_rows[[1]]
  }

  if (is.na(selected_row_index)) {
    return(survey_data[0, , drop = FALSE])
  }

  survey_data[selected_row_index, , drop = FALSE]
}

# ---------------------------------------------------------------------------
# Per-dimension wellness wheel data (state + services per dimension).
# ---------------------------------------------------------------------------

# Parse the orgservices_json column into a nested list.
parse_orgservices_json <- function(json_str) {
  json_str <- as.character(json_str %||% "")
  if (length(json_str) != 1 || !nzchar(json_str)) {
    return(list())
  }
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required. Run make install.", call. = FALSE)
  }
  tryCatch(jsonlite::fromJSON(json_str, simplifyVector = FALSE), error = function(e) list())
}

# Dimension label list for a given state, used to populate data-active-categories.
get_dimension_categories <- function(orgservices, lang, state_value) {
  organizations <- lang$organizations
  out <- character(0)
  for (key in names(DIMENSION_LABEL_KEYS)) {
    dim <- orgservices[[key]]
    if (!is.null(dim) && identical(dim$state, state_value)) {
      label <- organizations[[DIMENSION_LABEL_KEYS[[key]]]]
      if (!is.null(label) && nzchar(label)) {
        out <- c(out, label)
      }
    }
  }
  out
}

# A translation label by key, with a fallback when missing/empty.
get_organization_details_label <- function(details, key, fallback) {
  value <- details[[key]]
  if (is.null(value) || !nzchar(value)) fallback else value
}

# Everything the details page needs for one organization: resolved name, labels,
# demographic percentages, and the established/emerging wellness categories. When
# `org_name` is NULL it is read from the ?id query param.
get_organization_details_context <- function(
  lang = get_lang(),
  org_name = NULL,
  survey_data = load_organization_details_data()
) {
  details <- lang$organization_details
  if (is.null(org_name)) {
    org_name <- tryCatch(get_query_param("id"), error = function(e) NULL)
  }

  row <- get_organization_details_row(org_name = org_name, survey_data = survey_data)

  fallback_org_name <- if (!is.null(org_name) && length(org_name) &&
    nzchar(trimws(as.character(org_name[[1]])))) {
    trimws(as.character(org_name[[1]]))
  } else {
    "Organization Name"
  }

  org_name_value <- get_named_value(row, "orgname", fallback = fallback_org_name)
  years_served <- get_named_value(row, "lengthserve")

  # Demographics are already cleaned by the transform; read them by name.
  pct_age_12_17 <- get_named_value(row, "pct_age_12_17")
  pct_age_18_25 <- get_named_value(row, "pct_age_18_25")
  pct_age_over26 <- get_named_value(row, "pct_age_over26")
  pct_women <- get_named_value(row, "pct_women")
  pct_men <- get_named_value(row, "pct_men")
  pct_gender <- get_named_value(row, "pct_gender")
  pct_disabilities <- get_named_value(row, "pct_disabilities")
  pct_spiritual <- get_named_value(row, "pct_spiritual")
  pct_race_eth <- get_named_value(row, "pct_race_eth")
  pct_us_born <- get_named_value(row, "pct_us_born")
  pct_queer <- get_named_value(row, "pct_queer")

  orgservices <- parse_orgservices_json(get_named_value(row, "orgservices_json", ""))
  established_categories <- get_dimension_categories(orgservices, lang, "established")
  emerging_categories <- get_dimension_categories(orgservices, lang, "emerging")

  labels <- list(
    page_subtitle_fallback = get_organization_details_label(details, "page_subtitle_fallback", "Organization details"),
    org_subtitle = get_organization_details_label(details, "org_subtitle", "Serving youth in Greater Boston"),
    card_age_title = get_organization_details_label(details, "card_age_title", "Age Breakdown"),
    age_12_17 = get_organization_details_label(details, "age_12_17", "12-17 yrs old"),
    age_18_25 = get_organization_details_label(details, "age_18_25", "18-25 yrs old"),
    age_26_plus = get_organization_details_label(details, "age_26_plus", "26+ yrs old"),
    card_gender_title = get_organization_details_label(details, "card_gender_title", "Gender Identity"),
    gender_women = get_organization_details_label(details, "gender_women", "Identifies as women"),
    gender_men = get_organization_details_label(details, "gender_men", "Identifies as men"),
    gender_other = get_organization_details_label(details, "gender_other", "Identifies as another gender identity"),
    card_other_demographics_title = get_organization_details_label(details, "card_other_demographics_title", "Additional Demographics"),
    other_disabilities = get_organization_details_label(details, "other_disabilities", "With one or more disabilities"),
    other_spiritual = get_organization_details_label(details, "other_spiritual", "Identifies with a religious or spiritual practice"),
    other_race_eth = get_organization_details_label(details, "other_race_eth", "People of color"),
    other_us_born = get_organization_details_label(details, "other_us_born", "Born in the United States"),
    other_queer = get_organization_details_label(details, "other_queer", "Identifies as LGBTQIA+")
  )

  list(
    details = details,
    labels = labels,
    orgname = org_name_value,
    lengthserve = years_served,
    pct_age_12_17 = pct_age_12_17,
    pct_age_18_25 = pct_age_18_25,
    pct_age_over26 = pct_age_over26,
    pct_women = pct_women,
    pct_men = pct_men,
    pct_gender = pct_gender,
    pct_disabilities = pct_disabilities,
    pct_spiritual = pct_spiritual,
    pct_race_eth = pct_race_eth,
    pct_us_born = pct_us_born,
    pct_queer = pct_queer,
    established_categories = established_categories,
    emerging_categories = emerging_categories,
    has_data = nrow(row) > 0
  )
}

TRANSLATIONS_DIR <- file.path("data", "translations")

load_app_translations <- local({
  cached <- NULL

  function(dir = TRANSLATIONS_DIR) {
    if (!is.null(cached)) {
      return(cached)
    }

    if (!dir.exists(dir)) {
      stop(sprintf("Expected translations directory at '%s'.", dir), call. = FALSE)
    }

    if (!requireNamespace("jsonlite", quietly = TRUE)) {
      stop("Package 'jsonlite' is required. Run make install.", call. = FALSE)
    }

    files <- list.files(dir, pattern = "\\.json$", full.names = TRUE)
    if (!length(files)) {
      stop(sprintf("No .json files found in translations directory '%s'.", dir), call. = FALSE)
    }

    loaded <- lapply(files, function(f) {
      content <- jsonlite::fromJSON(f, simplifyVector = FALSE)
      if (!is.list(content) || !length(content)) {
        stop(sprintf("Translations file '%s' is empty or invalid.", f), call. = FALSE)
      }
      content
    })
    # Name each entry by its locale code (filename without .json)
    names(loaded) <- tools::file_path_sans_ext(basename(files))

    cached <<- loaded
    cached
  }
})

# All translations as JSON for the client (window.APP_TRANSLATIONS in app.js),
# which uses them for the wellness wheel and theme-settings panel.
get_frontend_translations_json <- function() {
  if (!requireNamespace("jsonlite", quietly = TRUE)) {
    stop("Package 'jsonlite' is required. Run make install.", call. = FALSE)
  }

  jsonlite::toJSON(
    load_app_translations(),
    auto_unbox = TRUE,
    pretty = FALSE,
    null = "null"
  )
}
