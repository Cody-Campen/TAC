# functions/analyze_data.R
# The primary model, as one pure function.
# Nothing in this file touches the filesystem.

library(broom)

# Fits the primary model and tidies it for the table and figure.
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
