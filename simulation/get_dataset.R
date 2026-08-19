# get_dataset.R
# Generates one simulated dataset for a condition. `params` is the named
# list assigned in run_sim.R; every condition must supply these fields.

#' Draws one dataset from the linear model the study estimates.
#'
#' @param params Named list for one condition, supplying the numeric
#'   scalars `n`, `b0`, `b1`, and `sigma`.
#' @return Data frame of `n` rows with numeric columns `x` and `y`.
generate_dataset <- function(params) {
  n  <- params$n
  b0 <- params$b0
  b1 <- params$b1
  sigma <- params$sigma

  x <- rnorm(n, mean = 0, sd = 1)
  y <- b0 + b1 * x + rnorm(n, mean = 0, sd = sigma)

  data.frame(x = x, y = y)
}
