from __future__ import annotations

from dataclasses import asdict, dataclass, field
from datetime import datetime
from typing import Any

from fastapi import HTTPException

from src.backend.clients.ehospital_client import (
    execute_ehospital_select,
    fetch_ehospital_table,
    update_ehospital_table_row,
    write_ehospital_table_row,
)

from .constants import (
    FEEDBACK_TABLE,
    HEALTHCARE_RECORDS_TABLE,
    LEGACY_COMPLETED_STATUS,
    MEDICAL_HISTORY_TABLE,
    PATIENTS_REGISTRATION_TABLE,
    STATUS_COMPLETED,
    STATUS_WAITING,
    fallback_risk_score_from_ctas,
    queue_name_for_ctas,
)
from .time import now_database_text, now_iso, parse_dt


SUMMARY_REASONING_SEPARATOR = "\n\nReasoning:\n"


@dataclass
class UrgentCareVisit:
    id: int
    patient_id: int
    name: str
    age: int
    symptoms: str
    medical_history: str
    ctas_level: int
    risk_score: int
    queue_name: str
    clinical_summary: str
    reasoning: str
    recommended_action: str
    status: str = STATUS_WAITING
    checked_in_at: str = field(default_factory=now_iso)
    consultation_started_at: str | None = None
    completed_at: str | None = None
    notified_at: str | None = None


def age_from_dob(dob: str | None) -> int:
    if not dob:
        return 0
    try:
        birth_date = datetime.fromisoformat(str(dob).split("T")[0])
    except ValueError:
        return 0
    today = datetime.now()
    return max(
        0,
        today.year
        - birth_date.year
        - ((today.month, today.day) < (birth_date.month, birth_date.day)),
    )


def approximate_dob_from_age(age: int) -> str:
    return f"{datetime.now().year - age}-01-01"


async def load_patient_registration_map() -> dict[int, dict[str, Any]]:
    rows = await fetch_ehospital_table(PATIENTS_REGISTRATION_TABLE)
    profiles: dict[int, dict[str, Any]] = {}
    for row in rows:
        try:
            profiles[int(row.get("patient_id"))] = row
        except (TypeError, ValueError):
            continue
    return profiles


async def load_medical_history_notes_map() -> dict[int, str]:
    rows = await fetch_ehospital_table(MEDICAL_HISTORY_TABLE)
    latest_rows: dict[int, dict[str, Any]] = {}
    for row in rows:
        try:
            patient_id = int(row.get("patient_id"))
        except (TypeError, ValueError):
            continue
        notes = str(row.get("notes") or "").strip()
        if not notes:
            continue
        current = latest_rows.get(patient_id)
        current_time = parse_dt(current.get("last_updated") or current.get("diagnosis_date")) if current else None
        row_time = parse_dt(row.get("last_updated") or row.get("diagnosis_date"))
        if current is None or (current_time is not None and row_time >= current_time):
            latest_rows[patient_id] = row
    return {patient_id: str(row.get("notes") or "").strip() for patient_id, row in latest_rows.items()}


async def ensure_patient_registration(
    patient_id: int,
    name: str,
    age: int,
    gender: str,
) -> dict[str, Any]:
    profiles = await load_patient_registration_map()
    if patient_id in profiles:
        return {"registered": True, "created": False, "patient": profiles[patient_id]}

    normalized_gender = gender if gender in {"Male", "Female", "Other"} else "Other"
    payload = {
        "patient_id": patient_id,
        "name": name.strip(),
        "dob": approximate_dob_from_age(age),
        "gender": normalized_gender,
        "contact_info": "Not provided",
    }
    try:
        result = await write_ehospital_table_row(PATIENTS_REGISTRATION_TABLE, payload)
    except HTTPException as exc:
        return {
            "registered": False,
            "created": False,
            "error": exc.detail,
            "attempted_payload": payload,
        }
    return {"registered": True, "created": True, "database_response": result}


def pack_summary_with_reasoning(summary: str, reasoning: str) -> str:
    summary = summary.strip()
    reasoning = reasoning.strip()
    if not reasoning:
        return summary
    return f"{summary}{SUMMARY_REASONING_SEPARATOR}{reasoning}"


def unpack_summary_with_reasoning(value: str) -> tuple[str, str]:
    if SUMMARY_REASONING_SEPARATOR not in value:
        return value.strip(), ""
    summary, reasoning = value.split(SUMMARY_REASONING_SEPARATOR, 1)
    return summary.strip(), reasoning.strip()


def visit_from_healthcare_record(
    row: dict[str, Any],
    profile: dict[str, Any] | None = None,
    medical_history_note: str = "",
) -> UrgentCareVisit:
    ctas_level = int(row.get("ctas_urgency_level") or row.get("ctas_level") or 5)
    risk_score = int(row.get("risk_score") or fallback_risk_score_from_ctas(ctas_level))
    record_id = int(row.get("record_id") or row.get("id") or row.get("patient_id") or 0)
    patient_id = int(row.get("patient_id") or record_id)
    profile = profile or {}
    status = str(row.get("status") or STATUS_WAITING)
    if status == LEGACY_COMPLETED_STATUS:
        status = STATUS_COMPLETED
    clinical_summary, stored_reasoning = unpack_summary_with_reasoning(
        str(row.get("clinical_summary") or "")
    )
    recommended_action = str(row.get("recommended_action") or "")
    default_reasoning = (
        f"Clinical decision support report: CTAS Level {ctas_level} with risk score {risk_score}/10. "
        f"Queue assignment: {row.get('queue_name') or queue_name_for_ctas(ctas_level)}. "
        f"Clinical summary: {clinical_summary or 'No clinical summary available.'} "
        f"Recommended staff action: {recommended_action or 'No recommended action available.'} "
        "This is decision support only and should be reviewed by clinical staff."
    )
    return UrgentCareVisit(
        id=record_id,
        patient_id=patient_id,
        name=str(profile.get("name") or row.get("name") or f"Patient {patient_id}"),
        age=age_from_dob(profile.get("dob")) or int(row.get("age") or 0),
        symptoms=str(row.get("symptoms") or ""),
        medical_history=str(row.get("medical_history") or medical_history_note or ""),
        ctas_level=ctas_level,
        risk_score=risk_score,
        queue_name=str(row.get("queue_name") or queue_name_for_ctas(ctas_level)),
        clinical_summary=clinical_summary,
        reasoning=str(row.get("reasoning") or stored_reasoning or default_reasoning),
        recommended_action=recommended_action,
        status=status,
        checked_in_at=str(row.get("check_in_time") or row.get("checked_in_at") or now_iso()),
        consultation_started_at=row.get("consultation_started_at"),
        completed_at=row.get("completed_at"),
        notified_at=row.get("notified_at"),
    )


def visit_to_healthcare_record(visit: UrgentCareVisit) -> dict[str, Any]:
    return {
        "patient_id": visit.patient_id,
        "symptoms": visit.symptoms,
        "ctas_urgency_level": visit.ctas_level,
        "risk_score": visit.risk_score,
        "queue_name": visit.queue_name,
        "status": visit.status,
        "clinical_summary": pack_summary_with_reasoning(visit.clinical_summary, visit.reasoning),
        "recommended_action": visit.recommended_action,
        "check_in_time": visit.checked_in_at,
        "consultation_started_at": visit.consultation_started_at,
        "completed_at": visit.completed_at,
        "notified_at": visit.notified_at,
    }


async def load_healthcare_records() -> list[UrgentCareVisit]:
    try:
        payload = await execute_ehospital_select(
            f"SELECT * FROM {HEALTHCARE_RECORDS_TABLE}",
            {},
        )
        rows = payload.get("data", [])
        if not isinstance(rows, list):
            rows = []
    except HTTPException:
        rows = await fetch_ehospital_table(HEALTHCARE_RECORDS_TABLE)
    profiles = await load_patient_registration_map()
    medical_history_notes = await load_medical_history_notes_map()
    visits: list[UrgentCareVisit] = []
    for row in rows:
        try:
            patient_id = int(row.get("patient_id") or 0)
            visits.append(
                visit_from_healthcare_record(
                    row,
                    profiles.get(patient_id),
                    medical_history_notes.get(patient_id, ""),
                )
            )
        except (TypeError, ValueError):
            continue
    return visits


async def load_active_visits() -> list[UrgentCareVisit]:
    return [visit for visit in await load_healthcare_records() if visit.status != STATUS_COMPLETED]


async def load_completed_visits() -> list[UrgentCareVisit]:
    return [visit for visit in await load_healthcare_records() if visit.status == STATUS_COMPLETED]


async def next_local_id() -> int:
    ids = [visit.id for visit in await load_healthcare_records()]
    return max(ids, default=0) + 1


def find_record_id_in_response(value: Any) -> int | None:
    if isinstance(value, dict):
        for key in ("record_id", "id"):
            if value.get(key) is not None:
                try:
                    return int(value[key])
                except (TypeError, ValueError):
                    pass
        for child in value.values():
            found = find_record_id_in_response(child)
            if found is not None:
                return found
    if isinstance(value, list):
        for item in value:
            found = find_record_id_in_response(item)
            if found is not None:
                return found
    return None


async def create_healthcare_record(visit: UrgentCareVisit) -> dict[str, Any]:
    try:
        result = await write_ehospital_table_row(
            HEALTHCARE_RECORDS_TABLE,
            visit_to_healthcare_record(visit),
        )
        record_id = find_record_id_in_response(result)
        if record_id is not None:
            visit.id = record_id
        return {"saved_to_database": True, "record_id": visit.id, "database_response": result}
    except HTTPException as exc:
        return {"saved_to_database": False, "error": exc.detail}


async def update_healthcare_record(record_id: int, payload: dict[str, Any]) -> dict[str, Any]:
    try:
        result = await update_ehospital_table_row(HEALTHCARE_RECORDS_TABLE, record_id, payload)
        return {"updated_database": True, "database_response": result}
    except HTTPException as exc:
        return {"updated_database": False, "error": exc.detail}


async def save_medical_history_note(visit: UrgentCareVisit) -> dict[str, Any]:
    if not visit.medical_history.strip():
        return {"saved_to_database": False, "skipped": True, "reason": "No medical history provided."}
    now = now_database_text()
    payload = {
        "patient_id": visit.patient_id,
        "diagnosed_by": "Patient self-report",
        "condition": "Patient-reported medical history",
        "status": "Active",
        "severity": "Unspecified",
        "diagnosis_date": now,
        "notes": visit.medical_history,
        "treatment_given": "",
        "followup_required": "false",
        "last_updated": now,
    }
    try:
        result = await write_ehospital_table_row(MEDICAL_HISTORY_TABLE, payload)
        return {"saved_to_database": True, "database_response": result}
    except HTTPException as exc:
        return {"saved_to_database": False, "error": exc.detail}


async def current_record_for_patient(patient_id: int) -> UrgentCareVisit | None:
    matches = [visit for visit in await load_healthcare_records() if visit.patient_id == patient_id]
    if not matches:
        return None
    matches.sort(key=lambda visit: parse_dt(visit.checked_in_at), reverse=True)
    return matches[0]


async def find_visit_anywhere(visit_id: int) -> UrgentCareVisit:
    for visit in await load_healthcare_records():
        if visit.id == visit_id:
            return visit
    raise HTTPException(status_code=404, detail="Patient not found.")


def serialize_visit(visit: UrgentCareVisit) -> dict[str, Any]:
    row = asdict(visit)
    row["urgency_label"] = f"Level {visit.ctas_level}: {visit.queue_name.replace(' Queue', '')}"
    return row
