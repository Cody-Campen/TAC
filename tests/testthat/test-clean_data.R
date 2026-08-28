# tests for clean_dataset() in empirical/functions/clean_data.R

source_project("empirical/functions/clean_data.R")

# One row per exclusion rule, so a rule that stops firing fails here.
test_that("invalid rows are dropped and valid ones kept", {
  raw <- make_raw(
    id    = c(1, 1, 2, 3, 4, 5),
    group = c("control", "control", "treatment", "control", "CONTROL", "control"),
    x1    = c(10, 99, 20, NA, 30, -999),   # dup id, missing, bad label, sentinel
    y     = c(1, 2, 3, 4, 5, 6)
  )

  cleaned <- clean_dataset(raw)

  expect_equal(cleaned$id, c(1, 2))
  expect_equal(cleaned$x1, c(10, 20))
})

# The `grouptreatment` coefficient depends on control being the reference level.
test_that("group comes back as a factor with control as the reference level", {
  cleaned <- clean_dataset(make_raw())

  expect_s3_class(cleaned$group, "factor")
  expect_equal(levels(cleaned$group), c("control", "treatment"))
})

# Pins the checked-in fixture: 243 rows in, 10 excluded.
# Update it deliberately if dummy_raw.csv is regenerated.
test_that("the dummy raw file cleans to the expected sample", {
  raw <- read.csv(project_path("empirical/data/dummy_raw.csv"),
                  stringsAsFactors = FALSE)

  cleaned <- clean_dataset(raw)

  expect_equal(nrow(raw), 243)
  expect_equal(nrow(cleaned), 233)
  expect_false(any(duplicated(cleaned$id)))
  expect_true(all(cleaned$x1 > 0))
})
