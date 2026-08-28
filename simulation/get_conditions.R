# get_conditions.R
# The design grid and the task_id -> params mapping.

# Fully crosses the study's factors into one row per task.
# Factor names match get_dataset()'s parameters.
# The dynr-scale truths are appended, because get_performance() reads a term's
# true value out of a column of this grid and get_estimates() now reports on
# that scale. They are functions of the factors, not factors themselves.
get_conditions <- function(seed = 1:5,
                           n    = 2,
                           t    = 500,
                           beta = 0.0107,
                           zeta = 1.4,
                           eta  = 39.23,
                           c    = 1,        # leave at 1; get_dataset() writes a bare 1 input
                           epsilon = 0.01,
                           dnoise = 0) {    # leave at 0; the draw has no process noise
  design <- expand.grid(seed = seed, n = n, t = t, beta = beta, zeta = zeta,
                        eta = eta, c = c, epsilon = epsilon, dnoise = dnoise,
                        KEEP.OUT.ATTRS = FALSE)

  cbind(design, dynr_truth(design))
}

# The dynr parameterisation of a set of structural parameters.
# The Dirac drink enters as an initial velocity, so v0 is the impulse response
# of the closed form get_dataset() draws from, differentiated at t = 0.
dynr_truth <- function(params) {
  data.frame(
    restoring = -params$beta^2,
    damping   = -2 * params$zeta * params$beta,
    v0        = params$c * params$eta * params$beta^2,
    mnoise    = params$epsilon^2
  )
}

# Turns one row of the grid into the `params` list run_task() expects.
# `task_id` arrives as a cluster array index, so anything out of range errors.
params_for_task <- function(design, task_id, fixed = list()) {
  valid <- is.numeric(task_id) && length(task_id) == 1L && !is.na(task_id) &&
    task_id >= 1 && task_id <= nrow(design) && task_id == trunc(task_id)

  if (!valid) {
    stop(sprintf("task_id must be a single whole number in 1:%d, got %s",
                 nrow(design), paste(deparse(task_id), collapse = " ")),
         call. = FALSE)
  }

  base::c(as.list(design[as.integer(task_id), ]),
          list(task_id = as.integer(task_id)),
          fixed)
}
