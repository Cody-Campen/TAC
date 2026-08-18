#!/bin/bash
# run_jobs.sh
# Submits one SLURM array job with one task per simulation condition.
# The number of conditions must match the design grid in run_sim.R
# (currently 3 levels of n x 3 levels of b1 = 9 conditions).
#
# Usage: sbatch run_jobs.sh
# After every task completes: Rscript simulation/aggregate_results.R

#SBATCH --job-name=sim_study
#SBATCH --array=1-9
#SBATCH --output=simulation/logs/slurm_%A_%a.out
#SBATCH --error=simulation/logs/slurm_%A_%a.err
#SBATCH --time=01:00:00
#SBATCH --mem=4G
#SBATCH --cpus-per-task=1

mkdir -p simulation/logs simulation/results

module load r

Rscript simulation/run_sim.R "$SLURM_ARRAY_TASK_ID"
