#!/usr/bin/env Rscript
# tac_dlo_sandbox.R
# Standalone scratch script -- NOT part of the simulation pipeline and not
# sourced by anything. Drives two candidate within-episode models with the
# *same* shot-noise ingestion process and compares them.
#
#   Rscript simulation/tac_dlo_sandbox.R
#
# Model 1, the damped linear oscillator of Giraldo et al. (2017):
#
#   d^2 TAC/dt^2 = -k^2 TAC - 2 zeta k dTAC/dt + k^2 eta I(t)
#
# Model 2, equation 1 of sections/01_background.tex with S(t) dropped and
# M(t) given the Michaelis-Menten form the metabolism literature uses:
#
#   dTAC/dt = I(t) - Vmax TAC / (Km + TAC)
#
# Same I(t), same drinks, same window; only the elimination differs. The
# whole point of the comparison is that the two disagree about the shape
# of the *decay*, which is the part of a TAC curve there is most data on:
#
#   - the oscillator eliminates by a linear restoring force, so its tail
#     is exponential with a half-life fixed by k and zeta -- it does not
#     depend on how much was drunk;
#   - Michaelis-Menten saturates, so above Km it eliminates at a nearly
#     constant *absolute* rate Vmax (the near-linear BAC decline ethanol
#     is known for) and only becomes exponential once TAC falls below Km.
#
# That difference propagates to dose scaling, which is where it matters
# for the paper's second criterion. The oscillator is linear, so doubling
# every dose exactly doubles TAC everywhere and doubles AUC -- it cannot
# produce disproportionate exposure. Michaelis-Menten is not linear, and
# AUC grows roughly with the square of the dose, so the same extra drink
# costs a slow metaboliser far more. Panel (f) measures both slopes.
#
# Writes simulation/figures/tac_dlo_sandbox.png and prints a summary.
# Base graphics only, no packages, so it runs on a bare R.
#
# Units: time in hours, dose in standard drinks. The two models do NOT
# share a TAC unit -- eta carries a factor of time (the oscillator's
# steady state is eta*I, a gain on the *rate*), while Michaelis-Menten
# accumulates dose directly. Only shapes are comparable, which is why
# panel (d) normalises each curve by its own peak rather than fudging a
# common scale.

# ---- Parameters (the things worth turning) ----------------------------

set.seed(2026)

pars <- list(
  duration     = 16,      # hours of record
  window       = c(1, 5), # the drinking episode: shot noise on, then off
  rate         = 2,       # drinks per hour while drinking
  dose_mean    = 1,       # mean dose per drink (exponentially distributed)
  tau          = 0.15,    # absorption time constant; a drink peaks tau
                          # after it is poured, mean lag 2*tau, hours

  # Model 1: damped linear oscillator
  k            = 0.9,     # natural frequency, radians/hour
  zeta         = 1.6,     # damping ratio; > 1 means no ringing
  eta          = 1,       # input gain (steady-state TAC per unit intake)

  # Model 2: Michaelis-Menten elimination. Km well below the peak is what
  # makes elimination effectively zero-order over most of the curve, which
  # is the regime ethanol is actually in.
  vmax         = 1.5,     # max elimination rate, dose/hour
  km           = 0.5,     # half-saturation concentration

  dt           = 1 / 240, # integration step, hours -- keep well under tau
  sigma        = 0.05,    # sensor measurement error SD (as a fraction of
                          # each model's own peak, so both are comparable)
  sample_every = 5 / 60   # sensor sampling interval, hours
)

# Dose multipliers for the scaling panel, and the grid it runs on. It needs
# a much longer record than the figure does: at 3x dose the Michaelis-Menten
# curve takes ~40 h to clear, and truncating it would understate exactly the
# nonlinearity being measured. Coarser step to keep the sweep quick.
sweep_mult     <- c(0.25, 0.5, 0.75, 1, 1.5, 2, 2.5, 3)
sweep_duration <- 96
sweep_dt       <- 1 / 60

out_png <- file.path("simulation", "figures", "tac_dlo_sandbox.png")

# ---- The shot-noise input (shared by both models) ---------------------

# A marked Poisson process: N ~ Poisson(rate * window length) drinks placed
# uniformly in the window, each with an exponential dose. Drawing the count
# first is the same process as drawing exponential gaps, and it keeps every
# arrival inside the window.
draw_events <- function(window, rate, dose_mean) {
  n <- rpois(1, rate * diff(window))
  data.frame(time = sort(runif(n, window[1], window[2])),
             dose = rexp(n, rate = 1 / dose_mean))
}

# I(t) = sum_i dose_i * g(t - t_i), with the alpha (gamma-2) absorption
# kernel g(u) = u * exp(-u/tau) / tau^2 for u >= 0.
#
# Unit area, so tau spreads a drink out without changing how much of it
# arrives; it peaks one tau after the drink and has mean lag 2*tau, and
# tau -> 0 approaches a train of delta spikes. The plain exponential
# kernel exp(-u/tau)/tau is the other obvious choice and is worse twice
# over: it has a drink hit its maximum absorption rate the instant it is
# poured, and that jump discontinuity is one the fixed-step integrators
# below cannot resolve -- it costs about three orders of magnitude on the
# oscillator's AUC identity, and the error barely shrinks as the step
# does. g(0) = 0 is what buys the accuracy back.
shot_noise <- function(t, events, tau) {
  if (nrow(events) == 0L) return(numeric(length(t)))
  lag <- outer(t, events$time, "-")
  pulse <- lag * exp(-lag / tau) / tau^2
  pulse[lag < 0 | !is.finite(pulse)] <- 0   # nothing arrives before the drink
  as.numeric(pulse %*% events$dose)
}

# ---- Model 1: the damped linear oscillator ----------------------------

# Fixed-step RK4 on the state (TAC, dTAC/dt). Fixed step rather than an ODE
# package because the input is spiky enough that the step has to be pinned
# to a fraction of tau anyway.
integrate_dlo <- function(times, input, k, zeta, eta, tac0 = 0, dtac0 = 0) {
  h <- times[2] - times[1]
  deriv <- function(t, x) {
    c(x[2], -k^2 * x[1] - 2 * zeta * k * x[2] + k^2 * eta * input(t))
  }

  state <- matrix(NA_real_, nrow = length(times), ncol = 2)
  x <- c(tac0, dtac0)
  state[1, ] <- x
  for (i in seq_len(length(times) - 1L)) {
    t  <- times[i]
    s1 <- deriv(t,         x)
    s2 <- deriv(t + h / 2, x + h / 2 * s1)
    s3 <- deriv(t + h / 2, x + h / 2 * s2)
    s4 <- deriv(t + h,     x + h * s3)
    x  <- x + h / 6 * (s1 + 2 * s2 + 2 * s3 + s4)
    state[i + 1L, ] <- x
  }
  data.frame(time = times, tac = state[, 1], dtac = state[, 2])
}

# Exact solution of the homogeneous equation, i.e. what happens once the
# drinking stops. Overlaying it on the integrator's output is both the
# decay annotation for the figure and a check that the integrator is right.
dlo_free_response <- function(t, k, zeta, tac0, dtac0, t0) {
  s <- t - t0
  out <- if (zeta > 1) {                       # overdamped: two real modes
    spread <- k * sqrt(zeta^2 - 1)
    r_slow <- -zeta * k + spread
    r_fast <- -zeta * k - spread
    c_slow <- (dtac0 - r_fast * tac0) / (r_slow - r_fast)
    c_slow * exp(r_slow * s) + (tac0 - c_slow) * exp(r_fast * s)
  } else if (isTRUE(all.equal(zeta, 1))) {     # critically damped
    (tac0 + (dtac0 + k * tac0) * s) * exp(-k * s)
  } else {                                     # underdamped: it rings
    w_d <- k * sqrt(1 - zeta^2)
    exp(-zeta * k * s) *
      (tac0 * cos(w_d * s) + (dtac0 + zeta * k * tac0) / w_d * sin(w_d * s))
  }
  out[s < 0] <- NA_real_
  out
}

# The slowest mode sets the tail: it is what you would read off the curve
# as the elimination rate. The faster overdamped mode is gone long before.
# Note what is missing from the arguments -- the dose. The oscillator's
# half-life is a property of the person, never of the night.
dlo_decay_rate <- function(k, zeta) {
  if (zeta > 1) k * (zeta - sqrt(zeta^2 - 1)) else if (zeta < 1) zeta * k else k
}

# ---- Model 2: Michaelis-Menten elimination ----------------------------

# dTAC/dt = I(t) - Vmax*TAC/(Km + TAC), same RK4 on a scalar state.
# TAC cannot go negative on its own: elimination vanishes as TAC does.
integrate_mm <- function(times, input, vmax, km, tac0 = 0) {
  h <- times[2] - times[1]
  deriv <- function(t, x) input(t) - vmax * x / (km + x)

  tac <- numeric(length(times))
  x <- tac0
  tac[1] <- x
  for (i in seq_len(length(times) - 1L)) {
    t  <- times[i]
    s1 <- deriv(t,         x)
    s2 <- deriv(t + h / 2, x + h / 2 * s1)
    s3 <- deriv(t + h / 2, x + h / 2 * s2)
    s4 <- deriv(t + h,     x + h * s3)
    x  <- x + h / 6 * (s1 + 2 * s2 + 2 * s3 + s4)
    tac[i + 1L] <- x
  }
  data.frame(time = times, tac = tac)
}

# The Michaelis-Menten decay has a closed form too, but as t(TAC) rather
# than TAC(t): separating dC/dt = -Vmax C/(Km + C) and integrating gives
#
#   Vmax * t = Km * log(C0/C) + (C0 - C).
#
# So feed it concentrations and get back the times they are reached. That
# is the exact overlay for panel (c), and the two terms are the two
# regimes side by side: the (C0 - C) term is the zero-order straight-line
# decline, the log term is the exponential tail that takes over below Km.
mm_decay_time <- function(tac, tac0, vmax, km) {
  (km * log(tac0 / tac) + (tac0 - tac)) / vmax
}

# Time to halve from a given concentration. Unlike the oscillator's, this
# depends on where you start: ~C/(2*Vmax) when C >> Km (so a bigger night
# means a longer half-life), flattening to Km*log(2)/Vmax at the bottom.
mm_half_life <- function(tac, vmax, km) (km * log(2) + tac / 2) / vmax

# ---- Simulate both models on one realisation --------------------------

events <- draw_events(pars$window, pars$rate, pars$dose_mean)
times  <- seq(0, pars$duration, by = pars$dt)
intake <- shot_noise(times, events, pars$tau)
input  <- function(t) shot_noise(t, events, pars$tau)

dlo <- integrate_dlo(times, input, pars$k, pars$zeta, pars$eta)
mm  <- integrate_mm(times, input, pars$vmax, pars$km)

# The sensor record, noise scaled to each model's own peak so that neither
# looks cleaner than the other purely because of the unit mismatch.
keep <- seq(1L, length(times), by = round(pars$sample_every / pars$dt))
obs <- function(tac) {
  data.frame(time = times[keep],
             tac  = tac[keep] + rnorm(length(keep), sd = pars$sigma * max(tac)))
}
dlo_obs <- obs(dlo$tac)
mm_obs  <- obs(mm$tac)

# Where the free decay starts. Not the end of the window: with tau > 0 the
# last drink is still being absorbed after the window closes, and the
# closed forms only apply once that has finished. The alpha kernel leaves
# (1 + u/tau)exp(-u/tau) of a dose still to arrive after u, so ten time
# constants in, 0.05% of that last drink is outstanding.
last_drink <- if (nrow(events) == 0L) pars$window[1] else max(events$time)
at    <- which.min(abs(times - min(last_drink + 10 * pars$tau, pars$duration)))
t_off <- times[at]

dlo_decay <- dlo_free_response(times, pars$k, pars$zeta,
                               tac0 = dlo$tac[at], dtac0 = dlo$dtac[at],
                               t0 = t_off)

# Exact MM decay, generated the other way round: pick concentrations from
# where the decay starts down to a hair above zero, and solve for when.
mm_grid  <- seq(mm$tac[at], mm$tac[at] / 500, length.out = 400)
mm_exact <- data.frame(
  time = t_off + mm_decay_time(mm_grid, mm$tac[at], pars$vmax, pars$km),
  tac  = mm_grid
)

# ---- Dose scaling: the same night, scaled up and down ------------------

# Multiply every dose, clear the whole curve on a long grid, and take AUC.
# The oscillator has no choice but to return exactly proportional AUC --
# it is a linear system. Whatever Michaelis-Menten does here, it does
# because saturation is real.
sweep_one <- function(mult) {
  ev <- events
  ev$dose <- ev$dose * mult
  tt <- seq(0, sweep_duration, by = sweep_dt)
  n  <- length(tt)
  inp <- function(t) shot_noise(t, ev, pars$tau)

  d <- integrate_dlo(tt, inp, pars$k, pars$zeta, pars$eta)
  m <- integrate_mm(tt, inp, pars$vmax, pars$km)
  trap <- function(y) sum((y[-1] + y[-n]) / 2) * sweep_dt

  c(dlo = trap(d$tac), mm = trap(m$tac),
    dlo_left = d$tac[n], mm_left = m$tac[n])
}

sweep <- as.data.frame(t(vapply(sweep_mult, sweep_one, numeric(4))))
sweep$mult <- sweep_mult

# Slope of log(AUC) on log(dose): 1 means strictly proportional.
auc_slope <- function(auc) unname(coef(lm(log(auc) ~ log(sweep$mult)))[2])

# ---- Figure -----------------------------------------------------------

dir.create(dirname(out_png), showWarnings = FALSE, recursive = TRUE)
png(out_png, width = 9, height = 10, units = "in", res = 300)
op <- par(mfrow = c(3, 2), mar = c(4.1, 4.5, 2.8, 1.1), family = "serif")

shade <- function() rect(pars$window[1], -1e9, pars$window[2], 1e9,
                         col = "grey93", border = NA)

# (a) the driving process, shared by both models.
plot(times, intake, type = "n", xlab = "Time (hours)",
     ylab = expression(paste("Ingestion rate  ", I(t))),
     main = "(a) Shot-noise input, shared by both models", bty = "n")
shade()
lines(times, intake, col = "#404040", lwd = 1)
rug(events$time, col = "black", lwd = 1.2, ticksize = 0.04)
box(bty = "l")

# (b) oscillator, with its exact free decay laid over the tail.
plot(times, dlo$tac, type = "n", xlab = "Time (hours)", ylab = "TAC(t)",
     main = "(b) Damped oscillator: exponential decay", bty = "n")
shade()
points(dlo_obs$time, dlo_obs$tac, pch = 1, cex = 0.4, col = "grey55")
lines(times, dlo$tac, col = "#404040", lwd = 1.6)
lines(times, dlo_decay, col = "black", lwd = 1.4, lty = 2)
abline(v = t_off, col = "grey40", lty = 3)
legend("topright", bty = "n", cex = 0.8,
       legend = c("simulated", "sensor samples",
                  sprintf("exact decay (half-life %.2f h, dose-free)",
                          log(2) / dlo_decay_rate(pars$k, pars$zeta))),
       col = c("#404040", "grey55", "black"),
       lty = c(1, NA, 2), pch = c(NA, 1, NA), lwd = c(1.6, NA, 1.4))
box(bty = "l")

# (c) Michaelis-Menten, same treatment.
plot(times, mm$tac, type = "n", xlab = "Time (hours)", ylab = "TAC(t)",
     main = "(c) Michaelis-Menten: near-linear decline", bty = "n")
shade()
points(mm_obs$time, mm_obs$tac, pch = 1, cex = 0.4, col = "grey55")
lines(times, mm$tac, col = "#404040", lwd = 1.6)
lines(mm_exact$time, mm_exact$tac, col = "black", lwd = 1.4, lty = 2)
abline(v = t_off, col = "grey40", lty = 3)
abline(h = pars$km, col = "grey40", lty = 4)
legend("topright", bty = "n", cex = 0.8,
       legend = c("simulated", "sensor samples",
                  sprintf("exact decay (half-life %.2f h at peak,\n%.2f h at 10%% of peak)",
                          mm_half_life(max(mm$tac), pars$vmax, pars$km),
                          mm_half_life(0.1 * max(mm$tac), pars$vmax, pars$km)),
                  "Km (saturation crossover)"),
       col = c("#404040", "grey55", "black", "grey40"),
       lty = c(1, NA, 2, 4), pch = c(NA, 1, NA, NA), lwd = c(1.6, NA, 1.4, 1))
box(bty = "l")

# (d) shape comparison. Each curve is divided by its own peak because the
# two models do not share a TAC unit (see the header).
plot(times, dlo$tac / max(dlo$tac), type = "n", ylim = c(0, 1.05),
     xlab = "Time (hours)", ylab = "TAC(t) / peak",
     main = "(d) Same input, same peak: different shape", bty = "n")
shade()
lines(times, dlo$tac / max(dlo$tac), col = "#404040", lwd = 1.8)
lines(times, mm$tac / max(mm$tac), col = "black", lwd = 1.6, lty = 2)
legend("topright", bty = "n", cex = 0.85,
       legend = c(sprintf("oscillator (peak %.2f)", max(dlo$tac)),
                  sprintf("Michaelis-Menten (peak %.2f)", max(mm$tac))),
       col = c("#404040", "black"), lty = c(1, 2), lwd = c(1.8, 1.6))
box(bty = "l")

# (e) the decay on a log scale, each aligned at its own peak. Straight
# means a constant half-life. This is the panel that separates the models.
peak_d <- which.max(dlo$tac)
peak_m <- which.max(mm$tac)
tail_d <- seq(peak_d, length(times))
tail_m <- seq(peak_m, length(times))
plot(NA, xlim = c(0, pars$duration - times[peak_m]), ylim = c(0.01, 1),
     log = "y", xlab = "Hours since peak", ylab = "TAC / peak",
     main = "(e) Decay shape: straight = constant half-life", bty = "n")
lines(times[tail_d] - times[peak_d], dlo$tac[tail_d] / dlo$tac[peak_d],
      col = "#404040", lwd = 1.8)
lines(times[tail_m] - times[peak_m], mm$tac[tail_m] / mm$tac[peak_m],
      col = "black", lwd = 1.6, lty = 2)
legend("bottomleft", bty = "n", cex = 0.85,
       legend = c("oscillator (log-linear)", "Michaelis-Menten (steepens)"),
       col = c("#404040", "black"), lty = c(1, 2), lwd = c(1.8, 1.6))
box(bty = "l")

# (f) dose scaling. The dashed reference is strict proportionality; the
# oscillator sits on it by construction, so the gap is the whole story.
# Both series set the limits -- Michaelis-Menten leaves the oscillator's
# range entirely, which is the finding, not an overflow to clip away.
rel_dlo <- sweep$dlo / sweep$dlo[sweep$mult == 1]
rel_mm  <- sweep$mm  / sweep$mm[sweep$mult == 1]
plot(NA, log = "xy", xlim = range(sweep$mult),
     ylim = range(c(rel_dlo, rel_mm)),
     xlab = "Dose multiplier", ylab = "AUC (relative to 1x)",
     main = "(f) Dose scaling: linear vs saturable", bty = "n")
lines(sweep$mult, sweep$mult, col = "grey65", lwd = 1, lty = 3)
lines(sweep$mult, rel_dlo, col = "#404040", lwd = 1.8)
points(sweep$mult, rel_dlo, pch = 16, cex = 0.7, col = "#404040")
lines(sweep$mult, rel_mm, col = "black", lwd = 1.6, lty = 2)
points(sweep$mult, rel_mm, pch = 1, cex = 0.7)
legend("topleft", bty = "n", cex = 0.85,
       legend = c(sprintf("oscillator (slope %.2f)", auc_slope(sweep$dlo)),
                  sprintf("Michaelis-Menten (slope %.2f)", auc_slope(sweep$mm)),
                  "strict proportionality"),
       col = c("#404040", "black", "grey65"), lty = c(1, 2, 3),
       pch = c(16, 1, NA), lwd = c(1.8, 1.6, 1))
box(bty = "l")

par(op)
invisible(dev.off())

# ---- Summary ----------------------------------------------------------

end <- length(times)
trap <- function(y) sum((y[-1] + y[-end]) / 2) * pars$dt

# Oscillator AUC against the identity that falls out of integrating its
# equation over [0, T] from rest:
#   k^2 * integral(TAC) = k^2 * eta * integral(I) - dTAC(T) - 2 zeta k TAC(T).
# The boundary terms are subtracted rather than assumed away -- the record
# ends while TAC is still coming down. A gap that survives the correction
# means the step is too coarse for tau.
dlo_area  <- trap(dlo$tac)
dlo_exact <- pars$eta * sum(events$dose) -
  (dlo$dtac[end] + 2 * pars$zeta * pars$k * dlo$tac[end]) / pars$k^2

# The matching Michaelis-Menten bookkeeping is just mass balance: what
# went in, minus what is still there, was eliminated.
mm_left <- mm$tac[end]
mm_gone <- sum(events$dose) - mm_left

# Hours from peak to 10% of peak, the crude "how long does the night last"
# number, computed the same way for both.
time_to_tenth <- function(tac) {
  p <- which.max(tac)
  below <- which(seq_along(tac) > p & tac < 0.1 * tac[p])
  if (length(below)) times[below[1]] - times[p] else NA_real_
}

cat(sprintf(
  paste0(
    "input (shared): %d drinks, %.2f total dose, over %.1f-%.1f h\n",
    "\n",
    "                              oscillator   Michaelis-Menten\n",
    "peak TAC                      %10.3f   %16.3f\n",
    "  (units differ -- see header; compare shapes, not levels)\n",
    "time of peak (h)              %10.2f   %16.2f\n",
    "peak to 10%% of peak (h)       %10.2f   %16.2f\n",
    "half-life at peak (h)         %10.2f   %16.2f\n",
    "half-life at 10%% of peak (h)  %10.2f   %16.2f\n",
    "AUC vs dose, log-log slope    %10.2f   %16.2f\n",
    "\n",
    "The oscillator's two half-lives are equal because they have to be:\n",
    "its decay is exponential, so the tail carries no information about\n",
    "how much was drunk. Michaelis-Menten's shrink as TAC falls, and its\n",
    "AUC slope above 1 is the disproportionate-exposure property that\n",
    "criterion 2 in the background section asks for.\n",
    "\n",
    "checks\n",
    "  oscillator AUC:   %.4f simulated vs %.4f exact (eta * dose,\n",
    "                    less the boundary terms at t = %.0f h)\n",
    "  oscillator tail:  max |simulated - closed form| = %.2e\n",
    "  MM mass balance:  %.4f in, %.4f eliminated, %.4f still present\n",
    "  MM tail:          max |simulated - closed form| = %.2e\n",
    "  sweep cleared:    %.2e (oscillator), %.2e (MM) left at %.0f h\n",
    "\n",
    "wrote %s\n"),
  nrow(events), sum(events$dose), pars$window[1], pars$window[2],
  max(dlo$tac), max(mm$tac),
  times[peak_d], times[peak_m],
  time_to_tenth(dlo$tac), time_to_tenth(mm$tac),
  log(2) / dlo_decay_rate(pars$k, pars$zeta),
  mm_half_life(max(mm$tac), pars$vmax, pars$km),
  log(2) / dlo_decay_rate(pars$k, pars$zeta),
  mm_half_life(0.1 * max(mm$tac), pars$vmax, pars$km),
  auc_slope(sweep$dlo), auc_slope(sweep$mm),
  dlo_area, dlo_exact, pars$duration,
  max(abs(dlo$tac[seq(at, end)] - dlo_decay[seq(at, end)])),
  sum(events$dose), mm_gone, mm_left,
  # The exact MM decay is a curve in (t, TAC); compare it to the simulation
  # by interpolating it onto the simulation's own times.
  {
    on_grid <- approx(mm_exact$time, mm_exact$tac,
                      xout = times[seq(at, end)], rule = 2)$y
    max(abs(mm$tac[seq(at, end)] - on_grid))
  },
  max(sweep$dlo_left), max(sweep$mm_left), sweep_duration,
  out_png
))
