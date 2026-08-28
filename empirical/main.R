# main.R
# The empirical pipeline: clean -> analyze -> tables -> figures.
# Naming stages runs only those.
#
#   Rscript empirical/main.R                   # every stage, in order
#   Rscript empirical/main.R tables figures    # just the outputs

source("stages.R")
source("empirical/paths.R")

usage <- "usage: Rscript empirical/main.R [all|clean|analyze|tables|figures]..."

stages <- list(
  clean = function() {
    source("empirical/functions/read_data.R")
    source("empirical/functions/clean_data.R")

    raw <- read.csv(raw_data_path(emp_paths$raw_config, emp_paths$raw_fallback),
                    stringsAsFactors = FALSE)
    cleaned <- clean_dataset(raw)

    dir.create(dirname(emp_paths$cleaned), showWarnings = FALSE, recursive = TRUE)
    saveRDS(cleaned, emp_paths$cleaned)
    message(sprintf("Cleaned %d rows -> %d rows.", nrow(raw), nrow(cleaned)))
  },

  analyze = function() {
    require_input(emp_paths$cleaned, "Rscript empirical/main.R clean")
    source("empirical/functions/analyze_data.R")

    results <- analyze_dataset(readRDS(emp_paths$cleaned))

    saveRDS(results, emp_paths$results)
    message(sprintf("Fit model on n = %d, R^2 = %.3f.",
                    results$n, results$r_squared))
  },

  tables = function() {
    require_input(emp_paths$results, "Rscript empirical/main.R analyze")
    source("style.R")
    source("empirical/make_tables.R")

    dir.create(dirname(emp_paths$table), showWarnings = FALSE, recursive = TRUE)
    writeLines(make_empirical_table(readRDS(emp_paths$results)), emp_paths$table)
    message(sprintf("Wrote %s.", emp_paths$table))
  },

  figures = function() {
    require_input(emp_paths$cleaned, "Rscript empirical/main.R clean")
    source("style.R")
    source("empirical/make_figures.R")

    dir.create(dirname(emp_paths$figure), showWarnings = FALSE, recursive = TRUE)
    ggsave(emp_paths$figure, make_empirical_figure(readRDS(emp_paths$cleaned)),
           width = emp_figure_size$width, height = emp_figure_size$height,
           units = "in", dpi = 300)
    message(sprintf("Wrote %s.", emp_paths$figure))
  }
)

run_stages(commandArgs(trailingOnly = TRUE), stages, usage)
