# functions/analyze_data.R
# The primary model, as one pure function. Sourced by
# empirical/main.R's analyze stage (which reads and writes) and by
# the test suite. Nothing in this file touches the filesystem.

library(broom)

#' Fits the primary model and tidies it for the table and figure.
#'
#' @param cleaned Data frame from clean_dataset(), with `y`, `x1`, and
#'   factor `group`.
#' @return Named list: `fit` (the lm), `estimates` (tidy data frame with
#'   confidence intervals), numeric `n`, and numeric `r_squared`.
analyze_dataset <- function(cleaned) {
  # don't retain raw data in the fitted object -- keeps saved .rds small
  fit <- lm(y ~ x1 + group, data = cleaned, model = FALSE, x = FALSE, y = FALSE)
  estimates <- tidy(fit, conf.int = TRUE)

  list(
    fit = fit,
    estimates = estimates,
    n = nrow(cleaned),
    r_squared = summary(fit)$r.squared
  )
}
