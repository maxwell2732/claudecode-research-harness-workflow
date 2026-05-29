# Study Specification — Econometrics Replication Example

---

## 1. Research Question

**Primary research question:**
Did the regional job-training program increase household annual income, and by how much?

**Secondary questions:**
- Are effects larger for urban households?
- Is the effect robust to excluding early-adopter regions?

---

## 2. Identification Strategy

**Design type:** Staggered difference-in-differences

**Identification assumption:**
In the absence of the job-training program, treated and control regions would have followed parallel income trends.

**Identification strength:** `[quasi-experimental: DiD]`

**Threats to identification:**
- Differential pre-trends by region: partially tested via pre-trend check (Task 1.2)
- Anticipation effects: assumed absent; not directly testable with this data
- Compositional changes in treated regions: unresolved — noted as limitation

---

## 3. Data

**Primary dataset:**
- Path: `data/raw/`
- File name(s): `panel_outcomes.csv`, `policy_timing.csv`
- Data dictionary: see §4 below
- Unit of observation: household × year
- Geographic coverage: 4 synthetic regions (A, B, C, D)
- Time coverage: 2018–2022 (5 years)
- Source: synthetically generated for demonstration

---

## 4. Variables

**Outcome variable(s):**

| Variable name | Description | Source file | Units |
|---|---|---|---|
| `income_annual` | Annual household income | `panel_outcomes.csv` | local currency units |

**Treatment / exposure variable(s):**

| Variable name | Description | Source file | Units | Variation used |
|---|---|---|---|---|
| `policy_active` | Job-training program active in region × year | `policy_timing.csv` | 0/1 | Region × year rollout |

**Control variables / covariates:**

| Variable name | Description | Rationale |
|---|---|---|
| `urban` | Urban/rural indicator | Controls for urban–rural income differential |
| `hh_size` | Household size | Controls for household composition |

**Derived variables (post-merge):**

| Variable name | Formula | Rationale |
|---|---|---|
| `treated` | `policy_active == 1` | Binary treatment indicator |
| `post` | `year >= treat_year` (where applicable) | Post-treatment period indicator |

---

## 5. Sample Restrictions

| Restriction | Rationale |
|---|---|
| Keep years 2018–2022 | Full panel; no restriction needed |
| Drop observations with missing `income_annual` | Outcome must be observed |

**Expected sample size (after restrictions):** approximately 580 household-year observations

---

## 6. Expected Outputs

| Output | Type | Script | Status |
|---|---|---|---|
| Table 1: Descriptive statistics | Table | `scripts/analysis_descriptive.R` | `cc:todo` |
| Figure 1: Pre-trend plot | Figure | `scripts/analysis_descriptive.R` | `cc:todo` |
| Table 2: Main DiD results | Table | `scripts/analysis_main_did.R` | `cc:todo` |
| Table 3: Robustness — no early adopters | Table | `scripts/analysis_robustness.R` | `cc:todo` |

---

## 7. Open Questions

| Question | Status |
|---|---|
| Whether to use region FE only or region + year FE | resolved: use two-way FE (region + year) |
| How to handle compositional changes | open — document as limitation |

---

## 8. Approvals

| Decision | Approved by | Date |
|---|---|---|
| Study specification v1 | Example (pre-approved) | 2026-05-29 |
