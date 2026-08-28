# stages.R
# The stage dispatcher both pipelines share.
# A main.R defines its stages in pipeline order and hands them to run_stages().

# Runs the requested stages, always in the order `stages` lists them.
# Order is fixed by `stages` rather than by the command line.
run_stages <- function(requested, stages, usage = "") {
  if (length(requested) == 0L || identical(requested, "all")) {
    requested <- names(stages)
  }

  unknown <- setdiff(requested, names(stages))
  if (length(unknown) > 0L) {
    stop(sprintf("unknown stage: %s\n%s",
                 paste(unknown, collapse = ", "), usage), call. = FALSE)
  }

  to_run <- names(stages)[names(stages) %in% requested]

  for (i in seq_along(to_run)) {
    message(sprintf("[%d/%d] %s", i, length(to_run), to_run[i]))
    stages[[to_run[i]]]()
  }

  invisible(to_run)
}

# Stops with a stage-aware message if a stage's input file is missing.
# It names the stage to run first, rather than failing inside readRDS().
require_input <- function(path, produced_by) {
  if (!file.exists(path)) {
    stop(sprintf("%s not found -- run `%s` first.", path, produced_by),
         call. = FALSE)
  }
  invisible(path)
}
