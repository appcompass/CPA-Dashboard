# Editor formatting config for the R Language Server (REditorSupport.r extension).
# Makes "Format Document" / format-on-save use the same `styler` tidyverse style
# the repo was formatted with: tidyverse_style(indent_by = <editor tabSize>).
# https://github.com/REditorSupport/languageserver#configuration
options(
  languageserver.formatting_style = function(options) {
    styler::tidyverse_style(indent_by = options$tabSize)
  }
)
