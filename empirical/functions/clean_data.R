# functions/clean_data.R
# The cleaning rules, as one pure function.
# Nothing in this file touches the filesystem.

# Applies every cleaning rule to the raw empirical data.
# `group` comes back as a factor with levels control, treatment.
clean_dataset <- function(raw) {
  raw$group <- trimws(raw$group)

  cleaned <- raw[!duplicated(raw$id), ]
  cleaned <- cleaned[!is.na(cleaned$x1) & cleaned$x1 > 0, ]  # drop sentinel/NA values
  cleaned <- cleaned[cleaned$group %in% c("control", "treatment"), ]
  cleaned$group <- factor(cleaned$group, levels = c("control", "treatment"))

  cleaned
}
