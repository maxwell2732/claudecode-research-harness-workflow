# Example: Basic Data Cleaning

This example walks through the audit and cleaning stages of the Research Agent Harness using a single synthetic household survey CSV.

---

## What this example demonstrates

| Stage | Command | Output |
|---|---|---|
| Setup | `/research-harness-setup` | `study_spec.md`, folder structure |
| Audit | `/research-harness-audit` | `reports/data_audit_report.md` |
| Clean | `/research-harness-clean` | `data/processed/households_clean.csv`, `reports/data_cleaning_report.md` |

---

## File structure

```
basic-data-cleaning/
├── README.md                               ← you are here
├── study_spec.md                           ← pre-filled for this example
├── data/
│   └── raw/
│       └── households.csv                  ← synthetic data (200 rows)
├── reports/
│   └── data_cleaning_plan.md               ← pre-filled cleaning plan
└── scripts/
    └── clean_households.R                  ← stub cleaning script
```

After running the harness commands, these will be created:

```
├── data/processed/households_clean.csv
├── logs/audit_YYYYMMDD.log
├── logs/clean_YYYYMMDD.log
└── reports/
    ├── data_audit_report.md
    └── data_cleaning_report.md
```

---

## Quickstart

```bash
/research-harness-audit
# Review reports/data_audit_report.md
# Then:
/research-harness-clean
```

---

## What to notice

- The audit report will flag `income_annual` for using `-9` as a missing code
- The audit report will flag `hh_size` for 3 outlier values (> 15)
- The cleaning script drops 8 observations with missing `hhid`
- The cleaning script recodes `-9` to `NA` across income variables
- The final `households_clean.csv` has 183 rows (200 − 8 missing ID − 9 out-of-scope region)
- Every dropped observation is documented with reason and count
