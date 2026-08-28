# run_task.R
# The work of one task: generate a dataset, fit the model, save the estimate.
# Pure definitions only, so run_sim.R sources its dependencies first.

# Where a task's output lands, zero-padded so the files sort in task order.
task_file <- function(out_dir, task_id) {
  file.path(out_dir, sprintf("task_%05d.rds", task_id))
}

# Runs one replication and saves its estimate, unless it already ran.
# The skip is what makes a failed array element resubmittable on its own.
run_task <- function(params, out_dir) {
  out_file <- task_file(out_dir, params$task_id)

  if (file.exists(out_file)) {
    return(invisible(out_file))
  }

  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  set.seed(params$seed)

  result <- get_estimates(get_dataset(params))

  # Tag with the whole design row, so a new factor needs no edit here.
  # `task_id` is dropped because condition_cols() would read it as a factor.
  tags <- params[setdiff(names(params), "task_id")]
  result[names(tags)] <- tags

  saveRDS(result, out_file)

  invisible(out_file)
}
