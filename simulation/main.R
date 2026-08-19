# main.R
# Post-processing for the simulation study: harvest the per-task results,
# then build the table and the figure. Run after run_jobs.sh finishes.
# Naming stages runs only those, so a figure tweak does not re-harvest
# 4500 files.
#
#   Rscript simulation/main.R           # every stage, in order
#   Rscript simulation/main.R figures   # just the figure
#
# The per-task path is not here -- that is run_sim.R, one process per
# array element.

source("shared/stages.R")

raw_dir      <- "simulation/results/raw"
results_path <- "simulation/results/results.rds"
table_path   <- "simulation/tables/tab_sim.tex"
figure_path  <- "simulation/figures/fig_sim.png"

usage <- "usage: Rscript simulation/main.R [all|results|tables|figures]..."

stages <- list(
  results = function() {
    source("simulation/get_conditions.R")
    source("simulation/get_answers.R")

    # make_design() sizes run_jobs.sh's array, so its row count is also
    # the number of task files a complete run leaves behind.
    results <- collect_answers(raw_dir, expected = nrow(make_design()))

    dir.create(dirname(results_path), showWarnings = FALSE, recursive = TRUE)
    saveRDS(results, results_path)
    message(sprintf("Wrote %s (%d conditions).", results_path, nrow(results)))
  },

  tables = function() {
    require_input(results_path, "Rscript simulation/main.R results")
    source("shared/style.R")
    source("simulation/make_tables.R")

    dir.create(dirname(table_path), showWarnings = FALSE, recursive = TRUE)
    writeLines(make_sim_table(readRDS(results_path)), table_path)
    message(sprintf("Wrote %s.", table_path))
  },

  figures = function() {
    require_input(results_path, "Rscript simulation/main.R results")
    source("shared/style.R")
    source("simulation/make_figures.R")

    dir.create(dirname(figure_path), showWarnings = FALSE, recursive = TRUE)
    ggsave(figure_path, make_sim_figure(readRDS(results_path)),
           width = 6.5, height = 5, units = "in", dpi = 300)
    message(sprintf("Wrote %s.", figure_path))
  }
)

run_stages(commandArgs(trailingOnly = TRUE), stages, usage)
