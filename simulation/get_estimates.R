# get_estimates.R
# Fits the model to one simulated dataset and extracts the quantities
# needed for performance evaluation.
#
# Returns a one-row broom::tidy() data frame (term, estimate, std.error,
# statistic, p.value, conf.low, conf.high) for the "x" term, so replications
# can be row-bound directly and share column names with the empirical
# pipeline's estimates. `converged` lets get_answers.R compute
# convergence/failure rates and drop non-converged replications from the
# performance measures.

library(broom)

fit_model <- function(data) {
  fit <- tryCatch(lm(y ~ x, data = data), error = function(e) NULL)

  if (is.null(fit)) {
    return(data.frame(
      estimate = NA_real_, std.error = NA_real_,
      conf.low = NA_real_, conf.high = NA_real_,
      converged = FALSE
    ))
  }

  est <- tidy(fit, conf.int = TRUE)
  est <- est[est$term == "x", c("estimate", "std.error", "conf.low", "conf.high")]
  est$converged <- TRUE
  est
}
