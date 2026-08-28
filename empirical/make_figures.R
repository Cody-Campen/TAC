# make_figures.R
# Builds the empirical figure for sections/05_empirical_results.tex.
# theme_apa_minimal() comes from style.R.

library(ggplot2)

# Printed size in inches, handed to ggsave() by main.R.
emp_figure_size <- list(width = 6, height = 4.5)

group_colors <- c(control = "#404040", treatment = "#A0A0A0")

# Draws the empirical scatter with a fitted line per group.
# It needs the cleaned observations only, not the saved model object.
make_empirical_figure <- function(cleaned) {
  ggplot(cleaned, aes(x = x1, y = y, color = group, shape = group)) +
    geom_point(size = 1.6, alpha = 0.8) +
    geom_smooth(method = "lm", se = FALSE, linewidth = 0.7) +
    scale_color_manual(values = group_colors, name = "Group") +
    scale_shape_discrete(name = "Group") +
    labs(x = expression(X[1]), y = "Y") +
    theme_apa_minimal()
}
