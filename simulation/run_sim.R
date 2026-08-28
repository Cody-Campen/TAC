# run_sim.R
# The entry point for a single simulation task.
# One task is one row of the design grid, so tasks resubmit independently.
#
#   Rscript simulation/run_sim.R 3          # run task 3
#   Rscript simulation/run_sim.R --n-tasks  # print the task count

source("simulation/get_conditions.R")

# Every parameter get_dataset() needs is a design factor.
design <- get_conditions()

args <- commandArgs(trailingOnly = TRUE)
if (identical(args[1], "--n-tasks")) {
  cat(nrow(design), "\n", sep = "")
  quit(save = "no")
}

task_id <- suppressWarnings(as.integer(args[1]))
if (is.na(task_id) || task_id < 1L || task_id > nrow(design)) {
  stop(sprintf("usage: Rscript simulation/run_sim.R <task_id in 1:%d>|--n-tasks",
               nrow(design)))
}

# Loaded only once there is a task to run, so --n-tasks stays quick and quiet.
source("simulation/paths.R")
source("simulation/get_dataset.R")
source("simulation/get_estimates.R")
source("simulation/run_task.R")

params <- params_for_task(design, task_id)

run_task(params, out_dir = sim_paths$raw)
