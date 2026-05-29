# Data Cleaning Plan — Basic Data Cleaning Example

---

## Plan Metadata

- **Study spec:** `study_spec.md`
- **Audit report:** `reports/data_audit_report.md` (to be generated)
- **Date:** 2026-05-29
- **Analyst:** Claude Code

---

## 1. Source Files

| File | Path | Row count (from audit) | Description |
|---|---|---|---|
| households.csv | `data/raw/households.csv` | 200 | Synthetic household survey |

---

## 2. Target Outputs

| Output file | Path | Description |
|---|---|---|
| households_clean.csv | `data/processed/households_clean.csv` | Analysis-ready household dataset |

**Final analysis-ready dataset:** `data/processed/households_clean.csv`

---

## 3. Variable Cleaning Tasks

### 3.1 Variable Renaming

None required — variable names are already clean.

### 3.2 Type Conversions

| Variable | Current type | Target type | Notes |
|---|---|---|---|
| `hhid` | character/integer | character | Keep as string ID |
| `urban` | integer | factor/logical | 1 = urban, 0 = rural |
| `survey_year` | integer | integer | No change needed |

### 3.3 Date Parsing

No date variables in this dataset.

### 3.4 Missing Value Coding

| Variable | Current missing code | Standard missing code | Notes |
|---|---|---|---|
| `income_annual` | `-9` | `NA` | Recode -9 to NA; log count affected |
| `hhid` | empty string / blank | `NA` | Already blank in CSV; drop these rows (see §4) |

### 3.5 Duplicate Checks

| Level | ID variable | Expected duplicates | Action if found |
|---|---|---|---|
| Household | `hhid` | 0 | Stop and report |

### 3.6 ID Consistency Checks

No cross-file merge in this example — single file only.

### 3.7 Unit Harmonization

`income_annual` is already in consistent units (local currency). No conversion needed.

### 3.8 Winsorization / Outlier Flags

Flag households with `hh_size > 15` as `hh_size_flag = 1` but do NOT drop them or winsorize.
Document the count of flagged observations in the cleaning report.

### 3.9 Reshaping

Not applicable — data is already at the household level.

---

## 4. Sample Restrictions

| Filter | Condition | Expected obs dropped | Documented reason |
|---|---|---|---|
| Drop missing ID | `is.na(hhid)` | 8 | Cannot link records without valid household ID |
| Restrict to regions A, B, C | `region %in% c("A","B","C")` | 9 | Region D is out of scope per study_spec.md §5 |

**Total expected drops:** 17
**Expected final N:** 183

---

## 5. Merge Tasks

None — single source file.

---

## 6. Derived Variables

| Variable name | Formula | Source variables | Rationale |
|---|---|---|---|
| `hh_size_flag` | `hh_size > 15` → 1, else 0 | `hh_size` | Flag outlier household sizes for sensitivity check |
| `income_missing` | `is.na(income_annual)` → 1, else 0 | `income_annual` | Indicator for income missingness (after recoding -9 to NA) |

---

## 7. Final Dataset Specification

| Property | Value |
|---|---|
| File path | `data/processed/households_clean.csv` |
| Unit of observation | Household |
| Expected row count | 183 |
| Expected column count | 8 (original 6 + hh_size_flag + income_missing) |
| ID variable | `hhid` |

---

## 8. Open Questions Before Cleaning Starts

None.
