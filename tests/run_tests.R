#!/usr/bin/env Rscript
# run_tests.R
# Runs the whole suite. Every test file in tests/testthat/ is picked up
# automatically -- adding a test never means editing this file.
#
#   Rscript tests/run_tests.R                      # fast suite (seconds)
#   RUN_SLOW_TESTS=true Rscript tests/run_tests.R  # + statistical tests
#
# Run it from the project root, like every other script here.

if (!dir.exists("tests/testthat")) {
  stop("run this from the project root: Rscript tests/run_tests.R", call. = FALSE)
}

library(testthat)

# Attached here, quietly, only to keep "package 'broom' was built under R
# version x.y.z" from being counted as a test warning on every run. Drop
# this line once the installed broom matches your R version.
suppressWarnings(library(broom))

#' Runs every test file in tests/testthat/, stopping on the first failure.
#'
#' @return test_dir()'s results, invisibly.
# There is no DESCRIPTION here to declare the testthat edition, so ask for
# the 3rd explicitly. local_edition() unwinds when its calling frame exits,
# so the tests have to run inside that same frame -- hence the function.
run_suite <- function() {
  local_edition(3)
  test_dir("tests/testthat", stop_on_failure = TRUE)
}

run_suite()
