# run_sim.R
# Defines the simulation design (the full factorial grid of condition
# parameters), picks the one condition this job is responsible for, and
# runs it via main.R.
#
# Condition index comes from the command line so the same script works
# both locally (`Rscript simulation/run_sim.R 3`) and as one task of a
# SLURM array job (run_jobs.sh passes $SLURM_ARRAY_TASK_ID).

args <- commandArgs(trailingOnly = TRUE)
cond_id <- if (length(args) >= 1) as.integer(args[1]) else 1L

# ---- Design: factors crossed to form the condition grid ----
design <- expand.grid(
  n  = c(50, 100, 250),
  b1 = c(0, 0.2, 0.5),
  KEEP.OUT.ATTRS = FALSE
)
design$cond_id <- seq_len(nrow(design))

# ---- Fixed (non-manipulated) parameters ----
b0    <- 0
sigma <- 1
nsim  <- 500

stopifnot(cond_id >= 1L, cond_id <= nrow(design))
row <- design[cond_id, ]

params <- list(
  cond_id = row$cond_id,
  n       = row$n,
  b1      = row$b1,
  b0      = b0,
  sigma   = sigma
)

source("simulation/main.R")
