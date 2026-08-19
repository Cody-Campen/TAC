# functions/clean_data.R
# The cleaning rules, as one pure function. Sourced by
# empirical/main.R's clean stage (which reads and writes) and by the
# test suite. Nothing in this file touches the filesystem -- keep it that
# way, or the tests stop being able to source it.

#' Applies every cleaning rule to the raw empirical data.
#'
#' @param raw Data frame as read.csv() returns it, with columns `id`,
#'   character `group`, `x1`, and `y`.
#' @return Data frame of the analysed rows, `group` a factor with levels
#'   control, treatment.
clean_dataset <- function(raw) {
  raw$group <- trimws(raw$group)

  cleaned <- raw[!duplicated(raw$id), ]
  cleaned <- cleaned[!is.na(cleaned$x1) & cleaned$x1 > 0, ]  # drop sentinel/NA values
  cleaned <- cleaned[cleaned$group %in% c("control", "treatment"), ]
  cleaned$group <- factor(cleaned$group, levels = c("control", "treatment"))

  cleaned
}
