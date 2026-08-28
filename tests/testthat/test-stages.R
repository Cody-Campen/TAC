# tests for run_stages() in stages.R

source_project("stages.R")

# Each stage records that it ran, so a test can read back what happened.
recording_stages <- function(log) {
  list(
    first  = function() log$ran <- c(log$ran, "first"),
    second = function() log$ran <- c(log$ran, "second"),
    third  = function() log$ran <- c(log$ran, "third")
  )
}

# Bare `Rscript main.R` has to mean the whole pipeline.
# run_jobs.sh chains exactly that.
test_that("naming no stage runs all of them in pipeline order", {
  log <- new.env(); log$ran <- character()

  suppressMessages(run_stages(character(), recording_stages(log)))

  expect_equal(log$ran, c("first", "second", "third"))
})

# Stages consume each other's output files, so the list order wins.
# Otherwise `main.R figures results` would draw a figure from stale results.
test_that("requested stages run in pipeline order, not the order given", {
  log <- new.env(); log$ran <- character()

  suppressMessages(run_stages(c("third", "first"), recording_stages(log)))

  expect_equal(log$ran, c("first", "third"))
})

# A typo must stop before anything runs.
test_that("an unknown stage errors without running anything", {
  log <- new.env(); log$ran <- character()

  expect_error(run_stages("figrues", recording_stages(log)), "unknown stage: figrues")
  expect_equal(log$ran, character())
})
