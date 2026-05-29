# CHNS Research Harness — Task 03: merge individual×wave modules onto spine
# Date: 2026-05-29
# Author: Claude Code

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _chns_utils import (
    get_logger, RAW_ROOT, INTER_DIR,
    read_sas, read_dta, do_merge,
)

import pandas as pd

LOG_FILE = "03_individual_modules.log"
log = get_logger("ind_modules", LOG_FILE)

# (path_relative_to_RAW_ROOT, prefix, merge_keys, merge_type_note)
INDIVIDUAL_MODULES = [
    # Physical exam & activity
    ("Master_PE_PA_201908/Master_PE_PA_201908/pexam_pub_12.sas7bdat",  "pe_",    ["IDIND", "WAVE"], "1:1"),
    ("Master_PE_PA_201908/Master_PE_PA_201908/pact_12.sas7bdat",       "pa_",    ["IDIND", "WAVE"], "1:1"),
    ("Master_PE_PA_201908/Master_PE_PA_201908/pstress_12.sas7bdat",    "ps_",    ["IDIND", "WAVE"], "1:1"),
    # Education
    ("Master_Educ_201804/Master_Educ_201804/educ_12.sas7bdat",         "educ_",  ["IDIND", "WAVE"], "1:1"),
    # Healthcare
    ("Master_HealthCare_201804/Master_HealthCare_201804/hlth_12.sas7bdat", "hlth_", ["IDIND", "WAVE"], "1:1"),
    ("Master_HealthCare_201804/Master_HealthCare_201804/ins_12.sas7bdat",  "ins_",  ["IDIND", "WAVE"], "1:1"),
    # Constructed income (individual)
    ("Master_Constructed_Income_201804/Master_Constructed_Income_201804/indinc_10.sas7bdat", "inc_", ["IDIND", "WAVE"], "1:1"),
    # Income categories (individual)
    ("Master_Income_Categories_201804c1/Master_Income_Categories_201804/wages_12.sas7bdat", "wage_", ["IDIND", "WAVE"], "1:1"),
    ("Master_Income_Categories_201804c1/Master_Income_Categories_201804/jobs_13.sas7bdat",  "job_",  ["IDIND", "WAVE"], "1:1"),
    # oinc_12 is household-level (no IDIND) — handled in 04_household_modules.py
    ("Master_Income_Categories_201804c1/Master_Income_Categories_201804/subi_12.sas7bdat",  "subi_", ["IDIND", "WAVE"], "1:1"),
    # Time use
    ("Master_TimeUse_201804/Master_TimeUse_201804/timea_12.sas7bdat",   "time_",  ["IDIND", "WAVE"], "1:1"),
    # Media
    ("Master_Media_201410/media_00.sas7bdat",    "media_", ["IDIND", "WAVE"], "1:1"),
    ("Master_Media_201410/medsv_00.sas7bdat",    "medsv_", ["IDIND", "WAVE"], "1:1"),
    # Caltrac energy
    ("Master_Caltrac_201410/en_00.sas7bdat",     "cal_",   ["IDIND", "WAVE"], "1:1"),
    # Macronutrients (already individual×wave)
    ("Master_Macronutrients_201410/c12diet.sas7bdat", "diet_", ["IDIND", "WAVE"], "1:1"),
    # Ever-married women questionnaire
    ("Master_EverMarriedWomen_201804/Master_EverMarriedWomen_201804/emw_12.sas7bdat", "emw_", ["IDIND", "WAVE"], "1:1"),
    # Relationship master (IDIND only — no WAVE)
    ("Master_Relationship_201410/relationmast_pub_00.sas7bdat", "rel_", ["IDIND"], "1:1"),
]


def main():
    log.info("START merge individual modules")

    spine_path = INTER_DIR / "spine.parquet"
    if not spine_path.exists():
        log.error("spine.parquet not found — run 02_spine.py first")
        sys.exit(1)

    panel = pd.read_parquet(spine_path)
    log.info("Loaded spine: %d rows × %d cols", len(panel), len(panel.columns))
    base_rows = len(panel)

    for rel_path, prefix, keys, mtype in INDIVIDUAL_MODULES:
        fp = RAW_ROOT / rel_path
        if not fp.exists():
            log.warning("SKIP (not found): %s", rel_path)
            continue

        try:
            if fp.suffix.lower() == ".dta":
                mod, _ = read_dta(fp, prefix=prefix, log=log)
            else:
                mod, _ = read_sas(fp, prefix=prefix, log=log)
        except Exception as exc:
            log.error("READ FAILED %s: %s", fp.name, exc)
            continue

        # Guard: skip if any merge key is missing from this module
        missing_keys = [k for k in keys if k not in mod.columns]
        if missing_keys:
            log.warning("SKIP %s — merge key(s) missing: %s", fp.name, missing_keys)
            continue

        # Drop columns already in panel (except keys)
        existing = [c for c in mod.columns if c in panel.columns and c not in keys]
        if existing:
            log.info("  Dropping already-present cols from %s: %s", fp.name, existing[:10])
            mod = mod.drop(columns=existing)

        # Deduplicate right table on keys before merge (keep first)
        dups = mod.duplicated(subset=keys).sum()
        if dups > 0:
            log.warning("  %s has %d duplicate keys — keeping first occurrence", fp.name, dups)
            mod = mod.drop_duplicates(subset=keys, keep="first")

        step_name = f"{fp.stem} ({' × '.join(keys)})"
        panel = do_merge(
            left=panel,
            right=mod,
            keys=keys,
            how="left",
            step=step_name,
            merge_type=mtype,
            log=log,
        )

        if len(panel) != base_rows:
            log.error(
                "Row count changed after merging %s: expected %d got %d",
                fp.name, base_rows, len(panel),
            )
            sys.exit(1)

    out_path = INTER_DIR / "panel_individual.parquet"
    panel.to_parquet(out_path, index=False)
    log.info("Saved: %d rows × %d cols → %s", len(panel), len(panel.columns), out_path.name)
    log.info("SUCCESS")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        log.exception("FATAL: %s", exc)
        sys.exit(1)
