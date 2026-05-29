# Study: Econometrics Replication Example — DiD
# Task: data cleaning and merge — panel_outcomes + policy_timing
# Date: 2026-05-29
# Analyst: Claude Code
# Description: Merge household panel with policy timing file; apply sample restrictions.
# Cleaning plan: reports/data_cleaning_plan.md

library(here)

# --- Open log ---
log_file <- here("logs", paste0("clean_", format(Sys.Date(), "%Y%m%d"), ".log"))
dir.create(here("logs"), showWarnings = FALSE)
sink(log_file, append = FALSE, split = TRUE)

cat("=== Merge and Cleaning Log ===\n")
cat("Study:    Econometrics Replication Example\n")
cat("Task:     clean_merge\n")
cat("Started: ", format(Sys.time()), "\n\n")

# --- Load left file (panel outcomes) ---
panel_path <- here("data", "raw", "panel_outcomes.csv")
cat("Loading left file:", panel_path, "\n")
panel <- read.csv(panel_path, stringsAsFactors = FALSE)
cat("Left file rows:", nrow(panel), "\n\n")

# --- Load right file (policy timing) ---
policy_path <- here("data", "raw", "policy_timing.csv")
cat("Loading right file:", policy_path, "\n")
policy <- read.csv(policy_path, stringsAsFactors = FALSE)
cat("Right file rows:", nrow(policy), "\n\n")

# --- Merge diagnostics (pre-merge) ---
cat("=== Merge diagnostics ===\n")
cat("Merge type:  m:1\n")
cat("Merge keys:  region, year\n")
cat("Left keys unique?  ", !anyDuplicated(paste(panel$region, panel$year)), "\n")
cat("Right keys unique? ", !anyDuplicated(paste(policy$region, policy$year)), "\n")
cat("Left N:  ", nrow(panel), "\n")
cat("Right N: ", nrow(policy), "\n\n")

# --- Perform merge ---
merged <- merge(panel, policy, by = c("region", "year"), all.x = TRUE)

cat("Post-merge N:   ", nrow(merged), "\n")
n_matched    <- sum(!is.na(merged$policy_active))
n_unmatched  <- sum(is.na(merged$policy_active))
cat("Matched:        ", n_matched, "\n")
cat("Unmatched-left: ", n_unmatched, "\n")
cat("Match rate:     ", round(n_matched / nrow(merged) * 100, 1), "%\n\n")

if (n_unmatched > 0) {
  cat("WARNING: Unmatched left rows found — inspect before proceeding.\n")
  print(merged[is.na(merged$policy_active), c("hhid", "region", "year")])
}

# --- Sample restriction: drop missing income_annual ---
n_before <- nrow(merged)
merged <- merged[!is.na(merged$income_annual), ]
n_dropped_income <- n_before - nrow(merged)
cat("Restriction — drop missing income_annual:\n")
cat("  Before:", n_before, "| Dropped:", n_dropped_income, "| After:", nrow(merged), "\n\n")

# --- Derived variables ---
merged$treated <- as.integer(merged$policy_active == 1)
merged$post    <- as.integer(!is.na(merged$treat_year) & merged$year >= merged$treat_year)
cat("Derived: treated — N treated obs:", sum(merged$treated, na.rm = TRUE), "\n")
cat("Derived: post    — N post obs:   ", sum(merged$post, na.rm = TRUE), "\n\n")

# --- Final summary ---
cat("=== Final dataset ===\n")
cat("Rows:   ", nrow(merged), "\n")
cat("Columns:", ncol(merged), "\n")
cat("Regions:", paste(sort(unique(merged$region)), collapse = ", "), "\n")
cat("Years:  ", paste(sort(unique(merged$year)), collapse = ", "), "\n")

# --- Save output ---
dir.create(here("data", "processed"), showWarnings = FALSE, recursive = TRUE)
out_path <- here("data", "processed", "panel_analysis.csv")
write.csv(merged, out_path, row.names = FALSE)
cat("\nSaved:", out_path, "\n")

cat("\nFinished:", format(Sys.time()), "\n")
cat("Exit: 0 (success)\n")
sink()
