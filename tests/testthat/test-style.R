# tests for fmt() in style.R

source_project("style.R")

# Fixed decimals, not significant digits: APA tables need trailing zeros
# kept ("0.950", not "0.95") so the columns line up.
test_that("fmt() prints a fixed number of decimals, trailing zeros included", {
  expect_equal(fmt(c(0.95, 1, 0.123456)), c("0.950", "1.000", "0.123"))
})

# The b1 column is printed at 2 decimals and the rest at 3, so the digits
# argument has to be honoured rather than ignored.
test_that("fmt() honours the digits argument", {
  expect_equal(fmt(0.5, digits = 2), "0.50")
  expect_equal(fmt(123.4567, digits = 1), "123.5")
})
