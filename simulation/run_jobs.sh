#!/bin/bash
# run_jobs.sh
# One SLURM array task per row of run_sim.R's design grid. The array size
# is not written here -- run_sim.R is the single source of truth for it,
# and the submit line below asks it for the count:
#
#   mkdir -p simulation/logs simulation/results/raw
#   sbatch --array=1-$(Rscript simulation/run_sim.R --n-tasks) simulation/run_jobs.sh
#
# (the dirs must exist first -- Slurm opens --output/--error before the
# script body runs, so mkdir there would be too late).
#
# Each task is idempotent (run_task() skips replications whose output
# already exists), so a failed task can simply be resubmitted on its own:
#   sbatch --array=<task_id> simulation/run_jobs.sh
#
# The last task to finish chains a follow-up job (afterok on the whole
# array) that runs the post-processing pipeline, simulation/main.R.

#SBATCH --job-name=sim_study
#SBATCH --output=simulation/logs/slurm_%A_%a.out
#SBATCH --error=simulation/logs/slurm_%A_%a.err
#SBATCH --time=00:05:00
#SBATCH --mem=1G
#SBATCH --cpus-per-task=1

module load r

Rscript simulation/run_sim.R "$SLURM_ARRAY_TASK_ID"

# Last task chains the post-processing job.
if [ "$SLURM_ARRAY_TASK_ID" -eq "$SLURM_ARRAY_TASK_MAX" ]; then
  sbatch --dependency=afterok:"$SLURM_ARRAY_JOB_ID" \
    --job-name=sim_post \
    --output=simulation/logs/post_%j.out \
    --error=simulation/logs/post_%j.err \
    --time=00:20:00 \
    --mem=4G \
    --wrap="module load r && Rscript simulation/main.R"
fi
