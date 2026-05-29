# Study: Basic Data Cleaning Example
# Task: data cleaning — households.csv
# Date: 2026-05-29
# Analyst: Claude Code
# Description: Recode missing values, apply sample restrictions, generate derived variables.
# Cleaning plan: reports/data_cleaning_plan.md

library(here)

# --- Open log ---
log_file <- here("logs", paste0("clean_", format(Sys.Date(), "%Y%m%d"), ".log"))
dir.create(here("logs"), showWarnings = FALSE)
sink(log_file, append = FALSE, split = TRUE)

cat("=== Data Cleaning Log ===\n")
cat("Study:    Basic Data Cleaning Example\n")
cat("Task:     clean_households\n")
cat("Started: ", format(Sys.time()), "\n\n")

# --- Load raw data ---
raw_path <- here("data", "raw", "households.csv")
cat("Loading:", raw_path, "\n")
df <- read.csv(raw_path, stringsAsFactors = FALSE)
cat("Loaded:", nrow(df), "rows,", ncol(df), "columns\n\n")

# --- Recode missing values ---
# income_annual: -9 is the legacy missing code
n_income_neg9 <- sum(df$income_annual == -9, na.rm = TRUE)
df$income_annual[df$income_annual == -9] <- NA
cat("Recoded income_annual: -9 -> NA for", n_income_neg9, "observations\n")

# hhid: blank/empty string -> NA
n_hhid_blank <- sum(is.na(df$hhid) | df$hhid == "", na.rm = TRUE)
df$hhid[df$hhid == ""] <- NA
cat("Found", n_hhid_blank, "observations with missing hhid\n\n")

# --- Sample restriction 1: Drop missing hhid ---
n_before <- nrow(df)
df <- df[!is.na(df$hhid), ]
n_dropped_id <- n_before - nrow(df)
cat("Restriction 1 — Drop missing hhid:\n")
cat("  Before:", n_before, "| Dropped:", n_dropped_id, "| After:", nrow(df), "\n\n")

# --- Sample restriction 2: Keep regions A, B, C only ---
n_before <- nrow(df)
df <- df[df$region %in% c("A", "B", "C"), ]
n_dropped_region <- n_before - nrow(df)
cat("Restriction 2 — Keep regions A, B, C (drop D):\n")
cat("  Before:", n_before, "| Dropped:", n_dropped_region, "| After:", nrow(df), "\n\n")

# --- Derived variable: hh_size_flag ---
df$hh_size_flag <- as.integer(df$hh_size > 15)
n_flagged <- sum(df$hh_size_flag)
cat("Derived variable hh_size_flag (hh_size > 15):", n_flagged, "households flagged\n")

# --- Derived variable: income_missing ---
df$income_missing <- as.integer(is.na(df$income_annual))
n_income_missing <- sum(df$income_missing)
cat("Derived variable income_missing:", n_income_missing, "observations with missing income\n\n")

# --- Final checks ---
cat("=== Final dataset summary ===\n")
cat("Rows:   ", nrow(df), "\n")
cat("Columns:", ncol(df), "\n")
cat("Regions:", paste(sort(unique(df$region)), collapse = ", "), "\n")
cat("Income missing:", sum(is.na(df$income_annual)), "\n")
cat("HH size flagged:", sum(df$hh_size_flag), "\n\n")

if (anyDuplicated(df$hhid)) {
  cat("ERROR: Duplicate hhid values found — cleaning failed.\n")
  sink()
  quit(status = 1)
}
cat("ID check: no duplicate hhid values — PASS\n\n")

# --- Save output ---
dir.create(here("data", "processed"), showWarnings = FALSE, recursive = TRUE)
out_path <- here("data", "processed", "households_clean.csv")
write.csv(df, out_path, row.names = FALSE)
cat("Saved:", out_path, "\n")

cat("\nFinished:", format(Sys.time()), "\n")
cat("Exit: 0 (success)\n")
sink()
