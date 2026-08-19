# test-analyze_data.R -- empirical/functions/analyze_data.R
# Checks the fitted model against a hand-derived example and pins the
# pieces the downstream table scripts read off it.

source_project("empirical/functions/analyze_data.R")

# y = 10 + 2*x1 + 5*d + e, with e orthogonal to every column of the design
# matrix, so OLS returns the construction coefficients exactly. x1 has the
# same mean in both groups, so SE(x1) = sqrt(s^2/Sxx) separates cleanly:
# SSE = 8, df = 5, s^2 = 1.6, Sxx = 10 -> SE(x1) = 0.4. R^2 = 1 - 8/98.
worked_example <- function() {
  make_cleaned(
    x1    = c(1, 2, 3, 4, 1, 2, 3, 4),
    group = rep(c("control", "treatment"), each = 4),
    y     = c(13, 13, 15, 19, 18, 18, 20, 24)
  )
}

coef_row <- function(estimates, term) estimates[estimates$term == term, ]

# The estimator itself: coefficients and their SEs must match the algebra
# above, not a second lm() call.
test_that("analyze_dataset() recovers the hand-computed fit", {
  results <- analyze_dataset(worked_example())
  est <- results$estimates

  expect_equal(coef_row(est, "(Intercept)")$estimate, 10, tolerance = 1e-9)
  expect_equal(coef_row(est, "x1")$estimate, 2, tolerance = 1e-9)
  expect_equal(coef_row(est, "grouptreatment")$estimate, 5, tolerance = 1e-9)
  expect_equal(coef_row(est, "x1")$std.error, 0.4, tolerance = 1e-9)
  expect_equal(results$r_squared, 0.9183673469387755, tolerance = 1e-9)
})

# make_tables.R maps these exact term names to display labels, so a new
# predictor has to be added there too; this is what says so.
test_that("the results carry the terms and columns make_tables.R reads", {
  results <- analyze_dataset(worked_example())

  expect_named(results, c("fit", "estimates", "n", "r_squared"))
  expect_equal(results$estimates$term, c("(Intercept)", "x1", "grouptreatment"))
  expect_true(all(c("estimate", "std.error", "p.value", "conf.low", "conf.high")
                  %in% names(results$estimates)))
})

# analyze_data.R passes model = FALSE to keep results.rds small; if that is
# dropped the saved object silently starts carrying the whole dataset.
# Checked by name because `fit$x` would partial-match `xlevels`.
test_that("the fitted object does not retain the data", {
  fit <- analyze_dataset(worked_example())$fit

  expect_false(any(c("model", "x", "y") %in% names(fit)))
})
