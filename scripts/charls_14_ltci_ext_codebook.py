# CHARLS Research Harness — Extended LTCI Subsample Codebook
# Task: charls_14 — codebook for charls_ltci_ext_subsample.parquet
# Date: 2026-06-03
# Author: Claude Code

import sys
import pandas as pd
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _charls_utils import get_logger, PROC_DIR

VAR_META = {
    # ── IDs ──────────────────────────────────────────────────
    "ID":           {"role":"id",  "paper_def":"Individual ID (CHARLS respondent code)", "source":"Demographic_Background"},
    "HOUSEHOLDID":  {"role":"id",  "paper_def":"Household ID", "source":"Demographic_Background"},
    "COMMUNITYID":  {"role":"id",  "paper_def":"Community ID", "source":"Demographic_Background"},
    "WAVE":         {"role":"id",  "paper_def":"Survey wave year (2011/2013/2018/2020)", "source":"constructed"},

    # ── Employment outcomes (original) ────────────────────────
    "NON_AGRI_EMPLOY": {
        "role":"outcome", "paper_mean":0.462,
        "paper_def":"Non-agricultural employment =1. 2011/2013: FA002==1 OR FC014==1 OR FA003==1 OR FC015==1. 2018: FA002_W4==1 OR FA003==1. 2020: FA004==1 OR FA005==1.",
        "source":"Work_Retirement_and_Pension / Work_Retirement",
        "note":"2020 questionnaire changed employment routing; FA004 directly asks about nonfarm work. NON_AGRI_EMPLOY not directly comparable across all 4 waves.",
    },
    "AGRI_EMPLOY": {
        "role":"outcome", "paper_mean":0.075,
        "paper_def":"Agricultural (hired farm) employment =1. 2011/2013/2018: FC001==1. 2020: FA002_S2.notna() (farm-employed multi-select).",
        "source":"Work_Retirement",
        "note":"2020 uses FA002_S2 (Farm Employed) as proxy; FC001 in 2020 refers to nonfarm wage employment and is not used here.",
    },

    # ── Treatment ─────────────────────────────────────────────
    "TREAT":        {"role":"treatment", "paper_def":"=1 if community in one of 12 LTCI pilot cities.", "source":"PSU city name matching (2011/2013)"},
    "POST":         {"role":"treatment", "paper_def":"=1 if post-LTCI implementation. Qingdao: WAVE>=2013. Other cities: WAVE>=2018. 2020: POST=1 for all LTCI cities.", "source":"constructed"},
    "TREAT_X_POST": {"role":"treatment", "paper_def":"DiD interaction: TREAT × POST. Primary regressor.", "source":"constructed"},
    "IS_LTCI_CITY": {"role":"treatment", "paper_def":"Raw city treatment flag (before timing).", "source":"PSU"},
    "IS_QINGDAO":   {"role":"treatment", "paper_def":"=1 if Qingdao (early LTCI adopter, 2012).", "source":"PSU"},

    # ── Demographics ─────────────────────────────────────────
    "GENDER":   {"role":"control", "paper_mean":0.450, "paper_def":"Male=1, Female=0.", "source":"RGENDER (2011); XRGENDER (2018/2020); 2013 filled from 2011 baseline."},
    "AGE":      {"role":"control", "paper_mean":53.671,"paper_def":"Age at survey.", "source":"wave - birth_year. 2020: ZRBIRTHYEAR/BA003_1; 2018: BA004_W3_1; 2013: ZBA002_1; 2011: BA002_1."},
    "HUKOU":    {"role":"control", "paper_mean":0.290, "paper_def":"Urban (non-agricultural) hukou=1.", "source":"BC001/ZBC001 (2011/2013); filled from 2011 for 2018; BA009 (2020)."},
    "MARITAL":  {"role":"control", "paper_mean":0.074, "paper_def":"Non-married=1, Married (incl. living apart)=0.", "source":"BE001 (2011/2013/2018); BA011 (2020). Married=BE001 in {1,2}."},
    "EDUCATION":{"role":"control", "paper_mean":0.534, "paper_def":"Middle school and above=1. Threshold BD001/ZREDU>=5.", "source":"BD001 (2011); ZBD001 (2013); BD001_W2_4 (2018); ZREDU (2020).", "note":"Value 4=primary graduate; value 5=middle school start."},

    # ── Original health controls ──────────────────────────────
    "HEALTH_SELF":   {"role":"control", "paper_def":"Self-rated health 1(VeryPoor)–5(VeryGood). Recoded: 6–DA001 for 2011/2013/2020; DA002 for 2018.", "source":"Health_Status"},
    "N_CHRONIC":     {"role":"control", "paper_mean":0.838, "paper_def":"Number of chronic diseases. 2011-2018: sum DA007_N_==1 (14 diseases). 2020: count non-null DA003_N_ (15 slots).", "source":"Health_Status", "note":"2020 uses different coding: disease-slot counts vs. binary per-disease flags. Not directly comparable."},
    "HEALTH_INSURED":{"role":"control", "paper_mean":0.965,"paper_def":"Health insurance coverage=1. EA001S* (2011/2013) or EA001_W4_S* (2018). NaN for 2020 (module absent).", "source":"Health_Care_and_Insurance", "note":"NaN for all 2020 observations."},

    # ── Caregiving controls ───────────────────────────────────
    "CARE_GRANDCHILD":{"role":"control","paper_mean":0.490,"paper_def":"Cared for grandchildren past year=1 (CF001==1). NaN for 2020 (no Family_Transfer).", "source":"Family_Transfer/Family_Information"},
    "CARE_INTENSITY": {"role":"control","paper_def":"Hours of parent care per week: <10h=1, 10-20h=2, >=20h=3. NaN for 2020.", "source":"Family_Transfer: CF005_N vars"},
    "LN_HH_INCOME":   {"role":"control","paper_def":"Log household income (sum of member wages, ln). Partial proxy — excludes agri/transfer income.", "source":"Household_Income", "note":"High missing rate; wage sums only."},

    # ── Mechanism variables (original) ───────────────────────
    "LN_CARE_HRS":   {"role":"mechanism","paper_def":"Log annual hours of parent care (ln). NaN for 2020.", "source":"Family_Transfer: CF005_N × CF005_N weeks"},
    "CARE_HRS_WEEK": {"role":"mechanism","paper_def":"Total weekly hours of parent care.", "source":"Family_Transfer"},
    "SLEEP_HOURS":   {"role":"mechanism","paper_def":"Average nightly sleep hours. DA049 (2011/2013), DA049_W4 (2018), DA030 (2020).", "source":"Health_Status"},
    "SOCIAL_ACTIVITY":{"role":"mechanism","paper_def":"Any social activity participation past month=1. DA056S* (2011/2013), DA056_S* (2018), DA038_S* (2020).", "source":"Health_Status"},
    "N_PAIN_PARTS":  {"role":"mechanism","paper_def":"Number of body parts with pain (0–15 for 2011–2018; 0–16 for 2020).", "source":"Health_Status: DA042S* (2011/2013/2018); DA028_S* (2020)"},
    "DEPRESSION_CESD":{"role":"mechanism_outcome","paper_def":"CES-D 10 depression score (0–30). Higher=more depressed. Reverse-scored: DC013/DC016 (2011-2018); DC020/DC023 (2020). 2018: from Cognition.dta (previously missing in charls_11).", "source":"Health_Status DC009-DC018 (2011/2013); Cognition.dta DC009-DC018 (2018); Health_Status DC016-DC025 (2020)", "note":"2018 CES-D now available (was labelled missing in charls_11); minor instrument differences across waves."},

    # ═══════════════════════════════════════════════════════════
    #  NEW HEALTH / HUMAN-CAPITAL OUTCOME VARIABLES
    # ═══════════════════════════════════════════════════════════

    "N_ADL": {
        "role":"outcome_hc",
        "paper_def":"Number of basic ADL limitations (0–6). Each item: dressing, bathing, eating, bed transfer, toilet, continence. Item=1 if difficulty score>=2 (some/great difficulty or can't do).",
        "source":"Health_Status DB010-DB015 (2011/2013/2018); DB001,3,5,7,9,11 (2020)",
        "note":"Variable numbering differs between 2020 and earlier waves (2020 ADL section renumbered). All 6 items available across all 4 waves.",
    },
    "N_IADL": {
        "role":"outcome_hc",
        "paper_def":"Number of IADL limitations (0–5 for 2011/2013/2018; 0–6 for 2020). Items: household chores, meal prep, shopping, [phone calls — 2020 only], medications, money management.",
        "source":"Health_Status DB016-DB020 (2011/2013/2018); DB012,14,16,18,20,22 (2020)",
        "note":"2020 adds phone calls (DB018) as a 6th IADL item. When pooling waves, researchers may want to restrict to the common 5-item subset.",
    },
    "COGN_WORD_RECALL": {
        "role":"outcome_hc",
        "paper_def":"Immediate word recall score. 2011: DC006S1-10 (10-word list, 0-10). 2013: DC006_1_S1-10 (trial 1 of 10-word list, 0-10). 2018: DC013_W4_1_S1-3 (3-word list — Ball/Flag/Tree — 0-3). 2020: DC012_S1-10 (10-word list, 0-10).",
        "source":"Health_Status (2011/2013/2020); Cognition.dta (2018)",
        "note":"CRITICAL: 2018 uses a different 3-word instrument (max score=3) while other waves use 10-word lists (max=10). Do NOT pool 2018 raw scores with other waves without normalisation. Consider standardising within wave.",
    },
    "COGN_WORD_DELAYED": {
        "role":"outcome_hc",
        "paper_def":"Delayed word recall score. 2011/2013: DC027S1-10 (same 10-word list, 0-10). 2018: DC028_W4_S1-10 (10-word delayed list — Butter etc., 0-10). 2020: DC028_S1-10 (0-10).",
        "source":"Health_Status (2011/2013/2020); Cognition.dta (2018)",
        "note":"2018 delayed recall uses a DIFFERENT 10-word list (HRS-style) from the immediate recall (3-word list). It IS comparable in scale (0-10) to 2011/2013/2020 delayed recall but uses a different word set.",
    },
    "COGN_SERIAL7": {
        "role":"outcome_hc",
        "paper_def":"Serial-subtraction (100-7) score (0-5 correct steps). 2011/2013: DC019-DC023 coded as actual result (correct=93,86,79,72,65). 2020: DC007_1-5==1 (correct indicator). 2018: DC014_W4_1-5 absence-of-refusal proxy (NaN=gave answer; 97/98=DK/refused).",
        "source":"Health_Status (2011/2013/2020); Cognition.dta (2018)",
        "note":"2018 scoring uses absence of DK/refused as proxy for correct. May overcount; treat with caution. Always use wave fixed effects.",
    },
    "COGN_ORIENT": {
        "role":"outcome_hc",
        "paper_def":"Orientation score (0-5 items correct). Items: year, season, date, day-of-week, month. Each item correct=1. 2011/2013: DC001S1/S2/S3/DC002/DC003. 2018: DC001_W4/DC002_W4/DC003_W4/DC005_W4/DC006_W4. 2020: DC001-DC005.",
        "source":"Health_Status (2011/2013/2020); Cognition.dta (2018)",
        "note":"Orientation scoring is comparable across all 4 waves (same 5 items, same binary correct/wrong coding).",
    },

    # ── Flag ──────────────────────────────────────────────────
    "IS_CAREGIVER_RAW": {
        "role":"flag",
        "paper_def":"Caregiving screening flag. 2011/2013: CF004==1. 2018: any CF004_W4_N==1. 2020: =1 if respondent was ever a caregiver in 2011/2013/2018 ('ever-caregiver' imputation).",
        "source":"Family_Transfer (2011/2013/2018); imputed for 2020",
        "note":"2020 values are imputed — not measured. Include a wave==2020 dummy or wave FE when using 2020 data.",
    },
}


def main():
    log = get_logger("charls_14", "charls_14_ext_codebook.log")
    log.info("=== charls_14_ltci_ext_codebook.py START ===")

    in_path = PROC_DIR / "charls_ltci_ext_subsample.parquet"
    if not in_path.exists():
        log.error("Extended subsample not found: %s — run charls_13 first", in_path)
        sys.exit(1)

    df = pd.read_parquet(str(in_path))
    log.info("Loaded: %d rows × %d cols", len(df), len(df.columns))

    n_total = len(df)
    records = []

    for col in df.columns:
        meta   = VAR_META.get(col, {})
        series = df[col]
        dtype  = str(series.dtype)
        n_miss = int(series.isna().sum())
        n_obs  = n_total - n_miss
        pct_m  = round(100.0 * n_miss / n_total, 2) if n_total > 0 else 0.0
        n_uniq = int(series.nunique(dropna=True))

        col_min = col_max = col_mean = col_sd = ex_vals = ""
        if pd.api.types.is_numeric_dtype(series):
            nn = series.dropna()
            if len(nn):
                col_min  = str(round(float(nn.min()),  4))
                col_max  = str(round(float(nn.max()),  4))
                col_mean = str(round(float(nn.mean()), 4))
                col_sd   = str(round(float(nn.std()),  4))
        else:
            top = series.dropna().value_counts().head(5).index.tolist()
            ex_vals = "; ".join(str(v)[:40] for v in top)

        paper_mean = meta.get("paper_mean", "")
        mean_match = ""
        if paper_mean != "" and col_mean:
            diff = abs(float(col_mean) - float(paper_mean))
            mean_match = ("CLOSE" if diff < 0.02
                          else "MODERATE" if diff < 0.10
                          else "DIFFERS")

        # Per-wave means for new variables
        wave_means = {}
        if pd.api.types.is_numeric_dtype(series) and "WAVE" in df.columns:
            for w in sorted(df["WAVE"].dropna().unique()):
                wm = df.loc[df["WAVE"] == w, col].mean()
                wave_means[f"mean_w{int(w)}"] = round(wm, 3) if pd.notna(wm) else ""

        rec = {
            "variable_name":   col,
            "role":            meta.get("role", "unknown"),
            "paper_definition":meta.get("paper_def", ""),
            "source":          meta.get("source", ""),
            "notes":           meta.get("note", ""),
            "dtype":           dtype,
            "n_obs":           n_obs,
            "n_missing":       n_miss,
            "pct_missing":     pct_m,
            "n_unique":        n_uniq,
            "min":             col_min,
            "max":             col_max,
            "mean":            col_mean,
            "sd":              col_sd,
            "example_values":  ex_vals,
            "paper_mean":      str(paper_mean) if paper_mean != "" else "",
            "mean_match":      mean_match,
            **wave_means,
        }
        records.append(rec)
        log.info("  %-25s role=%-15s N=%d pct_miss=%.1f%% mean=%s (paper=%s) %s",
                 col, rec["role"], n_obs, pct_m,
                 col_mean or "N/A",
                 str(paper_mean) if paper_mean != "" else "N/A",
                 mean_match)

    cb = pd.DataFrame(records)
    out_path = PROC_DIR / "charls_ltci_ext_codebook.csv"
    cb.to_csv(str(out_path), index=False, encoding="utf-8-sig")
    log.info("Saved: %s  (%d variables)", out_path, len(cb))

    log.info("=== Match against paper Table 2 ===")
    for _, row in cb[cb["mean_match"] != ""].iterrows():
        log.info("  %-25s mean=%-7s paper=%-7s %s",
                 row["variable_name"], row["mean"], row["paper_mean"], row["mean_match"])

    log.info("=== New HC variable summary across waves ===")
    new_vars = ["N_ADL","N_IADL","COGN_WORD_RECALL","COGN_WORD_DELAYED",
                "COGN_SERIAL7","COGN_ORIENT","DEPRESSION_CESD"]
    for nv in new_vars:
        row = cb[cb["variable_name"] == nv]
        if row.empty:
            continue
        r = row.iloc[0]
        wave_str = "  ".join(
            f"W{w}={r.get(f'mean_w{w}','?')}"
            for w in [2011, 2013, 2018, 2020]
        )
        log.info("  %-25s overall_mean=%-6s  by wave: %s", nv, r["mean"], wave_str)

    log.info("=== charls_14_ltci_ext_codebook.py SUCCESS ===")


if __name__ == "__main__":
    main()
