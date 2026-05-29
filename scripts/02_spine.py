# CHNS Research Harness — Task 02: build individual×wave spine
# Date: 2026-05-29
# Author: Claude Code

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _chns_utils import (
    get_logger, RAW_ROOT, INTER_DIR,
    read_sas, do_merge, log_filter,
)

LOG_FILE = "02_spine.log"
log = get_logger("spine", LOG_FILE)

ID_DIR = RAW_ROOT / "Master_ID_201908" / "Master_ID_201908"


def main():
    log.info("START build spine")
    INTER_DIR.mkdir(parents=True, exist_ok=True)

    # --- surveys: the authoritative person×wave frame ---
    surveys_path = ID_DIR / "surveys_pub_12.sas7bdat"
    log.info("Reading surveys_pub_12 (spine base)")
    surveys, _ = read_sas(surveys_path, prefix=None, log=log)
    # Standardise column names already done in read_sas
    n_surveys = len(surveys)
    log.info("surveys rows: %d, cols: %d", n_surveys, len(surveys.columns))

    # --- master: individual-level demographics (no WAVE) ---
    mast_path = ID_DIR / "mast_pub_12.sas7bdat"
    log.info("Reading mast_pub_12")
    mast, _ = read_sas(mast_path, prefix="id_", log=log)
    # Drop columns already in surveys that would conflict (keep surveys' version)
    drop_from_mast = [c for c in mast.columns if c in surveys.columns and c != "IDIND"]
    if drop_from_mast:
        log.info("Dropping from mast (already in surveys): %s", drop_from_mast)
        mast = mast.drop(columns=drop_from_mast)

    spine = do_merge(
        left=surveys,
        right=mast,
        keys=["IDIND"],
        how="left",
        step="spine: surveys ← mast (1:1 on IDIND)",
        merge_type="1:1",
        log=log,
        conflict_note="mast cols prefixed id_; surveys cols kept where duplicated",
    )

    # --- roster: person×wave characteristics ---
    rst_path = ID_DIR / "rst_12.sas7bdat"
    log.info("Reading rst_12")
    rst, _ = read_sas(rst_path, prefix="rst_", log=log)
    drop_from_rst = [c for c in rst.columns if c in spine.columns and c not in ("IDIND", "HHID", "WAVE", "COMMID")]
    if drop_from_rst:
        log.info("Dropping from rst (already in spine): %s", drop_from_rst)
        rst = rst.drop(columns=drop_from_rst)

    spine = do_merge(
        left=spine,
        right=rst,
        keys=["IDIND", "WAVE"],
        how="left",
        step="spine: surveys+mast ← rst (1:1 on IDIND×WAVE)",
        merge_type="1:1",
        log=log,
    )

    n_after = len(spine)
    if n_after != n_surveys:
        log.warning(
            "Row count changed after rst merge: %d → %d (expected %d)",
            n_surveys, n_after, n_surveys,
        )
    else:
        log.info("Row count stable at %d after rst merge", n_after)

    out_path = INTER_DIR / "spine.parquet"
    spine.to_parquet(out_path, index=False)
    log.info("Saved spine: %d rows × %d cols → %s", len(spine), len(spine.columns), out_path.name)
    log.info("SUCCESS")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        log.exception("FATAL: %s", exc)
        sys.exit(1)
