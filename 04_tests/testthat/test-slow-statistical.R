# test-slow-statistical.R -- the simulation pipeline, end to end
# Checks the study's statistical claims rather than any one function, so
# these need real replications and are gated behind RUN_SLOW_TESTS=true.

source_project("simulation/get_dataset.R")
source_project("simulation/get_estimates.R")
source_project("simulation/get_answers.R")

skip_unless_slow <- function() {
  skip_if_not(identical(Sys.getenv("RUN_SLOW_TESTS"), "true"),
              "slow test; set RUN_SLOW_TESTS=true to run")
}

# One condition the way run_jobs.sh + simulation/main.R would, in one process.
run_condition <- function(params, nsim = 500) {
  estimates <- do.call(rbind, lapply(seq_len(nsim), function(rep) {
    set.seed(rep)
    fit_model(generate_dataset(params))
  }))

  compute_performance(estimates, params)
}

# A correctly specified OLS interval covers at its nominal rate. 500 reps
# at true coverage .95 has SE ~= .0097, so the +/- .03 bound is ~3 SE --
# loose enough that a pass is not a coin flip.
test_that("95% intervals cover the true value about 95% of the time", {
  skip_unless_slow()

  res <- run_condition(make_params(n = 100, b1 = 0.5), nsim = 500)

  expect_gt(res$coverage, 0.92)
  expect_lt(res$coverage, 0.98)
})

# At b1 = 0 the `power` column is the type I error rate, which should sit
# at the nominal 5%. This is the condition that catches an inflated test.
test_that("the null condition rejects at about the nominal 5% rate", {
  skip_unless_slow()

  res <- run_condition(make_params(n = 100, b1 = 0), nsim = 500)

  expect_gt(res$power, 0.02)
  expect_lt(res$power, 0.09)
})

# The estimator is root-n consistent, so error must shrink as n grows and
# bias must vanish -- an ordering that holds regardless of Monte Carlo noise.
test_that("error shrinks and bias vanishes as the sample size grows", {
  skip_unless_slow()

  small <- run_condition(make_params(n = 50,  b1 = 0.5), nsim = 500)
  large <- run_condition(make_params(n = 250, b1 = 0.5), nsim = 500)

  expect_lt(large$rmse, small$rmse)
  expect_lt(abs(run_condition(make_params(n = 20000, b1 = 0.5), nsim = 50)$bias), 0.01)
})
