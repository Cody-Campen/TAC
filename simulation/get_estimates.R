# get_estimates.R
# Fits the model to one dataset, returns a one-row broom::tidy() frame
# for the "x" term (row-bindable across replications, same columns as
# the empirical pipeline). `converged` lets get_answers.R compute
# convergence rates and drop failed fits from performance measures.

library(broom)

#' Fits the model to one dataset and tidies the "x" term.
#'
#' @param data Data frame from generate_dataset(), with numeric columns
#'   `x` and `y`.
#' @return One-row data frame: numeric `estimate`, `std.error`,
#'   `conf.low`, `conf.high`, and logical `converged`.
# A failed fit returns the same columns with NA estimates rather than an
# error, so the failure stays countable instead of vanishing from results.
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
