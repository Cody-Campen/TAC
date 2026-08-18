# main.R
# Runs the full empirical-results pipeline end to end: clean -> analyze ->
# tables -> figures. Each stage is also runnable on its own (see the
# Rscript comment at the top of each file) so you can, e.g., regenerate
# tables/figures without re-touching the raw data.
#
#   Rscript empirical/main.R

message("1/4 cleaning...")
source("empirical/clean_data.R")

message("2/4 analyzing...")
source("empirical/analyze_data.R")

message("3/4 tables...")
source("empirical/make_tables.R")

message("4/4 figures...")
source("empirical/make_figures.R")

message("Done. See empirical/tables/ and empirical/figures/.")
