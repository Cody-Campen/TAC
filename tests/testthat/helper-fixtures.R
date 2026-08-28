# helper-fixtures.R
# Small builders for test inputs, each argument defaulted.
# A test names only the field it cares about:
#
#   make_params(n = 10, sigma = 0)
#   make_estimates(estimate = c(0.4, 0.5), converged = c(TRUE, FALSE))

# ---- simulation ----

# Builds the `params` list run_sim.R hands to run_task()/get_dataset().
make_params <- function(n = 100, b0 = 0, b1 = 0.5, sigma = 1,
                        seed = 1, task_id = 1) {
  list(n = n, b0 = b0, b1 = b1, sigma = sigma, seed = seed, task_id = task_id)
}

# Builds one or more rows in get_estimates()'s output shape.
# Scalars recycle against `estimate`, which sets the number of rows.
make_estimates <- function(estimate = 0.5,
                           std.error = 0.1,
                           conf.low  = estimate - 0.2,
                           conf.high = estimate + 0.2,
                           converged = TRUE,
                           n  = 100,
                           b1 = 0.5) {
  data.frame(
    estimate  = estimate,
    std.error = std.error,
    conf.low  = conf.low,
    conf.high = conf.high,
    converged = converged,
    n         = n,
    b1        = b1
  )
}

# ---- empirical ----

# Builds a raw frame in the shape read.csv() produces from the source file.
# `group` is untrimmed, like the real data.
make_raw <- function(id    = 1:4,
                     group = c("control", "treatment", "control", "treatment"),
                     x1    = c(10, 20, 30, 40),
                     y     = c(1, 2, 3, 4)) {
  data.frame(id = id, group = group, x1 = x1, y = y,
             stringsAsFactors = FALSE)
}

# Builds a frame in the shape clean_dataset() produces.
# `group` becomes a factor in the modelled order.
make_cleaned <- function(x1    = c(10, 20, 30, 40),
                         group = c("control", "control", "treatment", "treatment"),
                         y     = c(1, 2, 3, 4),
                         id    = seq_along(x1)) {
  data.frame(
    id    = id,
    group = factor(group, levels = c("control", "treatment")),
    x1    = x1,
    y     = y
  )
}

# Builds a results.rds frame, one row per condition.
# The longest of `n`, `b1` and `nsim` sets the number of rows.
make_results <- function(n = c(50, 100), b1 = 0.5, nsim = 500,
                         convergence = 1, bias = 0.01, rel_bias = 0.02,
                         rmse = 0.1, coverage = 0.95, power = 0.8) {
  data.frame(n = n, b1 = b1, nsim = nsim, convergence = convergence,
             bias = bias, rel_bias = rel_bias, rmse = rmse,
             coverage = coverage, power = power)
}

# Builds analyze_dataset()'s list, minus the `fit` the table never touches.
make_analysis <- function(term      = c("(Intercept)", "x1", "grouptreatment"),
                          estimate  = c(10, 2, 5),
                          std.error = c(1.183, 0.4, 0.894),
                          p.value   = c(0.001, 0.002, 0.003),
                          n = 8, r_squared = 0.918) {
  list(
    estimates = data.frame(
      term      = term,
      estimate  = estimate,
      std.error = std.error,
      p.value   = p.value,
      conf.low  = estimate - 1,
      conf.high = estimate + 1,
      stringsAsFactors = FALSE
    ),
    n = n,
    r_squared = r_squared
  )
}
