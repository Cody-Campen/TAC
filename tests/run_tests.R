#!/usr/bin/env Rscript
# run_tests.R
# Runs the whole suite from the project root.
# Every test file in tests/testthat/ is picked up automatically.
#
#   Rscript tests/run_tests.R

if (!dir.exists("tests/testthat")) {
  stop("run this from the project root: Rscript tests/run_tests.R", call. = FALSE)
}

library(testthat)

# Attached quietly to keep broom's build-version warning out of the results.
suppressWarnings(library(broom))

# Runs every test file, stopping on the first failure.
# local_edition() unwinds with its calling frame, so the tests run inside one.
run_suite <- function() {
  local_edition(3)
  test_dir("tests/testthat", stop_on_failure = TRUE)
}

run_suite()
