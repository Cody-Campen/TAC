# tests for sim_results_long() in simulation/make_figures.R

source_project("simulation/make_figures.R")

# Values have to land under the measure they came from.
# A mislabelled panel renders fine and reports the wrong number.
test_that("sim_results_long() keeps each value with its own measure", {
  results <- make_results(n = c(50, 100), bias = c(0.01, 0.02),
                          rmse = c(0.30, 0.40))

  long <- sim_results_long(results)

  expect_equal(nrow(long), 2 * 4)        # 2 conditions x 4 measures
  expect_equal(long$value[long$measure == "Bias"], c(0.01, 0.02))
  expect_equal(long$value[long$measure == "RMSE"], c(0.30, 0.40))
})

# Facet order is the factor's level order.
# The panels read bias, RMSE, coverage, power rather than alphabetically.
test_that("sim_results_long() fixes the panel order", {
  long <- sim_results_long(make_results())

  expect_equal(levels(long$measure),
               c("Bias", "RMSE", "95% CI Coverage", "Power"))
})
