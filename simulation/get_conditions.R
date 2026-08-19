# get_conditions.R
# The design grid and the task_id -> params mapping.

#' Fully crosses the study's factors into one row per task.
#'
#' @param seed Integer vector of replication seeds, crossed with every
#'   condition.
#' @param n Numeric vector of sample sizes.
#' @param b1 Numeric vector of true slopes.
#' 
#' @return Data frame with columns `seed`, `n`, `b1`, one row per task.
make_design <- function(seed = 1:500,
                        n    = c(50, 100, 250),
                        b1   = c(0, 0.2, 0.5)) {
  expand.grid(seed = seed, n = n, b1 = b1, KEEP.OUT.ATTRS = FALSE)
}

#' Turns one row of the grid into the `params` list run_task() expects.
#'
#' @param design Data frame from make_design().
#' @param task_id Single whole number in `1:nrow(design)`; anything else
#'   is an error, since it arrives as a cluster array index.
#' @param fixed Named list of the non-manipulated parameters (b0, sigma).
#' @return Named list: the design row's columns, `task_id`, and `fixed`.
params_for_task <- function(design, task_id, fixed = list()) {
  valid <- is.numeric(task_id) && length(task_id) == 1L && !is.na(task_id) &&
    task_id >= 1 && task_id <= nrow(design) && task_id == trunc(task_id)

  if (!valid) {
    stop(sprintf("task_id must be a single whole number in 1:%d, got %s",
                 nrow(design), paste(deparse(task_id), collapse = " ")),
         call. = FALSE)
  }

  c(as.list(design[as.integer(task_id), ]),
    list(task_id = as.integer(task_id)),
    fixed)
}
