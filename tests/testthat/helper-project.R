# helper-project.R
# Files named helper-*.R are sourced automatically before any test runs.
#
# testthat sets the working directory to tests/testthat/ while the suite
# runs, but every script in this project addresses files relative to the
# project root. These two functions bridge that gap: use project_path()
# for data files and source_project() for code.

project_root <- local({
  path <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  while (!file.exists(file.path(path, ".here"))) {
    parent <- dirname(path)
    if (identical(parent, path)) {
      stop("could not find the .here marker in any parent of ", getwd(),
           " -- is the project root missing its .here file?", call. = FALSE)
    }
    path <- parent
  }
  path
})

#' Resolves a root-relative path against the project root.
#'
#' @param ... Character path components, as file.path() takes them.
#' @return Single string, the absolute path.
project_path <- function(...) file.path(project_root, ...)

#' Sources a project file by its root-relative path.
#'
#' @param rel_path Single string; root-relative path of the R file.
#' @return TRUE, invisibly.
# Sourced into the global environment so the functions stay visible
# inside test_that() blocks.
source_project <- function(rel_path) {
  source(project_path(rel_path), local = FALSE)
  invisible(TRUE)
}
