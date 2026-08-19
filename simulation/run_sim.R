# run_sim.R
# The entry point for a single simulation task. Defines the design grid --
# the experimental factors crossed with the replication seeds -- and runs
# the one task named on the command line. One task = one row of the grid =
# one replication, no in-process loop, so tasks fail and resubmit
# independently of each other.
#
#   Rscript simulation/run_sim.R 3          # run task 3
#   Rscript simulation/run_sim.R --n-tasks  # print the task count
#                                           # (run_jobs.sh sizes its
#                                           # array with this)
#
# This is the only script in the per-task path; everything it calls lives
# in a get_*/run_task file that defines functions and nothing else.

source("simulation/get_conditions.R")

# ---- Fixed (non-manipulated) parameters ----
b0    <- 0
sigma <- 1

# ---- Design: change the factor levels in make_design()'s defaults ----
design <- make_design()

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

# Loaded only once there is a task to run, so --n-tasks stays quick and
# quiet -- run_jobs.sh reads its output straight into the sbatch array size.
source("simulation/paths.R")
source("simulation/get_dataset.R")
source("simulation/get_estimates.R")
source("simulation/run_task.R")

params <- params_for_task(design, task_id, fixed = list(b0 = b0, sigma = sigma))

run_task(params, out_dir = sim_paths$raw)
