# style.R
# Formatting and plot styling shared by both pipelines.
# Sourced by each main.R before the make_* builders that use it.

# Fixed-decimal formatting for every number that reaches a table.
fmt <- function(x, digits = 3) formatC(x, digits = digits, format = "f")

# The APA-style theme every figure in the paper shares.
# Calling it needs ggplot2 attached, but defining it does not.
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
