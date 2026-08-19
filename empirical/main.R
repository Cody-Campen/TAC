# main.R
# The empirical pipeline: clean -> analyze -> tables -> figures. Naming
# stages runs only those, so tables and figures can be rebuilt without
# re-touching the raw data.
#
#   Rscript empirical/main.R                   # every stage, in order
#   Rscript empirical/main.R tables figures    # just the outputs
#
# The raw dataset is read in the clean stage and nowhere else; everything
# after it reads only empirical/data/processed/.

source("shared/stages.R")

cleaned_path <- "empirical/data/processed/cleaned.rds"
results_path <- "empirical/data/processed/results.rds"
table_path   <- "empirical/tables/tab_empirical.tex"
figure_path  <- "empirical/figures/fig_empirical.png"

usage <- "usage: Rscript empirical/main.R [all|clean|analyze|tables|figures]..."

stages <- list(
  clean = function() {
    source("empirical/functions/read_data.R")
    source("empirical/functions/clean_data.R")

    raw <- read.csv(raw_data_path(), stringsAsFactors = FALSE)
    cleaned <- clean_dataset(raw)

    dir.create(dirname(cleaned_path), showWarnings = FALSE, recursive = TRUE)
    saveRDS(cleaned, cleaned_path)
    message(sprintf("Cleaned %d rows -> %d rows.", nrow(raw), nrow(cleaned)))
  },

  analyze = function() {
    require_input(cleaned_path, "Rscript empirical/main.R clean")
    source("empirical/functions/analyze_data.R")

    results <- analyze_dataset(readRDS(cleaned_path))

    saveRDS(results, results_path)
    message(sprintf("Fit model on n = %d, R^2 = %.3f.",
                    results$n, results$r_squared))
  },

  tables = function() {
    require_input(results_path, "Rscript empirical/main.R analyze")
    source("shared/style.R")
    source("empirical/make_tables.R")

    dir.create(dirname(table_path), showWarnings = FALSE, recursive = TRUE)
    writeLines(make_empirical_table(readRDS(results_path)), table_path)
    message(sprintf("Wrote %s.", table_path))
  },

  figures = function() {
    require_input(cleaned_path, "Rscript empirical/main.R clean")
    source("shared/style.R")
    source("empirical/make_figures.R")

    dir.create(dirname(figure_path), showWarnings = FALSE, recursive = TRUE)
    ggsave(figure_path, make_empirical_figure(readRDS(cleaned_path)),
           width = 6, height = 4.5, units = "in", dpi = 300)
    message(sprintf("Wrote %s.", figure_path))
  }
)

run_stages(commandArgs(trailingOnly = TRUE), stages, usage)
