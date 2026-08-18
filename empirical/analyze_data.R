# analyze_data.R
# Reads the cleaned dataset (never the raw one), fits the primary model,
# and saves results to empirical/data/processed/results.rds (gitignored)
# for make_tables.R and make_figures.R to read.
#
# `estimates` is a broom::tidy() data frame (term, estimate, std.error,
# statistic, p.value, conf.low, conf.high) so it plugs directly into
# modelsummary/apa_table's "already tidy" input without reshaping.
#
#   Rscript empirical/analyze_data.R

library(broom)

analyze_dataset <- function(cleaned) {
  # model = FALSE, x = FALSE, y = FALSE: don't retain a copy of the data
  # inside the fitted object -- keeps saved .rds files free of raw values.
  fit <- lm(y ~ x1 + group, data = cleaned, model = FALSE, x = FALSE, y = FALSE)
  estimates <- tidy(fit, conf.int = TRUE)

  list(
    fit = fit,
    estimates = estimates,
    n = nrow(cleaned),
    r_squared = summary(fit)$r.squared
  )
}

cleaned <- readRDS("empirical/data/processed/cleaned.rds")
results <- analyze_dataset(cleaned)

saveRDS(results, "empirical/data/processed/results.rds")

message(sprintf(
  "Fit model on n = %d, R^2 = %.3f.", results$n, results$r_squared
))
