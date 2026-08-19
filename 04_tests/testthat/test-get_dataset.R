# test-get_dataset.R -- simulation/get_dataset.R
# Checks the generated data match the data-generating model exactly where
# they can be, and that the seed makes a replication reproducible.

source_project("simulation/get_dataset.R")

# The only fully deterministic check available: with no error term, y must
# equal b0 + b1*x to machine precision, so a wrong coefficient shows up.
test_that("with sigma = 0 the data lie exactly on the regression line", {
  set.seed(1)
  data <- generate_dataset(make_params(n = 20, b0 = 2, b1 = 3, sigma = 0))

  expect_equal(data$y, 2 + 3 * data$x)
})

# Reproducibility is the whole reason the design carries a seed column: the
# same seed must rerun a replication exactly, a different one must not.
test_that("the seed determines the dataset", {
  set.seed(1); first  <- generate_dataset(make_params(n = 10))
  set.seed(1); second <- generate_dataset(make_params(n = 10))
  set.seed(2); other  <- generate_dataset(make_params(n = 10))

  expect_identical(first, second)
  expect_false(isTRUE(all.equal(first$y, other$y)))
})

# get_estimates.R fits y ~ x on this frame, so the shape is a contract; a
# condition missing a field should fail on the first task, not produce a
# quietly wrong dataset.
test_that("generate_dataset() returns the frame fit_model() expects", {
  data <- generate_dataset(make_params(n = 25))

  expect_named(data, c("x", "y"))
  expect_equal(nrow(data), 25)

  incomplete <- make_params()
  incomplete$b1 <- NULL
  expect_error(generate_dataset(incomplete))
})
