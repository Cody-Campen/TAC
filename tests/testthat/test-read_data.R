# tests for raw_data_path() in empirical/functions/read_data.R

source_project("empirical/functions/read_data.R")

# The config file is edited by hand on each machine.
# A stray newline must not become part of the path.
test_that("raw_data_path() returns the configured path, trimmed", {
  config <- withr::local_tempfile()
  writeLines("  C:/outside/the/repo/real_data.csv  ", config)

  expect_equal(raw_data_path(config), "C:/outside/the/repo/real_data.csv")
})

# The fallback has to announce itself.
# Silence would mean shipping a paper analysed on dummy data.
test_that("a missing config warns before falling back to the dummy data", {
  absent <- file.path(withr::local_tempdir(), "data_path.local.txt")

  expect_warning(path <- raw_data_path(absent, fallback = "dummy.csv"),
                 "not found")
  expect_equal(path, "dummy.csv")
})
