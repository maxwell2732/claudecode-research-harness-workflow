# Examples — Research Agent Harness

Each example demonstrates one or more stages of the research harness workflow using synthetic data. No real data is used. All examples are self-contained stubs: they show the expected file structure, script patterns, and report formats without requiring external data sources.

---

## Example Index

### 1. basic-data-cleaning

**Learning objective:** Run `/research-harness-audit` and `/research-harness-clean` on a single synthetic CSV file.

**Covers:**
- Variable inspection and missingness reporting
- Renaming and type conversion
- Missing-value recoding
- Observation filtering with documented drops
- Saving a cleaned dataset to `data/processed/`
- Producing `data_audit_report.md` and `data_cleaning_report.md`

**Does not cover:** merging, econometric models, review, release.

**Entry point:** `examples/basic-data-cleaning/README.md`

---

### 2. econometrics-replication

**Learning objective:** Run the full 7-stage workflow on a synthetic difference-in-differences dataset.

**Covers:**
- Study spec with a DiD identification strategy
- Two-file merge (panel outcomes + policy timing), with full merge report
- Descriptive statistics and pre-trend check
- Main DiD regression with fixed effects
- Robustness check (alternative control group)
- Review: identification assessment, numerical verification
- Replication package assembly

**Entry point:** `examples/econometrics-replication/README.md`

---

## How to use an example

```bash
# Copy the example folder to a working directory
cp -r examples/basic-data-cleaning /tmp/my-cleaning-test
cd /tmp/my-cleaning-test

# Start Claude Code and run the harness
claude
/research-harness-audit
/research-harness-clean
```

All paths in example scripts are relative to the example folder root.

---

## Synthetic data notice

All CSV files in these examples contain randomly generated data.
They are designed to illustrate data structures only — the numbers are not meaningful.
