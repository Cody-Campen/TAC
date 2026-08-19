# style.R
# Formatting and plot styling shared by both pipelines, so the paper's
# tables and figures cannot drift apart. Sourced by each main.R before
# the make_* builders that use it.
#
# theme_apa_minimal() needs ggplot2 attached to be *called*; defining it
# here does not, so the table stages can source this file on its own.

#' Fixed-decimal formatting for every number that reaches a table.
#'
#' @param x Numeric vector to format.
#' @param digits Single integer; decimal places to keep.
#' @return Character vector the same length as `x`.
fmt <- function(x, digits = 3) formatC(x, digits = digits, format = "f")

#' The APA-style theme every figure in the paper shares.
#'
#' @param base_size Single number; base font size in points, inherited by
#'   the axis, strip, and legend text.
#' @param base_family Single string naming the base font family.
#' @return A ggplot2 theme object, to be added to a plot.
theme_apa_minimal <- function(base_size = 12, base_family = "serif") {
  theme_minimal(base_size = base_size, base_family = base_family) +
    theme(
      panel.grid.minor = element_blank(),
      panel.grid.major = element_blank(),
      axis.line = element_line(color = "black", linewidth = 0.4),
      axis.ticks = element_line(color = "black", linewidth = 0.4),
      strip.text = element_text(size = base_size),
      legend.title = element_text(size = base_size),
      legend.position = "bottom",
      legend.background = element_blank(),
      legend.key = element_blank()
    )
}
