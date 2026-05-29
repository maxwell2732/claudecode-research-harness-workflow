# Study Specification

> This file is the research contract. It defines what is being studied, with what data, and how.
> Changes to any field below require human approval before any analysis script is run.
> Populate this file during `/research-harness-setup`. Leave fields as `unknown` if not yet determined.

---

## 1. Research Question

**Primary research question:**
<!-- State the main empirical question in one or two sentences. -->
unknown

**Secondary questions (if any):**
unknown

---

## 2. Identification Strategy

**Design type:**
<!-- Choose one: cross-sectional, panel, DiD, IV, RD, experimental (RCT), synthetic control, event study, other -->
unknown

**Identification assumption:**
<!-- State the key assumption in plain language. E.g., "parallel trends in the absence of treatment" for DiD. -->
unknown

**Identification strength:**
<!-- Choose one: [descriptive] / [correlational] / [quasi-experimental: specify] / [experimental] -->
unknown

**Threats to identification:**
<!-- List the main threats and whether they are addressed, partially addressed, or unresolved. -->
unknown

---

## 3. Data

**Primary dataset:**
- Path: `data/raw/`
- File name(s): unknown
- Data dictionary path: unknown
- Unit of observation: unknown
- Geographic coverage: unknown
- Time coverage: unknown
- Source: unknown

**Secondary datasets (if any):**
- unknown

---

## 4. Variables

**Outcome variable(s):**
| Variable name | Description | Source file | Units |
|---|---|---|---|
| unknown | | | |

**Treatment / exposure variable(s):**
| Variable name | Description | Source file | Units | Variation used |
|---|---|---|---|---|
| unknown | | | | |

**Control variables / covariates:**
| Variable name | Description | Rationale |
|---|---|---|
| unknown | | |

**Instrumental variables (if any):**
| Variable name | Description | Exclusion restriction justification |
|---|---|---|
| unknown | | |

---

## 5. Sample Restrictions

List all inclusion/exclusion criteria applied to the estimation sample. Changes to this list require human approval.

| Restriction | Rationale |
|---|---|
| unknown | |

**Expected sample size (after restrictions):** unknown

---

## 6. Expected Outputs

List all tables and figures that the final paper or report requires.

| Output | Type | Script | Status |
|---|---|---|---|
| Table 1: Descriptive statistics | Table | `analysis/descriptive/scripts/table1.R` | `cc:todo` |
| Table 2: Main regression results | Table | unknown | `cc:todo` |
| Figure 1: unknown | Figure | unknown | `cc:todo` |

---

## 7. Open Questions and Unresolved Issues

List anything not yet determined. Mark resolved items with the date resolved.

| Question | Status | Date resolved |
|---|---|---|
| unknown | open | |

---

## 8. Approvals

| Decision | Approved by | Date |
|---|---|---|
| Study specification v1 | | |
| Sample restriction changes | | |
| Estimator or outcome changes | | |
