from __future__ import annotations

import re
from datetime import date
from typing import Any

from fastapi import HTTPException

from src.backend.clients.ehospital_client import (
    execute_ehospital_select,
    write_ehospital_table_row,
)


def patient_response(row: dict[str, Any]) -> dict[str, Any]:
    return {
        "patient_id": row.get("patient_id"),
        "name": row.get("name") or f"Patient {row.get('patient_id')}",
    }


async def select_rows(sql: str, replacements: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    payload = await execute_ehospital_select(sql, replacements)
    rows = payload.get("data", [])
    return rows if isinstance(rows, list) else []


async def create_row(table_name: str, payload: dict[str, Any]) -> dict[str, Any]:
    response = await write_ehospital_table_row(table_name, payload)
    created = response.get("data", response) if isinstance(response, dict) else {}
    return created if isinstance(created, dict) else {}


async def create_patient_from_request(
    *,
    name: str,
    gender: str | None = None,
    email: str | None = None,
    phone: str | None = None,
    age: int | None = None,
) -> dict[str, Any]:
    clean_name = name.strip()
    if not clean_name:
        raise HTTPException(status_code=400, detail="Patient name is required")
    if age is not None and (age < 0 or age > 130):
        raise HTTPException(status_code=400, detail="Patient age must be between 0 and 130")

    payload: dict[str, Any] = {"name": clean_name}
    if gender and gender.strip():
        payload["gender"] = gender.strip()
    if email and email.strip():
        payload["contact_info"] = email.strip()
    if phone and phone.strip():
        payload["phone_number"] = phone.strip()
    if age is not None:
        payload["dob"] = f"{date.today().year - age}-01-01"
    return await create_row("patients_registration", payload)


async def list_patients() -> list[dict[str, Any]]:
    rows = await select_rows(
        """
        SELECT patient_id, name
        FROM patients_registration
        WHERE patient_id IS NOT NULL
        ORDER BY name ASC, patient_id ASC
        LIMIT 200
        """
    )
    return [patient_response(row) for row in rows if isinstance(row, dict)]


async def find_patient_by_name(name: str) -> dict[str, Any] | None:
    rows = await select_rows(
        """
        SELECT patient_id, name
        FROM patients_registration
        WHERE LOWER(name) = LOWER(:name)
        ORDER BY patient_id DESC
        LIMIT 1
        """,
        {"name": name},
    )
    return rows[0] if rows else None


async def find_patient_by_id(patient_id: int) -> dict[str, Any]:
    rows = await select_rows(
        """
        SELECT patient_id, name
        FROM patients_registration
        WHERE patient_id = :patient_id
        LIMIT 1
        """,
        {"patient_id": patient_id},
    )
    if rows:
        return patient_response(rows[0])
    return {"patient_id": patient_id, "name": f"Patient {patient_id}"}


async def find_or_create_patient_by_name(
    name: str,
    *,
    dob: str | None = None,
    gender: str | None = None,
    contact_info: str | None = None,
) -> dict[str, Any]:
    clean_name = re.sub(r"\s+", " ", name).strip()
    if not clean_name:
        raise HTTPException(status_code=400, detail="Patient name is required")
    existing = await find_patient_by_name(clean_name)
    if existing:
        return patient_response(existing)
    created = await create_row(
        "patients_registration",
        {
            "name": clean_name,
            "dob": dob or "1900-01-01",
            "gender": gender or "Unknown",
            "contact_info": contact_info or "Unknown",
        },
    )
    return patient_response(created)


def extract_patient_name(text: str) -> str | None:
    patterns = [
        r"\bpatient\s+name\s*[:\-]\s*(?P<name>[A-Za-z][A-Za-z .,'-]{1,80})",
        r"\bpatient\s*[:\-]\s*(?P<name>[A-Za-z][A-Za-z .,'-]{1,80})",
        r"\bname\s*[:\-]\s*(?P<name>[A-Za-z][A-Za-z .,'-]{1,80})",
    ]
    stop_words = re.compile(
        r"\b(date|dob|birth|age|gender|sex|id|health|report|specimen|collected|received)\b",
        re.IGNORECASE,
    )
    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if not match:
            continue
        name = re.split(r"\s{2,}|\t|\||,", match.group("name").strip(), maxsplit=1)[0]
        name = re.sub(r"\s+", " ", name).strip(" .:-")
        if len(name) >= 2 and not stop_words.search(name):
            return name
    return None


def extract_patient_dob(text: str) -> str | None:
    dob_patterns = [
        r"\b(?:date\s+of\s+birth|birth\s+date|dob)\s*[:\-]\s*(?P<date>\d{4}[-/]\d{1,2}[-/]\d{1,2})",
        r"\b(?:date\s+of\s+birth|birth\s+date|dob)\s*[:\-]\s*(?P<date>\d{1,2}[-/]\d{1,2}[-/]\d{2,4})",
    ]
    for pattern in dob_patterns:
        match = re.search(pattern, text, re.IGNORECASE)
        if not match:
            continue
        parsed = _parse_date(match.group("date"))
        if parsed:
            return parsed
    return None


def _parse_date(raw: str) -> str | None:
    parts = raw.replace("/", "-").split("-")
    if len(parts) != 3:
        return None
    try:
        if len(parts[0]) == 4:
            year, month, day = int(parts[0]), int(parts[1]), int(parts[2])
        else:
            month, day, year = int(parts[0]), int(parts[1]), int(parts[2])
            if year < 100:
                year += 2000
        return date(year, month, day).isoformat()
    except ValueError:
        return None


async def resolve_report_patient(report_text: str) -> dict[str, Any] | None:
    extracted_name = extract_patient_name(report_text)
    if not extracted_name:
        return None
    return await find_or_create_patient_by_name(
        extracted_name,
        dob=extract_patient_dob(report_text),
    )


async def save_lab_values_for_patient(
    patient_id: int | None,
    lab_values: list[dict[str, Any]],
    report_date: str,
    detected_test_type: str = "blood",
) -> dict[str, Any]:
    if patient_id is None:
        return {"count": 0, "errors": ["No patient ID was available for saving."]}

    if detected_test_type == "eye":
        return await _save_eye_record(patient_id, lab_values, report_date)
    if detected_test_type == "lab":
        return await _save_generic_lab_records(patient_id, lab_values, report_date)
    return await _save_blood_records(patient_id, lab_values, report_date)


async def _save_eye_record(
    patient_id: int,
    lab_values: list[dict[str, Any]],
    report_date: str,
) -> dict[str, Any]:
    score = next((value for value in lab_values if value.get("name") == "Vision Score"), None)
    follow_up = next((value for value in lab_values if value.get("unit") == "status"), None)
    payload = {
        "patient_id": patient_id,
        "test_date": report_date,
        "test_type": follow_up.get("name") if follow_up else "Eye Exam",
        "result": follow_up.get("display") if follow_up else "Recorded",
        "vision_metric": "Vision Score" if score else None,
        "vision_score": f"{score.get('value'):g}/{score.get('normalMax'):g}" if score else None,
        "comments": follow_up.get("display") if follow_up else "",
    }
    payload = {key: value for key, value in payload.items() if value is not None}
    try:
        await create_row("eye_test", payload)
        return {"count": 1, "errors": []}
    except Exception as exc:
        return {"count": 0, "errors": [f"Could not save parsed eye record: {exc}"]}


async def _save_generic_lab_records(
    patient_id: int,
    lab_values: list[dict[str, Any]],
    report_date: str,
) -> dict[str, Any]:
    saved_count = 0
    errors: list[str] = []
    for value in lab_values:
        payload = {
            "patient_id": patient_id,
            "test_date": report_date,
            "test_type": value.get("name") or "Lab Test",
            "result": value.get("display") or f"{value.get('value')} {value.get('unit', '')}".strip(),
            "status": value.get("status", "recorded"),
            "sample_type": "Uploaded report",
            "lab_location": "",
            "comments": (
                f"Reference: {value.get('normalMin')}-{value.get('normalMax')} {value.get('unit', '')}".strip()
                if value.get("unit") != "status"
                else value.get("display", "")
            ),
        }
        try:
            await create_row("lab_tests", payload)
            saved_count += 1
        except Exception as exc:
            errors.append(f"Could not save parsed lab value {value.get('name')}: {exc}")
    return {"count": saved_count, "errors": errors}


async def _save_blood_records(
    patient_id: int,
    lab_values: list[dict[str, Any]],
    report_date: str,
) -> dict[str, Any]:
    saved_count = 0
    errors: list[str] = []
    for value in lab_values:
        if value.get("unit") == "status":
            continue
        payload = {
            "patient_id": patient_id,
            "test_name": value["name"],
            "result_value": str(value["value"]),
            "unit": value.get("unit") or "",
            "normal_range": f"{value['normalMin']}-{value['normalMax']}",
            "test_date": report_date,
        }
        try:
            await create_row("bloodtests", payload)
            saved_count += 1
        except Exception as exc:
            errors.append(f"Could not save parsed blood value {value['name']}: {exc}")
    return {"count": saved_count, "errors": errors}
