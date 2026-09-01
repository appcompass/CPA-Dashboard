# Full page shell (formerly www/html/index.html). Shiny injects its own and the
# router's head dependencies into <head> when the UI is a complete <html> tag.

# A single radio option in the theme-settings panel. `i18n` is the translation
# key consumed client-side by applyThemeSettingsTranslations (www/js/app.js).
theme_radio <- function(group, value, label, i18n = NULL, checked = FALSE) {
  tags$label(
    class = "form-check",
    div(
      class = "form-selectgroup-item",
      tags$input(
        type = "radio",
        name = group,
        value = value,
        class = "form-check-input",
        checked = if (checked) NA else NULL
      ),
      div(class = "form-check-label", `data-i18n` = i18n, label)
    )
  )
}

# A single colour swatch in the colour-scheme selector.
theme_color_radio <- function(value) {
  div(
    class = "col-auto",
    tags$label(
      class = "form-colorinput",
      tags$input(
        name = "theme-primary",
        type = "radio",
        value = value,
        class = "form-colorinput-input"
      ),
      tags$span(class = paste0("form-colorinput-color bg-", value))
    )
  )
}

theme_settings_ui <- function() {
  reset_icon <- tags$svg(
    xmlns = "http://www.w3.org/2000/svg",
    width = "24",
    height = "24",
    viewBox = "0 0 24 24",
    fill = "none",
    stroke = "currentColor",
    `stroke-width` = "2",
    `stroke-linecap` = "round",
    `stroke-linejoin` = "round",
    class = "icon icon-1",
    tags$path(d = "M19.95 11a8 8 0 1 0 -.5 4m.5 5v-5h-5")
  )

  tags$form(
    class = "offcanvas offcanvas-start offcanvas-narrow",
    tabindex = "-1",
    id = "offcanvasSettings",
    div(
      class = "offcanvas-header",
      h2(
        class = "offcanvas-title",
        `data-i18n` = "theme_settings.title",
        "Theme Settings"
      ),
      tags$button(
        type = "button",
        class = "btn-close",
        `data-bs-dismiss` = "offcanvas",
        `data-i18n` = "theme_settings.close_aria",
        `data-i18n-attr` = "aria-label",
        `aria-label` = "Close"
      )
    ),
    div(
      class = "offcanvas-body d-flex flex-column",
      div(
        div(
          class = "mb-4",
          tags$label(
            class = "form-label",
            `data-i18n` = "theme_settings.color_mode_label",
            "Color mode"
          ),
          p(
            class = "form-hint",
            `data-i18n` = "theme_settings.color_mode_hint",
            "Choose the color mode for your app."
          ),
          theme_radio("theme", "light", "Light", "theme_settings.options.light", checked = TRUE),
          theme_radio("theme", "dark", "Dark", "theme_settings.options.dark")
        ),
        div(
          class = "mb-4",
          tags$label(
            class = "form-label",
            `data-i18n` = "theme_settings.color_scheme_label",
            "Color scheme"
          ),
          p(
            class = "form-hint",
            `data-i18n` = "theme_settings.color_scheme_hint",
            "The perfect color mode for your app."
          ),
          div(
            class = "row g-2",
            lapply(
              c("blue", "azure", "indigo", "purple", "pink", "red", "orange",
                "yellow", "lime", "green", "teal", "cyan"),
              theme_color_radio
            )
          )
        ),
        div(
          class = "mb-4",
          tags$label(
            class = "form-label",
            `data-i18n` = "theme_settings.font_family_label",
            "Font family"
          ),
          p(
            class = "form-hint",
            `data-i18n` = "theme_settings.font_family_hint",
            "Choose the font family that fits your app."
          ),
          div(
            theme_radio("theme-font", "sans-serif", "Sans-serif", "theme_settings.options.sans_serif", checked = TRUE),
            theme_radio("theme-font", "serif", "Serif", "theme_settings.options.serif"),
            theme_radio("theme-font", "monospace", "Monospace", "theme_settings.options.monospace"),
            theme_radio("theme-font", "comic", "Comic", "theme_settings.options.comic")
          )
        ),
        div(
          class = "mb-4",
          tags$label(
            class = "form-label",
            `data-i18n` = "theme_settings.theme_base_label",
            "Theme base"
          ),
          p(
            class = "form-hint",
            `data-i18n` = "theme_settings.theme_base_hint",
            "Choose the gray shade for your app."
          ),
          div(
            theme_radio("theme-base", "slate", "Slate", "theme_settings.options.slate"),
            theme_radio("theme-base", "gray", "Gray", "theme_settings.options.gray", checked = TRUE),
            theme_radio("theme-base", "zinc", "Zinc", "theme_settings.options.zinc"),
            theme_radio("theme-base", "neutral", "Neutral", "theme_settings.options.neutral"),
            theme_radio("theme-base", "stone", "Stone", "theme_settings.options.stone")
          )
        ),
        div(
          class = "mb-4",
          tags$label(
            class = "form-label",
            `data-i18n` = "theme_settings.corner_radius_label",
            "Corner Radius"
          ),
          p(
            class = "form-hint",
            `data-i18n` = "theme_settings.corner_radius_hint",
            "Choose the border radius factor for your app."
          ),
          div(
            theme_radio("theme-radius", "0", "0"),
            theme_radio("theme-radius", "0.5", "0.5"),
            theme_radio("theme-radius", "1", "1", checked = TRUE),
            theme_radio("theme-radius", "1.5", "1.5"),
            theme_radio("theme-radius", "2", "2")
          )
        )
      ),
      div(
        class = "mt-auto space-y",
        tags$button(
          type = "button",
          class = "btn w-100",
          id = "reset-changes",
          reset_icon,
          tags$span(`data-i18n` = "theme_settings.reset_changes", "Reset changes")
        ),
        a(
          href = "#",
          class = "btn btn-primary w-100",
          `data-bs-dismiss` = "offcanvas",
          `data-i18n` = "theme_settings.save",
          "Save"
        )
      )
    )
  )
}

# The full page shell. Returns a tagList; Shiny wraps it in its document template
# (<html>/<head>/<body>) and injects its own + the router's head dependencies.
# The tags$head() block is hoisted into <head> by htmltools.
# `router` is the shiny.router UI.
# Cache-busting stamp for a static asset, taken from its mtime.
#
# Browsers cache /css/styles.css and /js/app.js hard, so without a changing
# query string an edit is invisible to anyone who has loaded the page before --
# including every returning visitor to the live site after a deploy. app.js has
# carried a stamp for a while; styles.css did NOT, so a stylesheet change looked
# like it had simply not been applied. Both go through here now, so the next
# asset that gets added cannot quietly miss out.
#
# A missing file makes file.info() return NA rather than erroring, which would
# print "?v=NA" and defeat the point; fall back to 0 for that too.
asset_version <- function(...) {
  stamp <- tryCatch(
    as.integer(as.numeric(file.info(file.path(...))$mtime)),
    error = function(e) NA_integer_
  )
  if (length(stamp) != 1L || is.na(stamp)) 0L else stamp
}

main_ui <- function(router, page_title = "CHANGE Lab") {
  app_css_version <- asset_version("www", "css", "styles.css")
  app_js_version <- asset_version("www", "js", "app.js")

  tagList(
    tags$head(
      tags$meta(
        name = "viewport",
        content = "width=device-width, initial-scale=1, viewport-fit=cover"
      ),
      tags$meta(`http-equiv` = "X-UA-Compatible", content = "ie=edge"),
      tags$title(page_title),
      tags$link(
        rel = "stylesheet",
        href = sprintf("/css/styles.css?v=%d", app_css_version)
      )
    ),
    div(
      class = "page",
      uiOutput("header"),
      div(
        class = "page-wrapper",
        router,
        footer_ui()
      )
    ),
    div(class = "settings", theme_settings_ui()),
    tags$script(src = "https://cdnjs.cloudflare.com/ajax/libs/svg.js/3.2.4/svg.min.js"),
    tags$script(src = "/js/tabler/tabler-theme.min.js"),
    tags$script(src = "/js/tabler/tabler.min.js", defer = NA),
    tags$script(
      HTML(sprintf("window.APP_TRANSLATIONS = %s;", get_frontend_translations_json()))
    ),
    tags$script(src = sprintf("/js/app.js?v=%d", app_js_version))
  )
}
