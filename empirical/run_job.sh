#!/bin/bash
# run_job.sh
# Submits the empirical pipeline (clean -> analyze -> tables -> figures)
# as one SLURM job.
#
# Usage: sbatch empirical/run_job.sh
#
# Real dataset must be reachable from the compute node: put
# empirical/config/data_path.local.txt on the cluster filesystem first
# -- see empirical/README.md.

#SBATCH --job-name=empirical
#SBATCH --output=empirical/logs/slurm_%j.out
#SBATCH --error=empirical/logs/slurm_%j.err
#SBATCH --time=00:30:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1

mkdir -p empirical/logs

module load r

Rscript empirical/main.R
