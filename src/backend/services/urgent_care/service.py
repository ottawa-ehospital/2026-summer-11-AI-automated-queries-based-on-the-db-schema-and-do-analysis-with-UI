from __future__ import annotations

from typing import Any

from fastapi import HTTPException

from src.backend.clients.ehospital_client import fetch_ehospital_table, write_ehospital_table_row
from src.backend.core.config import settings
from src.backend.schemas.urgent_care import (
    UrgentCareFeedbackRequest,
    UrgentCareIntakeRequest,
    UrgentCareWorkflowFeedbackRequest,
)

from .constants import FEEDBACK_TABLE, HEALTHCARE_RECORDS_TABLE, STATUS_COMPLETED, STATUS_CONSULTATION
from .feedback import alert_display_key, feedback_alert_agent
from .history import fetch_patient_history
from .metadata import validate_urgent_care_tables
from .queueing import (
    patient_status_payload,
    patients_response,
    queues_response,
    serialize_visit,
    summary_payload,
)
from .records import (
    UrgentCareVisit,
    create_healthcare_record,
    current_record_for_patient,
    ensure_patient_registration,
    find_visit_anywhere,
    load_active_visits,
    load_completed_visits,
    next_local_id,
    save_medical_history_note,
    update_healthcare_record,
)
from .risk import risk_analysis_agent
from .time import now_database_text, now_iso


async def health_response() -> dict[str, Any]:
    compatibility = await validate_urgent_care_tables()
    return {
        "status": "ok" if compatibility.ready else "degraded",
        "persistence_ready": compatibility.ready,
        "required_tables": compatibility.required_tables,
        "missing_tables": compatibility.missing_tables,
        "missing_fields": compatibility.missing_fields,
        "ai_model_provider": settings.ai_model_provider,
        "ai_model_name": settings.ai_model_name,
    }


async def intake(request: UrgentCareIntakeRequest) -> dict[str, Any]:
    compatibility = await validate_urgent_care_tables()
    if not compatibility.ready:
        raise HTTPException(
            status_code=503,
            detail={
                "error": "Required urgent-care eHospital tables are unavailable.",
                "missing_tables": compatibility.missing_tables,
                "missing_fields": compatibility.missing_fields,
            },
        )

    local_id = await next_local_id()
    database_patient_id = request.patient_id or local_id
    registration_result = await ensure_patient_registration(
        database_patient_id,
        request.name,
        request.age,
        request.gender,
    )
    request_with_id = request.model_copy(update={"patient_id": database_patient_id})
    history_rows = await fetch_patient_history(database_patient_id)
    analysis = risk_analysis_agent(request_with_id, history_rows)
    visit = UrgentCareVisit(
        id=local_id,
        patient_id=database_patient_id,
        name=request.name.strip(),
        age=request.age,
        symptoms=request.symptoms.strip(),
        medical_history=request.medical_history.strip(),
        ctas_level=analysis.ctas_level,
        risk_score=analysis.risk_score,
        queue_name=analysis.queue_name,
        clinical_summary=analysis.clinical_summary,
        reasoning=analysis.reasoning,
        recommended_action=analysis.recommended_action,
        checked_in_at=now_iso(),
    )
    database_result = await create_healthcare_record(visit)
    medical_history_result = await save_medical_history_note(visit)
    active = await load_active_visits()
    if all(row.id != visit.id for row in active):
        active.append(visit)
    completed = await load_completed_visits()
    return {
        "message": "Risk Analysis Agent completed. Queue Prioritization Agent assigned the patient.",
        "patient": serialize_visit(visit),
        "analysis": analysis.model_dump(),
        "queues": (await queues_response())["queues"],
        "summary": summary_payload(active, completed),
        "registration_database": registration_result,
        "database": database_result,
        "medical_history_database": medical_history_result,
        "local_storage": {"saved_locally": False, "skipped": True},
    }


async def customer_check_in(request: UrgentCareIntakeRequest) -> dict[str, Any]:
    result = await intake(request)
    if not result.get("database", {}).get("saved_to_database"):
        raise HTTPException(
            status_code=502,
            detail={
                "error": "Check-in analysis completed, but the visit record was not saved to healthcare_records.",
                "database": result.get("database"),
                "registration_database": result.get("registration_database"),
            },
        )
    patient_row = result["patient"]
    try:
        visit = await find_visit_anywhere(int(patient_row["id"]))
    except HTTPException:
        visit = UrgentCareVisit(**{key: patient_row[key] for key in UrgentCareVisit.__dataclass_fields__ if key in patient_row})
    return {
        "message": "Check-in complete.",
        "patient": await patient_status_payload(visit),
        "analysis": result.get("analysis"),
        "database": result.get("database"),
        "registration_database": result.get("registration_database"),
        "medical_history_database": result.get("medical_history_database"),
    }


async def status_for_visit(visit_id: int) -> dict[str, Any]:
    visit = await find_visit_anywhere(visit_id)
    return {"patient": await patient_status_payload(visit)}


async def history_for_patient(patient_id: int) -> dict[str, Any]:
    return {"patient_id": patient_id, "history": await fetch_patient_history(patient_id)}


async def notify_visit(visit_id: int) -> dict[str, Any]:
    visit = await find_visit_anywhere(visit_id)
    visit.notified_at = now_iso()
    database_result = await update_healthcare_record(
        visit.id,
        {"notified_at": visit.notified_at},
    )
    return {
        "message": "Patient notified.",
        "patient": serialize_visit(visit),
        "database": database_result,
    }


async def start_visit(visit_id: int) -> dict[str, Any]:
    visit = await find_visit_anywhere(visit_id)
    visit.status = STATUS_CONSULTATION
    visit.consultation_started_at = now_iso()
    database_result = await update_healthcare_record(
        visit.id,
        {"status": visit.status, "consultation_started_at": visit.consultation_started_at},
    )
    return {
        "message": "Consultation started.",
        "patient": serialize_visit(visit),
        "database": database_result,
    }


async def complete_visit(visit_id: int) -> dict[str, Any]:
    visit = await find_visit_anywhere(visit_id)
    visit.status = STATUS_COMPLETED
    visit.completed_at = now_iso()
    database_result = await update_healthcare_record(
        visit.id,
        {"status": visit.status, "completed_at": visit.completed_at},
    )
    active = [row for row in await load_active_visits() if row.id != visit_id]
    completed = await load_completed_visits()
    if all(row.id != visit.id for row in completed):
        completed.append(visit)
    return {
        "message": "Patient marked as completed/discharged.",
        "patient": serialize_visit(visit),
        "summary": summary_payload(active, completed),
        "database": database_result,
    }


async def customer_feedback(visit_id: int, payload: UrgentCareFeedbackRequest) -> dict[str, Any]:
    visit = await find_visit_anywhere(visit_id)
    raw_message = payload.message.strip()
    rating = payload.rating.strip() or "Unsure"
    condition_update = payload.condition_update.strip()
    feedback_message = payload.feedback_message.strip()

    if raw_message.startswith("[CONDITION_UPDATE]"):
        condition_update = raw_message.replace("[CONDITION_UPDATE]", "", 1).strip()
    elif raw_message.startswith("[APP_FEEDBACK]"):
        feedback_message = raw_message.replace("[APP_FEEDBACK]", "", 1).strip()
    elif not feedback_message:
        feedback_message = raw_message

    request = UrgentCareWorkflowFeedbackRequest(
        patient_id=visit.patient_id,
        rating=rating,
        message=feedback_message,
        feedback_message=feedback_message,
        condition_update=condition_update,
        ctas_level=visit.ctas_level,
        risk_score=visit.risk_score,
    )
    result = await save_feedback(request)
    return {
        "message": result["alert_agent"].get("patient_message") or "Your update was submitted.",
        "feedback": result.get("feedback"),
        "alert_agent": result.get("alert_agent"),
        "database": result.get("database"),
        "alert": result.get("alert"),
    }


async def save_feedback(request: UrgentCareWorkflowFeedbackRequest) -> dict[str, Any]:
    feedback_text = request.message.strip() or request.feedback_message.strip()
    condition_text = request.condition_update.strip()
    linked_record = await current_record_for_patient(request.patient_id)
    record_id = linked_record.id if linked_record else None
    ctas_level = request.ctas_level or (linked_record.ctas_level if linked_record else None)
    risk_score = request.risk_score or (linked_record.risk_score if linked_record else None)
    alert_request = request.model_copy(update={"ctas_level": ctas_level, "risk_score": risk_score})
    alert = feedback_alert_agent(alert_request)
    database_feedback = {
        "record_id": record_id,
        "rating": request.rating,
        "feedback_message": feedback_text,
        "condition_update": condition_text,
        "alert_required": str(alert.alert_required).lower(),
        "alert_reason": alert.alert_reason,
        "created_time": now_database_text(),
    }
    try:
        database_result = {
            "saved_to_database": True,
            "database_response": await write_ehospital_table_row(FEEDBACK_TABLE, database_feedback),
        }
    except HTTPException as exc:
        database_result = {"saved_to_database": False, "error": exc.detail}

    local_feedback = {
        **database_feedback,
        "risk_score": risk_score,
        "alert_agent": alert.model_dump(),
        "agent_decision_summary": _agent_decision_summary(alert.model_dump()),
    }
    alert_record = None
    if alert.alert_required:
        alert_record = {
            "patient_id": request.patient_id,
            "record_id": record_id,
            "datetime": database_feedback["created_time"],
            "rating": request.rating,
            "ctas_level": ctas_level,
            "risk_score": risk_score,
            "feedback": feedback_text,
            "condition_update": condition_text,
            "agent_decision_summary": _agent_decision_summary(alert.model_dump()),
            **alert.model_dump(),
        }

    return {
        "message": "Feedback saved and analyzed by the Feedback Alert Agent.",
        "feedback": local_feedback,
        "alert_agent": alert.model_dump(),
        "alert": alert_record,
        "database": database_result,
    }


async def feedback_rows() -> dict[str, Any]:
    return {"feedback": await fetch_ehospital_table(FEEDBACK_TABLE)}


async def alerts_response() -> dict[str, Any]:
    rows = await fetch_ehospital_table(FEEDBACK_TABLE)
    records = await fetch_ehospital_table(HEALTHCARE_RECORDS_TABLE)
    patient_by_record = {
        str(row.get("record_id")): row.get("patient_id")
        for row in records
        if row.get("record_id") is not None
    }
    alerts: list[dict[str, Any]] = []
    seen: set[str] = set()
    for row in rows:
        if str(row.get("alert_required")).lower() not in {"true", "1", "yes"}:
            continue
        severity = row.get("alert_severity") or "needs review"
        database_alert = {
            **row,
            "patient_id": patient_by_record.get(str(row.get("record_id")), "Unknown"),
            "severity": severity,
            "alert_severity": severity,
            "alert_reason": row.get("alert_reason", "No alert reason provided."),
            "agent_source": row.get("agent_source", "database_feedback_alert_record"),
            "agent_decision_summary": (
                "Feedback Alert Agent decision: staff alert required. "
                f"Severity: {severity}. "
                f"Reason: {row.get('alert_reason', 'No alert reason provided.')}"
            ),
            "recommended_staff_action": (
                "Ask clinical staff to review this feedback and reassess the patient if needed."
            ),
            "datetime": row.get("created_time"),
            "feedback": row.get("feedback_message", ""),
        }
        key = alert_display_key(database_alert)
        if key not in seen:
            alerts.append(database_alert)
            seen.add(key)
    return {"alerts": alerts}


def _agent_decision_summary(alert: dict[str, Any]) -> str:
    return (
        "Feedback Alert Agent decision: "
        f"{'staff alert required' if alert.get('alert_required') else 'no immediate staff alert required'}. "
        f"Severity: {alert.get('severity')}. Reason: {alert.get('alert_reason')}"
    )


__all__ = [
    "alerts_response",
    "complete_visit",
    "customer_check_in",
    "customer_feedback",
    "feedback_rows",
    "health_response",
    "history_for_patient",
    "intake",
    "notify_visit",
    "patients_response",
    "queues_response",
    "save_feedback",
    "start_visit",
    "status_for_visit",
]
