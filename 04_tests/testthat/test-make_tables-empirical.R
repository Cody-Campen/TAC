# test-make_tables-empirical.R -- empirical/make_tables.R
# Checks the term labels the paper prints, including what happens to a
# term nobody has given a label to.

source_project("shared/style.R")
source_project("empirical/make_tables.R")

# The model's internal names are not what the paper should show:
# `grouptreatment` has to reach the page as "Treatment".
test_that("make_empirical_table() prints the display label for each term", {
  tex <- make_empirical_table(make_analysis())

  expect_true(any(grepl("Intercept & 10.000", tex, fixed = TRUE)))
  expect_true(any(grepl("$X_1$ & 2.000", tex, fixed = TRUE)))
  expect_true(any(grepl("Treatment & 5.000", tex, fixed = TRUE)))
  expect_false(any(grepl("grouptreatment", tex, fixed = TRUE)))
})

# A predictor added to the model but not to term_labels falls through to
# its raw name -- ugly in the paper, but visible, which is the point. If
# this ever starts erroring instead, that is a deliberate change.
test_that("a term with no label falls through to its raw name", {
  tex <- make_empirical_table(make_analysis(
    term      = c("(Intercept)", "x2_new"),
    estimate  = c(10, 3),
    std.error = c(1, 0.5),
    p.value   = c(0.01, 0.02)
  ))

  expect_true(any(grepl("x2_new & 3.000", tex, fixed = TRUE)))
})
