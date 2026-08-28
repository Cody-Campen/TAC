# tests for make_sim_table() in simulation/make_tables.R

source_project("style.R")
source_project("simulation/make_tables.R")

body_rows <- function(tex) grep("\\\\\\\\$", tex, value = TRUE)

# One condition in, one row out.
# A grouping bug upstream shows up here as the wrong number of lines.
test_that("make_sim_table() writes one body row per condition", {
  tex <- make_sim_table(make_results(n = c(50, 100, 250)))

  rows <- body_rows(tex)
  expect_equal(length(rows), 4)          # 3 conditions + the header row
  expect_true(any(grepl("^ +50 & 0.50 & 0.010", rows)))
})

# The sprintf() format string and the column spec are written separately.
# Adding a measure to one and not the other breaks the LaTeX.
test_that("every body row has as many columns as the header", {
  tex <- make_sim_table(make_results())

  columns <- vapply(body_rows(tex), function(row) {
    length(strsplit(row, " & ", fixed = TRUE)[[1]])
  }, integer(1))

  expect_true(all(columns == columns[1]))
  expect_equal(columns[[1]], 7)
})
