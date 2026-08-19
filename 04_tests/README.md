# Tests

    Rscript tests/run_tests.R                      # fast suite, seconds
    RUN_SLOW_TESTS=true Rscript tests/run_tests.R  # + the statistical tests

Run from the project root. Needs the `testthat` package
(`install.packages("testthat")`); everything else is already a dependency
of the analysis itself.

## Convention

One test file per source file, named after it, discovered automatically:

    empirical/functions/clean_data.R  ->  tests/testthat/test-clean_data.R

Each file opens with a one- or two-sentence comment saying what it covers,
then holds about three tests of varied kinds -- typically one numeric check
against a hand-derived value, one contract check on the shape passed between
stages, and one edge or failure case. A short comment above each test says
why it is worth running ("we expect RMSE to shrink as n grows, per the CLT"),
not what the code below it does.

Expected numbers are worked out by hand and written as literals, with the
algebra in a comment. Never compute the expectation with the same expression
the function under test uses -- that passes even when the formula is wrong.

## Helpers

`source_project()` takes a path relative to the project root and works
regardless of where the suite was started from; `project_path()` does the
same for data files. `make_params()`, `make_estimates()`, `make_raw()`,
`make_cleaned()`, `make_results()` and `make_analysis()` build test inputs --
every argument has a default, so name only the field the test is about.
Files matching `helper-*.R` are sourced before any test runs; put new
fixture builders there.

Two source files share a basename across the pipelines, so their test files
carry a suffix: `test-make_tables-sim.R` and `test-make_tables-empirical.R`.
For the same reason the functions themselves are named distinctly
(`make_sim_table()` vs `make_empirical_table()`) -- `source_project()` loads
into the global environment, where same-named functions would overwrite
each other between test files.

## What can be tested

Everything except the five entry points. `shared/*.R`, `simulation/get_*.R`,
`simulation/run_task.R`, `simulation/make_*.R`, `empirical/functions/*.R`
and `empirical/make_*.R` only define functions when sourced, so tests can
reach all of them.

The entry points -- `simulation/run_sim.R`, `simulation/main.R`,
`empirical/main.R` and the two `.sh` submit scripts -- read and write files
when run, so a test that sourced one would run the pipeline. They hold no
logic beyond wiring: each `main.R` is a named list of stage functions handed
to `run_stages()`. When you add logic worth testing, put it in a function
file and let the stage call it.

Statistical tests live in `test-slow-statistical.R` behind
`RUN_SLOW_TESTS=true`, with fixed seeds and loose tolerances -- a test that
fails one run in twenty trains you to ignore the suite.

Tests never touch the real dataset and never write into
`simulation/results/` or `empirical/data/processed/`. They build inputs
inline, read `empirical/data/dummy_raw.csv` (checked in, and deliberately
full of duplicate ids, `NA`s, `-999` sentinels and untrimmed labels), and
write only to `withr::local_tempdir()`.
