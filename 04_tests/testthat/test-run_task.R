# test-run_task.R -- simulation/run_task.R
# Checks one cluster task writes the file collect_answers() expects, and that
# a rerun is safe. Everything here writes to a temporary directory.

source_project("simulation/get_dataset.R")
source_project("simulation/get_estimates.R")
source_project("simulation/run_task.R")

# collect_answers() reads results/raw/ with list.files() and groups by the
# condition columns, so both the zero-padded name and the tags matter.
test_that("run_task() writes one padded, tagged file per task", {
  out_dir <- withr::local_tempdir()

  path <- run_task(make_params(n = 20, b1 = 0.3, seed = 42, task_id = 7),
                   out_dir = out_dir)

  expect_equal(list.files(out_dir), "task_00007.rds")
  expect_equal(path, task_file(out_dir, 7))

  result <- readRDS(path)
  expect_equal(nrow(result), 1)
  expect_equal(result$seed, 42)
  expect_equal(result$n, 20)
  expect_equal(result$b1, 0.3)
  expect_true(all(c("estimate", "std.error", "conf.low", "conf.high", "converged")
                  %in% names(result)))
})

# The resubmission story rests on this: sbatch --array=<id> on a failed
# task must not redo the ones that already succeeded.
test_that("run_task() leaves an already-finished task alone", {
  out_dir <- withr::local_tempdir()
  saveRDS("existing result", task_file(out_dir, 3))

  run_task(make_params(n = 20, task_id = 3), out_dir = out_dir)

  expect_equal(readRDS(task_file(out_dir, 3)), "existing result")
})

# Seeding happens inside run_task(), so a rerun in a fresh directory has to
# reproduce the replication exactly -- that is what makes the study rerunnable.
test_that("the same task run twice produces the same result", {
  params <- make_params(n = 20, seed = 123, task_id = 1)
  first_dir  <- withr::local_tempdir()
  second_dir <- withr::local_tempdir()

  run_task(params, out_dir = first_dir)
  run_task(params, out_dir = second_dir)

  expect_equal(readRDS(task_file(first_dir, 1)),
               readRDS(task_file(second_dir, 1)))
})
