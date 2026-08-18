# get_dataset.R
# Generates one simulated dataset for a given condition.
#
# `params` is a named list of condition values assigned in run_sim.R
# (e.g. sample size, true effect size). Every condition in the design
# must supply the fields this function reads.

generate_dataset <- function(params) {
  n  <- params$n
  b0 <- params$b0
  b1 <- params$b1
  sigma <- params$sigma

  x <- rnorm(n, mean = 0, sd = 1)
  y <- b0 + b1 * x + rnorm(n, mean = 0, sd = sigma)

  data.frame(x = x, y = y)
}
