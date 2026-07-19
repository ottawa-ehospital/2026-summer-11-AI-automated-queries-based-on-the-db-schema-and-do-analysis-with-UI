from __future__ import annotations

from dataclasses import asdict
from typing import Any

from .constants import (
    CTAS_LEVELS,
    QUEUE_EMERGENCY,
    QUEUE_NON_URGENT,
    QUEUE_NORMAL,
    STATUS_COMPLETED,
    STATUS_CONSULTATION,
    STATUS_WAITING,
    ctas_label,
)
from .records import UrgentCareVisit, load_active_visits, load_completed_visits
from .time import now_iso, parse_dt


def waiting_minutes(visit: UrgentCareVisit) -> int:
    start = parse_dt(visit.checked_in_at)
    end = parse_dt(visit.consultation_started_at) if visit.consultation_started_at else parse_dt(None)
    return max(0, int((end - start).total_seconds() // 60))


def serialize_visit(visit: UrgentCareVisit) -> dict[str, Any]:
    row = asdict(visit)
    row["urgency_label"] = ctas_label(visit.ctas_level)
    row["waiting_minutes"] = waiting_minutes(visit)
    return row


def sort_queue(visits: list[UrgentCareVisit]) -> list[UrgentCareVisit]:
    return sorted(
        visits,
        key=lambda visit: (visit.ctas_level, -visit.risk_score, parse_dt(visit.checked_in_at)),
    )


def queue_prioritization_agent(visits: list[UrgentCareVisit]) -> dict[str, list[dict[str, Any]]]:
    queues: dict[str, list[UrgentCareVisit]] = {
        QUEUE_EMERGENCY: [],
        QUEUE_NORMAL: [],
        QUEUE_NON_URGENT: [],
    }
    for visit in visits:
        if visit.status not in (STATUS_WAITING, STATUS_CONSULTATION):
            continue
        queues.setdefault(visit.queue_name, []).append(visit)
    return {name: [serialize_visit(visit) for visit in sort_queue(rows)] for name, rows in queues.items()}


def summary_payload(active: list[UrgentCareVisit], completed: list[UrgentCareVisit]) -> dict[str, Any]:
    ctas_counts = {str(level): 0 for level in CTAS_LEVELS}
    for visit in active + completed:
        ctas_counts[str(visit.ctas_level)] += 1
    total_patients = len(active) + len(completed)
    return {
        "total": total_patients,
        "total_patients": total_patients,
        "waiting": sum(1 for visit in active if visit.status == STATUS_WAITING),
        "in_consultation": sum(1 for visit in active if visit.status == STATUS_CONSULTATION),
        "completed": len(completed),
        "ctas_counts": ctas_counts,
    }


def patient_access_token(visit: UrgentCareVisit) -> str:
    return f"patient-{visit.id}-{visit.patient_id}"


def estimated_wait_range(patients_ahead: int) -> str:
    low = patients_ahead * 10
    high = low + 15
    if patients_ahead == 0:
        return "Soon / next available"
    return f"{low}-{high} minutes"


async def patient_status_payload(visit: UrgentCareVisit) -> dict[str, Any]:
    active = await load_active_visits()
    queue_number = None
    patients_ahead = 0
    if visit.status != STATUS_COMPLETED:
        global_queue = sort_queue(
            [row for row in active if row.status in (STATUS_WAITING, STATUS_CONSULTATION)]
        )
        for index, row in enumerate(global_queue, start=1):
            if row.id == visit.id:
                queue_number = index
                patients_ahead = max(0, index - 1)
                break

    return {
        "local_patient_id": visit.id,
        "patient_id": visit.patient_id,
        "queue_number": queue_number,
        "status": visit.status,
        "patients_ahead": patients_ahead,
        "estimated_wait_range": estimated_wait_range(patients_ahead),
        "notified": bool(visit.notified_at) or visit.status == STATUS_CONSULTATION,
        "notified_at": visit.notified_at,
        "checked_in_at": visit.checked_in_at,
        "server_time": now_iso(),
        "access_token": patient_access_token(visit),
        "submitted_information": {
            "name": visit.name,
            "age": visit.age,
            "symptoms": visit.symptoms,
            "medical_history": visit.medical_history,
            "ctas_urgency_level": visit.ctas_level,
            "risk_score": visit.risk_score,
            "queue_name": visit.queue_name,
            "clinical_summary": visit.clinical_summary,
            "recommended_action": visit.recommended_action,
        },
    }


async def queues_response() -> dict[str, Any]:
    active = await load_active_visits()
    completed = await load_completed_visits()
    return {
        "summary": summary_payload(active, completed),
        "queues": queue_prioritization_agent(active),
    }


async def patients_response() -> dict[str, Any]:
    active = await load_active_visits()
    completed = await load_completed_visits()
    return {
        "active": [serialize_visit(visit) for visit in active],
        "completed": [serialize_visit(visit) for visit in completed],
    }
