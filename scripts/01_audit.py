# CHNS Research Harness — Task 01: audit all raw files
# Date: 2026-05-29
# Author: Claude Code

import sys
import datetime
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _chns_utils import get_logger, RAW_ROOT, REPORTS_DIR

import pyreadstat
import pandas as pd

LOG_FILE = "01_audit.log"
log = get_logger("audit", LOG_FILE)


def audit_file(path: Path) -> dict:
    try:
        if path.suffix.lower() == ".sas7bdat":
            df, meta = pyreadstat.read_sas7bdat(str(path), metadataonly=False)
        elif path.suffix.lower() == ".dta":
            df, meta = pyreadstat.read_dta(str(path))
        else:
            return None

        df.columns = [c.upper() for c in df.columns]
        n_rows, n_cols = df.shape
        labels = getattr(meta, "column_names_to_labels", {}) or {}

        col_info = []
        for col in df.columns:
            n_missing = int(df[col].isna().sum())
            pct_missing = round(100.0 * n_missing / n_rows, 2) if n_rows > 0 else 0.0
            label = labels.get(col, "")
            col_info.append({
                "variable": col,
                "label": str(label)[:120],
                "dtype": str(df[col].dtype),
                "n_missing": n_missing,
                "pct_missing": pct_missing,
            })

        return {
            "file": str(path.relative_to(RAW_ROOT)),
            "n_rows": n_rows,
            "n_cols": n_cols,
            "columns": col_info,
        }
    except Exception as exc:
        log.error("FAILED %s: %s", path.name, exc)
        return {"file": str(path.relative_to(RAW_ROOT)), "error": str(exc)}


def main():
    log.info("START audit — scanning %s", RAW_ROOT)

    extensions = {".sas7bdat", ".dta"}
    data_files = sorted(
        p for p in RAW_ROOT.rglob("*") if p.suffix.lower() in extensions
    )
    log.info("Found %d data files", len(data_files))

    results = []
    for fp in data_files:
        log.info("Auditing: %s", fp.relative_to(RAW_ROOT))
        info = audit_file(fp)
        if info:
            results.append(info)
            if "error" not in info:
                log.info("  → %d rows × %d cols", info["n_rows"], info["n_cols"])

    # Write audit report
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    report_path = REPORTS_DIR / "audit_report.md"
    ts = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    lines = [
        f"# CHNS Audit Report\n",
        f"Generated: {ts}  \n",
        f"Total files scanned: {len(results)}\n\n",
        "---\n\n",
    ]
    for r in results:
        lines.append(f"## `{r['file']}`\n")
        if "error" in r:
            lines.append(f"**ERROR**: {r['error']}\n\n")
            continue
        lines.append(f"- Rows: {r['n_rows']:,}  \n")
        lines.append(f"- Columns: {r['n_cols']}  \n\n")
        lines.append("| Variable | Label | Dtype | N Missing | % Missing |\n")
        lines.append("|----------|-------|-------|----------:|-----------:|\n")
        for c in r["columns"]:
            lines.append(
                f"| {c['variable']} | {c['label']} | {c['dtype']} | {c['n_missing']:,} | {c['pct_missing']} |\n"
            )
        lines.append("\n")

    report_path.write_text("".join(lines), encoding="utf-8")
    log.info("Audit report written to %s", report_path.relative_to(Path(__file__).parent.parent))
    log.info("SUCCESS")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        log.exception("FATAL: %s", exc)
        sys.exit(1)
