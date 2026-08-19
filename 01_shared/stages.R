# stages.R
# The stage dispatcher both pipelines share. A main.R defines its stages
# as a named list in pipeline order and hands it to run_stages(); the
# command line names which of them to run.

#' Runs the requested stages, always in the order `stages` lists them.
#'
#' @param requested Character vector of stage names; empty, or the single
#'   string "all", means every stage.
#' @param stages Named list of zero-argument functions, in pipeline order.
#' @param usage Single string of usage text, appended to the error message
#'   when a requested stage is unknown.
#' @return Character vector of the stages that ran, invisibly.
# Order is fixed by `stages`, not by the command line, so
# `main.R figures results` cannot draw a figure from a stale results file.
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

#' Stops with a stage-aware message if a stage's input file is missing.
#'
#' @param path Single string; the file the calling stage is about to read.
#' @param produced_by Single string naming the command that creates `path`.
#' @return `path` invisibly, if it exists.
# Named so a stage run out of order says which stage to run first, rather
# than failing with a bare "cannot open connection" from readRDS().
require_input <- function(path, produced_by) {
  if (!file.exists(path)) {
    stop(sprintf("%s not found -- run `%s` first.", path, produced_by),
         call. = FALSE)
  }
  invisible(path)
}
