# CPA-Dashboard

CPA-Dashboard is a Shiny application built with `shiny.router` and Tabler UI templates. The app currently focuses on browsing organizations, viewing an organization's profile, and selecting an organization from survey data.

## What’s included

- A routed Shiny app with a shared layout and page templates.
- A login page whose organization picker is populated from survey data loaded at runtime.
- An organizations list page and an organization details page.
- A small test suite that checks app startup, template rendering, and data helpers.

## Project structure

- `app.R` boots the app.
- `R/data.R` loads the data layer from single-concern modules in `R/data/`
  (encryption, dimension metadata, survey transform pipeline, data access,
  interview data, translations).
- `R/lang.R` loads the translations and language settings.
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

## How updates go live (automatic deployment)

The live dashboard is hosted on Posit Connect Cloud, which is connected to this
GitHub repository. You never have to publish the app by hand — it updates itself.

Here is the whole flow:

1. You make your changes on a branch and open a pull request.
2. A reviewer approves it and merges the pull request into the `main` branch.
3. Posit Connect Cloud notices that `main` has changed, rebuilds the app with
   your latest changes, and publishes it to the live site automatically.

Within a few minutes of merging to `main`, the live dashboard shows your changes.

Good to know:

- Only changes merged into `main` go live. Work on other branches is safe to
  experiment with and won't affect the live site.
- Every pull request automatically runs the test suite first, so problems are
  usually caught before anything reaches `main`.
- The secret data key (`CPA_DATA_KEY`) lives securely inside Posit Connect Cloud,
  which lets the live app read the encrypted survey data. It is never stored in
  the code.

### When you add or remove files

Connect Cloud reads a `manifest.json` file in the project root to know which
files and R packages the app needs. If you add, rename, or remove files (or add
a new R package), refresh that list and commit it as part of your change:

```bash
make manifest
```

If a deploy fails with `Unable to locate manifest.json`, regenerate it with the
command above and commit the result.

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

1. Encrypt a plaintext survey file:

```bash
INPUT=/path/to/survey_data.csv OUTPUT=data/survey_data.csv.enc make encrypt-data
```

This creates `data/survey_data.csv.enc`.

1. Run the app with `CPA_DATA_KEY` set so it can decrypt at runtime.

Optional: decrypt locally for inspection/debugging:

```bash
INPUT=data/survey_data.csv.enc OUTPUT=/tmp/survey_data.csv make decrypt-data
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
