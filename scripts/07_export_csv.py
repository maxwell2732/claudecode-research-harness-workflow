# CHNS Research Harness — Task 07: export final CSV and codebook
# Date: 2026-05-29
# Author: Claude Code

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _chns_utils import get_logger, INTER_DIR, PROC_DIR

import pandas as pd
import numpy as np

LOG_FILE = "07_export_csv.log"
log = get_logger("export_csv", LOG_FILE)


def build_codebook(df: pd.DataFrame) -> pd.DataFrame:
    """Build a codebook DataFrame from the merged panel."""
    records = []
    n_total = len(df)

    for col in df.columns:
        series = df[col]
        dtype = str(series.dtype)
        n_missing = int(series.isna().sum())
        n_obs = n_total - n_missing
        pct_missing = round(100.0 * n_missing / n_total, 2) if n_total > 0 else 0.0
        n_unique = int(series.nunique(dropna=True))

        col_min = col_max = col_mean = ""
        example_values = ""

        if pd.api.types.is_numeric_dtype(series):
            non_null = series.dropna()
            if len(non_null) > 0:
                col_min = str(round(float(non_null.min()), 6))
                col_max = str(round(float(non_null.max()), 6))
                col_mean = str(round(float(non_null.mean()), 6))
        else:
            top = series.dropna().value_counts().head(5).index.tolist()
            example_values = "; ".join(str(v)[:40] for v in top)

        records.append({
            "variable_name": col,
            "variable_label": "",     # populated below from metadata lookup if available
            "source_file": "",        # populated below
            "source_module": "",      # populated below
            "dtype": dtype,
            "n_obs": n_obs,
            "n_missing": n_missing,
            "pct_missing": pct_missing,
            "min": col_min,
            "max": col_max,
            "mean": col_mean,
            "n_unique": n_unique,
            "example_values": example_values,
        })

    return pd.DataFrame(records)


def enrich_codebook_from_audit(cb: pd.DataFrame) -> pd.DataFrame:
    """Read audit_report lines to back-fill variable_label, source_file, source_module."""
    from pathlib import Path as P
    audit_path = P(__file__).parent.parent / "reports" / "audit_report.md"
    if not audit_path.exists():
        log.warning("audit_report.md not found — skipping label enrichment")
        return cb

    # Parse audit report: sections start with ## `file_path`
    current_file = ""
    current_module = ""
    label_map: dict[str, tuple[str, str, str]] = {}  # var → (label, file, module)

    for line in audit_path.read_text(encoding="utf-8").splitlines():
        if line.startswith("## `"):
            current_file = line.strip("## `").strip("`").strip()
            parts = current_file.split("/")
            current_module = parts[0] if parts else current_file
        elif line.startswith("| ") and "|" in line:
            parts = [p.strip() for p in line.split("|")]
            if len(parts) >= 3 and parts[1] not in ("Variable", "---", "----------"):
                var = parts[1].upper()
                label = parts[2] if len(parts) > 2 else ""
                if var and var not in label_map:
                    label_map[var] = (label, current_file, current_module)

    def fill_row(row):
        var = row["variable_name"]
        if var in label_map:
            lbl, src_file, src_mod = label_map[var]
            if not row["variable_label"]:
                row["variable_label"] = lbl
            if not row["source_file"]:
                row["source_file"] = src_file
            if not row["source_module"]:
                row["source_module"] = src_mod
        return row

    cb = cb.apply(fill_row, axis=1)
    return cb


def main():
    log.info("START export CSV and codebook")
    PROC_DIR.mkdir(parents=True, exist_ok=True)

    in_path = INTER_DIR / "panel_full.parquet"
    if not in_path.exists():
        log.error("panel_full.parquet not found — run 06_merge_aggregates.py first")
        sys.exit(1)

    panel = pd.read_parquet(in_path)
    log.info("Loaded panel_full: %d rows × %d cols", len(panel), len(panel.columns))

    # Export main CSV
    out_csv = PROC_DIR / "chns_merged_panel.csv"
    log.info("Writing %s ...", out_csv.name)
    panel.to_csv(out_csv, index=False, encoding="utf-8-sig")
    log.info("Wrote %s: %d rows × %d cols", out_csv.name, len(panel), len(panel.columns))

    # Build and export codebook
    log.info("Building codebook ...")
    cb = build_codebook(panel)
    cb = enrich_codebook_from_audit(cb)

    out_cb = PROC_DIR / "chns_codebook.csv"
    cb.to_csv(out_cb, index=False, encoding="utf-8-sig")
    log.info("Wrote %s: %d variables", out_cb.name, len(cb))

    # Summary statistics
    log.info("--- Final dataset summary ---")
    log.info("  Total rows:    %d", len(panel))
    log.info("  Total columns: %d", len(panel.columns))
    log.info("  Waves present: %s", sorted(panel["WAVE"].dropna().unique().tolist()) if "WAVE" in panel.columns else "N/A")
    if "IDIND" in panel.columns:
        log.info("  Unique individuals: %d", panel["IDIND"].nunique())
    if "HHID" in panel.columns:
        log.info("  Unique households:  %d", panel["HHID"].nunique())

    overall_pct_missing = round(100.0 * panel.isna().sum().sum() / (len(panel) * len(panel.columns)), 2)
    log.info("  Overall missing%%: %.2f%%", overall_pct_missing)
    log.info("SUCCESS")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        log.exception("FATAL: %s", exc)
        sys.exit(1)
