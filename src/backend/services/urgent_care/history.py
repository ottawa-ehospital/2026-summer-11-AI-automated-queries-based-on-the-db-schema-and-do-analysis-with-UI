from __future__ import annotations

from typing import Any

from fastapi import HTTPException

from src.backend.clients.ehospital_client import execute_ehospital_select, fetch_ehospital_table

from .constants import FEEDBACK_TABLE, HEALTHCARE_RECORDS_TABLE


async def fetch_patient_history(patient_id: int, limit: int = 5) -> list[dict[str, Any]]:
    history_rows: list[dict[str, Any]] = []
    try:
        record_rows = await _select_healthcare_records(patient_id, limit)
        record_ids: list[int] = []
        for row in record_rows:
            row["_history_source"] = "healthcare_record"
            history_rows.append(row)
            if row.get("record_id") is not None:
                record_ids.append(int(row["record_id"]))
        for record_id in record_ids[:limit]:
            for row in await _select_feedback(record_id, limit):
                row["_history_source"] = "feedback"
                history_rows.append(row)
        return history_rows
    except HTTPException:
        return await _fallback_history_table_scan(patient_id, limit)


async def _select_healthcare_records(patient_id: int, limit: int) -> list[dict[str, Any]]:
    payload = await execute_ehospital_select(
        (
            f"SELECT * FROM {HEALTHCARE_RECORDS_TABLE} "
            "WHERE patient_id = :patient_id "
            "ORDER BY check_in_time DESC "
            "LIMIT :limit"
        ),
        {"patient_id": patient_id, "limit": limit},
    )
    rows = payload.get("data", [])
    return rows if isinstance(rows, list) else []


async def _select_feedback(record_id: int, limit: int) -> list[dict[str, Any]]:
    payload = await execute_ehospital_select(
        (
            f"SELECT * FROM {FEEDBACK_TABLE} "
            "WHERE record_id = :record_id "
            "ORDER BY created_time DESC "
            "LIMIT :limit"
        ),
        {"record_id": record_id, "limit": limit},
    )
    rows = payload.get("data", [])
    return rows if isinstance(rows, list) else []


async def _fallback_history_table_scan(patient_id: int, limit: int) -> list[dict[str, Any]]:
    history_rows: list[dict[str, Any]] = []
    feedback_rows = await fetch_ehospital_table(FEEDBACK_TABLE)
    record_rows = await fetch_ehospital_table(HEALTHCARE_RECORDS_TABLE)
    record_ids: set[str] = set()
    for row in record_rows:
        if str(row.get("patient_id")) == str(patient_id):
            row["_history_source"] = "healthcare_record"
            history_rows.append(row)
            record_ids.add(str(row.get("record_id")))
    for row in feedback_rows:
        if str(row.get("record_id")) in record_ids:
            row["_history_source"] = "feedback"
            history_rows.append(row)
    return history_rows[: limit * 2]
