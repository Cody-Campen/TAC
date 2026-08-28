# get_performance.R
# Collapses per-replication estimates into performance measures.
# Every measure is computed within `term`.

# The parameters get_estimates() reports, in table order.
# Each must also name a column in the raw data, which holds its true value.
sim_terms <- c("restoring", "damping", "v0", "mnoise", "dnoise")

# Collapses one condition's replications into performance measures.
# There is one row per parameter, not one per condition.
get_performance <- function(estimates, params, terms = sim_terms) {
  rows <- lapply(terms, function(term) {
    term_rows(estimates[estimates$term == term, ], term, params[[term]])
  })

  do.call(rbind, rows)
}

# The performance measures for a single parameter.
# Split out so get_performance() reads as one row per term.
term_rows <- function(est, term, truth) {
  if (is.null(truth)) {
    stop("no true value supplied for '", term, "'", call. = FALSE)
  }

  # Every measure but `convergence` uses converged replications only.
  nsim      <- nrow(est)
  converged <- est[est$converged, ]
  error     <- converged$estimate - truth

  # A condition in which every fit failed has nothing to average.
  # Report NA rather than the NaN mean(numeric(0)) gives.
  if (nrow(converged) == 0L) {
    return(data.frame(
      term = term, truth = truth, nsim = nsim, convergence = 0,
      bias = NA_real_, rel_bias = NA_real_, rmse = NA_real_,
      emp_se = NA_real_, avg_se = NA_real_, coverage = NA_real_,
      stringsAsFactors = FALSE
    ))
  }

  bias <- mean(error)

  data.frame(
    term        = term,
    truth       = truth,
    nsim        = nsim,
    convergence = nrow(converged) / nsim,
    bias        = bias,
    # Guarded because relative bias is undefined at a true value of zero.
    rel_bias    = if (truth == 0) NA_real_ else bias / truth,
    rmse        = sqrt(mean(error^2)),
    # The estimates' own spread, to be read against the SEs the model reports.
    emp_se      = stats::sd(converged$estimate),
    avg_se      = mean(converged$std.error, na.rm = TRUE),
    # Wald coverage is not valid for dnoise, whose true value of 0 is a boundary.
    coverage    = mean(converged$conf.low <= truth & truth <= converged$conf.high,
                       na.rm = TRUE),
    stringsAsFactors = FALSE
  )
}

# Harvests every per-task file in `raw_dir` into one row per condition and term.
# Passing `expected` turns a partly finished array into an error.
collect_performance <- function(raw_dir, expected = NULL, terms = sim_terms) {
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

  by <- condition_cols(raw)
  conditions <- split(raw, raw[by], drop = TRUE)

  results <- do.call(rbind, lapply(conditions, function(cond) {
    cbind(cond[rep(1L, length(terms)), by, drop = FALSE],
          get_performance(cond, condition_params(cond), terms = terms),
          row.names = NULL)
  }))

  # Ordered by `terms` rather than alphabetically, which is how the tables read.
  results <- results[do.call(order, c(results[by],
                                      list(match(results$term, terms)))), ]
  rownames(results) <- NULL
  results
}

# Columns get_estimates() and run_task() write on every row.
# Whatever else run_task() tagged the rows with is the design grid.
result_cols <- c("term", "estimate", "std.error", "conf.low", "conf.high",
                 "converged", "seed")

# The columns of the raw results that identify a condition.
condition_cols <- function(raw) {
  by <- setdiff(names(raw), result_cols)

  if (length(by) == 0L) {
    stop("no condition columns in the raw results -- does run_task() still ",
         "tag its rows with the design grid?", call. = FALSE)
  }

  by
}

# The true parameter values of one condition, taken from its first row.
# The grid holds what get_dataset() generated from, so its columns are truth.
condition_params <- function(cond) {
  as.list(cond[1L, condition_cols(cond), drop = FALSE])
}
