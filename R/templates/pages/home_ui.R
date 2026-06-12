home_ui <- function(lang = get_lang()) {
  home <- lang$home

  tagList(
    h1(home$heading),
    p(home$subtext)
  )
}
