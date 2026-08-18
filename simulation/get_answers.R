# get_answers.R
# Collapses per-replication estimates for one condition into standard
# simulation performance measures.
#
# `estimates` is the row-bound output of fit_model() across replications
# (see main.R). `params` is the condition's parameter list, used to look
# up the true value the estimates are being judged against.

compute_performance <- function(estimates, params) {
  true_val <- params$b1

  converged <- estimates[estimates$converged, ]
  n_converged <- nrow(converged)

  bias      <- mean(converged$estimate - true_val)
  rel_bias  <- bias / true_val
  rmse      <- sqrt(mean((converged$estimate - true_val)^2))
  coverage  <- mean(converged$conf.low <= true_val & true_val <= converged$conf.high)
  power     <- mean(converged$conf.low > 0 | converged$conf.high < 0)

  data.frame(
    n              = params$n,
    b1             = params$b1,
    nsim           = nrow(estimates),
    convergence    = n_converged / nrow(estimates),
    bias           = bias,
    rel_bias       = rel_bias,
    rmse           = rmse,
    coverage       = coverage,
    power          = power
  )
}
