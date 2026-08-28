# tests for get_dataset() in simulation/get_dataset.R

source_project("simulation/get_dataset.R")

# With no error, the second derivative is an exact function of the TAC.
# It should equal eq. 1 from \parencite{giraldo2017a}.
test_that("test of expected second derivative",
  {
    set.seed(1)

    n <- 10
    t <- 1200
    beta <- 0.0107
    zeta <- 1.4
    eta <- 39.23
    c <- 1
    epsilon <- 0

    # get_dataset() returns list(data, inits); this test only wants the frame.
    data <- get_dataset(
      list(
        n = n,
        t = t,
        beta = beta,
        zeta = zeta,
        eta = eta,
        c = c,
        epsilon = epsilon
      )
    )$data

    # creating our lags so we can compute derivatives
    lag_by_id <- function(x, id, k) {
      unsplit(lapply(split(x, id), function(xi) c(rep(NA, k), head(xi, -k))), id)
    }
    data$tac_lag1 = lag_by_id(data$tac, data$id, 1)
    data$tac_lag2 = lag_by_id(data$tac, data$id, 2)

    data$tac_d1 = data$tac - data$tac_lag1
    data$tac_d2 = data$tac - 2 * data$tac_lag1 + data$tac_lag2

    # eq. 1 from \parencite{giraldo2017a} is:
    expected_tac_d2 <- -1 * beta^2 * data$tac - 2 * zeta * beta * data$tac_d1 + beta^2 * eta * data$input

    # the first two rows of each subject have no second difference to compare.
    comparable <- !is.na(data$tac_d2)

    expect_equal(data$tac_d2[comparable], expected_tac_d2[comparable],
                tolerance = 1e-5)
  }
)


