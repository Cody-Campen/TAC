# paths.R
# Every path the empirical pipeline reads or writes.
# `raw_config` is gitignored, because it points at data outside the repo.

emp_dir <- "empirical"

emp_paths <- list(
  raw_config   = file.path(emp_dir, "config", "data_path.local.txt"),
  raw_fallback = file.path(emp_dir, "data", "dummy_raw.csv"),
  cleaned      = file.path(emp_dir, "data", "processed", "cleaned.rds"),
  results      = file.path(emp_dir, "data", "processed", "results.rds"),
  table        = file.path(emp_dir, "tables", "tab_empirical.tex"),
  figure       = file.path(emp_dir, "figures", "fig_empirical.png")
)
