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
