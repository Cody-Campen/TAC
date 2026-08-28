# tests for get_conditions() and params_for_task() in simulation/get_conditions.R

source_project("simulation/get_conditions.R")

# Seed varies fastest, which gives conditions common random numbers.
# It is also the order run_jobs.sh indexes its array in.
test_that("get_conditions() fully crosses the factors with seed varying fastest", {
  design <- get_conditions(seed = 1:3, n = c(10, 20), b1 = 0)

  expect_named(design, c("seed", "n", "b1"))
  expect_equal(design$seed, c(1, 2, 3, 1, 2, 3))
  expect_equal(design$n, c(10, 10, 10, 20, 20, 20))
})

# Pins the study design run_jobs.sh sizes its array from.
# Changing it invalidates everything in results/raw/.
test_that("the current study design is 500 seeds x 3 sample sizes x 3 effects", {
  design <- get_conditions()

  expect_equal(nrow(design), 4500)
  expect_equal(sort(unique(design$n)), c(50, 100, 250))
  expect_equal(sort(unique(design$b1)), c(0, 0.2, 0.5))
  expect_equal(range(design$seed), c(1, 500))
})

# The array index is the only thing connecting a task to its condition.
# An out-of-range id must stop rather than silently recycle.
test_that("params_for_task() maps ids onto grid rows and rejects bad ones", {
  design <- get_conditions(seed = 1:3, n = c(10, 20), b1 = 0)

  first <- params_for_task(design, 1, fixed = list(b0 = 0, sigma = 1))
  expect_equal(first[c("seed", "n", "task_id")], list(seed = 1, n = 10, task_id = 1L))
  expect_true(all(c("n", "b0", "b1", "sigma", "seed") %in% names(first)))

  expect_equal(params_for_task(design, 4)$n, 20)  # rolls into the next condition
  expect_error(params_for_task(design, 0), "1:6")
  expect_error(params_for_task(design, 7), "1:6")
  expect_error(params_for_task(design, 1.5), "1:6")
})
