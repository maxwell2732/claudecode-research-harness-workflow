# CHNS Research Harness — Task 05: aggregate sub-item tables to IDIND/HHID×WAVE
# Date: 2026-05-29
# Author: Claude Code

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
from _chns_utils import get_logger, RAW_ROOT, INTER_DIR, read_sas, read_dta, log_filter

from typing import Optional
import pandas as pd

LOG_FILE = "05_aggregate_items.log"
log = get_logger("agg_items", LOG_FILE)


# ── helpers ──────────────────────────────────────────────────────────────────

def safe_read(fp: Path) -> Optional[pd.DataFrame]:
    try:
        if fp.suffix.lower() == ".dta":
            df, _ = read_dta(fp, log=log)
        else:
            df, _ = read_sas(fp, log=log)
        df.columns = [c.upper() for c in df.columns]
        return df
    except Exception as exc:
        log.error("READ FAILED %s: %s", fp.name, exc)
        return None


def check_keys(df: pd.DataFrame, keys: list, fname: str) -> bool:
    missing = [k for k in keys if k not in df.columns]
    if missing:
        log.warning("SKIP %s — group key(s) missing: %s (have: %s)", fname, missing, list(df.columns[:10]))
        return False
    return True


def save_agg(df: pd.DataFrame, name: str):
    INTER_DIR.mkdir(parents=True, exist_ok=True)
    out = INTER_DIR / f"agg_{name}.parquet"
    df.to_parquet(out, index=False)
    log.info("Saved %s: %d rows × %d cols", out.name, len(df), len(df.columns))


# ── individual aggregations ───────────────────────────────────────────────────

def agg_nutrition():
    """nutr1/2/3: food-level records → household×wave totals."""
    NUTR_DIR = RAW_ROOT / "Master_Nutrition_201410" / "Master_Nutrition_201410"
    dfs = []
    for fname in ("nutr1_00.dta", "nutr2_00.dta", "nutr3_00.dta"):
        fp = NUTR_DIR / fname
        if not fp.exists():
            log.warning("SKIP nutrition file not found: %s", fname)
            continue
        df = safe_read(fp)
        if df is None:
            continue
        dfs.append(df)
        log.info("  %s: %d rows", fname, len(df))

    if not dfs:
        log.warning("No nutrition files read — skipping")
        return

    nutr = pd.concat(dfs, ignore_index=True)
    log.info("Combined nutrition: %d rows", len(nutr))

    group_keys = ["HHID", "WAVE"]
    agg_cols = {}

    # V22 = 3-day total consumed (grams); V23 = per-person per-day consumption
    for col in ["V22", "V23"]:
        if col in nutr.columns:
            agg_cols[f"nutr_{col.lower()}_sum"] = pd.NamedAgg(column=col, aggfunc="sum")
            agg_cols[f"nutr_{col.lower()}_mean"] = pd.NamedAgg(column=col, aggfunc="mean")

    if not agg_cols:
        log.warning("No V22/V23 columns found in nutrition data — saving raw groupby count only")
        agg = nutr.groupby(group_keys, as_index=False).size().rename(columns={"size": "nutr_n_fooditems"})
    else:
        agg = nutr.groupby(group_keys, as_index=False).agg(**agg_cols)
        count = nutr.groupby(group_keys, as_index=False).size().rename(columns={"size": "nutr_n_fooditems"})
        agg = agg.merge(count, on=group_keys, how="left")

    log.info("nutrition agg: %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "nutrition")


def agg_crops():
    """cropt_12: crop-level → household×wave totals."""
    fp = RAW_ROOT / "Master_Agriculture_201804" / "Master_Agriculture_201804" / "cropt_12.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    group_keys = ["HHID", "WAVE"]
    num_cols = df.select_dtypes(include="number").columns.difference(group_keys + ["T1","T2","T3","T4","T5","COMMID","LINE"])
    agg = df.groupby(group_keys, as_index=False)[list(num_cols)].sum()
    agg.columns = [c if c in group_keys else f"ag_cropt_{c.lower()}" for c in agg.columns]
    agg["ag_cropt_n_crops"] = df.groupby(group_keys)["HHID"].transform("count").groupby(
        df[group_keys].apply(tuple, axis=1)
    ).first().reset_index(drop=True) if False else df.groupby(group_keys, as_index=False).size()["size"].values
    log.info("cropt agg: %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "cropt")


def agg_farmg():
    """farmg_12: plot-level → household×wave totals (land area, output value)."""
    fp = RAW_ROOT / "Master_Agriculture_201804" / "Master_Agriculture_201804" / "farmg_12.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    group_keys = ["HHID", "WAVE"]
    num_cols = df.select_dtypes(include="number").columns.difference(group_keys + ["T1","T2","T3","T4","T5","COMMID","LINE","STRATUM"])
    agg = df.groupby(group_keys, as_index=False)[list(num_cols)].sum()
    agg.columns = [c if c in group_keys else f"ag_farmg_{c.lower()}" for c in agg.columns]
    log.info("farmg agg: %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "farmg")


def agg_fishi():
    """fishi_12: fish species × household → household×wave totals."""
    fp = RAW_ROOT / "Master_Agriculture_201804" / "Master_Agriculture_201804" / "fishi_12.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    group_keys = ["HHID", "WAVE"]
    num_cols = df.select_dtypes(include="number").columns.difference(group_keys + ["T1","T2","T3","T4","T5","COMMID","LINE","STRATUM"])
    agg = df.groupby(group_keys, as_index=False)[list(num_cols)].sum()
    agg.columns = [c if c in group_keys else f"ag_fishi_{c.lower()}" for c in agg.columns]
    log.info("fishi agg: %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "fishi")


def agg_foods():
    """foods_12: food items × household → household×wave totals."""
    fp = RAW_ROOT / "Master_Agriculture_201804" / "Master_Agriculture_201804" / "foods_12.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    group_keys = ["HHID", "WAVE"]
    num_cols = df.select_dtypes(include="number").columns.difference(group_keys + ["T1","T2","T3","T4","T5","COMMID","LINE","STRATUM"])
    agg = df.groupby(group_keys, as_index=False)[list(num_cols)].sum()
    agg.columns = [c if c in group_keys else f"ag_foods_{c.lower()}" for c in agg.columns]
    log.info("foods agg: %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "foods")


def agg_carec():
    """carec_12: child-level childcare → household×wave counts."""
    fp = RAW_ROOT / "Master_Childcare_201804" / "Master_Childcare_201804" / "carec_12.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    group_keys = ["HHID", "WAVE"]
    agg = df.groupby(group_keys, as_index=False).size().rename(columns={"size": "care_n_children_childcare"})
    log.info("carec agg: %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "carec")


def agg_busi():
    """busi_12: individual business items → individual×wave total income."""
    fp = RAW_ROOT / "Master_Business_201804" / "Master_Business_201804" / "busi_12.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    group_keys = ["IDIND", "WAVE"]
    num_cols = df.select_dtypes(include="number").columns.difference(group_keys + ["T1","T2","T3","T4","T5","COMMID","LINE","HHID","STRATUM"])
    agg = df.groupby(group_keys, as_index=False)[list(num_cols)].sum()
    agg.columns = [c if c in group_keys else f"biz_busi_{c.lower()}" for c in agg.columns]
    log.info("busi agg: %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "busi")


def agg_busn():
    """busn_12: household business items → household×wave counts."""
    fp = RAW_ROOT / "Master_Business_201804" / "Master_Business_201804" / "busn_12.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    group_keys = ["HHID", "WAVE"]
    num_cols = df.select_dtypes(include="number").columns.difference(group_keys + ["T1","T2","T3","T4","T5","COMMID","LINE","STRATUM"])
    agg = df.groupby(group_keys, as_index=False)[list(num_cols)].sum()
    agg.columns = [c if c in group_keys else f"biz_busn_{c.lower()}" for c in agg.columns]
    log.info("busn agg: %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "busn")


def agg_subf():
    """subf_12: subsidy type × household → household×wave total subsidy."""
    fp = RAW_ROOT / "Master_Income_Categories_201804c1" / "Master_Income_Categories_201804" / "subf_12.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    group_keys = ["HHID", "WAVE"]
    num_cols = df.select_dtypes(include="number").columns.difference(group_keys + ["T1","T2","T3","T4","T5","COMMID","LINE","STRATUM"])
    agg = df.groupby(group_keys, as_index=False)[list(num_cols)].sum()
    agg.columns = [c if c in group_keys else f"subf_{c.lower()}" for c in agg.columns]
    log.info("subf agg: %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "subf")


def agg_birth():
    """birth_12: birth events → individual×wave birth counts."""
    fp = RAW_ROOT / "Master_EverMarriedWomen_201804" / "Master_EverMarriedWomen_201804" / "birth_12.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    group_keys = ["IDIND", "WAVE"]
    if not check_keys(df, group_keys, fp.name):
        return
    agg = df.groupby(group_keys, as_index=False).size().rename(columns={"size": "emw_n_births_wave"})
    log.info("birth agg: %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "birth")


def agg_preg():
    """preg_12: pregnancy events → individual×wave pregnancy counts."""
    fp = RAW_ROOT / "Master_EverMarriedWomen_201804" / "Master_EverMarriedWomen_201804" / "preg_12.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    group_keys = ["IDIND", "WAVE"]
    if not check_keys(df, group_keys, fp.name):
        return
    agg = df.groupby(group_keys, as_index=False).size().rename(columns={"size": "emw_n_preg_wave"})
    log.info("preg agg: %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "preg")


def agg_wed():
    """wed_12: marriage events → individual-level most recent marriage info."""
    fp = RAW_ROOT / "Master_EverMarriedWomen_201804" / "Master_EverMarriedWomen_201804" / "wed_12.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    if not check_keys(df, ["IDIND"], fp.name):
        return
    # Take the most recent record per IDIND (sort by WAVE desc if available)
    if "WAVE" in df.columns:
        df = df.sort_values("WAVE", ascending=False)
    agg = df.drop_duplicates(subset=["IDIND"], keep="first").copy()
    keep_cols = ["IDIND"] + [c for c in agg.columns if c != "IDIND"]
    agg = agg[keep_cols]
    agg.columns = ["IDIND"] + [f"emw_wed_{c.lower()}" if c != "IDIND" else c for c in agg.columns[1:]]
    log.info("wed agg (most recent per IDIND): %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "wed")


def agg_birthmast():
    """birthmast_pub_12: birth master → individual-level cumulative births."""
    fp = RAW_ROOT / "Master_EverMarriedWomen_201804" / "Master_EverMarriedWomen_201804" / "birthmast_pub_12.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    if not check_keys(df, ["IDIND"], fp.name):
        return
    agg = df.drop_duplicates(subset=["IDIND"], keep="first").copy()
    agg.columns = ["IDIND" if c == "IDIND" else f"emw_bm_{c.lower()}" for c in agg.columns]
    log.info("birthmast agg: %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "birthmast")


def agg_infnt():
    """infnt_00: infant records → individual×wave infant count."""
    fp = RAW_ROOT / "Master_InfantFeeding_201410" / "infnt_00.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    group_keys = ["IDIND", "WAVE"]
    if not all(k in df.columns for k in group_keys):
        log.warning("infnt_00 missing IDIND or WAVE — skipping")
        return
    agg = df.groupby(group_keys, as_index=False).size().rename(columns={"size": "inf_n_infants"})
    log.info("infnt agg: %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "infnt")


def agg_infed():
    """infed_00: infant feeding × food → individual×wave food-type feeding counts."""
    fp = RAW_ROOT / "Master_InfantFeeding_201410" / "infed_00.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    group_keys = ["IDIND", "WAVE"]
    if not all(k in df.columns for k in group_keys):
        log.warning("infed_00 missing IDIND or WAVE — skipping")
        return
    num_cols = df.select_dtypes(include="number").columns.difference(group_keys + ["T1","T2","T3","T4","T5","COMMID","LINE","HHID","STRATUM"])
    agg = df.groupby(group_keys, as_index=False)[list(num_cols)].sum()
    agg.columns = [c if c in group_keys else f"inf_fed_{c.lower()}" for c in agg.columns]
    log.info("infed agg: %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "infed")


def agg_birth_mother():
    """birth_12: births keyed by IDIND_M (mother) + IDIND_C (child) + WAVE.
    Aggregate to mother×wave: count of live births per mother per wave.
    Join key for panel: IDIND = IDIND_M."""
    fp = RAW_ROOT / "Master_EverMarriedWomen_201804" / "Master_EverMarriedWomen_201804" / "birth_12.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    if not check_keys(df, ["IDIND_M", "WAVE"], fp.name):
        return
    # Count births per mother per wave
    agg = df.groupby(["IDIND_M", "WAVE"], as_index=False).agg(
        emw_n_births=("IDIND_C", "count"),
        emw_n_births_alive=("S52", lambda x: (x == 1).sum()),  # S52=1 usually means alive
    )
    agg = agg.rename(columns={"IDIND_M": "IDIND"})
    log.info("birth agg (mother×wave): %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "birth")


def agg_preg_mother():
    """preg_12: pregnancy records keyed by IDIND_M + WAVE.
    Aggregate to mother×wave: count pregnancies per mother per wave."""
    fp = RAW_ROOT / "Master_EverMarriedWomen_201804" / "Master_EverMarriedWomen_201804" / "preg_12.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    if not check_keys(df, ["IDIND_M", "WAVE"], fp.name):
        return
    agg = df.groupby(["IDIND_M", "WAVE"], as_index=False).size().rename(columns={"size": "emw_n_preg_wave"})
    agg = agg.rename(columns={"IDIND_M": "IDIND"})
    log.info("preg agg (mother×wave): %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "preg")


def agg_birthmast_mother():
    """birthmast_pub_12: birth master keyed by IDIND_M + IDIND_C (no WAVE).
    Aggregate to mother level: total children born, sex composition."""
    fp = RAW_ROOT / "Master_EverMarriedWomen_201804" / "Master_EverMarriedWomen_201804" / "birthmast_pub_12.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    if not check_keys(df, ["IDIND_M"], fp.name):
        return
    agg = df.groupby("IDIND_M", as_index=False).agg(
        emw_bm_n_children=("IDIND_C", "count"),
        emw_bm_n_boys=("GENDER", lambda x: (x == 1).sum()),
        emw_bm_n_girls=("GENDER", lambda x: (x == 2).sum()),
    )
    agg = agg.rename(columns={"IDIND_M": "IDIND"})
    log.info("birthmast agg (mother): %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "birthmast")


def agg_relationmast():
    """relationmast_pub_00: dyadic relationship file (IDIND_1, IDIND_2, no WAVE).
    For each IDIND (as IDIND_1): count total alter relationships and get mode REL_TYPE."""
    fp = RAW_ROOT / "Master_Relationship_201410" / "relationmast_pub_00.sas7bdat"
    df = safe_read(fp)
    if df is None:
        return
    if not check_keys(df, ["IDIND_1", "IDIND_2"], fp.name):
        return
    # From IDIND_1 perspective
    agg = df.groupby("IDIND_1", as_index=False).agg(
        rel_n_relationships=("IDIND_2", "count"),
        rel_mode_rel_type=("REL_TYPE", lambda x: x.mode().iloc[0] if x.notna().any() else float("nan")),
    )
    agg = agg.rename(columns={"IDIND_1": "IDIND"})
    log.info("relationmast agg (IDIND_1 perspective): %d rows × %d cols", len(agg), len(agg.columns))
    save_agg(agg, "relationmast")


def main():
    log.info("START aggregate sub-item tables")
    INTER_DIR.mkdir(parents=True, exist_ok=True)

    agg_nutrition()
    agg_crops()
    agg_farmg()
    agg_fishi()
    agg_foods()
    agg_carec()
    agg_busi()
    agg_busn()
    agg_subf()
    agg_birth_mother()
    agg_preg_mother()
    agg_wed()
    agg_birthmast_mother()
    agg_infnt()
    agg_infed()
    agg_relationmast()

    saved = list(INTER_DIR.glob("agg_*.parquet"))
    log.info("Total aggregated tables saved: %d", len(saved))
    for p in sorted(saved):
        log.info("  %s", p.name)
    log.info("SUCCESS")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        log.exception("FATAL: %s", exc)
        sys.exit(1)
