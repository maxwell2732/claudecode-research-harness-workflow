# Data Cleaning Plan

> Fill this template before running `/research-harness-clean`.
> The Analyst reads this file to generate and run cleaning scripts.
> Every cleaning decision listed here must appear in the cleaning report after the scripts run.

---

## Plan Metadata

- **Study spec:** `study_spec.md`
- **Audit report:** `reports/data_audit_report.md`
- **Date:** YYYY-MM-DD
- **Analyst:** Claude Code

---

## 1. Source Files

All source files must be in `data/raw/`. List every file this cleaning task reads.

| File | Path | Row count (from audit) | Description |
|---|---|---|---|
| | `data/raw/` | | |

---

## 2. Target Outputs

All output files must go to `data/processed/` or `data/intermediate/`. No output may overwrite `data/raw/`.

| Output file | Path | Description | Replaces |
|---|---|---|---|
| | `data/processed/` | | |

**Final analysis-ready dataset:** `data/processed/analysis_ready.csv` (or specify)

---

## 3. Variable Cleaning Tasks

### 3.1 Variable Renaming

| Original name | New name | Source file | Reason |
|---|---|---|---|
| | | | |

### 3.2 Type Conversions

| Variable | Current type | Target type | Notes |
|---|---|---|---|
| | | | |

### 3.3 Date Parsing

| Variable | Raw format | Target format | Example |
|---|---|---|---|
| | | ISO 8601 (YYYY-MM-DD) | |

### 3.4 Missing Value Coding

| Variable | Current missing code | Standard missing code | Notes |
|---|---|---|---|
| | e.g., -9, 99, "N/A" | `NA` / `.` | |

### 3.5 Duplicate Checks

| Level | ID variable(s) | Expected duplicates | Action if found |
|---|---|---|---|
| | | | drop first / drop last / keep all and flag / stop |

### 3.6 ID Consistency Checks

| Files to compare | Shared ID variable | Expected match rate | Action if mismatch |
|---|---|---|---|
| | | | |

### 3.7 Unit Harmonization

| Variable | Current units | Target units | Conversion factor |
|---|---|---|---|
| | | | |

### 3.8 Winsorization / Outlier Flags (only if explicitly requested in study spec)

| Variable | Lower percentile | Upper percentile | Action: winsorize / flag only |
|---|---|---|---|
| | | | |

### 3.9 Reshaping

| File | Current shape | Target shape | ID variable | Time variable |
|---|---|---|---|---|
| | wide / long | wide / long | | |

---

## 4. Sample Restrictions

List every filter that drops observations. Filters applied here must match `study_spec.md` §5 exactly.

| Filter | Condition | Expected obs dropped | Documented reason |
|---|---|---|---|
| | | | |

**Required: every dropped observation must be counted and logged.**

---

## 5. Merge Tasks

Complete one row per merge operation, in execution order.

| Step | Left file | Right file | Merge type | Merge keys | Expected match rate | Action if unmatched |
|---|---|---|---|---|---|---|
| 1 | | | `1:1` / `m:1` / `1:m` / `m:m` | | | keep / drop / flag |

**If merge keys are ambiguous or unknown:** stop — do not guess. Document the issue and ask for clarification.

---

## 6. Derived Variables

| Variable name | Formula / definition | Source variables | Rationale |
|---|---|---|---|
| | | | |

---

## 7. Final Dataset Specification

| Property | Value |
|---|---|
| File path | `data/processed/` |
| Unit of observation | |
| Expected row count | |
| Expected column count | |
| ID variable | |
| Time variable (if panel) | |

---

## 8. Open Questions Before Cleaning Starts

List anything unresolved that would block or change the cleaning plan.

| Question | Severity | Status |
|---|---|---|
| | `blocking` / `non-blocking` | open / resolved |
