# main.R
# Post-processing for the simulation study: results, then table and figure.
# Run it after run_jobs.sh finishes.
#
#   Rscript simulation/main.R           # every stage, in order
#   Rscript simulation/main.R figures   # just the figure

source("stages.R")
source("simulation/paths.R")

usage <- "usage: Rscript simulation/main.R [all|results|tables|figures]..."

stages <- list(
  results = function() {
    source("simulation/get_conditions.R")
    source("simulation/get_performance.R")

    # The design's row count is how many task files a complete run leaves.
    results <- collect_performance(sim_paths$raw, expected = nrow(get_conditions()))

    dir.create(dirname(sim_paths$results), showWarnings = FALSE, recursive = TRUE)
    saveRDS(results, sim_paths$results)
    message(sprintf("Wrote %s (%d conditions).", sim_paths$results, nrow(results)))
  },

  tables = function() {
    require_input(sim_paths$results, "Rscript simulation/main.R results")
    source("style.R")
    source("simulation/make_tables.R")

    dir.create(dirname(sim_paths$table), showWarnings = FALSE, recursive = TRUE)
    writeLines(make_sim_table(readRDS(sim_paths$results)), sim_paths$table)
    message(sprintf("Wrote %s.", sim_paths$table))
  },

  figures = function() {
    require_input(sim_paths$results, "Rscript simulation/main.R results")
    source("style.R")
    source("simulation/make_figures.R")

    dir.create(dirname(sim_paths$figure), showWarnings = FALSE, recursive = TRUE)
    ggsave(sim_paths$figure, make_sim_figure(readRDS(sim_paths$results)),
           width = sim_figure_size$width, height = sim_figure_size$height,
           units = "in", dpi = 300)
    message(sprintf("Wrote %s.", sim_paths$figure))
  }
)

run_stages(commandArgs(trailingOnly = TRUE), stages, usage)
