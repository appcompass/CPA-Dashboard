# ---- load_survey_data ----

test_that("load_survey_data returns a data frame with organization column", {
  withr::local_dir(project_root)

  data <- load_survey_data()

  expect_s3_class(data, "data.frame")
  expect_gt(nrow(data), 0L)
  expect_true(any(nzchar(trimws(data[[1]]))))
})

test_that("load_survey_data fails clearly for a missing file", {
  withr::local_dir(project_root)

  expect_error(
    load_survey_data(encrypted_path = tempfile(fileext = ".enc")),
    "Expected encrypted survey data file"
  )
})

test_that("load_survey_data reads encrypted file when present", {
  withr::local_dir(project_root)

  plain <- tempfile(fileext = ".csv")
  enc <- tempfile(fileext = ".enc")
  passphrase <- "test-key"

  writeLines(c("Organization,Other", "Label row,Ignore", "Org A,1", "Org B,2"), plain)

  encrypt_data_file(input_path = plain, output_path = enc, passphrase = passphrase)
  data <- load_survey_data(encrypted_path = enc, passphrase = passphrase)

  expect_equal(nrow(data), 2L)
  expect_equal(data[[1]], c("Org A", "Org B"))
})

test_that("load_survey_data fails for encrypted file when key is missing", {
  withr::local_dir(project_root)

  plain <- tempfile(fileext = ".csv")
  enc <- tempfile(fileext = ".enc")

  writeLines(c("Organization,Other", "Label row,Ignore", "Org A,1"), plain)
  encrypt_data_file(input_path = plain, output_path = enc, passphrase = "secret")

  expect_error(
    load_survey_data(encrypted_path = enc, passphrase = ""),
    "Found encrypted data"
  )
})

test_that("load_organization_details_data reads encrypted file", {
  withr::local_dir(project_root)

  plain <- tempfile(fileext = ".csv")
  enc <- paste0(plain, ".enc")
  passphrase <- "test-key"

  writeLines(
    c(
      "Organization,YearsServed,RoleLength",
      "Organization Name:,How long have you served in this role/title at your organization?,How long have your organization been serving youth in the greater Boston area?",
      "Org A,8+ years,1-3 years"
    ),
    plain
  )

  encrypt_data_file(input_path = plain, output_path = enc, passphrase = passphrase)
  unlink(plain)

  data <- load_organization_details_data(encrypted_path = enc, passphrase = passphrase)

  expect_s3_class(data, "data.frame")
  expect_equal(trimws(data[[1]][1]), "Org A")
  expect_equal(trimws(data[[2]][1]), "8+ years")
})

# ---- get_org_names ----

test_that("get_org_names returns a sorted character vector of unique names", {
  withr::local_dir(project_root)

  orgs <- get_org_names()

  expect_type(orgs, "character")
  expect_gt(length(orgs), 0L)
  expect_equal(orgs, sort(unique(orgs)))
  expect_true(all(nzchar(orgs)))
})

test_that("get_org_names trims whitespace and removes blank entries", {
  fake <- data.frame(V1 = c("  Alpha Org ", "Beta Org", "", "  ", "Alpha Org"),
                     stringsAsFactors = FALSE)

  orgs <- get_org_names(fake)

  expect_equal(orgs, c("Alpha Org", "Beta Org"))
})

test_that("get_org_names deduplicates names", {
  fake <- data.frame(V1 = c("Org A", "Org B", "Org A"),
                     stringsAsFactors = FALSE)

  expect_equal(get_org_names(fake), c("Org A", "Org B"))
})

test_that("get_org_names returns empty vector for all-blank input", {
  fake <- data.frame(V1 = c("", "  "), stringsAsFactors = FALSE)

  expect_equal(get_org_names(fake), character(0))
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

  encrypted[[length(encrypted)]] <- as.raw(
    bitwXor(as.integer(encrypted[[length(encrypted)]]), 1L)
  )

  expect_error(
    decrypt_data_raw(encrypted, passphrase),
    "authentication failed"
  )
})

test_that("decrypt_data_raw supports legacy unauthenticated payload format", {
  withr::local_dir(project_root)

  passphrase <- "legacy-passphrase"
  key <- derive_data_key(passphrase)
  iv <- openssl::rand_bytes(16)
  plain <- charToRaw("legacy ciphertext")
  ciphertext <- openssl::aes_cbc_encrypt(plain, key = key, iv = iv)
  legacy_payload <- c(iv, ciphertext)

  expect_warning(
    out <- decrypt_data_raw(legacy_payload, passphrase),
    "legacy unauthenticated payload"
  )
  expect_equal(rawToChar(out), "legacy ciphertext")
})

test_that("decrypt_data_raw fails for too-short payload", {
  withr::local_dir(project_root)

  expect_error(
    decrypt_data_raw(as.raw(1:8), "passphrase"),
    "invalid or corrupted"
  )
})

test_that("encrypt_data_file fails clearly when key is missing", {
  withr::local_dir(project_root)

  plain <- tempfile(fileext = ".csv")
  writeLines(c("Organization,Other", "Label row,Ignore", "Org A,1"), plain)

  expect_error(
    encrypt_data_file(input_path = plain, output_path = tempfile(fileext = ".enc"), passphrase = ""),
    "Missing encryption key"
  )
})

test_that("assert_survey_data_startup_ready succeeds with encrypted file", {
  withr::local_dir(project_root)

  plain <- tempfile(fileext = ".csv")
  enc <- tempfile(fileext = ".enc")
  writeLines(c("Organization,Other", "Label row,Ignore", "Org A,1"), plain)
  encrypt_data_file(input_path = plain, output_path = enc, passphrase = "secret")

  expect_true(assert_survey_data_startup_ready(encrypted_path = enc, passphrase = "secret"))
})

test_that("assert_survey_data_startup_ready fails when no data files exist", {
  withr::local_dir(project_root)

  expect_error(
    assert_survey_data_startup_ready(encrypted_path = tempfile(fileext = ".enc")),
    "Startup check failed"
  )
})

test_that("assert_survey_data_startup_ready fails for encrypted file without key", {
  withr::local_dir(project_root)

  plain <- tempfile(fileext = ".csv")
  enc <- tempfile(fileext = ".enc")
  writeLines(c("Organization,Other", "Label row,Ignore", "Org A,1"), plain)
  encrypt_data_file(input_path = plain, output_path = enc, passphrase = "secret")

  expect_error(
    assert_survey_data_startup_ready(
      encrypted_path = enc,
      passphrase = "",
      key_env_var = "CPA_DATA_KEY"
    ),
    "CPA_DATA_KEY is not set"
  )
})
