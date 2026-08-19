# make_figures.R
# Builds the empirical figure from the cleaned data. empirical/main.R
# saves it to empirical/figures/fig_empirical.png, \includegraphics'd by
# sections/05_empirical_results.tex.
#
# Pure -- theme_apa_minimal() comes from shared/style.R.

library(ggplot2)

group_colors <- c(control = "#404040", treatment = "#A0A0A0")

#' Draws the empirical scatter with a fitted line per group.
#'
#' @param cleaned Data frame from clean_dataset(), with `x1`, `y`, and
#'   factor `group`.
#' @return A ggplot object.
# Fitted lines are drawn by geom_smooth() from the same data, so this
# needs the cleaned observations only, not the saved model object.
make_empirical_figure <- function(cleaned) {
  ggplot(cleaned, aes(x = x1, y = y, color = group, shape = group)) +
    geom_point(size = 1.6, alpha = 0.8) +
    geom_smooth(method = "lm", se = FALSE, linewidth = 0.7) +
    scale_color_manual(values = group_colors, name = "Group") +
    scale_shape_discrete(name = "Group") +
    labs(x = expression(X[1]), y = "Y") +
    theme_apa_minimal()
}
