# CPA-Dashboard

Minimal R Shiny backend app using a Vue 3 frontend.

## Run

```bash
Rscript -e "shiny::runApp('.', host = '0.0.0.0', port = 3838)"
```

## Tests

Tests use [`testthat`](https://testthat.r-lib.org/) and [`shiny::testServer()`](https://shiny.posit.co/r/reference/shiny/latest/testserver.html) for server-side unit testing.

Install dependencies once:

```r
install.packages(c("shiny", "testthat"))
```

Run tests from the project root:

```bash
Rscript -e "library(testthat); test_dir('tests/testthat', reporter = 'progress')"
```
