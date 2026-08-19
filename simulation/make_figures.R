# make_figures.R
# Builds the simulation results figure. simulation/main.R saves it to
# simulation/figures/fig_sim.png, \includegraphics'd by
# sections/03_simulation_results.tex.
#
# Pure -- theme_apa_minimal() comes from style.R.

library(ggplot2)

# Printed size in inches, handed to ggsave() by main.R. Kept here because
# adding a facet row is what makes the figure need more height.
sim_figure_size <- list(width = 6.5, height = 5)

# Which measures get a panel, and how each is labelled. Adding a measure
# here is the only change a new panel needs.
measure_labels <- c(
  bias     = "Bias",
  rmse     = "RMSE",
  coverage = "95% CI Coverage",
  power    = "Power"
)

#' Reshapes the results frame to one row per condition *and* measure.
#'
#' @param results Data frame from collect_performance(), one row per
#'   condition with a column per measure.
#' @param labels Named character vector mapping measure columns to panel
#'   labels; its order sets the facet order.
#' @return Data frame with columns `n`, factor `b1`, factor `measure`,
#'   and numeric `value`.
# Kept out of the plotting call so the facet labelling can be tested
# without rendering anything.
sim_results_long <- function(results, labels = measure_labels) {
  do.call(rbind, lapply(names(labels), function(measure) {
    data.frame(
      n       = results$n,
      b1      = factor(results$b1),
      measure = factor(labels[[measure]], levels = labels),
      value   = results[[measure]]
    )
  }))
}

#' Draws the faceted simulation results figure, one panel per measure.
#'
#' @param results Data frame from collect_performance(), one row per condition.
#' @return A ggplot object.
make_sim_figure <- function(results) {
  ggplot(sim_results_long(results), aes(x = n, y = value, color = b1, group = b1)) +
    geom_line(linewidth = 0.6) +
    geom_point(size = 1.8) +
    facet_wrap(~measure, scales = "free_y") +
    scale_color_manual(values = c("#404040", "#909090", "#C0C0C0"),
                       name = expression(True~beta[1])) +
    labs(x = "Sample Size (N)", y = NULL) +
    theme_apa_minimal()
}
