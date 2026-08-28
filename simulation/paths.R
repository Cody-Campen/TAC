# paths.R
# Every path the simulation pipeline reads or writes.
# The function files take their paths as arguments instead, so tests can
# point them at a temporary directory.

sim_dir <- "simulation"

sim_paths <- list(
  raw     = file.path(sim_dir, "results", "raw"),
  results = file.path(sim_dir, "results", "results.rds"),
  table   = file.path(sim_dir, "tables", "tab_sim.tex"),
  figure  = file.path(sim_dir, "figures", "fig_sim.png")
)
