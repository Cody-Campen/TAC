# read_data.R
# Where the real dataset lives. The path is configuration, not code: it
# points outside the repo and differs between the laptop and the cluster,
# so it comes from a gitignored file rather than a hardcoded string.

#' Returns the configured raw data path, or the dummy data if unconfigured.
#'
#' @param config Single string; gitignored file whose first line is the
#'   real data's absolute path.
#' @param fallback Single string; path used, with a warning, when
#'   `config` is absent.
#' @return Single string, the path to read the raw data from.
# Both paths are supplied by the caller from paths.R. The fallback warns
# because silently analysing dummy data and silently analysing the real
# data look identical downstream.
raw_data_path <- function(config, fallback) {
  if (file.exists(config)) {
    return(trimws(readLines(config, n = 1)))
  }

  warning(
    config, " not found (copy it from data_path.example.txt and set it to ",
    "the real data's absolute path). Falling back to ", fallback, ".",
    call. = FALSE
  )
  fallback
}
