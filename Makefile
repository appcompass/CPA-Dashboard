RSCRIPT := Rscript

.DEFAULT_GOAL := help

.PHONY: help install test run

help: ## Show available targets and descriptions
	@awk 'BEGIN {FS = ":.*## "; printf "Usage:\n  make <target>\n\nTargets:\n"} /^[a-zA-Z_-]+:.*## / {printf "  %-10s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install: ## Install required R packages (shiny, testthat)
	@$(RSCRIPT) -e "install.packages(c('shiny', 'testthat', 'remotes'), repos = 'https://cloud.r-project.org')"
	@$(RSCRIPT) -e "remotes::install_github('Appsilon/shiny.router')"

test: ## Run testthat tests from tests/testthat
	@$(RSCRIPT) -e "library(testthat); test_dir('tests/testthat', reporter = 'progress')"

run: ## Run the Shiny app on host 0.0.0.0 and port 3838
	@$(RSCRIPT) -e "options(shiny.autoreload = TRUE); shiny::runApp('.', host = '0.0.0.0', port = 3838)"
