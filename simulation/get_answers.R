# get_answers.R
# Collapses one condition's per-replication estimates into standard
# performance measures. `estimates` is fit_model()'s row-bound output
# (see run_task.R); `params` supplies the true value to judge against.

#' Collapses one condition's replications into performance measures.
#'
#' @param estimates Data frame of fit_model()'s row-bound output for a
#'   single condition, including the logical `converged` column.
#' @param params Named list supplying the numeric scalars `n` and `b1`,
#'   `b1` being the true value the estimates are judged against.
#' @return One-row data frame: `n`, `b1`, `nsim`, `convergence`, `bias`,
#'   `rel_bias`, `rmse`, `coverage`, `power`.
# Every measure but `convergence` is computed over converged replications
# only.
compute_performance <- function(estimates, params) {
  true_val <- params$b1

  converged <- estimates[estimates$converged, ]
  n_converged <- nrow(converged)

  bias      <- mean(converged$estimate - true_val)
  rel_bias  <- bias / true_val
  rmse      <- sqrt(mean((converged$estimate - true_val)^2))
  coverage  <- mean(converged$conf.low <= true_val & true_val <= converged$conf.high)
  power     <- mean(converged$conf.low > 0 | converged$conf.high < 0)

  data.frame(
    n              = params$n,
    b1             = params$b1,
    nsim           = nrow(estimates),
    convergence    = n_converged / nrow(estimates),
    bias           = bias,
    rel_bias       = rel_bias,
    rmse           = rmse,
    coverage       = coverage,
    power          = power
  )
}

#' Harvests every per-task file in `raw_dir` into one row per condition.
#'
#' @param raw_dir Single string; directory holding the array's per-task
#'   .rds files.
#' @param expected Single number, the design's task count, or NULL to
#'   skip the completeness check.
#' @return Data frame of performance measures, one row per condition,
#'   ordered by `n` then `b1`.
# Passing `expected` turns a partly finished array -- a task that failed
# and was never resubmitted -- into an error, instead of results quietly
# computed from fewer replications than the paper claims.
collect_answers <- function(raw_dir = "simulation/results/raw", expected = NULL) {
  raw_files <- list.files(raw_dir, pattern = "\\.rds$", full.names = TRUE)

  if (length(raw_files) == 0L) {
    stop("no task results in ", raw_dir, " -- has run_jobs.sh finished?",
         call. = FALSE)
  }

  if (!is.null(expected) && length(raw_files) != expected) {
    stop(sprintf("found %d task results in %s, expected %d -- resubmit the missing tasks",
                 length(raw_files), raw_dir, expected), call. = FALSE)
  }

  raw <- do.call(rbind, lapply(raw_files, readRDS))

  conditions <- split(raw, list(raw$n, raw$b1), drop = TRUE)
  results <- do.call(rbind, lapply(conditions, function(cond) {
    compute_performance(cond, list(n = cond$n[1], b1 = cond$b1[1]))
  }))

  results <- results[order(results$n, results$b1), ]
  rownames(results) <- NULL
  results
}
