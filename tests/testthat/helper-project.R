# helper-project.R
# Files named helper-*.R are sourced automatically before any test runs.
# testthat runs in tests/testthat/, but the project addresses files from root.

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

# Resolves a root-relative path against the project root.
project_path <- function(...) file.path(project_root, ...)

# Sources a project file by its root-relative path.
# It goes into the global environment, so test_that() blocks can see it.
source_project <- function(rel_path) {
  source(project_path(rel_path), local = FALSE)
  invisible(TRUE)
}
