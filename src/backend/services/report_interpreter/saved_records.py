from __future__ import annotations

from typing import Any

from fastapi import HTTPException

from src.backend.services.report_interpreter.constants import (
    DATABASE_RECORD_TYPES,
    TEST_TYPE_BY_ID,
)
from src.backend.services.report_interpreter.patients import select_rows
from src.backend.services.report_interpreter.utils import format_date_value


def get_test_types() -> list[dict[str, str]]:
    return DATABASE_RECORD_TYPES


def require_test_type(test_type: str) -> dict[str, str]:
    config = TEST_TYPE_BY_ID.get(test_type)
    if not config:
        raise HTTPException(status_code=400, detail="Invalid test type")
    return config


async def get_test_dates(test_type: str, patient_id: int) -> list[str]:
    config = require_test_type(test_type)
    rows = await select_rows(
        f"""
        SELECT DISTINCT {config["dateField"]} AS test_date
        FROM {config["table"]}
        WHERE patient_id = :patient_id AND {config["dateField"]} IS NOT NULL
        ORDER BY {config["dateField"]} DESC
        """,
        {"patient_id": patient_id},
    )
    return [format_date_value(row.get("test_date")) for row in rows if row.get("test_date")]


async def get_tests_by_type_and_date(
    test_type: str,
    test_date: str,
    patient_id: int,
) -> dict[str, Any]:
    config = require_test_type(test_type)
    tests = await select_rows(
        f"""
        SELECT *
        FROM {config["table"]}
        WHERE patient_id = :patient_id AND {config["dateField"]} = :test_date
        ORDER BY {config["dateField"]} DESC
        """,
        {"patient_id": patient_id, "test_date": test_date},
    )
    if not tests:
        raise HTTPException(status_code=404, detail="No saved records found")
    return _format_saved_record(test_type, test_date, tests)


def _format_saved_record(test_type: str, test_date: str, tests: list[dict[str, Any]]) -> dict[str, Any]:
    if test_type == "blood":
        lines = [f"Blood Test Results - Date: {test_date}\n", "-" * 50]
        for row in tests:
            lines.append(
                f"{row.get('test_name')}: {row.get('result_value')} {row.get('unit')} "
                f"(Normal: {row.get('normal_range')})"
            )
        return {"formattedText": "\n".join(lines), "testType": "Blood Test"}

    if test_type == "eye":
        lines = [f"Eye Test Results - Date: {test_date}\n", "-" * 50]
        for row in tests:
            lines.extend(
                [
                    f"Test Type: {row.get('test_type')}",
                    f"Result: {row.get('result')}",
                    f"Vision: {row.get('vision_metric')} (Score: {row.get('vision_score')})",
                ]
            )
            if row.get("comments"):
                lines.append(f"Comments: {row.get('comments')}")
            lines.append("")
        return {"formattedText": "\n".join(lines), "testType": "Eye Test"}

    if test_type == "lab":
        lines = [f"Lab Test Results - Date: {test_date}\n", "-" * 50]
        for row in tests:
            lines.extend(
                [
                    f"Test: {row.get('test_type')}",
                    f"Result: {row.get('result')}",
                    f"Status: {row.get('status')}",
                    f"Sample Type: {row.get('sample_type')}",
                    f"Lab Location: {row.get('lab_location')}",
                ]
            )
            if row.get("comments"):
                lines.append(f"Comments: {row.get('comments')}")
            lines.append("")
        return {"formattedText": "\n".join(lines), "testType": "Lab Test"}

    if test_type == "diagnosis":
        lines = [f"Diagnosis Records - Date: {test_date}\n", "-" * 50]
        for row in tests:
            lines.extend(
                [
                    f"Code: {row.get('diagnosis_code')}",
                    f"Description: {row.get('diagnosis_description')}",
                    "",
                ]
            )
        return {"formattedText": "\n".join(lines), "testType": "Diagnosis"}

    if test_type == "tumor":
        lines = [f"Tumor Records - Date: {test_date}\n", "-" * 50]
        for row in tests:
            lines.extend(
                [
                    f"Type: {row.get('tumor_type')}",
                    f"Location: {row.get('location')}",
                    f"Size: {row.get('size_cm')} cm",
                    f"Status: {row.get('status')}",
                ]
            )
            if row.get("notes"):
                lines.append(f"Notes: {row.get('notes')}")
            lines.append("")
        return {"formattedText": "\n".join(lines), "testType": "Tumor Record"}

    raise HTTPException(status_code=400, detail="Invalid test type")
