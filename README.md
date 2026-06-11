# CPA-Dashboard

CPA-Dashboard is a Shiny application built with `shiny.router` and Tabler UI templates. The app currently focuses on browsing organizations, viewing an organization's profile, and selecting an organization from survey data.

## What’s included

- A routed Shiny app with a shared layout and page templates.
- A login page whose organization picker is populated from survey data loaded at runtime.
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
- `data/survey_data.csv.enc` is the source for the organization select list.

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

## Deploy to Posit Connect Cloud

Connect Cloud expects a `manifest.json` file in the project root.

Generate/update it before publishing:

```bash
make manifest
```

If you see `Unable to locate manifest.json`, regenerate it and republish.

## Routing

The app currently defines these routes:

- `/` - home page
- `login` - login page
- `organizations` - organization list page
- `organizations/details` - organization details page

## Data flow

The organization selector on the login page is generated from survey data.

- `load_survey_data()` reads and decrypts `data/survey_data.csv.enc`.
- For encrypted files, decryption uses the `CPA_DATA_KEY` environment variable at runtime.
- `get_org_names()` extracts, trims, deduplicates, and sorts the organization names.
- `organizations_list_ui()` renders those names into the `<select>` control.

## Encrypted data workflow

You can keep survey data encrypted in a public repository and decrypt it only at app runtime.

1. Set an encryption key in your shell:

```bash
export CPA_DATA_KEY="your-strong-secret"
```

2. Encrypt the plaintext survey file:

```bash
make encrypt-data
```

This creates `data/survey_data.csv.enc`.

3. Remove plaintext before pushing publicly:

```bash
rm -f data/survey_data.csv
```

4. Run the app with `CPA_DATA_KEY` set so it can decrypt at runtime.

Optional: decrypt locally for inspection/debugging:

```bash
make decrypt-data
```

Notes:

- Never commit `CPA_DATA_KEY` to git.
- Store `CPA_DATA_KEY` in deployment secrets (for example Posit Connect, Docker/Kubernetes secrets, or a cloud secret manager).

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
- encrypted data helper and runtime decryption behavior

## Development notes

- The project uses `shiny.router` for navigation.
- Template files are grouped under `R/templates/layout`, `R/templates/pages`, and `R/templates/components`.
- If you add new routes or templates, update the relevant tests so the README and test coverage stay aligned.
