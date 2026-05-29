# CHNS Research Harness — Task 04: merge household×wave modules (m:1) onto panel
# Date: 2026-05-29
# Author: Claude Code

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _chns_utils import (
    get_logger, RAW_ROOT, INTER_DIR,
    read_sas, do_merge,
)

import pandas as pd

LOG_FILE = "04_household_modules.log"
log = get_logger("hh_modules", LOG_FILE)

# (path_relative_to_RAW_ROOT, prefix, merge_keys, merge_type_note)
HOUSEHOLD_MODULES = [
    # Constructed household income
    ("Master_Constructed_Income_201804/Master_Constructed_Income_201804/hhinc_10.sas7bdat",
     "hhinc_", ["HHID", "WAVE"], "m:1"),
    # Assets
    ("Master_Asset_201804/Master_Asset_201804/asset_12.sas7bdat",
     "asset_", ["HHID", "WAVE"], "m:1"),
    # Childcare household
    ("Master_Childcare_201804/Master_Childcare_201804/careh_12.sas7bdat",
     "careh_", ["HHID", "WAVE"], "m:1"),
    # Household subsidies
    ("Master_Income_Categories_201804c1/Master_Income_Categories_201804/subh_12.sas7bdat",
     "subh_", ["HHID", "WAVE"], "m:1"),
    # Other income (household-level despite name)
    ("Master_Income_Categories_201804c1/Master_Income_Categories_201804/oinc_12.sas7bdat",
     "oinc_", ["HHID", "WAVE"], "m:1"),
    # Medical service usage (household×wave, no IDIND)
    ("Master_Media_201410/medsv_00.sas7bdat",
     "medsv_", ["HHID", "WAVE"], "m:1"),
    # Agriculture household files
    ("Master_Agriculture_201804/Master_Agriculture_201804/farmh_12.sas7bdat",
     "farmh_", ["HHID", "WAVE"], "m:1"),
    ("Master_Agriculture_201804/Master_Agriculture_201804/gardh_12.sas7bdat",
     "gardh_", ["HHID", "WAVE"], "m:1"),
    ("Master_Agriculture_201804/Master_Agriculture_201804/fishh_12.sas7bdat",
     "fishh_", ["HHID", "WAVE"], "m:1"),
    # Urban index — keyed by COMMID×WAVE (merge m:1 via COMMID + WAVE)
    ("Master_UrbanIndex_201804/Master_UrbanIndex_201804/urban_11.sas7bdat",
     "urban_", ["COMMID", "WAVE"], "m:1"),
]


def main():
    log.info("START merge household modules")

    in_path = INTER_DIR / "panel_individual.parquet"
    if not in_path.exists():
        log.error("panel_individual.parquet not found — run 03_individual_modules.py first")
        sys.exit(1)

    panel = pd.read_parquet(in_path)
    log.info("Loaded panel: %d rows × %d cols", len(panel), len(panel.columns))
    base_rows = len(panel)

    for rel_path, prefix, keys, mtype in HOUSEHOLD_MODULES:
        fp = RAW_ROOT / rel_path
        if not fp.exists():
            log.warning("SKIP (not found): %s", rel_path)
            continue

        try:
            mod, _ = read_sas(fp, prefix=prefix, log=log)
        except Exception as exc:
            log.error("READ FAILED %s: %s", fp.name, exc)
            continue

        # Guard: skip if any merge key is missing
        missing_keys = [k for k in keys if k not in mod.columns]
        if missing_keys:
            log.warning("SKIP %s — merge key(s) missing: %s", fp.name, missing_keys)
            continue

        # Drop cols already in panel (except keys)
        existing = [c for c in mod.columns if c in panel.columns and c not in keys]
        if existing:
            log.info("  Dropping already-present cols from %s: %s", fp.name, existing[:10])
            mod = mod.drop(columns=existing)

        # For m:1 merges: deduplicate right table on keys
        dups = mod.duplicated(subset=keys).sum()
        if dups > 0:
            log.warning("  %s has %d duplicate keys — keeping first", fp.name, dups)
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
                "Row count changed after merging %s: expected %d got %d — check for duplicate keys in right table",
                fp.name, base_rows, len(panel),
            )
            sys.exit(1)

    out_path = INTER_DIR / "panel_with_household.parquet"
    panel.to_parquet(out_path, index=False)
    log.info("Saved: %d rows × %d cols → %s", len(panel), len(panel.columns), out_path.name)
    log.info("SUCCESS")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        log.exception("FATAL: %s", exc)
        sys.exit(1)
