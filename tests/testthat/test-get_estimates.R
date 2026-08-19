# tests for fit_model() in simulation/get_estimates.R

source_project("simulation/get_estimates.R")

# x = 1..5, y = 2, 4, 5, 4, 5:  Sxx = 10, Sxy = 6 -> b1 = 0.6
#   SSE = 2.4, df = 3, s^2 = 0.8 -> SE = sqrt(0.08) = 0.2828427124746191
#   95% CI = 0.6 +/- 3.182446305284263 * SE  (t-table, df = 3)
worked_example <- function() data.frame(x = 1:5, y = c(2, 4, 5, 4, 5))

test_that("fit_model() recovers the hand-computed slope, SE and interval", {
  est <- fit_model(worked_example())

  expect_equal(est$estimate,  0.6, tolerance = 1e-9)
  expect_equal(est$std.error, 0.2828427124746191, tolerance = 1e-9)
  expect_equal(est$conf.low,  -0.3001317453, tolerance = 1e-7)
  expect_equal(est$conf.high,  1.5001317453, tolerance = 1e-7)
})

# One row for the x term, with the columns get_performance.R reads -- this is
# the shape every replication in results/raw/ is stored in.
test_that("fit_model() returns the row shape get_performance.R reads", {
  est <- fit_model(worked_example())

  expect_equal(nrow(est), 1)
  expect_named(est, c("estimate", "std.error", "conf.low", "conf.high", "converged"))
  expect_true(est$converged)
})

# collect_performance() rbinds successes and failures together, so a fit that
# errors has to come back as a flagged NA row with identical columns --
# not an exception thousands of replications into a cluster run.
test_that("a fit that errors comes back as an NA row that binds cleanly", {
  failed <- fit_model(data.frame(x = numeric(0), y = numeric(0)))

  expect_false(failed$converged)
  expect_true(is.na(failed$estimate))
  expect_named(failed, names(fit_model(worked_example())))
  expect_equal(nrow(rbind(fit_model(worked_example()), failed)), 2)
})
