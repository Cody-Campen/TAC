# get_dataset.R
# Draws one dataset from the Giraldo oscillator for a condition.
# `params` is the named list run_sim.R assigns.
get_dataset <- function(params) {
  # Constants.
  n <- params$n
  t <- params$t
  beta <- params$beta
  zeta <- params$zeta
  eta <- params$eta
  c <- params$c
  epsilon <- params$epsilon
  jitter <- if (is.null(params$jitter)) 0.05 else params$jitter

  id <- rep(1:n, each = t)
  time <- rep(0:(t-1), times = n)
  input <- rep(c(1, rep(0, times = t-1)), times = n)

  # These are the eigen values
  lambda_1 <- -1 * beta * zeta - beta * sqrt(zeta^2 - 1)
  lambda_2 <- -1 * beta * zeta + beta * sqrt(zeta^2 - 1)

  # Function to let us jitter the initial values.
  perturb <- function(x) x + stats::runif(1, -jitter * abs(x), jitter * abs(x))

  tac <- c * (beta * eta) / (2 * sqrt(zeta^2 - 1)) * (exp(lambda_2*(time)) - exp(lambda_1*(time))) + rnorm(n*t, mean = 0, sd = epsilon)

  list(
    data = data.frame(
      id = id,
      time = time,
      tac = tac,
      input = input
    ),

    # the initial values are transformed to be in terms of dynr's parameters
    inits = c(
      restoring = perturb(-beta^2),
      damping   = perturb(-2 * zeta * beta),
      v0        = perturb(c * eta * beta^2),
      mnoise    = perturb(epsilon^2)
    )
  )
}
