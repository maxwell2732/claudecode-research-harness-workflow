# CHNS Research Harness — shared utilities
# Date: 2026-05-29
# Author: Claude Code

import sys
import logging
import datetime
from pathlib import Path

from typing import List, Optional, Tuple

import pandas as pd
import pyreadstat

PROJECT_ROOT = Path(__file__).resolve().parent.parent
RAW_ROOT = PROJECT_ROOT / "input" / "data" / "chns_raw"
INTER_DIR = PROJECT_ROOT / "data" / "intermediate"
PROC_DIR = PROJECT_ROOT / "data" / "processed"
LOG_DIR = PROJECT_ROOT / "logs"
REPORTS_DIR = PROJECT_ROOT / "reports"


def get_logger(name: str, log_file: str) -> logging.Logger:
    LOG_DIR.mkdir(parents=True, exist_ok=True)
    logger = logging.getLogger(name)
    logger.setLevel(logging.INFO)
    fh = logging.FileHandler(LOG_DIR / log_file, encoding="utf-8")
    sh = logging.StreamHandler(sys.stdout)
    fmt = logging.Formatter("%(asctime)s %(levelname)s %(message)s")
    fh.setFormatter(fmt)
    sh.setFormatter(fmt)
    logger.addHandler(fh)
    logger.addHandler(sh)
    return logger


def read_sas(path: Path, prefix: Optional[str] = None, log=None) -> Tuple[pd.DataFrame, dict]:
    """Read .sas7bdat and optionally prefix non-key columns. Returns (df, meta)."""
    df, meta = pyreadstat.read_sas7bdat(str(path))
    df.columns = [c.upper() for c in df.columns]
    if log:
        log.info("READ %s: %d rows × %d cols", path.name, len(df), len(df.columns))
    if prefix:
        key_cols = {"IDIND", "HHID", "WAVE", "COMMID", "LINE",
                    "T1", "T2", "T3", "T4", "T5", "STRATUM"}
        rename = {c: f"{prefix}{c}" for c in df.columns if c not in key_cols}
        df = df.rename(columns=rename)
    return df, meta


def read_dta(path: Path, prefix: Optional[str] = None, log=None) -> Tuple[pd.DataFrame, dict]:
    """Read .dta and optionally prefix non-key columns."""
    df, meta = pyreadstat.read_dta(str(path))
    df.columns = [c.upper() for c in df.columns]
    if log:
        log.info("READ %s: %d rows × %d cols", path.name, len(df), len(df.columns))
    if prefix:
        key_cols = {"IDIND", "HHID", "WAVE", "COMMID", "LINE",
                    "T1", "T2", "T3", "T4", "T5", "STRATUM"}
        rename = {c: f"{prefix}{c}" for c in df.columns if c not in key_cols}
        df = df.rename(columns=rename)
    return df, meta


def log_filter(log, description: str, before: int, after: int):
    dropped = before - after
    log.info("FILTER [%s]: %d → %d (dropped %d)", description, before, after, dropped)


def append_merge_report(
    step: str,
    merge_type: str,
    keys: List[str],
    left_n: int,
    right_n: int,
    result_n: int,
    matched: int,
    unmatched_left: int,
    unmatched_right: int,
    dup_note: str = "",
    conflict_note: str = "",
):
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    path = REPORTS_DIR / "merge_report.md"
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    block = f"""
## {step}
- **Timestamp**: {ts}
- **Merge type**: {merge_type}
- **Keys**: {', '.join(keys)}
- **Left rows**: {left_n:,}
- **Right rows**: {right_n:,}
- **Post-merge rows**: {result_n:,}
- **Matched**: {matched:,}
- **Unmatched left**: {unmatched_left:,}
- **Unmatched right**: {unmatched_right:,}
- **Duplicate key note**: {dup_note or 'none'}
- **Variable conflict note**: {conflict_note or 'none'}

"""
    with open(path, "a", encoding="utf-8") as f:
        f.write(block)


def do_merge(
    left: pd.DataFrame,
    right: pd.DataFrame,
    keys: List[str],
    how: str,
    step: str,
    merge_type: str,
    log,
    suffix_right: str = "_right",
    conflict_note: str = "",
) -> pd.DataFrame:
    """Left-join with automatic merge report logging."""
    left_n = len(left)
    right_n = len(right)

    # Duplicate key check on right
    dup_count = right.duplicated(subset=keys).sum()
    if dup_count > 0 and merge_type in ("1:1",):
        log.warning("MERGE %s: %d duplicate keys in right table", step, dup_count)
    dup_note = f"{dup_count} duplicate key rows in right table" if dup_count else ""

    merged = left.merge(right, on=keys, how=how, suffixes=("", suffix_right))
    result_n = len(merged)

    # Approximate matched/unmatched via indicator
    ind = left.merge(right[keys].drop_duplicates(), on=keys, how="left", indicator=True)
    matched = int((ind["_merge"] == "both").sum())
    unmatched_left = int((ind["_merge"] == "left_only").sum())

    ind_r = right[keys].drop_duplicates().merge(
        left[keys].drop_duplicates(), on=keys, how="left", indicator=True
    )
    unmatched_right = int((ind_r["_merge"] == "left_only").sum())

    log.info(
        "MERGE %s: left=%d right=%d result=%d matched=%d unmatched_left=%d unmatched_right=%d",
        step, left_n, right_n, result_n, matched, unmatched_left, unmatched_right,
    )
    append_merge_report(
        step=step,
        merge_type=merge_type,
        keys=keys,
        left_n=left_n,
        right_n=right_n,
        result_n=result_n,
        matched=matched,
        unmatched_left=unmatched_left,
        unmatched_right=unmatched_right,
        dup_note=dup_note,
        conflict_note=conflict_note,
    )
    return merged
