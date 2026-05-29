# CHNS Research Harness — Task 06: merge aggregated sub-tables onto panel
# Date: 2026-05-29
# Author: Claude Code

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _chns_utils import get_logger, INTER_DIR, do_merge

import pandas as pd

LOG_FILE = "06_merge_aggregates.log"
log = get_logger("merge_agg", LOG_FILE)

# (agg_parquet_name, merge_keys, merge_type, note)
AGG_MERGES = [
    # HHID×WAVE aggregates
    ("agg_nutrition.parquet",  ["HHID", "WAVE"], "m:1", "nutrition totals per household×wave"),
    ("agg_cropt.parquet",      ["HHID", "WAVE"], "m:1", "crop totals per household×wave"),
    ("agg_farmg.parquet",      ["HHID", "WAVE"], "m:1", "farmland totals per household×wave"),
    ("agg_fishi.parquet",      ["HHID", "WAVE"], "m:1", "fish totals per household×wave"),
    ("agg_foods.parquet",      ["HHID", "WAVE"], "m:1", "food store totals per household×wave"),
    ("agg_carec.parquet",      ["HHID", "WAVE"], "m:1", "childcare count per household×wave"),
    ("agg_busn.parquet",       ["HHID", "WAVE"], "m:1", "household business totals per household×wave"),
    ("agg_subf.parquet",       ["HHID", "WAVE"], "m:1", "food subsidy totals per household×wave"),
    # IDIND×WAVE aggregates
    ("agg_busi.parquet",       ["IDIND", "WAVE"], "1:1", "individual business income per person×wave"),
    ("agg_birth.parquet",      ["IDIND", "WAVE"], "1:1", "birth count per person×wave"),
    ("agg_preg.parquet",       ["IDIND", "WAVE"], "1:1", "pregnancy count per person×wave"),
    ("agg_infnt.parquet",      ["IDIND", "WAVE"], "1:1", "infant count per person×wave"),
    ("agg_infed.parquet",      ["IDIND", "WAVE"], "1:1", "infant feeding totals per person×wave"),
    # IDIND-only aggregates (no WAVE)
    ("agg_wed.parquet",         ["IDIND"], "1:1", "most recent marriage info per person"),
    ("agg_birthmast.parquet",   ["IDIND"], "1:1", "cumulative birth info per mother (IDIND_M→IDIND)"),
    ("agg_relationmast.parquet",["IDIND"], "1:1", "relationship counts per person (IDIND_1→IDIND)"),
]


def main():
    log.info("START merge aggregated tables")

    in_path = INTER_DIR / "panel_with_household.parquet"
    if not in_path.exists():
        log.error("panel_with_household.parquet not found — run 04_household_modules.py first")
        sys.exit(1)

    panel = pd.read_parquet(in_path)
    log.info("Loaded panel: %d rows × %d cols", len(panel), len(panel.columns))
    base_rows = len(panel)

    for agg_name, keys, mtype, note in AGG_MERGES:
        fp = INTER_DIR / agg_name
        if not fp.exists():
            log.warning("SKIP (not found): %s", agg_name)
            continue

        agg = pd.read_parquet(fp)
        log.info("Merging %s: %d rows — %s", agg_name, len(agg), note)

        # Drop columns already in panel (except keys)
        existing = [c for c in agg.columns if c in panel.columns and c not in keys]
        if existing:
            log.info("  Dropping already-present cols: %s", existing[:10])
            agg = agg.drop(columns=existing)

        # Deduplicate on keys before merge
        dups = agg.duplicated(subset=keys).sum()
        if dups > 0:
            log.warning("  %s has %d duplicate keys — keeping first", agg_name, dups)
            agg = agg.drop_duplicates(subset=keys, keep="first")

        panel = do_merge(
            left=panel,
            right=agg,
            keys=keys,
            how="left",
            step=f"{agg_name} ({' × '.join(keys)})",
            merge_type=mtype,
            log=log,
            conflict_note=note,
        )

        if len(panel) != base_rows:
            log.error(
                "Row count changed after merging %s: expected %d got %d",
                agg_name, base_rows, len(panel),
            )
            sys.exit(1)

    out_path = INTER_DIR / "panel_full.parquet"
    panel.to_parquet(out_path, index=False)
    log.info("Saved: %d rows × %d cols → %s", len(panel), len(panel.columns), out_path.name)
    log.info("SUCCESS")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        log.exception("FATAL: %s", exc)
        sys.exit(1)
