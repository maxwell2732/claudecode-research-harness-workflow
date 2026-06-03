# CHARLS Research Harness — Extended LTCI Subsample (2011-2020)
# Task: charls_13 — extend Zhang et al. (2026) LTCI replication to include 2020 wave
#        and add health / human-capital outcome variables
# Date: 2026-06-03
# Author: Claude Code
#
# Key extensions vs charls_11:
#   - Adds 2020 wave (post=1 for all LTCI cities)
#   - 2020 has no Family_Transfer; caregiving filled from prior waves
#   - 2018 CES-D loaded from Cognition.dta (was missing in charls_11)
#   - New variables: N_ADL, N_IADL, COGN_WORD_RECALL, COGN_WORD_DELAYED,
#                    COGN_SERIAL7, COGN_ORIENT (extended DEPRESSION_CESD for 2018/2020)
#
# 2020 module availability:
#   Present:  Demographic_Background, Health_Status_and_Functioning,
#             Work_Retirement, Family_Information, Household_Income,
#             Individual_Income, Sample_Infor
#   Absent:   Family_Transfer, Health_Care_and_Insurance, PSU
#   → HEALTH_INSURED = NaN for 2020
#   → CARE_GRANDCHILD, CARE_INTENSITY, LN_CARE_HRS = NaN for 2020

import sys
import math
import numpy as np
import pandas as pd
import pyreadstat

from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from _charls_utils import (
    get_logger, find_file, log_filter,
    WAVE_DIRS, INTER_DIR, PROC_DIR, LOG_DIR, write_parquet,
)

WAVES = [2011, 2013, 2018, 2020]

LTCI_CITY_NAMES = [
    "青岛", "上海", "广州", "重庆", "成都", "宁波",
    "齐齐哈尔", "安庆", "荆门", "苏州", "上饶", "承德",
]
QINGDAO_NAME = "青岛"


# ─────────────────────────────────────────────────────────────
#   1. COMMUNITY → CITY MAPPING  (from PSU 2011/2013 only)
# ─────────────────────────────────────────────────────────────

def build_city_map(log) -> pd.DataFrame:
    frames = []
    for wave in [2011, 2013]:
        path = find_file(WAVE_DIRS[wave], "PSU.dta", "psu.dta")
        if path is None:
            log.warning("PSU not found for wave %d", wave)
            continue
        df, _ = pyreadstat.read_dta(str(path))
        df.columns = [c.upper() for c in df.columns]
        if "COMMUNITYID" not in df.columns or "CITY" not in df.columns:
            log.warning("PSU W%d missing COMMUNITYID or CITY", wave)
            continue
        sub = df[["COMMUNITYID", "CITY"]].copy()
        sub["WAVE"] = wave
        frames.append(sub)
        log.info("PSU W%d: %d communities", wave, len(sub))

    if not frames:
        log.error("No PSU data — cannot identify LTCI cities")
        sys.exit(1)

    psu = pd.concat(frames, ignore_index=True)
    psu = psu.sort_values("WAVE", ascending=False).drop_duplicates("COMMUNITYID")
    psu = psu[["COMMUNITYID", "CITY"]].copy()

    def is_ltci(v):
        if pd.isna(v): return 0
        return int(any(n in str(v) for n in LTCI_CITY_NAMES))

    def is_qingdao(v):
        if pd.isna(v): return 0
        return int(QINGDAO_NAME in str(v))

    psu["IS_LTCI_CITY"] = psu["CITY"].apply(is_ltci)
    psu["IS_QINGDAO"]   = psu["CITY"].apply(is_qingdao)
    n_ltci = int(psu["IS_LTCI_CITY"].sum())
    log.info("City map: %d communities, %d in LTCI cities", len(psu), n_ltci)
    log.info("LTCI cities found: %s",
             sorted(psu.loc[psu.IS_LTCI_CITY == 1, "CITY"].unique().tolist()))
    return psu


# ─────────────────────────────────────────────────────────────
#   2. LOAD COGNITION MODULE (2018 only — separate file)
# ─────────────────────────────────────────────────────────────

def load_cognition_2018(log) -> pd.DataFrame:
    """Load 2018 Cognition.dta which contains CES-D DC009-DC018 and
    cognitive test scores (word recall, serial 7, orientation).
    Returns individual-level frame keyed by ID."""
    path = find_file(WAVE_DIRS[2018], "Cognition.dta", "cognition.dta")
    if path is None:
        log.warning("W2018: Cognition.dta not found — CES-D / cognition will be NaN")
        return pd.DataFrame(columns=["ID"])
    df, _ = pyreadstat.read_dta(str(path))
    df.columns = [c.upper() for c in df.columns]
    log.info("W2018 Cognition: %d rows × %d cols", len(df), len(df.columns))
    return df.drop_duplicates("ID")


# ─────────────────────────────────────────────────────────────
#   3. LOAD ONE WAVE
# ─────────────────────────────────────────────────────────────

def load_wave(wave: int, log) -> pd.DataFrame:
    wd = WAVE_DIRS[wave]
    log.info("--- Loading wave %d ---", wave)

    # ── Spine: Demographic_Background ─────────────────────────
    dem_path = find_file(wd, "Demographic_Background.dta", "demographic_background.dta")
    dem, _ = pyreadstat.read_dta(str(dem_path))
    dem.columns = [c.upper() for c in dem.columns]
    dem["WAVE"] = wave
    log.info("W%d Demographic: %d rows", wave, len(dem))

    # ── Family_Transfer (caregiving) — NOT available in 2020 ──
    ft_path = find_file(wd, "Family_Transfer.dta", "family_transfer.dta")
    if ft_path is not None:
        ft, _ = pyreadstat.read_dta(str(ft_path))
        ft.columns = [c.upper() for c in ft.columns]
        ft_keys = [c for c in ["ID", "HOUSEHOLDID", "COMMUNITYID"] if c in ft.columns]

        care_cols = []
        ft_cols = set(ft.columns)
        if wave in [2011, 2013]:
            for c in ["CF004", "CF001",
                      "CF005_2", "CF005_4", "CF005_6", "CF005_8",
                      "CF005_1", "CF005_3", "CF005_5", "CF005_7"]:
                if c in ft_cols: care_cols.append(c)
        else:  # 2018
            for c in ft_cols:
                cu = c.upper()
                if cu.startswith("CF004_W4") or cu.startswith("CF005_W4") or cu == "CF001":
                    care_cols.append(c)

        ft_sub = ft[ft_keys + care_cols].drop_duplicates(
            subset=["ID"] if "ID" in ft_keys else ft_keys[:1])
        dem = dem.merge(ft_sub, on=[k for k in ft_keys if k in dem.columns], how="left")
        log.info("W%d after FamilyTransfer merge: %d rows", wave, len(dem))
    else:
        log.info("W%d: No Family_Transfer (2020) — caregiving vars will be NaN", wave)

    # ── Work_Retirement ────────────────────────────────────────
    wr_path = find_file(wd,
                        "Work_Retirement_and_Pension.dta",
                        "Work_Retirement.dta",
                        "work_retirement_and_pension.dta",
                        "work_retirement.dta")
    if wr_path is not None:
        wr, _ = pyreadstat.read_dta(str(wr_path))
        wr.columns = [c.upper() for c in wr.columns]
        if wave in [2011, 2013]:
            wr_need = [c for c in ["FA001","FA002","FA003","FC001","FC014","FC015"]
                       if c in wr.columns]
        elif wave == 2018:
            wr_need = [c for c in ["FA001","FA002_W4","FA003","FC001","FA006_W3_3"]
                       if c in wr.columns]
        else:  # 2020
            # FA004=has nonfarm work, FA005=on leave, FA001=has farm work
            # FA002_S2=farm employed (hired agri labor)
            wr_need = [c for c in ["FA001","FA002_S1","FA002_S2","FA004","FA005","FC001"]
                       if c in wr.columns]
        wr_keys = [c for c in ["ID","HOUSEHOLDID","COMMUNITYID"] if c in wr.columns]
        wr_sub = wr[wr_keys + wr_need].drop_duplicates("ID")
        dem = dem.merge(wr_sub, on=[k for k in wr_keys if k in dem.columns], how="left")
        log.info("W%d after WorkRetirement merge: %d rows", wave, len(dem))

    # ── Health_Status_and_Functioning ─────────────────────────
    hs_path = find_file(wd, "Health_Status_and_Functioning.dta",
                        "health_status_and_functioning.dta")
    if hs_path is not None:
        hs, _ = pyreadstat.read_dta(str(hs_path))
        hs.columns = [c.upper() for c in hs.columns]
        hs_want = []
        hcols = set(hs.columns)

        # Self-rated health
        for c in ["DA001", "DA002"]:
            if c in hcols: hs_want.append(c); break

        # Chronic diseases (2011-2018: DA007_N_; 2020: DA003_N_)
        if wave in [2011, 2013, 2018]:
            for i in range(1, 15):
                c = f"DA007_{i}_"
                if c in hcols: hs_want.append(c)
        else:  # 2020
            for i in range(1, 16):
                c = f"DA003_{i}_"
                if c in hcols: hs_want.append(c)

        # Pain
        for c in ["DA041", "DA041_W4", "DA027"]:
            if c in hcols: hs_want.append(c)
        # Pain body parts (2011-2018: DA042S/DA042_S; 2020: DA028_S)
        if wave in [2011, 2013, 2018]:
            for i in range(1, 16):
                for fmt in [f"DA042S{i}", f"DA042_S{i}"]:
                    if fmt in hcols: hs_want.append(fmt); break
        else:
            for i in range(1, 17):
                c = f"DA028_S{i}"
                if c in hcols: hs_want.append(c)

        # Sleep
        for c in ["DA049", "DA049_W4", "DA050", "DA030"]:
            if c in hcols: hs_want.append(c); break

        # Social activity (2011/2013: DA056SN; 2018: DA056_SN; 2020: DA038_SN)
        if wave in [2011, 2013]:
            for i in range(1, 12):
                for fmt in [f"DA056S{i}", f"DA056_S{i}"]:
                    if fmt in hcols: hs_want.append(fmt); break
        elif wave == 2018:
            for i in range(1, 12):
                c = f"DA056_S{i}"
                if c in hcols: hs_want.append(c)
        else:  # 2020
            for i in range(1, 10):
                c = f"DA038_S{i}"
                if c in hcols: hs_want.append(c)

        # ADL (2011/2013/2018: DB010-DB015; 2020: DB001,3,5,7,9,11)
        if wave in [2011, 2013, 2018]:
            for c in ["DB010","DB011","DB012","DB013","DB014","DB015"]:
                if c in hcols: hs_want.append(c)
        else:
            for c in ["DB001","DB003","DB005","DB007","DB009","DB011"]:
                if c in hcols: hs_want.append(c)

        # IADL (2011/2013/2018: DB016-DB020; 2020: DB012,14,16,18,20,22)
        if wave in [2011, 2013, 2018]:
            for c in ["DB016","DB017","DB018","DB019","DB020"]:
                if c in hcols: hs_want.append(c)
        else:
            for c in ["DB012","DB014","DB016","DB018","DB020","DB022"]:
                if c in hcols: hs_want.append(c)

        # Orientation (2011/2013: DC001s1-s3/DC002/DC003; 2018 in Cognition; 2020: DC001-DC005)
        if wave in [2011, 2013]:
            for c in ["DC001S1","DC001S2","DC001S3","DC002","DC003"]:
                if c in hcols: hs_want.append(c)
        elif wave == 2020:
            for c in ["DC001","DC002","DC003","DC004","DC005"]:
                if c in hcols: hs_want.append(c)
        # 2018 orientation is in Cognition.dta — handled later

        # Word recall immediate (2011: DC006SN; 2013: DC006_1_SN; 2020: DC012_SN)
        if wave == 2011:
            for i in range(1, 11):
                c = f"DC006S{i}"
                if c in hcols: hs_want.append(c)
        elif wave == 2013:
            for i in range(1, 11):
                c = f"DC006_1_S{i}"
                if c in hcols: hs_want.append(c)
        elif wave == 2020:
            for i in range(1, 11):
                c = f"DC012_S{i}"
                if c in hcols: hs_want.append(c)

        # Word recall delayed (2011/2013: DC027SN; 2020: DC028_SN)
        if wave in [2011, 2013]:
            for i in range(1, 11):
                c = f"DC027S{i}"
                if c in hcols: hs_want.append(c)
        elif wave == 2020:
            for i in range(1, 11):
                c = f"DC028_S{i}"
                if c in hcols: hs_want.append(c)

        # Serial 7 (2011/2013: DC019-DC023; 2020: DC007_1-DC007_5)
        if wave in [2011, 2013]:
            for c in ["DC019","DC020","DC021","DC022","DC023"]:
                if c in hcols: hs_want.append(c)
        elif wave == 2020:
            for c in ["DC007_1","DC007_2","DC007_3","DC007_4","DC007_5"]:
                if c in hcols: hs_want.append(c)

        # CES-D (2011/2013: DC009-DC018; 2020: DC016-DC025)
        # 2018 CES-D is in Cognition.dta — handled separately
        if wave in [2011, 2013]:
            for i in range(9, 19):
                c = f"DC0{i:02d}"
                if c in hcols: hs_want.append(c)
        elif wave == 2020:
            for i in range(16, 26):
                c = f"DC0{i:02d}"
                if c in hcols: hs_want.append(c)

        hs_keys = [c for c in ["ID","HOUSEHOLDID","COMMUNITYID"] if c in hcols]
        hs_sub = hs[hs_keys + hs_want].drop_duplicates("ID")
        dem = dem.merge(hs_sub, on=[k for k in hs_keys if k in dem.columns], how="left")
        log.info("W%d after HealthStatus merge: %d rows", wave, len(dem))

    # ── Health_Care_and_Insurance (NOT in 2020) ────────────────
    hci_path = find_file(wd, "Health_Care_and_Insurance.dta",
                         "health_care_and_insurance.dta")
    if hci_path is not None:
        hci, _ = pyreadstat.read_dta(str(hci_path))
        hci.columns = [c.upper() for c in hci.columns]
        hci_want = []
        if wave in [2011, 2013]:
            hci_want = [c for c in [f"EA001S{i}" for i in range(1, 11)]
                        if c in hci.columns]
        else:
            hci_want = [c for c in [f"EA001_W4_S{i}" for i in range(1, 13)]
                        if c in hci.columns]
        hci_keys = [c for c in ["ID","HOUSEHOLDID","COMMUNITYID"] if c in hci.columns]
        hci_sub = hci[hci_keys + hci_want].drop_duplicates("ID")
        dem = dem.merge(hci_sub, on=[k for k in hci_keys if k in dem.columns], how="left")
        log.info("W%d after HealthInsurance merge: %d rows", wave, len(dem))
    else:
        log.info("W%d: No Health_Care_and_Insurance (2020) — HEALTH_INSURED=NaN", wave)

    # ── Family_Information (grandchild care) ───────────────────
    fi_path = find_file(wd, "Family_Information.dta", "family_information.dta")
    if fi_path is not None:
        fi, _ = pyreadstat.read_dta(str(fi_path))
        fi.columns = [c.upper() for c in fi.columns]
        fi_want = [c for c in fi.columns if c == "CF001"]
        fi_keys = [c for c in ["ID","HOUSEHOLDID","COMMUNITYID"] if c in fi.columns]
        if fi_want:
            fi_sub = fi[fi_keys + fi_want].drop_duplicates("ID")
            dem = dem.merge(fi_sub, on=[k for k in fi_keys if k in dem.columns],
                            how="left", suffixes=("", "_FI"))

    # ── Household_Income ──────────────────────────────────────
    hi_path = find_file(wd, "Household_Income.dta", "household_income.dta")
    if hi_path is not None:
        hi, _ = pyreadstat.read_dta(str(hi_path))
        hi.columns = [c.upper() for c in hi.columns]
        # Try named total income variable
        total_var = next((c for c in ["GH_INCOME","HHNETINCOME","GH001","GH002",
                                       "TOTAL_INCOME","TOTALINCOME"]
                          if c in hi.columns), None)
        if total_var:
            hi_sub = (hi[["HOUSEHOLDID", total_var]]
                      .drop_duplicates("HOUSEHOLDID")
                      .rename(columns={total_var: "HH_INCOME_RAW"}))
        else:
            # Sum member wage amounts
            if wave in [2011, 2013, 2018]:
                wage_cols = [c for c in hi.columns if c.startswith("GA006_1_")
                             and not c.endswith("_MIN") and not c.endswith("_MAX")]
                if not wage_cols:
                    wage_cols = [c for c in hi.columns if c.startswith("GA006_W4_")
                                 and not c.endswith("_MIN") and not c.endswith("_MAX")]
            else:  # 2020: GB003_N_ = amount per member
                wage_cols = [c for c in hi.columns
                             if c.startswith("GB003_") and not c.endswith("_MIN")
                             and not c.endswith("_MAX") and c.count("_") <= 2]
            if wage_cols:
                tmp = hi[["HOUSEHOLDID"] + wage_cols].copy()
                for wc in wage_cols:
                    tmp[wc] = pd.to_numeric(tmp[wc], errors="coerce")
                hh = tmp.groupby("HOUSEHOLDID")[wage_cols].sum(min_count=1)
                hh["HH_INCOME_RAW"] = hh[wage_cols].sum(axis=1, min_count=1)
                hi_sub = hh[["HH_INCOME_RAW"]].reset_index()
                log.info("W%d income: summed %d wage cols", wave, len(wage_cols))
            else:
                log.warning("W%d: No income columns found", wave)
                hi_sub = None
        if hi_sub is not None:
            dem = dem.merge(hi_sub, on="HOUSEHOLDID", how="left")

    # ── Load Cognition module for 2018 ─────────────────────────
    if wave == 2018:
        cog = load_cognition_2018(log)
        if len(cog) > 1:
            # Pull CES-D (DC009-DC018), orientation, word recall, serial 7
            cog_want = []
            ccols = set(cog.columns)
            for c in ["DC001_W4","DC002_W4","DC003_W4","DC005_W4","DC006_W4"]:
                if c in ccols: cog_want.append(c)
            for i in range(9, 19):
                c = f"DC0{i:02d}"
                if c in ccols: cog_want.append(c)
            # Word recall immediate (3-word: DC013_W4_1_S1/S2/S3)
            for s in range(1, 4):
                c = f"DC013_W4_1_S{s}"
                if c in ccols: cog_want.append(c)
            # Word recall delayed (DC028_W4_SN — 10 words from delayed list)
            for i in range(1, 11):
                c = f"DC028_W4_S{i}"
                if c in ccols: cog_want.append(c)
            # Serial 7 (DC014_W4_N and DC014_W4_N_1 for specific results)
            for i in range(1, 6):
                for c in [f"DC014_W4_{i}", f"DC014_W4_{i}_1"]:
                    if c in ccols: cog_want.append(c)
            cog_sub = cog[["ID"] + cog_want].drop_duplicates("ID")
            dem = dem.merge(cog_sub, on="ID", how="left")
            log.info("W2018 after Cognition merge: %d rows", len(dem))

    return dem


# ─────────────────────────────────────────────────────────────
#   4. CONSTRUCT ANALYSIS VARIABLES
# ─────────────────────────────────────────────────────────────

def _to_num(series):
    return pd.to_numeric(series, errors="coerce")


def _get(df, col):
    return _to_num(df.get(col, pd.Series(float("nan"), index=df.index)))


def construct_vars(df: pd.DataFrame, wave: int, log) -> pd.DataFrame:

    # ── Caregiving screening ───────────────────────────────────
    if wave in [2011, 2013]:
        if "CF004" in df.columns:
            df["IS_CAREGIVER_RAW"] = (_to_num(df["CF004"]) == 1).astype(float)
        else:
            df["IS_CAREGIVER_RAW"] = float("nan")
    elif wave == 2018:
        cf4_cols = [c for c in df.columns if c.startswith("CF004_W4")]
        if cf4_cols:
            df["IS_CAREGIVER_RAW"] = (
                df[cf4_cols].apply(pd.to_numeric, errors="coerce").eq(1).any(axis=1)
            ).astype(float)
        else:
            df["IS_CAREGIVER_RAW"] = float("nan")
    else:  # 2020 — filled from prior waves after stacking
        df["IS_CAREGIVER_RAW"] = float("nan")

    # ── Care hours / intensity (only 2011/2013/2018 Family_Transfer) ──
    if wave in [2011, 2013]:
        hrs_cols = ["CF005_2","CF005_4","CF005_6","CF005_8"]
        wks_cols = ["CF005_1","CF005_3","CF005_5","CF005_7"]
        total_hrs = pd.Series(0.0, index=df.index)
        total_ann = pd.Series(0.0, index=df.index)
        has_care  = pd.Series(False, index=df.index)
        for h, w in zip(hrs_cols, wks_cols):
            hv = _to_num(df.get(h, pd.Series(float("nan"), index=df.index)))
            wv = _to_num(df.get(w, pd.Series(float("nan"), index=df.index)))
            valid = hv.notna() & hv.gt(0)
            has_care |= valid
            total_hrs = total_hrs.add(hv.fillna(0))
            total_ann = total_ann.add((hv * wv.fillna(1)).fillna(0))
        df["CARE_HRS_WEEK"]   = total_hrs.where(has_care, float("nan"))
        df["CARE_HRS_ANNUAL"] = total_ann.where(has_care, float("nan"))
    elif wave == 2018:
        hrs_cols = sorted([c for c in df.columns if c.startswith("CF005_W4_2")])
        wks_cols = sorted([c for c in df.columns if c.startswith("CF005_W4_1")])
        total_hrs = pd.Series(0.0, index=df.index)
        total_ann = pd.Series(0.0, index=df.index)
        has_care  = pd.Series(False, index=df.index)
        for h in hrs_cols:
            idx = h.replace("CF005_W4_2","CF005_W4_1")
            hv = _to_num(df.get(h, pd.Series(float("nan"), index=df.index)))
            wv = _to_num(df.get(idx, pd.Series(float("nan"), index=df.index)))
            valid = hv.notna() & hv.gt(0)
            has_care |= valid
            total_hrs = total_hrs.add(hv.fillna(0))
            total_ann = total_ann.add((hv * wv.fillna(1)).fillna(0))
        df["CARE_HRS_WEEK"]   = total_hrs.where(has_care, float("nan"))
        df["CARE_HRS_ANNUAL"] = total_ann.where(has_care, float("nan"))
    else:  # 2020
        df["CARE_HRS_WEEK"]   = float("nan")
        df["CARE_HRS_ANNUAL"] = float("nan")

    def _intensity(h):
        if pd.isna(h): return float("nan")
        return 1.0 if h < 10 else (2.0 if h < 20 else 3.0)

    df["CARE_INTENSITY"] = df["CARE_HRS_WEEK"].apply(_intensity)
    df["LN_CARE_HRS"] = df["CARE_HRS_ANNUAL"].apply(
        lambda x: math.log(x) if (pd.notna(x) and x > 0) else float("nan"))

    # ── Grandchild care ────────────────────────────────────────
    if "CF001" in df.columns:
        df["CARE_GRANDCHILD"] = (_to_num(df["CF001"]) == 1).astype(float)
    else:
        df["CARE_GRANDCHILD"] = float("nan")

    # ── Employment outcomes ─────────────────────────────────────
    if wave in [2011, 2013]:
        df["NON_AGRI_EMPLOY"] = (
            (_get(df,"FA002")==1) | (_get(df,"FC014")==1) |
            (_get(df,"FA003")==1) | (_get(df,"FC015")==1)
        ).astype(float)
        df["AGRI_EMPLOY"] = (_get(df,"FC001") == 1).astype(float)
    elif wave == 2018:
        df["NON_AGRI_EMPLOY"] = (
            (_get(df,"FA002_W4")==1) | (_get(df,"FA003")==1)
        ).astype(float)
        df["AGRI_EMPLOY"] = (_get(df,"FC001") == 1).astype(float)
    else:  # 2020
        # FA004=1 has nonfarm work; FA005=1 on leave from nonfarm job
        # FA002_S2 notna = employed (hired) for farm work = agricultural wage labor
        df["NON_AGRI_EMPLOY"] = (
            (_get(df,"FA004")==1) | (_get(df,"FA005")==1)
        ).astype(float)
        # FA002_S2 coding: 2=farm employed (hired by others), 0=not, NaN=not asked
        df["AGRI_EMPLOY"] = (_get(df, "FA002_S2") == 2).astype(float)
        log.info("W2020 NON_AGRI_EMPLOY=1: %d", int(df["NON_AGRI_EMPLOY"].sum()))
        log.info("W2020 AGRI_EMPLOY=1: %d",     int(df["AGRI_EMPLOY"].sum()))

    # ── Demographics ───────────────────────────────────────────
    # Gender
    gender_ok = False
    if wave == 2020:
        # XRGENDER: 1=male, 2=female
        xg = _to_num(df.get("XRGENDER", pd.Series(float("nan"), index=df.index)))
        if xg.notna().any():
            df["GENDER"] = (xg == 1).astype(float)
            df.loc[xg.isna(), "GENDER"] = float("nan")
            gender_ok = True
    else:
        for gcol in ["RGENDER","XRGENDER"]:
            if gcol in df.columns:
                v = _to_num(df[gcol])
                if v.nunique() > 1:
                    df["GENDER"] = (v == 1).astype(float)
                    gender_ok = True
                    break
    if not gender_ok:
        df["GENDER"] = float("nan")
        log.warning("W%d: Gender not found (will fill from baseline)", wave)

    # Age
    if wave == 2020:
        by_pref = ["ZRBIRTHYEAR","BA003_1"]
    elif wave == 2018:
        by_pref = ["BA004_W3_1","BA002_1","ZBA002_1"]
    elif wave == 2013:
        by_pref = ["ZBA002_1","BA002_1"]
    else:
        by_pref = ["BA002_1","ZBA002_1"]

    birth_yr = pd.Series(float("nan"), index=df.index)
    for bc in by_pref:
        if bc in df.columns:
            birth_yr = birth_yr.fillna(_to_num(df[bc]))
    if birth_yr.notna().any():
        df["AGE"] = wave - birth_yr
    else:
        df["AGE"] = float("nan")
        log.warning("W%d: Birth year not found", wave)
    log.info("W%d AGE: %d non-null", wave, df["AGE"].notna().sum())

    # Hukou (urban=1)
    # 2020: BA009 (1=agri, 2=non-agri, 3=unified)
    # 2011/2013: BC001/ZBC001 (1=agri, 2=non-agri)
    if wave == 2020:
        hk = _to_num(df.get("BA009", pd.Series(float("nan"), index=df.index)))
        df["HUKOU"] = (hk == 2).astype(float)
        df.loc[hk.isna(), "HUKOU"] = float("nan")
    else:
        hk = pd.Series(float("nan"), index=df.index)
        for hcol in ["ZBC001","BC001"]:
            if hcol in df.columns:
                hk = hk.fillna(_to_num(df[hcol]))
        if hk.notna().any():
            df["HUKOU"] = (hk == 2).astype(float)
            df.loc[hk.isna(), "HUKOU"] = float("nan")
        else:
            df["HUKOU"] = float("nan")
            log.warning("W%d: Hukou not found (will fill from baseline)", wave)
    log.info("W%d HUKOU non-null: %d", wave, df["HUKOU"].notna().sum())

    # Marital (others=1; married in {1,2}=0)
    # 2020: BA011; earlier waves: BE001/ZBE001
    if wave == 2020:
        be = _to_num(df.get("BA011", pd.Series(float("nan"), index=df.index)))
    else:
        be = pd.Series(float("nan"), index=df.index)
        for mc in ["BE001","ZBE001"]:
            if mc in df.columns:
                be = be.fillna(_to_num(df[mc]))
    if be.notna().any():
        df["MARITAL"] = (be > 2).astype(float)
        df.loc[be.isna(), "MARITAL"] = float("nan")
    else:
        df["MARITAL"] = float("nan")

    # Education (middle school and above = 1; threshold >= 5)
    # 2020: ZREDU (preloaded) then BA010; earlier: BD001/ZBD001/BD001_W2_4
    if wave == 2020:
        edu_pref = ["ZREDU","BA010"]
    elif wave == 2013:
        edu_pref = ["ZBD001","BD001","BD001_W2_4"]
    elif wave == 2018:
        edu_pref = ["BD001_W2_4","BD001","ZBD001"]
    else:
        edu_pref = ["BD001","ZBD001","BD001_W2_4"]

    edu_ok = False
    for ecol in edu_pref:
        if ecol in df.columns:
            bd = _to_num(df[ecol])
            if bd.notna().sum() > len(df) * 0.5:
                df["EDUCATION"] = (bd >= 5).astype(float)
                df.loc[bd.isna(), "EDUCATION"] = float("nan")
                edu_ok = True
                log.info("W%d EDUCATION from %s: pct_high=%.1f%%",
                         wave, ecol,
                         100.0 * (bd >= 5).sum() / max(bd.notna().sum(), 1))
                break
    if not edu_ok:
        df["EDUCATION"] = float("nan")
        log.warning("W%d: Education not found", wave)

    # ── Self-rated health ──────────────────────────────────────
    # 2011/2013/2020: DA001 (1=VeryGood→5=VeryPoor → recode 6-x)
    # 2018: DA002 (direct 1-5, same direction as recoded DA001)
    if wave == 2018:
        hcol = "DA002" if "DA002" in df.columns else None
        df["HEALTH_SELF"] = _to_num(df[hcol]) if hcol else float("nan")
    else:
        if "DA001" in df.columns:
            df["HEALTH_SELF"] = 6 - _to_num(df["DA001"])
        else:
            df["HEALTH_SELF"] = float("nan")

    # ── Chronic diseases ──────────────────────────────────────
    # 2011-2018: DA007_N_==1 per disease type; 2020: DA003_N_ non-null = has disease
    if wave in [2011, 2013, 2018]:
        chronic_cols = [f"DA007_{i}_" for i in range(1, 15)
                        if f"DA007_{i}_" in df.columns]
        if chronic_cols:
            df["N_CHRONIC"] = (
                df[chronic_cols].apply(pd.to_numeric, errors="coerce").eq(1).sum(axis=1)
            ).astype(float)
        else:
            df["N_CHRONIC"] = float("nan")
    else:  # 2020 — DA003_N_ coding: 1=yes (diagnosed), 2=no
        dis_cols = [f"DA003_{i}_" for i in range(1, 16) if f"DA003_{i}_" in df.columns]
        if dis_cols:
            df["N_CHRONIC"] = (
                df[dis_cols].apply(pd.to_numeric, errors="coerce").eq(1).sum(axis=1)
            ).astype(float)
        else:
            df["N_CHRONIC"] = float("nan")

    # ── Health insurance ──────────────────────────────────────
    if wave in [2011, 2013]:
        ins_cols = [f"EA001S{i}" for i in range(1, 10) if f"EA001S{i}" in df.columns]
        no_ins   = "EA001S10"
        if ins_cols:
            has_any = df[ins_cols].notna().any(axis=1)
            df["HEALTH_INSURED"] = has_any.astype(float)
            if no_ins in df.columns:
                df.loc[df[no_ins].notna(), "HEALTH_INSURED"] = 0.0
        else:
            df["HEALTH_INSURED"] = float("nan")
    elif wave == 2018:
        ins_cols = [f"EA001_W4_S{i}" for i in range(1, 12)
                    if f"EA001_W4_S{i}" in df.columns]
        no_ins   = "EA001_W4_S12"
        if ins_cols:
            has_any = (df[ins_cols].apply(pd.to_numeric, errors="coerce") != 0).any(axis=1)
            df["HEALTH_INSURED"] = has_any.astype(float)
            if no_ins in df.columns:
                explicitly_uninsureds = _to_num(df[no_ins]) != 0
                df.loc[explicitly_uninsureds, "HEALTH_INSURED"] = 0.0
        else:
            df["HEALTH_INSURED"] = float("nan")
    else:  # 2020 — no insurance module
        df["HEALTH_INSURED"] = float("nan")

    # ── Log household income ──────────────────────────────────
    if "HH_INCOME_RAW" in df.columns:
        hh = pd.to_numeric(df["HH_INCOME_RAW"], errors="coerce")
        df["LN_HH_INCOME"] = hh.apply(
            lambda x: math.log(x) if (pd.notna(x) and x > 0) else float("nan"))
    else:
        df["LN_HH_INCOME"] = float("nan")

    # ── Sleep ─────────────────────────────────────────────────
    for sc in ["DA049","DA049_W4","DA050","DA030"]:
        if sc in df.columns:
            df["SLEEP_HOURS"] = pd.to_numeric(df[sc], errors="coerce")
            break
    else:
        df["SLEEP_HOURS"] = float("nan")

    # ── Social activity ───────────────────────────────────────
    if wave in [2011, 2013]:
        soc_cols = []
        for i in range(1, 12):
            for fmt in [f"DA056S{i}", f"DA056_S{i}"]:
                if fmt in df.columns: soc_cols.append(fmt); break
    elif wave == 2018:
        soc_cols = [f"DA056_S{i}" for i in range(1, 12) if f"DA056_S{i}" in df.columns]
    else:  # 2020
        soc_cols = [f"DA038_S{i}" for i in range(1, 10) if f"DA038_S{i}" in df.columns]

    if soc_cols:
        df["SOCIAL_ACTIVITY"] = (
            df[soc_cols].apply(pd.to_numeric, errors="coerce").eq(1).any(axis=1)
        ).astype(float)
    else:
        df["SOCIAL_ACTIVITY"] = float("nan")

    # ── Pain ─────────────────────────────────────────────────
    if wave in [2011, 2013, 2018]:
        pain_cols = []
        for i in range(1, 16):
            for fmt in [f"DA042S{i}", f"DA042_S{i}"]:
                if fmt in df.columns: pain_cols.append(fmt); break
        pain_sent = next((c for c in ["DA041","DA041_W4"] if c in df.columns), None)
    else:  # 2020
        pain_cols = [f"DA028_S{i}" for i in range(1, 17) if f"DA028_S{i}" in df.columns]
        pain_sent = "DA027" if "DA027" in df.columns else None

    if pain_cols:
        df["N_PAIN_PARTS"] = (
            df[pain_cols].apply(pd.to_numeric, errors="coerce").eq(1).sum(axis=1)
        ).astype(float)
        if pain_sent:
            no_pain = _to_num(df[pain_sent]).eq(0)
            df.loc[no_pain, "N_PAIN_PARTS"] = 0.0
    else:
        df["N_PAIN_PARTS"] = float("nan")

    # ═══════════════════════════════════════════════════════════
    #   NEW HEALTH / HUMAN-CAPITAL OUTCOME VARIABLES
    # ═══════════════════════════════════════════════════════════

    # ── N_ADL: count of basic ADL difficulties (0-6) ──────────
    # Coding: 1=no difficulty, 2=some, 3=great, 4=can't do / don't do
    # Any value >= 2 = has difficulty with that ADL
    if wave in [2011, 2013, 2018]:
        adl_cols = [c for c in ["DB010","DB011","DB012","DB013","DB014","DB015"]
                    if c in df.columns]
    else:  # 2020
        adl_cols = [c for c in ["DB001","DB003","DB005","DB007","DB009","DB011"]
                    if c in df.columns]
    if adl_cols:
        _adl_num = df[adl_cols].apply(pd.to_numeric, errors="coerce")
        _adl_tested = _adl_num.notna().any(axis=1)
        df["N_ADL"] = _adl_num.ge(2).sum(axis=1).where(_adl_tested, float("nan")).astype(float)
        log.info("W%d N_ADL: mean=%.2f, n_nonmiss=%d",
                 wave, df["N_ADL"].mean(), df["N_ADL"].notna().sum())
    else:
        df["N_ADL"] = float("nan")
        log.warning("W%d: ADL columns not found", wave)

    # ── N_IADL: count of IADL difficulties (0-5 or 0-6) ──────
    # 2011/2013/2018: DB016-DB020 (5 items)
    # 2020: DB012,14,16,18,20,22 (6 items — includes phone calls DB018)
    if wave in [2011, 2013, 2018]:
        iadl_cols = [c for c in ["DB016","DB017","DB018","DB019","DB020"]
                     if c in df.columns]
    else:
        iadl_cols = [c for c in ["DB012","DB014","DB016","DB018","DB020","DB022"]
                     if c in df.columns]
    if iadl_cols:
        _iadl_num = df[iadl_cols].apply(pd.to_numeric, errors="coerce")
        _iadl_tested = _iadl_num.notna().any(axis=1)
        df["N_IADL"] = _iadl_num.ge(2).sum(axis=1).where(_iadl_tested, float("nan")).astype(float)
        log.info("W%d N_IADL: mean=%.2f, n_nonmiss=%d",
                 wave, df["N_IADL"].mean(), df["N_IADL"].notna().sum())
    else:
        df["N_IADL"] = float("nan")
        log.warning("W%d: IADL columns not found", wave)

    # ── COGN_ORIENT: orientation score (0-5) ─────────────────
    # 2011/2013: DC001S1=1(year✓)/NaN(wrong), DC001S2=2(month✓)/NaN,
    #             DC001S3=3(day✓)/NaN — use notna() for these three
    #            DC002={1=correct,2=wrong}, DC003={1=correct,2=wrong} — use eq(1)
    # 2018: DC001_W4 etc. — 1=correct, 5=wrong, 97=DK — use eq(1)
    # 2020: DC001-DC005 — 1=correct, 2=wrong, 997/999=DK — use eq(1)
    if wave in [2011, 2013]:
        # DC001S1/S2/S3 use N-as-value-when-correct / NaN when wrong
        dc_date = [c for c in ["DC001S1","DC001S2","DC001S3"] if c in df.columns]
        # DC002/DC003: 1=correct, 2=wrong
        dc_other = [c for c in ["DC002","DC003"] if c in df.columns]
        all_orient = dc_date + dc_other
        if all_orient:
            num = df[all_orient].apply(pd.to_numeric, errors="coerce")
            tested = num.notna().any(axis=1)
            # date items: notna()=correct; other items: eq(1)=correct
            date_score  = num[dc_date].notna().sum(axis=1)  if dc_date  else pd.Series(0, index=df.index)
            other_score = num[dc_other].eq(1).sum(axis=1)   if dc_other else pd.Series(0, index=df.index)
            df["COGN_ORIENT"] = (date_score + other_score).where(tested, float("nan")).astype(float)
        else:
            df["COGN_ORIENT"] = float("nan")
    elif wave == 2018:
        orient_cols = [c for c in ["DC001_W4","DC002_W4","DC003_W4","DC005_W4","DC006_W4"]
                       if c in df.columns]
        if orient_cols:
            num = df[orient_cols].apply(pd.to_numeric, errors="coerce")
            tested = num.notna().any(axis=1)
            df["COGN_ORIENT"] = num.eq(1).sum(axis=1).where(tested, float("nan")).astype(float)
        else:
            df["COGN_ORIENT"] = float("nan")
    else:  # 2020: DC001-DC005 — 1=correct, 2=wrong, 997/999=DK
        orient_cols = [c for c in ["DC001","DC002","DC003","DC004","DC005"]
                       if c in df.columns]
        if orient_cols:
            num = df[orient_cols].apply(pd.to_numeric, errors="coerce")
            tested = num.notna().any(axis=1)
            df["COGN_ORIENT"] = num.eq(1).sum(axis=1).where(tested, float("nan")).astype(float)
        else:
            df["COGN_ORIENT"] = float("nan")

    # ── COGN_WORD_RECALL: immediate word recall score ─────────
    # NaN for respondents not tested. Score = words correctly recalled.
    # 2011: DC006SN — multi-select null=not-selected/notna=recalled (value=1 always)
    # 2013: DC006_1_SN — first-trial immediate recall (same pattern)
    # 2018: DC013_W4_1_S1/S2/S3 — 3-word test (0=not recalled, 1=recalled); max=3
    #        NOTE: different instrument/scale from other waves — see codebook
    # 2020: DC012_SN — 0=not recalled, 1=recalled; max=10
    def _recall_notna(df, cols):
        num = df[cols].apply(pd.to_numeric, errors="coerce")
        tested = num.notna().any(axis=1)
        return num.notna().sum(axis=1).where(tested, float("nan")).astype(float)

    def _recall_ne0(df, cols):
        """Columns use N-as-value-when-selected, 0=not-selected. Count non-zero."""
        num = df[cols].apply(pd.to_numeric, errors="coerce")
        tested = num.notna().any(axis=1)
        return num.ne(0).sum(axis=1).where(tested, float("nan")).astype(float)

    def _recall_eq1_binary(df, cols):
        """Columns are binary 0/1 where 1=recalled. Count =1."""
        num = df[cols].apply(pd.to_numeric, errors="coerce")
        tested = num.notna().any(axis=1)
        return num.eq(1).sum(axis=1).where(tested, float("nan")).astype(float)

    if wave == 2011:
        # DC006SN: value=N when selected (notna=recalled)
        wr_cols = [f"DC006S{i}" for i in range(1, 11) if f"DC006S{i}" in df.columns]
        df["COGN_WORD_RECALL"] = _recall_notna(df, wr_cols) if wr_cols else float("nan")
    elif wave == 2013:
        # DC006_1_SN: first-trial, same notna pattern
        wr_cols = [f"DC006_1_S{i}" for i in range(1, 11)
                   if f"DC006_1_S{i}" in df.columns]
        df["COGN_WORD_RECALL"] = _recall_notna(df, wr_cols) if wr_cols else float("nan")
    elif wave == 2018:
        # DC013_W4_1_SN: 3-word test, binary 0=not/1=yes
        wr_18 = [f"DC013_W4_1_S{i}" for i in range(1, 4)
                 if f"DC013_W4_1_S{i}" in df.columns]
        df["COGN_WORD_RECALL"] = _recall_eq1_binary(df, wr_18) if wr_18 else float("nan")
    else:  # 2020: DC012_SN uses N-as-value-when-selected, 0=not
        wr_cols = [f"DC012_S{i}" for i in range(1, 11)
                   if f"DC012_S{i}" in df.columns]
        df["COGN_WORD_RECALL"] = _recall_ne0(df, wr_cols) if wr_cols else float("nan")

    # ── COGN_WORD_DELAYED: delayed recall score ───────────────
    # 2011/2013: DC027SN — notna()=recalled (value=N when selected)
    # 2018: DC028_W4_SN — N-as-value-when-recalled, 0=not (same as 2020 immediate)
    # 2020: DC028_SN — N-as-value-when-recalled, 0=not
    if wave in [2011, 2013]:
        del_cols = [f"DC027S{i}" for i in range(1, 11) if f"DC027S{i}" in df.columns]
        df["COGN_WORD_DELAYED"] = _recall_notna(df, del_cols) if del_cols else float("nan")
    elif wave == 2018:
        del_18 = [f"DC028_W4_S{i}" for i in range(1, 11)
                  if f"DC028_W4_S{i}" in df.columns]
        df["COGN_WORD_DELAYED"] = _recall_ne0(df, del_18) if del_18 else float("nan")
    else:  # 2020
        del_cols = [f"DC028_S{i}" for i in range(1, 11)
                    if f"DC028_S{i}" in df.columns]
        df["COGN_WORD_DELAYED"] = _recall_ne0(df, del_cols) if del_cols else float("nan")

    # ── COGN_SERIAL7: serial-subtraction score (0-5) ──────────
    # 2011/2013: DC019-DC023 store actual arithmetic result;
    #   correct if DC019=93, DC020=86, DC021=79, DC022=72, DC023=65
    # 2018: DC014_W4_N — NaN means respondent gave a specific answer;
    #   97/98 (DK/refused) mean incorrect. Use isna() as proxy for correct.
    #   NOTE: isna() overestimates; researchers should treat with caution.
    # 2020: DC007_N — 1=correct, 997/999=DK/refused
    SERIAL7_EXPECTED = {
        "DC019": 93, "DC020": 86, "DC021": 79, "DC022": 72, "DC023": 65,
    }
    if wave in [2011, 2013]:
        s7_scores = pd.Series(0.0, index=df.index)
        s7_any = pd.Series(False, index=df.index)
        for col, exp in SERIAL7_EXPECTED.items():
            if col in df.columns:
                vals = _to_num(df[col])
                s7_any |= vals.notna()
                s7_scores = s7_scores.add((vals == exp).astype(float).fillna(0))
        df["COGN_SERIAL7"] = s7_scores.where(s7_any, float("nan"))
    elif wave == 2018:
        # DC014_W4_1 through DC014_W4_5: NaN = gave answer (assume correct)
        s7_scores = pd.Series(0.0, index=df.index)
        s7_any = pd.Series(False, index=df.index)
        for i in range(1, 6):
            col = f"DC014_W4_{i}"
            if col in df.columns:
                vals = _to_num(df[col])
                present = df[col].notna() | (vals.isna() &
                          df.get(f"DC014_W4_{i}_1",
                                 pd.Series(float("nan"), index=df.index)).notna())
                s7_any |= (df[col].notna() | df.get(
                    f"DC014_W4_{i}_1",
                    pd.Series(float("nan"), index=df.index)).notna())
                s7_scores = s7_scores.add(vals.isna().astype(float))
        df["COGN_SERIAL7"] = s7_scores.where(s7_any, float("nan"))
    else:  # 2020
        s7_cols = [f"DC007_{i}" for i in range(1, 6)
                   if f"DC007_{i}" in df.columns]
        if s7_cols:
            any_answered = df[s7_cols].apply(pd.to_numeric, errors="coerce").notna().any(axis=1)
            df["COGN_SERIAL7"] = (
                df[s7_cols].apply(pd.to_numeric, errors="coerce").eq(1).sum(axis=1)
            ).where(any_answered, float("nan")).astype(float)
        else:
            df["COGN_SERIAL7"] = float("nan")

    # ── DEPRESSION_CESD: CES-D 10 score (0-30) ───────────────
    # 2011/2013: DC009-DC018; 2018: DC009-DC018 (from Cognition.dta, merged above)
    # 2020: DC016-DC025
    # Coding: 1=rarely/none, 2=sometimes, 3=often, 4=most of time → subtract 1 → 0-3
    # Reverse-score positive items: DC013/DC016 (hopeful/happy) in 2011-2018;
    #                               DC020/DC023 (hopeful/happy) in 2020
    if wave in [2011, 2013, 2018]:
        cesd_cols = [f"DC0{i:02d}" for i in range(9, 19) if f"DC0{i:02d}" in df.columns]
        rev_items  = {"DC013", "DC016"}
    else:  # 2020
        cesd_cols = [f"DC0{i:02d}" for i in range(16, 26) if f"DC0{i:02d}" in df.columns]
        rev_items  = {"DC020", "DC023"}

    if len(cesd_cols) >= 8:
        cesd_df = df[cesd_cols].apply(pd.to_numeric, errors="coerce")
        # Recode out-of-range values (8/9/997/999) to NaN
        cesd_df = cesd_df.where(cesd_df.apply(lambda s: s.between(1, 4)), other=float("nan"))
        # Shift to 0-3
        cesd_df = cesd_df - 1
        # Reverse positive items
        for rc in rev_items:
            if rc in cesd_df.columns:
                cesd_df[rc] = 3 - cesd_df[rc]
        # Sum only if at least 8 of 10 items non-null
        n_valid = cesd_df.notna().sum(axis=1)
        df["DEPRESSION_CESD"] = cesd_df.sum(axis=1, skipna=False).where(
            n_valid >= 8, other=float("nan"))
        log.info("W%d DEPRESSION_CESD: %d non-null (%.1f%%)",
                 wave, df["DEPRESSION_CESD"].notna().sum(),
                 100.0 * df["DEPRESSION_CESD"].notna().mean())
    else:
        df["DEPRESSION_CESD"] = float("nan")
        log.warning("W%d: CES-D items found: %d / 10 — setting DEPRESSION_CESD=NaN",
                    wave, len(cesd_cols))

    return df


# ─────────────────────────────────────────────────────────────
#   5. MAIN PIPELINE
# ─────────────────────────────────────────────────────────────

def main():
    log = get_logger("charls_13", "charls_13_ext_subsample.log")
    log.info("=== charls_13_ltci_ext_subsample.py START ===")
    log.info("Waves: %s", WAVES)

    # Step 1: Community → city mapping (PSU 2011/2013 only)
    city_map = build_city_map(log)

    all_waves = []
    for wave in WAVES:
        df = load_wave(wave, log)
        df = construct_vars(df, wave, log)

        comm_col = "COMMUNITYID"
        if comm_col in df.columns:
            df = df.merge(city_map[["COMMUNITYID","IS_LTCI_CITY","IS_QINGDAO"]],
                          on=comm_col, how="left")
        else:
            df["IS_LTCI_CITY"] = float("nan")
            df["IS_QINGDAO"]   = float("nan")
            log.warning("W%d: COMMUNITYID not found", wave)

        all_waves.append(df)
        log.info("W%d loaded: %d rows", wave, len(df))

    # Step 2: Stack all waves
    panel = pd.concat(all_waves, ignore_index=True)
    log.info("Stacked panel: %d rows", len(panel))

    # Step 3: Fill time-invariant demographics from 2011 baseline
    baseline_gender = (panel[panel["WAVE"] == 2011][["ID","GENDER"]]
                       .dropna(subset=["GENDER"]).drop_duplicates("ID"))
    baseline_hukou  = (panel[panel["WAVE"] == 2011][["ID","HUKOU"]]
                       .dropna(subset=["HUKOU"]).drop_duplicates("ID"))

    for col, bl in [("GENDER", baseline_gender), ("HUKOU", baseline_hukou)]:
        n_miss_before = int(panel[col].isna().sum())
        if n_miss_before > 0:
            panel = panel.merge(bl.rename(columns={col: "_FILL"}), on="ID", how="left")
            to_fill = panel[col].isna() & panel["_FILL"].notna()
            panel.loc[to_fill, col] = panel.loc[to_fill, "_FILL"]
            panel.drop(columns=["_FILL"], inplace=True)
            log.info("Filled %s from 2011 baseline: %d rows (%d still missing)",
                     col, n_miss_before - int(panel[col].isna().sum()),
                     int(panel[col].isna().sum()))

    # Step 4: Fill 2020 caregiving from "ever caregiver" in prior waves
    # An individual is treated as a caregiver in 2020 if they were identified
    # as a caregiver (CF004/CF004_W4 == 1) in ANY of 2011, 2013, 2018.
    ever_caregiver = (
        panel[panel["WAVE"].isin([2011, 2013, 2018]) & (panel["IS_CAREGIVER_RAW"] == 1)]
        [["ID"]].drop_duplicates()
        .assign(_EVER_CG=1)
    )
    panel = panel.merge(ever_caregiver, on="ID", how="left")
    mask_2020_missing = (panel["WAVE"] == 2020) & panel["IS_CAREGIVER_RAW"].isna()
    panel.loc[mask_2020_missing & (panel["_EVER_CG"] == 1), "IS_CAREGIVER_RAW"] = 1.0
    panel.loc[mask_2020_missing & (panel["_EVER_CG"].isna()), "IS_CAREGIVER_RAW"] = 0.0
    panel.drop(columns=["_EVER_CG"], inplace=True)
    n_2020_cg = int((panel[(panel["WAVE"]==2020) & (panel["IS_CAREGIVER_RAW"]==1)].shape[0]))
    log.info("2020 wave: %d observations assigned IS_CAREGIVER_RAW=1 (ever-caregiver rule)",
             n_2020_cg)

    # Step 5: Filter to caregivers
    before = len(panel)
    panel = panel[panel["IS_CAREGIVER_RAW"] == 1].copy()
    log_filter(log, "keep informal caregivers (IS_CAREGIVER_RAW==1)", before, len(panel))

    # Step 6: TREAT and POST
    panel["TREAT"] = panel["IS_LTCI_CITY"].fillna(0).astype(int)

    def assign_post(row):
        if row["TREAT"] == 0:
            return 0
        w = row["WAVE"]
        if row["IS_QINGDAO"] == 1:
            return 1 if w >= 2013 else 0
        else:
            # All other LTCI cities: POST=1 starting 2018;
            # By 2020 all 12 pilot cities have active LTCI programs
            return 1 if w >= 2018 else 0

    panel["POST"]         = panel.apply(assign_post, axis=1)
    panel["TREAT_X_POST"] = panel["TREAT"] * panel["POST"]

    log.info("Treatment summary:")
    log.info("  TREAT=1: %d  TREAT=0: %d",
             int((panel["TREAT"]==1).sum()), int((panel["TREAT"]==0).sum()))
    log.info("  POST=1: %d   POST=0: %d",
             int((panel["POST"]==1).sum()),  int((panel["POST"]==0).sum()))
    log.info("  DiD (TREAT×POST=1): %d", int((panel["TREAT_X_POST"]==1).sum()))

    # Step 7: Select final columns
    final_cols = [
        "ID", "HOUSEHOLDID", "COMMUNITYID", "WAVE",
        # Outcomes (original)
        "NON_AGRI_EMPLOY", "AGRI_EMPLOY",
        # Treatment
        "TREAT", "POST", "TREAT_X_POST", "IS_LTCI_CITY", "IS_QINGDAO",
        # Demographics
        "GENDER", "AGE", "HUKOU", "MARITAL", "EDUCATION",
        # Health controls
        "HEALTH_SELF", "N_CHRONIC", "HEALTH_INSURED",
        # Caregiving controls
        "CARE_GRANDCHILD", "CARE_INTENSITY", "LN_HH_INCOME",
        # Care mechanism
        "LN_CARE_HRS", "CARE_HRS_WEEK",
        # Existing mechanism variables
        "SLEEP_HOURS", "SOCIAL_ACTIVITY", "N_PAIN_PARTS", "DEPRESSION_CESD",
        # NEW: ADL / IADL functional limitations
        "N_ADL", "N_IADL",
        # NEW: Cognition
        "COGN_WORD_RECALL", "COGN_WORD_DELAYED", "COGN_SERIAL7", "COGN_ORIENT",
        # Flag
        "IS_CAREGIVER_RAW",
    ]
    existing = [c for c in final_cols if c in panel.columns]
    missing_cols = [c for c in final_cols if c not in panel.columns]
    if missing_cols:
        log.warning("Missing final columns: %s", missing_cols)
    panel = panel[existing].copy()

    # Step 8: Log missing rates
    log.info("=== Missing rates ===")
    for col in sorted(panel.columns):
        n_miss = int(panel[col].isna().sum())
        if n_miss > 0:
            log.info("  %-30s missing: %d / %d (%.1f%%)",
                     col, n_miss, len(panel), 100.0 * n_miss / len(panel))

    # Step 9: Drop rows where BOTH employment outcomes are missing
    both_miss = panel["NON_AGRI_EMPLOY"].isna() & panel["AGRI_EMPLOY"].isna()
    before = len(panel)
    panel = panel[~both_miss].copy()
    log_filter(log, "drop rows with BOTH outcomes missing", before, len(panel))

    # Step 10: Descriptive statistics
    log.info("=== Wave breakdown ===")
    log.info("\n%s", panel.groupby("WAVE")[["ID"]].count().to_string())
    log.info("=== Treatment breakdown ===")
    log.info("\n%s",
             panel.groupby("TREAT")[
                 ["NON_AGRI_EMPLOY","AGRI_EMPLOY","GENDER","AGE","EDUCATION"]
             ].mean().round(3).to_string())
    log.info("=== New variable summary ===")
    for col in ["N_ADL","N_IADL","COGN_WORD_RECALL","COGN_WORD_DELAYED",
                "COGN_SERIAL7","COGN_ORIENT","DEPRESSION_CESD"]:
        if col in panel.columns:
            s = panel[col]
            n = s.notna().sum()
            log.info("  %-25s N=%d  mean=%.3f  sd=%.3f  min=%.0f  max=%.0f",
                     col, n, s.mean(), s.std(), s.min(), s.max())

    # Step 11: Save
    PROC_DIR.mkdir(parents=True, exist_ok=True)
    out_pq  = PROC_DIR / "charls_ltci_ext_subsample.parquet"
    out_csv = PROC_DIR / "charls_ltci_ext_subsample.csv"
    write_parquet(panel, out_pq, log=log)
    panel.to_csv(str(out_csv), index=False)
    log.info("CSV saved: %s  (%d rows × %d cols)", out_csv.name, len(panel), len(panel.columns))

    log.info("=== charls_13_ltci_ext_subsample.py SUCCESS ===")
    log.info("Extended subsample: %d observations (4 waves: 2011/2013/2018/2020)", len(panel))


if __name__ == "__main__":
    main()
