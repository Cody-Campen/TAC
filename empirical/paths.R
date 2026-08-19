# paths.R
# Every path the empirical pipeline reads or writes, in one place, so
# renaming the folder is a one-line change. Sourced by main.R; the function
# files take their paths as arguments instead, which is what lets the tests
# point them at a temporary directory.
#
# Paths stay root-relative because every entry point runs from the project
# root. `raw_config` is the one path here that is gitignored -- it points at
# the real dataset, which lives outside the repo.

emp_dir <- "empirical"

emp_paths <- list(
  raw_config   = file.path(emp_dir, "config", "data_path.local.txt"),
  raw_fallback = file.path(emp_dir, "data", "dummy_raw.csv"),
  cleaned      = file.path(emp_dir, "data", "processed", "cleaned.rds"),
  results      = file.path(emp_dir, "data", "processed", "results.rds"),
  table        = file.path(emp_dir, "tables", "tab_empirical.tex"),
  figure       = file.path(emp_dir, "figures", "fig_empirical.png")
)
