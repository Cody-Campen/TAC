# helper-fixtures.R
# Small builders for test inputs. Every argument has a default, so a test
# names only the field it cares about and the rest stays out of the way:
#
#   make_params(n = 10, sigma = 0)
#   make_estimates(estimate = c(0.4, 0.5), converged = c(TRUE, FALSE))
#
# Adding a fixture for a new function: give it a make_*() here rather
# than building the frame inline in each test.

# ---- simulation ----

#' Builds the `params` list run_sim.R hands to run_task()/generate_dataset().
#'
#' @param n,b0,b1,sigma Numeric scalars; the condition's parameters.
#' @param seed,task_id Numeric scalars identifying the replication.
#' @return Named list of the six parameters.
make_params <- function(n = 100, b0 = 0, b1 = 0.5, sigma = 1,
                        seed = 1, task_id = 1) {
  list(n = n, b0 = b0, b1 = b1, sigma = sigma, seed = seed, task_id = task_id)
}

#' Builds one or more rows in fit_model()'s output shape.
#'
#' @param estimate,std.error,conf.low,conf.high Numeric vectors; scalars
#'   recycle against `estimate`, which sets the number of rows.
#' @param converged Logical vector, recycled the same way.
#' @param n,b1 Numeric vectors tagging the condition the rows came from.
#' @return Data frame with one row per `estimate`.
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

#' Builds a raw frame in the shape read.csv() produces from the source file.
#'
#' @param id Vector of row ids.
#' @param group Character vector, untrimmed like the real data.
#' @param x1,y Numeric vectors.
#' @return Data frame with columns `id`, `group`, `x1`, `y`.
make_raw <- function(id    = 1:4,
                     group = c("control", "treatment", "control", "treatment"),
                     x1    = c(10, 20, 30, 40),
                     y     = c(1, 2, 3, 4)) {
  data.frame(id = id, group = group, x1 = x1, y = y,
             stringsAsFactors = FALSE)
}

#' Builds a frame in the shape clean_dataset() produces.
#'
#' @param x1,y Numeric vectors.
#' @param group Character vector of group labels, made a factor in the
#'   modelled order with both levels present.
#' @param id Vector of row ids.
#' @return Data frame with columns `id`, factor `group`, `x1`, `y`.
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

#' Builds a results.rds frame: one row per condition.
#'
#' @param n,b1,nsim Numeric vectors identifying the conditions; the
#'   longest sets the number of rows.
#' @param convergence,bias,rel_bias,rmse,coverage,power Numeric vectors of
#'   performance measures, recycled to match.
#' @return Data frame in the shape compute_performance() returns and the
#'   simulation table and figure builders consume.
make_results <- function(n = c(50, 100), b1 = 0.5, nsim = 500,
                         convergence = 1, bias = 0.01, rel_bias = 0.02,
                         rmse = 0.1, coverage = 0.95, power = 0.8) {
  data.frame(n = n, b1 = b1, nsim = nsim, convergence = convergence,
             bias = bias, rel_bias = rel_bias, rmse = rmse,
             coverage = coverage, power = power)
}

#' Builds analyze_dataset()'s list, minus the `fit` the table never touches.
#'
#' @param term Character vector of model term names.
#' @param estimate,std.error,p.value Numeric vectors, one per `term`.
#' @param n,r_squared Numeric scalars for the table note.
#' @return Named list with `estimates`, `n`, and `r_squared`.
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
