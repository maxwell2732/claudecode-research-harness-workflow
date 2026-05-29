# Study Specification — Basic Data Cleaning Example

> This is a pre-filled example spec. It is intentionally simple.
> The research question is trivial — the purpose is to demonstrate the cleaning workflow.

---

## 1. Research Question

**Primary research question:**
What is the distribution of household income and household size in the synthetic survey sample, and how does it vary by region?

**Secondary questions:**
None.

---

## 2. Identification Strategy

**Design type:** cross-sectional descriptive

**Identification strength:** `[descriptive]`

**Identification assumption:** None — this is descriptive analysis only.

---

## 3. Data

**Primary dataset:**
- Path: `data/raw/`
- File name: `households.csv`
- Data dictionary path: none (variables described below)
- Unit of observation: household
- Geographic coverage: 4 synthetic regions (A, B, C, D)
- Time coverage: single cross-section (survey year 2022)
- Source: synthetically generated for demonstration

---

## 4. Variables

**Outcome variable(s):**

| Variable name | Description | Source file | Units |
|---|---|---|---|
| `income_annual` | Annual household income | `households.csv` | local currency units; `-9` = missing |
| `hh_size` | Number of household members | `households.csv` | count |

**Treatment / exposure variable(s):** None (descriptive only).

**Control variables / covariates:**

| Variable name | Description | Rationale |
|---|---|---|
| `region` | Geographic region (A/B/C/D) | Stratification variable |
| `urban` | Urban/rural indicator (1/0) | Covariate for descriptive tables |

---

## 5. Sample Restrictions

| Restriction | Rationale |
|---|---|
| Drop observations with missing `hhid` | Cannot link records without a valid ID |
| Restrict to regions A, B, C (drop region D) | Region D is out of scope for this study |

**Expected sample size (after restrictions):** approximately 183 rows (from 200 raw)

---

## 6. Expected Outputs

| Output | Type | Script | Status |
|---|---|---|---|
| Table 1: Summary statistics by region | Table | `analysis/descriptive/scripts/table1.R` | `cc:todo` |

---

## 7. Open Questions

None for this example.

---

## 8. Approvals

| Decision | Approved by | Date |
|---|---|---|
| Study specification v1 | Example (pre-approved) | 2026-05-29 |
