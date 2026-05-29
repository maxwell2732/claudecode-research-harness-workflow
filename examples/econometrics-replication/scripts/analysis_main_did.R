# Study: Econometrics Replication Example — DiD
# Task: 2.1 — Main DiD regression (two-way FE)
# Identification: [quasi-experimental: DiD]
# Assumption: parallel trends in the absence of the job-training program
# Date: 2026-05-29
# Analyst: Claude Code

library(here)
library(fixest)   # for feols() with two-way fixed effects

# --- Open log ---
log_file <- here("analysis", "main", "logs", "main_did.log")
dir.create(here("analysis", "main", "logs"), showWarnings = FALSE, recursive = TRUE)
sink(log_file, append = FALSE, split = TRUE)

cat("=== Main DiD Regression Log ===\n")
cat("Task:            2.1 — Main DiD\n")
cat("Identification:  [quasi-experimental: DiD]\n")
cat("Assumption:      parallel trends\n")
cat("Estimator:       two-way FE (region + year), clustered SE by region\n")
cat("Started:        ", format(Sys.time()), "\n\n")

# --- Load analysis-ready data ---
data_path <- here("data", "processed", "panel_analysis.csv")
cat("Loading:", data_path, "\n")
df <- read.csv(data_path, stringsAsFactors = FALSE)
cat("Loaded:", nrow(df), "rows\n\n")

# --- Sample restriction for this task ---
n_before <- nrow(df)
df <- df[!is.na(df$treated) & !is.na(df$income_annual), ]
n_dropped <- n_before - nrow(df)
cat("Restriction — drop missing treated or income:\n")
cat("  Before:", n_before, "| Dropped:", n_dropped, "| After:", nrow(df), "\n\n")

cat("Estimation sample N:", nrow(df), "\n")
cat("Treated obs:        ", sum(df$treated), "\n")
cat("Control obs:        ", sum(!df$treated), "\n\n")

# --- Main DiD regression ---
cat("=== Model: income_annual ~ treated | region + year, cluster = region ===\n")
fit_main <- feols(income_annual ~ treated | region + year,
                  data    = df,
                  cluster = ~region)

cat("\n--- Main DiD results ---\n")
print(summary(fit_main))

# Extract and log key numbers
coef_treated <- coef(fit_main)["treated"]
se_treated   <- se(fit_main)["treated"]
pval_treated <- pvalue(fit_main)["treated"]
nobs_main    <- nobs(fit_main)

cat("\n=== Key results ===\n")
cat("N (estimation sample):      ", nobs_main, "\n")
cat("DiD coefficient (treated):  ", round(coef_treated, 2), "\n")
cat("Standard error:             ", round(se_treated, 2), "\n")
cat("p-value:                    ", round(pval_treated, 4), "\n\n")

# --- Save output table ---
dir.create(here("output", "tables"), showWarnings = FALSE, recursive = TRUE)
out_path <- here("output", "tables", "table2_main_did.csv")

results_df <- data.frame(
  term       = "treated",
  estimate   = round(coef_treated, 2),
  std_error  = round(se_treated, 2),
  p_value    = round(pval_treated, 4),
  n_obs      = nobs_main,
  fe         = "region + year",
  cluster    = "region"
)
write.csv(results_df, out_path, row.names = FALSE)
cat("Output saved:", out_path, "\n")

cat("\nFinished:", format(Sys.time()), "\n")
cat("Exit: 0 (success)\n")
sink()
