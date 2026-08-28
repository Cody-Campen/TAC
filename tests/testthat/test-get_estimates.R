# tests for get_estimates() in simulation/get_estimates.R

source_project("simulation/get_dataset.R")
source_project("simulation/get_conditions.R")
source_project("simulation/get_estimates.R")
source_project("style.R")

# these store the results from get_dataset(), its params, and get_estimates().
params <- list(
  n = 5, t = 600, beta = 0.0107, zeta = 1.4, eta = 39.23,
  c = 1, epsilon = 0.005
)

dataset <- get_dataset(params)

estimates <- get_estimates(dataset)

# Inverts the dynr parameterisation get_estimates() reports.
structural_params <- function(estimates, impulse = 1) {
  theta <- stats::setNames(estimates$estimate, estimates$term)

  beta <- sqrt(-theta[["restoring"]])
  c(beta = beta,
    zeta = -theta[["damping"]] / (2 * beta),
    eta  = theta[["v0"]] / (impulse * -theta[["restoring"]]))
}

# Integrates eq. 1 of \parencite{giraldo2017a} forward from the impulse.
ode_trajectory <- function(beta, zeta, eta, times, impulse = 1) {
  deriv <- function(t, y, parms) {
    list(c(y[["Velocity"]],
           -beta^2 * y[["Position"]] - 2 * zeta * beta * y[["Velocity"]]))
  }

  solution <- deSolve::ode(
    y      = c(Position = 0, Velocity = impulse * eta * beta^2),
    times  = times,
    func   = deriv,
    parms  = NULL,
    method = "lsoda",
    rtol   = 1e-10,
    atol   = 1e-12
  )

  as.numeric(solution[, "Position"])
}

# Plots the true curve against the fitted ODE
plot_ode_recovery <- function(check) {
  curves <- rbind(
    data.frame(time = check$times, tac = check$truth,  source = "True ODE"),
    data.frame(time = check$times, tac = check$fitted, source = "Fitted ODE")
  )
  curves$source <- factor(curves$source, levels = c("True ODE", "Fitted ODE"))

  figure <- ggplot2::ggplot(curves, ggplot2::aes(x = time, y = tac)) +
    ggplot2::geom_point(data = check$data, colour = "#C0C0C0", size = 0.5,
                        alpha = 0.5, inherit.aes = TRUE) +
    ggplot2::geom_line(ggplot2::aes(colour = source, linetype = source),
                       linewidth = 0.7) +
    ggplot2::scale_colour_manual(values = c("#404040", "#B22222"), name = NULL) +
    ggplot2::scale_linetype_manual(values = c("solid", "22"), name = NULL) +
    ggplot2::labs(
      x = "Time",
      y = "TAC",
      subtitle = sprintf(
        "beta %.5f -> %.5f   zeta %.3f -> %.3f   eta %.2f -> %.2f   RMSE %.5f",
        check$true_params[["beta"]], check$est_params[["beta"]],
        check$true_params[["zeta"]], check$est_params[["zeta"]],
        check$true_params[["eta"]],  check$est_params[["eta"]],
        check$rmse
      )
    ) +
    theme_apa_minimal()

  if (!interactive()) {
    return(NA)
  }

  grDevices::dev.new(width = 6.5, height = 4, noRStudioGD = TRUE)
  on.exit(grDevices::dev.off(), add = TRUE)
  print(figure)

  repeat {
    answer <- tolower(trimws(readline("Does the ODE recovery plot look OK? [y/n] ")))
    if (answer %in% c("y", "yes")) return(TRUE)
    if (answer %in% c("n", "no"))  return(FALSE)
  }
}

# Integrates the ODE a fit's estimates imply.
ode_recovery_check <- function(params, dataset, estimates) {
  # get_estimates() reports on dynr's scale, so invert it for the ODE.
  est_params <- structural_params(estimates)

  times  <- sort(unique(dataset$data$time))
  fitted <- ode_trajectory(est_params[["beta"]], est_params[["zeta"]],
                           est_params[["eta"]], times)
  truth  <- ode_trajectory(params$beta, params$zeta, params$eta, times)

  # The fit pools subjects, so one trajectory is compared to the per-time mean.
  observed <- as.numeric(tapply(dataset$data$tac, dataset$data$time,
                                mean)[as.character(times)])

  list(
    data        = dataset$data,
    times       = times,
    observed    = observed,
    truth       = truth,
    fitted      = fitted,
    converged   = all(estimates$converged),
    true_params = c(beta = params$beta, zeta = params$zeta, eta = params$eta),
    est_params  = est_params,
    rmse        = sqrt(mean((observed - fitted)^2)),
    amplitude   = diff(range(truth))
  )
}

test_that("the ODE implied by the estimates reproduces the true ODE trajectory", {
  skip_if_not_installed("deSolve")
  skip_if_not_installed("ggplot2")

  check <- ode_recovery_check(params, dataset, estimates)

  # Plot of the true(ish) ODE against the estimated ODE, judged by eye.
  looks_ok <- plot_ode_recovery(check)
  if (!is.na(looks_ok)) {
    expect_true(looks_ok)
  }

  expect_true(check$converged)

  # The estimates themselves, before the trajectory they imply.
  # Relative error, because beta is small enough to slip past a fixed tolerance.
  rel_error <- abs(check$est_params[names(check$true_params)] /
                     check$true_params - 1)
  expect_lt(rel_error[["beta"]], 0.05)
  expect_lt(rel_error[["zeta"]], 0.05)
  expect_lt(rel_error[["eta"]],  0.05)

  # The trajectory has to sit inside the noise, not merely have the right shape.
  expect_lt(check$rmse, 0.05 * check$amplitude)
  expect_lt(max(abs(check$observed - check$fitted)), 0.10 * check$amplitude)

  # The same statement again, without the Monte Carlo error in it.
  expect_lt(max(abs(check$truth - check$fitted)), 0.05 * check$amplitude)
})

test_that("dynr's estimate align with hand-calculated estimates", {
  # get the likelihood

})
  

test_that("the tidy frame is in the shape get_performance() reads", {
  source_project("simulation/get_performance.R")

  # One row per parameter, in the order the tables report them.
  expect_identical(names(estimates),
                   c("term", "estimate", "std.error", "conf.low", "conf.high",
                     "converged"))
  expect_identical(estimates$term, sim_terms)
  expect_type(estimates$estimate, "double")
  expect_type(estimates$std.error, "double")
  expect_type(estimates$conf.low, "double")
  expect_type(estimates$conf.high, "double")
  expect_type(estimates$converged, "logical")

  # A failed fit has to be rbind-able with a successful one, or collect_
  # performance() cannot stack a condition's replications.
  expect_identical(names(failed_fit), names(estimates))
  expect_identical(failed_fit$term, sim_terms)
  expect_identical(rbind(estimates, failed_fit)$term, rep(sim_terms, 2))

  # Tagged the way run_task() tags it, the frame is what get_performance() and
  # its condition helpers expect: the design columns are exactly the tags.
  tagged <- estimates
  tags   <- get_conditions()[1L, ]
  tagged[names(tags)] <- tags
  tagged$seed <- 1

  expect_setequal(condition_cols(tagged), setdiff(names(tags), "seed"))
  expect_equal(condition_params(tagged)$beta, tags$beta)

  performance <- get_performance(tagged, condition_params(tagged))

  expect_identical(performance$term, sim_terms)
  expect_identical(names(performance),
                   c("term", "truth", "nsim", "convergence", "bias", "rel_bias",
                     "rmse", "emp_se", "avg_se", "coverage"))
  expect_equal(performance$nsim, rep(1L, length(sim_terms)))
  expect_equal(performance$convergence, rep(1, length(sim_terms)))

  # The measures that read a column of the frame have to have found it.
  cells <- performance[performance$term %in% dynr_cells, ]
  expect_true(all(is.finite(cells$bias)))
  expect_true(all(is.finite(cells$avg_se)))
  expect_true(all(cells$coverage %in% c(0, 1)))
})