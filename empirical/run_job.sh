#!/bin/bash
# run_job.sh
# Submits the empirical-results pipeline (clean -> analyze -> tables ->
# figures) as one SLURM job.
#
# Usage: sbatch empirical/run_job.sh
#
# The real dataset must be reachable from the compute node: place
# empirical/config/data_path.local.txt on the cluster filesystem,
# pointing at the real data's absolute path, before submitting -- see
# empirical/README.md.

#SBATCH --job-name=empirical
#SBATCH --output=empirical/logs/slurm_%j.out
#SBATCH --error=empirical/logs/slurm_%j.err
#SBATCH --time=00:30:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1

mkdir -p empirical/logs

module load r

Rscript empirical/main.R
