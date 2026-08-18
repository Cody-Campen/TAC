# main.R
# Runs one simulation condition: `nsim` Monte Carlo replications of
# generate -> fit -> collect, followed by performance evaluation.
#
# Expects `params` (named list, one condition) and `nsim` to already be
# defined in the calling environment (run_sim.R sets these before
# sourcing this file). Writes one summary row per condition to
# simulation/results/.

source("simulation/get_dataset.R")
source("simulation/get_estimates.R")
source("simulation/get_answers.R")

run_condition <- function(params, nsim) {
  estimates <- do.call(rbind, lapply(seq_len(nsim), function(i) {
    data <- generate_dataset(params)
    fit_model(data)
  }))

  compute_performance(estimates, params)
}

results <- run_condition(params, nsim)
results$cond_id <- params$cond_id

dir.create("simulation/results", showWarnings = FALSE, recursive = TRUE)
saveRDS(results, sprintf("simulation/results/cond_%03d.rds", params$cond_id))
