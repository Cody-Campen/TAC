# read_data.R
# Where the real dataset lives.
# The path is configuration, so it comes from a gitignored file.

# Returns the configured raw data path, or the dummy data if unconfigured.
# The fallback warns, since dummy and real data look identical downstream.
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
