DATA_ENCRYPTION_MAGIC <- charToRaw("CPA2")

derive_data_key <- function(passphrase) {
  if (!nzchar(passphrase)) {
    stop("Data encryption key is empty.", call. = FALSE)
  }

  openssl::sha256(charToRaw(passphrase))
}

derive_data_keys <- function(passphrase) {
  master_key <- derive_data_key(passphrase)

  list(
    enc_key = openssl::sha256(c(charToRaw("enc"), master_key)),
    mac_key = openssl::sha256(c(charToRaw("mac"), master_key))
  )
}

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

encrypt_data_raw <- function(plain_raw, passphrase) {
  keys <- derive_data_keys(passphrase)
  iv <- openssl::rand_bytes(16)
  ciphertext <- openssl::aes_cbc_encrypt(plain_raw, key = keys$enc_key, iv = iv)
  payload <- c(DATA_ENCRYPTION_MAGIC, iv, ciphertext)
  mac <- compute_data_mac(payload, keys$mac_key)

  c(payload, mac)
}

encrypt_data_file <- function(
  input_path = file.path("data", "survey_data.csv"),
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
  output_path = file.path("data", "survey_data.csv"),
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

load_survey_data <- function(
  encrypted_path = file.path("data", "survey_data.csv.enc"),
  passphrase = Sys.getenv("CPA_DATA_KEY"),
  key_env_var = "CPA_DATA_KEY"
) {
  if (!file.exists(encrypted_path)) {
    stop(
      sprintf("Expected encrypted survey data file at '%s'.", encrypted_path),
      call. = FALSE
    )
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
        encrypted_path,
        key_env_var
      ),
      call. = FALSE
    )
  }

  encrypted_raw <- readBin(encrypted_path, what = "raw", n = file.info(encrypted_path)$size)
  plain_raw <- decrypt_data_raw(encrypted_raw, passphrase)

  temp_path <- tempfile(fileext = ".csv")
  on.exit(unlink(temp_path), add = TRUE)
  writeBin(plain_raw, temp_path)

  read.csv(temp_path, skip = 2, header = FALSE, stringsAsFactors = FALSE)
}

get_org_names <- function(survey_data = load_survey_data()) {
  names <- sort(unique(trimws(survey_data[[1]])))
  names[nzchar(names)]
}

load_organization_details_data <- function(path = file.path("data", "survey_data.csv")) {
  if (!file.exists(path)) {
    stop(sprintf("Expected data file at '%s'.", path), call. = FALSE)
  }

  read.csv(path, skip = 1, stringsAsFactors = FALSE)
}

get_organization_details_value <- function(row, index, fallback = "N/A") {
  if (is.null(row) || !nrow(row) || index > ncol(row)) {
    return(fallback)
  }

  value <- trimws(as.character(row[[index]][[1]]))
  if (!nzchar(value) || identical(value, "NA")) {
    fallback
  } else {
    value
  }
}

get_organization_details_row <- function(
  org_name = NULL,
  survey_data = load_organization_details_data()
) {
  org_names <- trimws(as.character(survey_data[[1]]))

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
    if (!length(non_empty_rows)) {
      NA_integer_
    } else {
      non_empty_rows[[1]]
    }
  }

  if (is.na(selected_row_index)) {
    return(survey_data[0, , drop = FALSE])
  }

  survey_data[selected_row_index, , drop = FALSE]
}

get_organization_details_wheel_categories <- function(row, lang, status_value) {
  if (is.null(row) || !nrow(row)) {
    return(character(0))
  }

  organizations <- lang$organizations

  category_specs <- list(
    list(label = organizations$wellness_emotional, status = get_organization_details_value(row, 30), choice = get_organization_details_value(row, 31)),
    list(label = organizations$wellness_physical, status = get_organization_details_value(row, 35), choice = get_organization_details_value(row, 33)),
    list(label = organizations$wellness_social, status = get_organization_details_value(row, 40), choice = get_organization_details_value(row, 38)),
    list(label = organizations$wellness_intellectual, status = get_organization_details_value(row, 45), choice = get_organization_details_value(row, 43)),
    list(label = organizations$wellness_environmental, status = get_organization_details_value(row, 50), choice = get_organization_details_value(row, 48)),
    list(label = organizations$wellness_occupational, status = get_organization_details_value(row, 55), choice = get_organization_details_value(row, 53)),
    list(label = organizations$wellness_financial, status = get_organization_details_value(row, 60), choice = get_organization_details_value(row, 58)),
    list(label = organizations$wellness_spiritual, status = get_organization_details_value(row, 65), choice = get_organization_details_value(row, 63))
  )

  categories <- vapply(
    category_specs,
    function(spec) {
      if (identical(spec$status, status_value)) {
        spec$label
      } else {
        NA_character_
      }
    },
    character(1)
  )

  categories[!is.na(categories) & nzchar(categories)]
}

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

  fallback_org_name <- if (!is.null(org_name) && length(org_name) && nzchar(trimws(as.character(org_name[[1]])))) {
    trimws(as.character(org_name[[1]]))
  } else {
    "Organization Name"
  }

  org_name_value <- get_organization_details_value(row, 1, fallback = fallback_org_name)
  years_served <- get_organization_details_value(row, 2)
  role_length <- get_organization_details_value(row, 3)

  # Youth served demographics requested by dashboard stakeholders.
  pct_age_12_17 <- get_organization_details_value(row, 4)
  pct_age_18_25 <- get_organization_details_value(row, 5)
  pct_age_over26 <- get_organization_details_value(row, 6)
  pct_women <- get_organization_details_value(row, 10)
  pct_men <- get_organization_details_value(row, 11)
  pct_gender <- get_organization_details_value(row, 12)
  pct_disabilities <- get_organization_details_value(row, 16)
  pct_spiritual <- get_organization_details_value(row, 17)
  pct_race_eth <- get_organization_details_value(row, 18)
  pct_us_born <- get_organization_details_value(row, 19)
  pct_queer <- get_organization_details_value(row, 20)

  established_categories <- get_organization_details_wheel_categories(row, lang, "Established")
  emerging_categories <- get_organization_details_wheel_categories(row, lang, "Emerging")

  list(
    details = details,
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
    role_length = role_length,
    established_categories = established_categories,
    emerging_categories = emerging_categories,
    has_data = nrow(row) > 0
  )
}

TRANSLATIONS_JSON_PATH <- file.path("data", "translations.json")

load_app_translations <- local({
  cached <- NULL

  function(path = TRANSLATIONS_JSON_PATH) {
    if (!is.null(cached)) {
      return(cached)
    }

    if (!file.exists(path)) {
      stop(sprintf("Expected translations file at '%s'.", path), call. = FALSE)
    }

    if (!requireNamespace("jsonlite", quietly = TRUE)) {
      stop("Package 'jsonlite' is required. Run make install.", call. = FALSE)
    }

    loaded <- jsonlite::fromJSON(path, simplifyVector = FALSE)
    if (!is.list(loaded) || !length(loaded)) {
      stop("Translations JSON is empty or invalid.", call. = FALSE)
    }

    cached <<- loaded
    cached
  }
})

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
