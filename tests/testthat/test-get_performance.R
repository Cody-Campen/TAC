# tests for compute_performance() and collect_performance() in simulation/get_performance.R

source_project("simulation/get_performance.R")

# true b1 = 0.5, estimates 0.4, 0.5, 0.7 -> errors -0.1, 0, 0.2
#   bias = 0.1/3, rel_bias = bias/0.5, rmse = sqrt(0.05/3) = sqrt(1/60)
test_that("bias, relative bias and RMSE match the hand-computed values", {
  res <- compute_performance(make_estimates(estimate = c(0.4, 0.5, 0.7)),
                             make_params(b1 = 0.5))

  expect_equal(res$bias,     0.0333333333333333, tolerance = 1e-9)
  expect_equal(res$rel_bias, 0.0666666666666667, tolerance = 1e-9)
  expect_equal(res$rmse,     0.1290994448735806, tolerance = 1e-9)
})

# Coverage counts intervals containing the true value; the boundary cases
# are the ones an off-by-one comparison gets wrong, so both are included.
test_that("coverage is the share of intervals containing the true value", {
  estimates <- make_estimates(
    estimate  = c(0.40, 0.70, 0.705, 0.295),
    conf.low  = c(0.30, 0.50, 0.510, 0.100),  # limit == true value, then above
    conf.high = c(0.50, 0.90, 0.900, 0.490)   # limit == true value, then below
  )

  res <- compute_performance(estimates, make_params(b1 = 0.5))

  expect_equal(res$coverage, 0.5)
})

# A failed fit contributes an NA row. It must be excluded from the measures
# rather than propagating, while still counting toward nsim -- otherwise a
# handful of failures turns a whole condition's results into NA.
test_that("failed replications are excluded but still counted", {
  estimates <- make_estimates(estimate  = c(0.4, 0.5, 0.7, NA_real_),
                              converged = c(TRUE, TRUE, TRUE, FALSE))

  res <- compute_performance(estimates, make_params(b1 = 0.5))

  expect_equal(res$bias, 0.0333333333333333, tolerance = 1e-9)
  expect_equal(res$convergence, 0.75)
  expect_equal(res$nsim, 4)
})

# ---- collect_performance() ----

# The harvest groups thousands of per-task files by condition. Rows
# leaking between conditions is the failure that would not show up
# anywhere else: the table still builds, with the wrong numbers in it.
test_that("collect_performance() gives one row per condition, in table order", {
  raw_dir <- withr::local_tempdir()
  saveRDS(make_estimates(estimate = 0.4, n = 100, b1 = 0.5),
          file.path(raw_dir, "task_00001.rds"))
  saveRDS(make_estimates(estimate = 0.6, n = 100, b1 = 0.5),
          file.path(raw_dir, "task_00002.rds"))
  saveRDS(make_estimates(estimate = 0.1, n = 50, b1 = 0.2),
          file.path(raw_dir, "task_00003.rds"))

  results <- collect_performance(raw_dir)

  expect_equal(nrow(results), 2)
  expect_equal(results$n, c(50, 100))              # ordered n, then b1
  expect_equal(results$nsim, c(1, 2))
  expect_equal(results$bias, c(-0.1, 0), tolerance = 1e-9)
})

# A task that failed and was never resubmitted leaves fewer files behind.
# Without this check the results are computed anyway, from fewer
# replications than the paper reports.
test_that("collect_performance() refuses a partly finished array", {
  raw_dir <- withr::local_tempdir()
  saveRDS(make_estimates(n = 50, b1 = 0.2), file.path(raw_dir, "task_00001.rds"))

  expect_error(collect_performance(raw_dir, expected = 2), "expected 2")
  expect_error(collect_performance(withr::local_tempdir()), "no task results")
})
