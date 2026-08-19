# paths.R
# Every path the simulation pipeline reads or writes, in one place, so
# renaming the folder is a one-line change. Sourced by the entry points;
# the function files take their paths as arguments instead, which is what
# lets the tests point them at a temporary directory.
#
# Paths stay root-relative because every entry point runs from the project
# root. run_jobs.sh spells its own out -- Slurm parses #SBATCH before any
# interpreter starts.

sim_dir <- "simulation"

sim_paths <- list(
  raw     = file.path(sim_dir, "results", "raw"),
  results = file.path(sim_dir, "results", "results.rds"),
  table   = file.path(sim_dir, "tables", "tab_sim.tex"),
  figure  = file.path(sim_dir, "figures", "fig_sim.png")
)
