# Example: Econometrics Replication (DiD)

This example walks through all 7 stages of the Research Agent Harness using a synthetic difference-in-differences dataset. The study examines whether a regional job-training program increased household income.

All data is synthetic. The numbers are not meaningful.

---

## Research Design

- **Design:** Staggered difference-in-differences
- **Treatment:** Regional job-training program rollout (varies by region and year)
- **Outcome:** Household annual income
- **Identification:** `[quasi-experimental: DiD]` — parallel trends assumption
- **Data:** Two files requiring a merge (panel outcomes + policy timing)

---

## What this example demonstrates

| Stage | Command | Demonstrates |
|---|---|---|
| 1 | `/research-harness-setup` | Creating spec and folder structure |
| 2 | `/research-harness-audit` | Auditing two files, identifying merge keys |
| 3 | `/research-harness-clean` | Merging panel + policy files, full merge report |
| 4 | `/research-harness-plan` | Generating analysis plan with DiD tasks |
| 5 | `/research-harness-work 1.1` | Descriptive statistics table |
| 5 | `/research-harness-work 2.1` | Main DiD regression |
| 5 | `/research-harness-work 3.1` | Robustness: alternative specification |
| 6 | `/research-harness-review` | Identification review + numerical verification |
| 7 | `/research-harness-release` | Replication package assembly |

---

## File structure

```
econometrics-replication/
├── README.md                                     ← you are here
├── study_spec.md                                 ← pre-filled DiD study spec
├── data/
│   └── raw/
│       ├── panel_outcomes.csv                    ← synthetic panel (household × year)
│       └── policy_timing.csv                     ← treatment roll-out by region × year
├── reports/
│   └── data_cleaning_plan.md                     ← pre-filled merge plan
└── scripts/
    ├── clean_merge.R                             ← merge stub
    ├── analysis_descriptive.R                   ← descriptive stats stub
    ├── analysis_main_did.R                      ← DiD regression stub
    └── analysis_robustness.R                    ← robustness stub
```

After running the full workflow, these will be created:

```
├── data/processed/panel_analysis.csv
├── logs/
├── output/tables/
├── output/figures/
└── reports/
    ├── data_audit_report.md
    ├── data_cleaning_report.md
    ├── merge_report.md
    ├── review_report.md
    └── reproducibility_report.md
```

---

## Quickstart

```bash
/research-harness-setup
/research-harness-audit
/research-harness-clean
/research-harness-plan
/research-harness-work 1.1
/research-harness-work 2.1
/research-harness-work 3.1
/research-harness-review
/research-harness-release
```

---

## What to notice about the merge

- `panel_outcomes.csv` has one row per household × year (hhid, year, income_annual, region)
- `policy_timing.csv` has one row per region × year with a treatment indicator
- The merge is `m:1`: many household-year observations per region-year treatment value
- The merge report will show: 600 rows in panel × 20 rows in policy → 600 rows post-merge, 100% match rate
- After merge, derive `treated = (policy_active == 1)` and `post = (year >= treat_year)`

---

## What to notice about the DiD review

- The review will check that the identification tag `[quasi-experimental: DiD]` appears in the script header
- The review will check that a pre-trend test task exists in `analysis_plan.md`
- The review will verify that all coefficients in the output table appear in the log file
- Any claim of "causal effect" without the DiD tag will be flagged as a major finding
