derive_data_key <- function(passphrase) {
  if (!nzchar(passphrase)) {
    stop("Data encryption key is empty.", call. = FALSE)
  }

  openssl::sha256(charToRaw(passphrase))
}

decrypt_data_raw <- function(encrypted_raw, passphrase) {
  if (length(encrypted_raw) <= 16) {
    stop("Encrypted data is invalid or corrupted.", call. = FALSE)
  }

  iv <- encrypted_raw[1:16]
  ciphertext <- encrypted_raw[-(1:16)]
  key <- derive_data_key(passphrase)

  openssl::aes_cbc_decrypt(ciphertext, key = key, iv = iv)
}

encrypt_data_raw <- function(plain_raw, passphrase) {
  key <- derive_data_key(passphrase)
  iv <- openssl::rand_bytes(16)
  ciphertext <- openssl::aes_cbc_encrypt(plain_raw, key = key, iv = iv)

  c(iv, ciphertext)
}

encrypt_data_file <- function(
    input_path = file.path("data", "survey_data.csv"),
    output_path = paste0(input_path, ".enc"),
    passphrase = Sys.getenv("CPA_DATA_KEY"),
    key_env_var = "CPA_DATA_KEY") {
  if (!requireNamespace("openssl", quietly = TRUE)) {
    stop("Package 'openssl' is required. Run make install.", call. = FALSE)
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
    key_env_var = "CPA_DATA_KEY") {
  if (!requireNamespace("openssl", quietly = TRUE)) {
    stop("Package 'openssl' is required. Run make install.", call. = FALSE)
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
    passphrase = Sys.getenv(key_env_var)) {
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
    key_env_var = "CPA_DATA_KEY") {
  if (!file.exists(encrypted_path)) {
    stop(
      sprintf("Expected encrypted survey data file at '%s'.", encrypted_path),
      call. = FALSE
    )
  }

  if (!requireNamespace("openssl", quietly = TRUE)) {
    stop("Package 'openssl' is required. Run make install.", call. = FALSE)
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
