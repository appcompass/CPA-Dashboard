# CPA-Dashboard

Minimal R Shiny backend app using a Vue 3 frontend.

## Run

```bash
cd /path/to/CPA-Dashboard
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

Tests cover:
- `shinyApp()` returns a valid Shiny app object
- `backend_clicks` output defaults to `"Received from Vue: 0"` when no clicks are received
- `backend_clicks` output reflects the Vue click count when `vue_clicks` is set
