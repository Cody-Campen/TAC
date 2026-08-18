# clean_data.R
# The ONLY script in this project that reads the raw dataset. Reads its
# location from empirical/config/data_path.local.txt (gitignored, real
# path never tracked by git -- copy data_path.example.txt to create it),
# falling back to the dummy dataset at empirical/data/dummy_raw.csv if
# that file doesn't exist. Cleans the data and writes the result to
# empirical/data/processed/cleaned.rds (gitignored). Every downstream
# script reads only that processed file.
#
#   Rscript empirical/clean_data.R

data_path_cfg <- "empirical/config/data_path.local.txt"
if (file.exists(data_path_cfg)) {
  data_path <- trimws(readLines(data_path_cfg, n = 1))
} else {
  warning(
    "empirical/config/data_path.local.txt not found (copy it from ",
    "data_path.example.txt and set it to the real data's absolute path). ",
    "Falling back to empirical/data/dummy_raw.csv.",
    call. = FALSE
  )
  data_path <- "empirical/data/dummy_raw.csv"
}

clean_dataset <- function(raw) {
  raw$group <- trimws(raw$group)

  cleaned <- raw[!duplicated(raw$id), ]
  cleaned <- cleaned[!is.na(cleaned$x1) & cleaned$x1 > 0, ]  # drop sentinel/NA values
  cleaned <- cleaned[cleaned$group %in% c("control", "treatment"), ]
  cleaned$group <- factor(cleaned$group, levels = c("control", "treatment"))

  cleaned
}

raw <- read.csv(data_path, stringsAsFactors = FALSE)
cleaned <- clean_dataset(raw)

dir.create("empirical/data/processed", showWarnings = FALSE, recursive = TRUE)
saveRDS(cleaned, "empirical/data/processed/cleaned.rds")

message(sprintf("Cleaned %d rows -> %d rows.", nrow(raw), nrow(cleaned)))
