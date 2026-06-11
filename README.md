# CPA-Dashboard

CPA-Dashboard is a Shiny application built with `shiny.router` and Tabler UI templates. The app currently focuses on browsing organizations, viewing an organization's profile, and selecting an organization from data loaded from `data/survey_data.csv`.

## What’s included

- A routed Shiny app with a shared layout and page templates.
- A login page whose organization picker is populated from `data/survey_data.csv`.
- An organizations list page and an organization details page.
- A small test suite that checks app startup, template rendering, and data helpers.

## Project structure

- `app.R` boots the app.
- `R/helpers.R` contains shared app helpers.
- `R/data.R` loads survey data and extracts organization names.
- `R/ui.R` wires the router and top-level UI.
- `R/server.R` handles route-specific rendering.
- `R/templates/` contains reusable UI pieces:
  - `layout/` for shared layout components like the header
  - `pages/` for full page templates
  - `components/` for smaller UI fragments used by pages
- `data/survey_data.csv` is the source for the organization select list.

## Setup

Install required R packages:

```bash
make install
```

## Run the app

```bash
make run
```

This starts the app on `http://0.0.0.0:3838`.

## Routing

The app currently defines these routes:

- `/` - home page
- `login` - login page
- `organizations` - organization list page
- `organizations/details` - organization details page

## Data flow

The organization selector on the login page is generated from `data/survey_data.csv`.

- `load_survey_data()` reads the file and skips the extra header rows.
- `get_org_names()` extracts, trims, deduplicates, and sorts the organization names.
- `organizations_list_ui()` renders those names into the `<select>` control.

## Tests

Run the test suite with:

```bash
make test
```

The tests cover:

- app startup
- page and component templates
- router-driven server behavior
- survey data loading and organization name extraction

## Development notes

- The project uses `shiny.router` for navigation.
- Template files are grouped under `R/templates/layout`, `R/templates/pages`, and `R/templates/components`.
- If you add new routes or templates, update the relevant tests so the README and test coverage stay aligned.
