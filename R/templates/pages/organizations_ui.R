# Organizations search page: a name search box, a wellness-area filter sidebar,
# and a card per organization. Filtering happens client-side in www/js/app.js
# using the data-* attributes stamped on the cards and filter checkboxes here.
organizations_ui <- function(lang = get_lang()) {
  organizations <- lang$organizations
  wheel <- lang$wheel
  survey_data <- load_survey_data()
  org_names <- get_org_names(survey_data)

  # Sub-categories shown under each wellness dimension in the filter sidebar,
  # mirroring the wellness wheel taxonomy (www/js/app.js WHEEL_META).
  dimension_sub_keys <- list(
    physical = c("wellness_physical_fitness", "wellness_physical_nutrition", "wellness_physical_screenings", "wellness_physical_other"),
    emotional = c("sub_emotional_1", "sub_emotional_2", "sub_emotional_3", "wellness_physical_other"),
    intellectual = c("sub_intellectual_1", "sub_intellectual_2", "sub_intellectual_3", "wellness_physical_other"),
    occupational = c("sub_occupational_1", "sub_occupational_2", "sub_occupational_3", "sub_occupational_4", "wellness_physical_other"),
    financial = c("sub_financial_1", "sub_financial_2", "sub_financial_3", "wellness_physical_other"),
    social = c("sub_social_1", "sub_social_2", "sub_social_3", "wellness_physical_other"),
    environmental = c("sub_environmental_1", "sub_environmental_2", "sub_environmental_3", "wellness_physical_other"),
    spiritual = c("sub_spiritual_1", "sub_spiritual_2", "sub_spiritual_3", "sub_spiritual_4", "wellness_physical_other")
  )

  # Sub-category labels live in either the organizations or wheel translation scope.
  sub_label <- function(key) organizations[[key]] %||% wheel[[key]] %||% key

  # Dimension -> Tabler text color for the established-areas badges, matching the
  # order/colors of the source template. Labels come from the translations.
  established_badge_colors <- c(
    physical = "text-blue",
    emotional = "text-azure",
    intellectual = "text-purple",
    occupational = "text-red",
    financial = "text-yellow",
    social = "text-green",
    environmental = "text-teal",
    spiritual = "text-cyan"
  )

  # The dimension labels repeat a shared word (e.g. "Physical wellness",
  # "Emotional wellness"). Drop the word common to every label so the badges read
  # just "Physical", "Emotional", etc. Computing the common word keeps this working
  # across languages instead of hard-coding "wellness".
  dimension_common_words <- {
    word_sets <- lapply(DIMENSION_LABEL_KEYS, function(label_key) {
      tolower(strsplit(trimws(organizations[[label_key]] %||% ""), "\\s+")[[1]])
    })
    Reduce(intersect, word_sets)
  }

  strip_common_words <- function(label) {
    words <- strsplit(trimws(label), "\\s+")[[1]]
    kept <- words[!tolower(words) %in% dimension_common_words]
    if (!length(kept)) label else paste(kept, collapse = " ")
  }

  render_established_badges <- function(orgservices) {
    badges <- lapply(names(DIMENSION_LABEL_KEYS), function(key) {
      dim <- orgservices[[key]]
      if (is.null(dim) || !identical(dim$state, "established")) {
        return(NULL)
      }
      label <- organizations[[DIMENSION_LABEL_KEYS[[key]]]]
      if (is.null(label) || !nzchar(label)) {
        return(NULL)
      }
      label <- strip_common_words(label)
      tags$span(
        class = paste("badge badge-outline", established_badge_colors[[key]], "badge-sm"),
        label
      )
    })
    Filter(Negate(is.null), badges)
  }

  serving_icon <- tags$svg(
    xmlns = "http://www.w3.org/2000/svg",
    width = "24",
    height = "24",
    viewBox = "0 0 24 24",
    fill = "none",
    stroke = "currentColor",
    `stroke-width` = "2",
    `stroke-linecap` = "round",
    `stroke-linejoin` = "round",
    class = "icon icon-2",
    tags$path(d = "M20.942 13.021a9 9 0 1 0 -9.407 7.967"),
    tags$path(d = "M12 7v5l3 3"),
    tags$path(d = "M15 19l2 2l4 -4")
  )

  # Dimension keys whose state matches `state_value` for a given organization.
  # Drives both the card data attributes and the sidebar filter matching.
  dimension_keys_by_state <- function(orgservices, state_value) {
    matched <- Filter(function(key) {
      dim <- orgservices[[key]]
      !is.null(dim) && identical(dim$state, state_value)
    }, names(DIMENSION_LABEL_KEYS))
    unlist(matched, use.names = FALSE)
  }

  # Match a stored survey service string against a subcategory label, tolerant of
  # trailing detail ("Educational workshops, e.g. ...") and minor word forms
  # ("Nutrition" vs "Nutritional"). Both inputs are already lowercased/trimmed.
  service_matches_label <- function(service, label) {
    if (!nzchar(service) || !nzchar(label)) {
      return(FALSE)
    }
    if (service == label || startsWith(service, label) || startsWith(label, service)) {
      return(TRUE)
    }
    sw <- strsplit(service, "\\s+")[[1]]
    lw <- strsplit(label, "\\s+")[[1]]
    length(sw) == length(lw) && length(sw) > 0 &&
      all(mapply(function(a, b) startsWith(a, b) || startsWith(b, a), sw, lw))
  }

  # Subcategory keys an organization provides as ESTABLISHED services. Each curated
  # subcategory it matches is emitted by its key; any established service in a
  # dimension that matches no curated subcategory contributes a dimension-specific
  # "<dimension>_other" key (the "Other" catch-all).
  established_subcat_keys <- function(orgservices) {
    out <- character(0)
    for (key in names(DIMENSION_LABEL_KEYS)) {
      dim <- orgservices[[key]]
      if (is.null(dim) || !identical(dim$state, "established")) next
      services <- tolower(trimws(vapply(dim$services %||% list(), as.character, character(1))))
      services <- services[nzchar(services)]
      if (!length(services)) next

      curated_keys <- setdiff(dimension_sub_keys[[key]], "wellness_physical_other")
      curated_labels <- tolower(trimws(vapply(curated_keys, sub_label, character(1))))
      has_other <- FALSE
      for (service in services) {
        matched <- vapply(curated_labels, service_matches_label, logical(1), service = service)
        if (any(matched)) {
          out <- c(out, curated_keys[matched])
        } else {
          has_other <- TRUE
        }
      }
      if (has_other) {
        out <- c(out, paste0(key, "_other"))
      }
    }
    unique(out)
  }

  # A checkbox per wellness dimension with its sub-categories nested underneath.
  # Every box is tagged so the client-side filter can match it against each
  # organization's areas; children inherit their parent's dimension. `group` is
  # the data-filter-group value (currently only "established").
  filter_checkbox <- function(group, dimension, role, label, subcat = NULL) {
    tags$label(
      class = if (identical(role, "child")) "form-check mt-1" else "form-check",
      tags$input(
        type = "checkbox",
        class = "form-check-input",
        `data-filter-group` = group,
        `data-filter-dimension` = dimension,
        `data-filter-role` = role,
        `data-filter-subcat` = subcat
      ),
      tags$span(class = "form-check-label", label)
    )
  }

  render_wellness_groups <- function(group) {
    tagList(lapply(names(DIMENSION_LABEL_KEYS), function(key) {
      children <- lapply(dimension_sub_keys[[key]], function(sub_key) {
        # "Other" is the dimension-specific catch-all (<dimension>_other).
        subcat <- if (identical(sub_key, "wellness_physical_other")) {
          paste0(key, "_other")
        } else {
          sub_key
        }
        filter_checkbox(group, key, "child", sub_label(sub_key), subcat = subcat)
      })
      div(
        class = "mb-2",
        filter_checkbox(group, key, "parent", organizations[[DIMENSION_LABEL_KEYS[[key]]]]),
        div(class = "ms-4", children)
      )
    }))
  }

  organization_card <- function(org_name, orgservices = list(), lengthserve = "") {
    initials <- toupper(substr(gsub("[^A-Za-z0-9]", "", org_name), 1, 2))
    if (!nzchar(initials)) {
      initials <- "OR"
    }

    serving_text <- if (nzchar(lengthserve) && !identical(lengthserve, "N/A")) {
      paste(lengthserve, organizations$card_serving_text)
    } else {
      organizations$card_serving_text
    }

    div(
      class = "card",
      div(
        class = "row g-0",
        div(
          class = "col-auto",
          div(
            class = "card-body",
            div(
              class = "avatar avatar-md",
              style = "background-image: none; background-color: var(--tblr-primary); color: white; display: flex; align-items: center; justify-content: center; font-weight: 600;",
              initials
            )
          )
        ),
        div(
          class = "col",
          div(
            class = "card-body ps-0",
            div(
              class = "row",
              div(
                class = "col-md",
                h3(
                  class = "mb-0",
                  a(
                    href = route_link(sprintf("organizations/details?id=%s", utils::URLencode(org_name, reserved = TRUE))),
                    org_name
                  )
                )
              ),
              div(class = "col-md-auto", h5(organizations$card_established_areas_label))
            ),
            div(
              class = "row",
              div(
                class = "col-md",
                div(
                  class = "mt-3 list-inline list-inline-dots mb-0 text-secondary d-sm-block d-none",
                  div(class = "list-inline-item", serving_icon, serving_text)
                ),
                div(
                  class = "mt-3 list mb-0 text-secondary d-block d-sm-none",
                  div(class = "list-item", serving_icon, serving_text)
                )
              ),
              div(
                class = "col-md-auto",
                div(class = "mt-3 badges-list", render_established_badges(orgservices))
              )
            )
          )
        )
      )
    )
  }

  tagList(
    div(
      class = "page-header d-print-none",
      `aria-label` = "Page header",
      div(
        class = "container-xl",
        div(
          class = "row g-2 align-items-center",
          div(class = "col", h2(class = "page-title", organizations$page_title)),
          div(
            class = "col-auto ms-auto d-print-none",
            div(
              class = "mb-3",
              tags$input(
                id = "organizations-search",
                type = "text",
                class = "form-control",
                placeholder = organizations$search_placeholder,
                autocomplete = "off",
                `aria-label` = organizations$search_placeholder
              )
            )
          )
        )
      )
    ),
    div(
      class = "page-body",
      div(
        class = "container-xl",
        div(
          class = "row g-4",
          div(
            class = "col-md-3",
            tags$form(
              id = "organizations-filter",
              autocomplete = "off",
              # Filtering is live; never let the form do a GET navigation/reload.
              onsubmit = "return false;",
              class = "sticky-top",
              div(class = "form-label", organizations$filter_established_label),
              div(
                class = "mb-4",
                render_wellness_groups("established")
              ),
              div(
                class = "mt-5",
                tags$button(
                  type = "button",
                  id = "organizations-filter-reset",
                  class = "btn btn-link w-100",
                  organizations$btn_reset_filter
                )
              )
            )
          ),
          div(
            class = "col-md-9",
            div(
              class = "row row-cards",
              id = "organizations-results",
              if (!length(org_names)) {
                div(
                  class = "col-12",
                  div(
                    class = "alert alert-info",
                    organizations$search_empty_data %||%
                      "No organizations are available in the stored data."
                  )
                )
              } else {
                tagList(
                  lapply(org_names, function(org_name) {
                    row <- get_organization_details_row(org_name = org_name, survey_data = survey_data)
                    orgservices <- parse_orgservices_json(get_named_value(row, "orgservices_json", ""))
                    lengthserve <- get_named_value(row, "lengthserve", fallback = "")
                    div(
                      class = "col-12 organization-result",
                      `data-org-name` = tolower(org_name),
                      `data-established` = paste(dimension_keys_by_state(orgservices, "established"), collapse = ","),
                      `data-established-subcats` = paste(established_subcat_keys(orgservices), collapse = ","),
                      organization_card(org_name, orgservices, lengthserve)
                    )
                  }),
                  div(
                    id = "organizations-no-results",
                    class = "col-12 d-none",
                    div(
                      class = "alert alert-info",
                      organizations$search_no_results %||%
                        "No organizations match your search."
                    )
                  )
                )
              }
            )
          )
        )
      )
    )
  )
}
