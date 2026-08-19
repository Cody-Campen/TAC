# run_task.R
# The work of one task: generate one dataset, fit the model, save the raw
# estimate tagged with the condition it came from. collect_performance() later
# groups those rows by condition into performance summaries.
#
# Pure definitions only -- run_sim.R sources the functions this depends
# on (generate_dataset, fit_model) before calling run_task().

#' Where a task's output lands.
#'
#' @param out_dir Single string; directory the raw per-task results go in.
#' @param task_id Single whole number; the task's index in the design.
#' @return Single string, the file path, zero-padded so the files sort in
#'   task order.
task_file <- function(out_dir, task_id) {
  file.path(out_dir, sprintf("task_%05d.rds", task_id))
}

#' Runs one replication and saves its estimate, unless it already ran.
#'
#' @param params Named list from params_for_task(), supplying `task_id`,
#'   `seed`, `n`, `b1`, and the fields generate_dataset() needs.
#' @param out_dir Single string; directory to write the .rds into,
#'   created if it does not exist. Supplied by the caller from paths.R.
#' @return Single string, the path written or the existing one, invisibly.
# The skip is what makes a task resubmittable: a failed array element can
# go back to the queue on its own without redoing, or double-counting,
# its neighbours.
run_task <- function(params, out_dir) {
  out_file <- task_file(out_dir, params$task_id)

  if (file.exists(out_file)) {
    return(invisible(out_file))
  }

  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

  set.seed(params$seed)

  result <- fit_model(generate_dataset(params))
  result$seed <- params$seed
  result$n    <- params$n
  result$b1   <- params$b1

  saveRDS(result, out_file)

  invisible(out_file)
}
