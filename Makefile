RSCRIPT := Rscript

.DEFAULT_GOAL := help

.PHONY: help install test run encrypt-data decrypt-data manifest

help: ## Show available targets and descriptions
	@awk 'BEGIN {FS = ":.*## "; printf "Usage:\n  make <target>\n\nTargets:\n"} /^[a-zA-Z_-]+:.*## / {printf "  %-10s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install required R packages (shiny, shiny.router, testthat, openssl, digest, rsconnect)
	@$(RSCRIPT) -e "install.packages(c('shiny', 'shiny.router', 'testthat', 'openssl', 'digest', 'rsconnect'), repos = 'https://cloud.r-project.org')"

test: ## Run testthat tests from tests/testthat
	@$(RSCRIPT) -e "library(testthat); test_dir('tests/testthat', reporter = 'progress')"

run: ## Run the Shiny app on host 0.0.0.0 and port 3838
	@$(RSCRIPT) -e "options(shiny.autoreload = TRUE); shiny::runApp('.', host = '0.0.0.0', port = 3838)"

encrypt-data: ## Encrypt data/survey_data.csv -> data/survey_data.csv.enc (requires CPA_DATA_KEY)
	@set -a; [ -f .env ] && . ./.env; set +a; \
	$(RSCRIPT) -e "source('R/data.R'); encrypt_data_file()"

decrypt-data: ## Decrypt data/survey_data.csv.enc -> data/survey_data.csv (requires CPA_DATA_KEY)
	@set -a; [ -f .env ] && . ./.env; set +a; \
	$(RSCRIPT) -e "source('R/data.R'); decrypt_data_file()"

manifest: ## Generate manifest.json for Posit Connect/Connect Cloud
	@$(RSCRIPT) R/scripts/write_manifest.R
