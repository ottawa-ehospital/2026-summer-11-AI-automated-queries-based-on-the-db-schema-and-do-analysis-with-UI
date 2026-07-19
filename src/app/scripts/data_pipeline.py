"""
Smart Health App — Automated Data Pipeline
Fetches all 8 tables from the eHospital API, normalizes them, joins
wearable + clinical data by patient_id, computes per-patient stats,
and exports a summary CSV to data/patient_summary.csv.

Usage:
    pip install -r requirements.txt
    python data_pipeline.py
"""

import os
import sys
import requests
import pandas as pd

BASE_URL = "https://aetab8pjmb.us-east-1.awsapprunner.com/table"

TABLES = [
    "wearable_vitals",
    "vitals_history",
    "ecg",
    "diabetes_analysis",
    "heart_disease_analysis",
    "stroke_prediction",
    "lab_tests",
    "diagnosis",
]

OUTPUT_DIR = os.path.join(os.path.dirname(__file__), "..", "data")
OUTPUT_FILE = os.path.join(OUTPUT_DIR, "patient_summary.csv")


# ── Fetch helpers ──────────────────────────────────────────────────────────────

def fetch_table(table_name: str) -> pd.DataFrame:
    """Download a table from the API and return as a DataFrame."""
    url = f"{BASE_URL}/{table_name}"
    print(f"  Fetching {url} ...", end=" ", flush=True)
    try:
        resp = requests.get(url, timeout=30)
        resp.raise_for_status()
        data = resp.json().get("data", [])
        df = pd.DataFrame(data)
        print(f"OK  ({len(df)} rows)")
        return df
    except Exception as exc:
        print(f"FAILED ({exc})")
        return pd.DataFrame()


# ── Normalization helpers ──────────────────────────────────────────────────────

def normalize_patient_id(df: pd.DataFrame) -> pd.DataFrame:
    """Ensure patient_id is a nullable integer column."""
    if "patient_id" in df.columns:
        df["patient_id"] = pd.to_numeric(df["patient_id"], errors="coerce").astype("Int64")
    return df


def standardize_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Lowercase and strip column names."""
    df.columns = [c.strip().lower() for c in df.columns]
    return df


def parse_timestamps(df: pd.DataFrame) -> pd.DataFrame:
    """Parse any column that looks like a timestamp into datetime."""
    ts_candidates = ["timestamp", "recorded_on", "test_date", "analysis_date", "diagnosed_on", "analyzed_on"]
    for col in ts_candidates:
        if col in df.columns:
            df[col] = pd.to_datetime(df[col], errors="coerce", utc=True)
    return df


def fill_nulls(df: pd.DataFrame) -> pd.DataFrame:
    """Fill numeric nulls with 0 and string nulls with empty string."""
    for col in df.columns:
        if df[col].dtype == object:
            df[col] = df[col].fillna("")
        else:
            df[col] = df[col].fillna(0)
    return df


def normalize(df: pd.DataFrame) -> pd.DataFrame:
    df = standardize_columns(df)
    df = normalize_patient_id(df)
    df = parse_timestamps(df)
    df = fill_nulls(df)
    return df


# ── Per-patient stats ──────────────────────────────────────────────────────────

def compute_wearable_stats(wearable: pd.DataFrame) -> pd.DataFrame:
    """Mean HR, HR spike count (>100 bpm)."""
    if wearable.empty or "patient_id" not in wearable.columns:
        return pd.DataFrame(columns=["patient_id", "mean_hr_wearable", "hr_spike_count"])

    wearable = wearable.copy()
    wearable["heart_rate"] = pd.to_numeric(wearable.get("heart_rate", 0), errors="coerce").fillna(0)

    stats = (
        wearable.groupby("patient_id")
        .agg(
            mean_hr_wearable=("heart_rate", "mean"),
            hr_spike_count=("heart_rate", lambda x: (x > 100).sum()),
        )
        .reset_index()
    )
    stats["mean_hr_wearable"] = stats["mean_hr_wearable"].round(1)
    return stats


def compute_diabetes_stats(diabetes: pd.DataFrame) -> pd.DataFrame:
    """Average glucose level per patient."""
    if diabetes.empty or "patient_id" not in diabetes.columns:
        return pd.DataFrame(columns=["patient_id", "avg_glucose"])

    diabetes = diabetes.copy()
    diabetes["glucose_level"] = pd.to_numeric(diabetes.get("glucose_level", 0), errors="coerce").fillna(0)

    stats = (
        diabetes.groupby("patient_id")
        .agg(avg_glucose=("glucose_level", "mean"))
        .reset_index()
    )
    stats["avg_glucose"] = stats["avg_glucose"].round(1)
    return stats


def compute_heart_disease_stats(heart: pd.DataFrame) -> pd.DataFrame:
    """Max risk score per patient."""
    if heart.empty or "patient_id" not in heart.columns:
        return pd.DataFrame(columns=["patient_id", "max_risk_score"])

    heart = heart.copy()
    heart["risk_score"] = pd.to_numeric(heart.get("risk_score", 0), errors="coerce").fillna(0)

    stats = (
        heart.groupby("patient_id")
        .agg(max_risk_score=("risk_score", "max"))
        .reset_index()
    )
    stats["max_risk_score"] = stats["max_risk_score"].round(3)
    return stats


def get_latest_ecg(ecg: pd.DataFrame) -> pd.DataFrame:
    """Most recent ECG result per patient."""
    if ecg.empty or "patient_id" not in ecg.columns:
        return pd.DataFrame(columns=["patient_id", "latest_ecg_result"])

    ecg = ecg.copy()
    ecg = ecg.sort_values("recorded_on", ascending=False, na_position="last")
    latest = ecg.groupby("patient_id").first().reset_index()[["patient_id", "ecg_result"]]
    latest = latest.rename(columns={"ecg_result": "latest_ecg_result"})
    return latest


# ── Main pipeline ──────────────────────────────────────────────────────────────

def main():
    print("=== Smart Health Data Pipeline ===\n")

    # 1. Fetch all tables
    print("[1] Fetching tables...")
    raw = {name: fetch_table(name) for name in TABLES}

    # 2. Normalize
    print("\n[2] Normalizing tables...")
    tables = {name: normalize(df) for name, df in raw.items()}

    # Alias wearable_vitals (some deployments expose it as-is)
    wearable = tables.get("wearable_vitals", pd.DataFrame())
    if wearable.empty:
        # Fallback: some APIs serve it under a different key
        print("  wearable_vitals empty — trying vitals_history as fallback for HR")
        wearable = tables.get("vitals_history", pd.DataFrame())

    # 3. Compute per-patient stats
    print("\n[3] Computing per-patient statistics...")
    w_stats = compute_wearable_stats(wearable)
    d_stats = compute_diabetes_stats(tables.get("diabetes_analysis", pd.DataFrame()))
    h_stats = compute_heart_disease_stats(tables.get("heart_disease_analysis", pd.DataFrame()))
    ecg_latest = get_latest_ecg(tables.get("ecg", pd.DataFrame()))

    print(f"  Wearable stats:       {len(w_stats)} patients")
    print(f"  Diabetes stats:       {len(d_stats)} patients")
    print(f"  Heart disease stats:  {len(h_stats)} patients")
    print(f"  ECG latest:           {len(ecg_latest)} patients")

    # 4. Join all stats by patient_id
    print("\n[4] Joining datasets...")
    summary = w_stats.copy()
    for df in [d_stats, h_stats, ecg_latest]:
        if not df.empty:
            summary = summary.merge(df, on="patient_id", how="outer")

    # Add stroke prediction stats (actual column is risk_score, NOT a binary prediction field)
    stroke = tables.get("stroke_prediction", pd.DataFrame())
    if not stroke.empty and "patient_id" in stroke.columns:
        stroke["risk_score"] = pd.to_numeric(stroke.get("risk_score", 0), errors="coerce").fillna(0)
        stroke_stats = stroke.groupby("patient_id").agg(
            stroke_max_risk_score=("risk_score", "max"),
            stroke_high_risk_count=("risk_score", lambda x: (x >= 0.5).sum()),
        ).reset_index()
        stroke_stats["stroke_max_risk_score"] = stroke_stats["stroke_max_risk_score"].round(3)
        summary = summary.merge(stroke_stats, on="patient_id", how="outer")

    # Sort by patient_id
    if not summary.empty and "patient_id" in summary.columns:
        summary = summary.sort_values("patient_id").reset_index(drop=True)

    print(f"  Final summary: {len(summary)} rows × {len(summary.columns)} columns")

    # 5. Export
    print(f"\n[5] Exporting to {OUTPUT_FILE} ...")
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    summary.to_csv(OUTPUT_FILE, index=False)
    print(f"  Done! Saved {len(summary)} patient records.\n")

    print("=== Pipeline complete ===")
    print(summary.to_string(max_rows=20))


if __name__ == "__main__":
    main()
