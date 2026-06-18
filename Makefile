RSCRIPT := Rscript

.DEFAULT_GOAL := help

.PHONY: help install test run encrypt encrypt-data decrypt decrypt-data manifest

help: ## Show available targets and descriptions
	@awk 'BEGIN {FS = ":.*## "; printf "Usage:\n  make <target>\n\nTargets:\n"} /^[a-zA-Z_-]+:.*## / {printf "  %-10s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install required R packages (shiny, shiny.router, testthat, openssl, digest, rsconnect)
	@$(RSCRIPT) -e "install.packages(c('shiny', 'shiny.router', 'testthat', 'openssl', 'digest', 'jsonlite', 'withr', 'rsconnect', 'languageserver', 'styler'), repos = 'https://cloud.r-project.org')"

test: ## Run testthat tests from tests/testthat
	@$(RSCRIPT) -e "library(testthat); test_dir('tests/testthat', reporter = 'progress')"

run: ## Run the Shiny app on host 0.0.0.0 and port 3838
	@$(RSCRIPT) -e "options(shiny.autoreload = TRUE); shiny::runApp('.', host = '0.0.0.0', port = 3838)"

encrypt: encrypt-data ## Alias for encrypt-data

encrypt-data: ## Encrypt a plaintext CSV to an encrypted payload (requires CPA_DATA_KEY, INPUT, OUTPUT)
	@test -n "$(INPUT)" || { echo "encrypt-data needs INPUT, e.g. make encrypt-data INPUT=data/plain.csv OUTPUT=data/survey_data.csv.enc"; exit 1; }
	@test -n "$(OUTPUT)" || { echo "encrypt-data needs OUTPUT, e.g. make encrypt-data INPUT=data/plain.csv OUTPUT=data/survey_data.csv.enc"; exit 1; }
	@set -a; [ -f .env ] && . ./.env; set +a; \
	$(RSCRIPT) -e "source('R/data.R'); encrypt_data_file(input_path = '$(INPUT)', output_path = '$(OUTPUT)')"

decrypt: decrypt-data ## Alias for decrypt-data

decrypt-data: ## Decrypt an encrypted payload to a CSV (requires CPA_DATA_KEY; INPUT/OUTPUT default to data/survey_data.csv.enc -> data/survey_data.csv)
	@set -a; [ -f .env ] && . ./.env; set +a; \
	$(RSCRIPT) -e "source('R/data.R'); decrypt_data_file(encrypted_path = '$(or $(INPUT),data/survey_data.csv.enc)', output_path = '$(or $(OUTPUT),data/survey_data.csv)')"

manifest: ## Generate manifest.json for Posit Connect/Connect Cloud
	@$(RSCRIPT) R/scripts/write_manifest.R
