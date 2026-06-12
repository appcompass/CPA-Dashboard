lang_change_nav_link_ui <- function(active_code = Sys.getenv("APP_LANG", "en")) {
  if (!active_code %in% rownames(SUPPORTED_LANGUAGES)) {
    active_code <- "en"
  }

  active_flag <- SUPPORTED_LANGUAGES[active_code, "flag_icon"]

  items <- lapply(rownames(SUPPORTED_LANGUAGES), function(code) {
    language_label <- SUPPORTED_LANGUAGES[code, "label"]
    flag_class <- SUPPORTED_LANGUAGES[code, "flag_icon"]

    tags$a(
      href = "#",
      class = paste(
        "list-group-item list-group-item-action d-flex align-items-center gap-2",
        if (identical(code, active_code)) "active" else ""
      ),
      onclick = sprintf(
        "Shiny.setInputValue('selected_lang', { code: '%s', search: window.location.search || '', hash: window.location.hash || '' }, {priority: 'event'}); return false;",
        code
      ),
      tags$span(class = paste("flag lang-dropdown-flag", flag_class)),
      tags$span(class = "fw-semibold", language_label)
    )
  })

  tags$li(
    class = "nav-item dropdown d-none d-md-flex",
    tags$a(
      href = "#",
      class = "nav-link px-0",
      `data-bs-toggle` = "dropdown",
      `data-bs-auto-close` = "outside",
      `aria-label` = "Supported languages",
      tags$span(class = paste("nav-link-icon flag lang-toggle-flag", active_flag))
    ),
    tags$div(
      class = "dropdown-menu dropdown-menu-arrow dropdown-menu-end dropdown-menu-card",
      tags$div(
        class = "card",
        tags$div(
          class = "card-body scroll-y p-2",
          style = "max-height: 50vh",
          tags$div(
            class = "list-group list-group-flush",
            items
          )
        )
      )
    )
  )
}
