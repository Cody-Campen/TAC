# get_dataset.R
# Generates one simulated dataset for a condition. `params` is the named
# list assigned in run_sim.R; every condition must supply these fields.

#' Draws one dataset from the linear model the study estimates.
#'
#' @param params Named list for one condition, supplying the numeric
#'   scalars `n`, `b0`, `b1`, and `sigma`.
#' 
#' @return Data frame size n*t x 2 with columns 'TAC' and 'input'. 
generate_dataset <- function(params) {
  n <- params$n
  t <- params$t
  beta <- params$beta
  zeta <- params$zeta
  eta <- params$eta
  c <- params$c

  # we have 4 columns, id, time, input and TAC, the first three are easy.
  id <- rep(1:n, each = t)
  time <- rep(0:(t-1), times = n)
  input <- rep(c(1, rep(0, times = t-1)), times = n) 

  # constants
  lambda_1 <- -1 * beta * zeta - beta * sqrt(zeta^2 - 1)
  lambda_2 <- -1 * beta * zeta + beta * sqrt(zeta^2 - 1)

  tac <- c * (beta * eta) / (2 * sqrt(zeta^2 - 1)) * (exp(lambda_2*(time)) - exp(lambda_1*(time)))

  
  data.frame(id = id,
             time = time,
             tac = tac,
             input = input)
}
