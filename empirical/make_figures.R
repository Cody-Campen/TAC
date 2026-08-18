# make_figures.R
# Run after run_analysis.R. Reads empirical/data/processed/cleaned.rds and
# writes empirical/figures/fig_empirical.png, referenced by
# sections/05_empirical_results.tex via \includegraphics.
#
#   Rscript empirical/make_figures.R

cleaned <- readRDS("empirical/data/processed/cleaned.rds")
results <- readRDS("empirical/data/processed/results.rds")

dir.create("empirical/figures", showWarnings = FALSE, recursive = TRUE)

png("empirical/figures/fig_empirical.png", width = 6, height = 4.5, units = "in", res = 300)

group_colors <- c(control = "#4C72B0", treatment = "#DD8452")

plot(
  cleaned$x1, cleaned$y,
  col = group_colors[as.character(cleaned$group)],
  pch = 16, cex = 0.8,
  xlab = expression(X[1]), ylab = "Y",
  main = "Empirical Analysis: Outcome by Predictor and Group"
)

for (g in levels(cleaned$group)) {
  sub <- cleaned[cleaned$group == g, ]
  abline(lm(y ~ x1, data = sub), col = group_colors[g], lwd = 2)
}

legend(
  "topleft", legend = levels(cleaned$group),
  col = group_colors[levels(cleaned$group)], pch = 16, lwd = 2, bty = "n"
)

dev.off()

message("Wrote empirical/figures/fig_empirical.png")
