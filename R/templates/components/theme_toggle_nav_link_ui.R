theme_toggle_nav_link_ui <- function(search = "", hash = "", lang = get_lang()) {
  header <- lang$header

  if (is.null(search) || !is.character(search) || length(search) != 1) {
    search <- ""
  }
  if (is.null(hash) || !is.character(hash) || length(hash) != 1) {
    hash <- ""
  }

  query <- shiny::parseQueryString(search)

  theme_value <- query[["theme"]]
  if (is.null(theme_value) || !length(theme_value)) {
    current_theme <- "light"
  } else {
    current_theme <- tolower(trimws(as.character(theme_value[[1]])))
  }

  is_valid_theme <- identical(current_theme, "light") || identical(current_theme, "dark")
  if (is.na(current_theme) || !nzchar(current_theme) || !is_valid_theme) {
    current_theme <- "light"
  }

  next_theme <- if (identical(current_theme, "dark")) "light" else "dark"
  query[["theme"]] <- next_theme

  query_names <- names(query)
  if (is.null(query_names) || !length(query_names)) {
    next_search <- paste0("?theme=", utils::URLencode(next_theme, reserved = TRUE))
  } else {
    query_parts <- vapply(
      query_names,
      function(key) {
        paste0(
          utils::URLencode(key, reserved = TRUE),
          "=",
          utils::URLencode(as.character(query[[key]]), reserved = TRUE)
        )
      },
      character(1)
    )
    next_search <- paste0("?", paste(query_parts, collapse = "&"))
  }

  next_label <- if (identical(next_theme, "dark")) {
    header$enable_dark_mode_aria
  } else {
    header$enable_light_mode_aria
  }
  next_title <- if (identical(next_theme, "dark")) {
    header$enable_dark_mode_title
  } else {
    header$enable_light_mode_title
  }

  tags$div(
    class = "nav-item d-flex align-items-center me-2",
    a(
      href = paste0(next_search, hash),
      id = "theme-toggle",
      class = "nav-link px-0",
      `data-bs-toggle` = "tooltip",
      `data-bs-placement` = "bottom",
      `aria-label` = next_label,
      `data-bs-original-title` = next_title,
      tags$svg(
        xmlns = "http://www.w3.org/2000/svg",
        width = "24",
        height = "24",
        viewBox = "0 0 24 24",
        fill = "none",
        stroke = "currentColor",
        `stroke-width` = "2",
        `stroke-linecap` = "round",
        `stroke-linejoin` = "round",
        class = "icon icon-1 hide-theme-dark",
        tags$path(d = "M12 3c.132 0 .263 0 .393 0a7.5 7.5 0 0 0 7.92 12.446a9 9 0 1 1 -8.313 -12.454z")
      ),
      tags$svg(
        xmlns = "http://www.w3.org/2000/svg",
        width = "24",
        height = "24",
        viewBox = "0 0 24 24",
        fill = "none",
        stroke = "currentColor",
        `stroke-width` = "2",
        `stroke-linecap` = "round",
        `stroke-linejoin` = "round",
        class = "icon icon-1 hide-theme-light",
        tags$path(d = "M12 12m-4 0a4 4 0 1 0 8 0a4 4 0 1 0 -8 0"),
        tags$path(d = "M3 12h1m8 -9v1m8 8h1m-9 8v1m-6.4 -15.4l.7 .7m12.1 -.7l-.7 .7m0 11.4l.7 .7m-12.1 -.7l-.7 .7")
      )
    )
  )
}
