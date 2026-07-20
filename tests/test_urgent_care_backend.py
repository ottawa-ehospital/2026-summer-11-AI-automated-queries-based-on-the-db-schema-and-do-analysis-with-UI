import asyncio
import sys
from pathlib import Path

from fastapi import HTTPException
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.backend.main import app
from src.backend.schemas.urgent_care import (
    UrgentCareIntakeRequest,
    UrgentCareWorkflowFeedbackRequest,
)
from src.backend.services.urgent_care import feedback, queueing, risk, service
from src.backend.services.urgent_care.constants import QUEUE_EMERGENCY, QUEUE_NON_URGENT
from src.backend.services.urgent_care.metadata import TableCompatibility
from src.backend.services.urgent_care.records import UrgentCareVisit


client = TestClient(app)


def test_urgent_care_routes_registered_and_existing_routes_preserved():
    paths = {route.path for route in app.routes}

    assert "/urgent-care/health" in paths
    assert "/urgent-care/customer/check-in" in paths
    assert "/urgent-care/customer/visits/{visit_id}/status" in paths
    assert "/urgent-care/workflow/queues" in paths
    assert "/assistant/chat" in paths
    assert "/report-interpreter/health" in paths
    assert "/nutrition-monitor/health" in paths
    assert "/wearables/ingest" in paths


def test_urgent_care_health_reports_live_metadata(monkeypatch):
    async def fake_validate():
        return TableCompatibility(
            required_tables={"healthcare_records": ["record_id"]},
            missing_tables=[],
            missing_fields={},
        )

    monkeypatch.setattr(service, "validate_urgent_care_tables", fake_validate)

    response = client.get("/urgent-care/health")

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ok"
    assert body["persistence_ready"] is True
    assert body["required_tables"] == {"healthcare_records": ["record_id"]}


def test_risk_analysis_model_success_uses_shared_model(monkeypatch):
    captured = {}

    def fake_model_json(prompt, system_prompt):
        captured["prompt"] = prompt
        captured["system_prompt"] = system_prompt
        return {
            "ctas_level": 2,
            "risk_score": 9,
            "clinical_summary": "Possible emergent symptoms.",
            "reasoning": "Needs prompt review.",
            "recommended_action": "Move up queue for staff assessment.",
        }

    monkeypatch.setattr(risk, "invoke_model_json", fake_model_json)

    result = risk.risk_analysis_agent(
        UrgentCareIntakeRequest(
            patient_id=20,
            name="Jane Doe",
            age=40,
            symptoms="Chest tightness",
            medical_history="Hypertension",
        ),
        [{"_history_source": "healthcare_record", "symptoms": "prior visit"}],
    )

    assert "Risk Analysis Agent" in captured["prompt"]
    assert result.ctas_level == 2
    assert result.risk_score == 9
    assert result.queue_name == QUEUE_EMERGENCY
    assert result.fallback_used is False


def test_risk_analysis_invalid_model_json_falls_back_to_red_flag(monkeypatch):
    def unavailable_model(*_args, **_kwargs):
        raise HTTPException(status_code=502, detail="model down")

    monkeypatch.setattr(risk, "invoke_model_json", unavailable_model)

    result = risk.risk_analysis_agent(
        UrgentCareIntakeRequest(
            patient_id=20,
            name="Jane Doe",
            age=40,
            symptoms="New chest pain and shortness of breath",
        ),
        [],
    )

    assert result.fallback_used is True
    assert result.ctas_level == 2
    assert result.queue_name == QUEUE_EMERGENCY


def test_feedback_red_flag_fallback_takes_precedence_over_model(monkeypatch):
    def model_says_no_alert(*_args, **_kwargs):
        return {
            "alert_required": False,
            "severity": "none",
            "alert_reason": "No alert.",
            "recommended_staff_action": "Store feedback.",
            "patient_message": "Thanks.",
            "feedback_type": "service_experience",
        }

    monkeypatch.setattr(feedback, "invoke_model_json", model_says_no_alert)

    alert = feedback.feedback_alert_agent(
        UrgentCareWorkflowFeedbackRequest(
            patient_id=20,
            rating="Reasonable",
            message="Queue is fine",
            condition_update="I have chest pain and cannot breathe",
            ctas_level=4,
            risk_score=3,
        )
    )

    assert alert.alert_required is True
    assert alert.severity == "high"
    assert alert.agent_source == "keyword_safety_fallback"


def test_queue_sorting_and_status_payload(monkeypatch):
    low = _visit(id=1, patient_id=20, ctas_level=5, risk_score=1, checked_in_at="2026-07-17T10:00:00")
    high_later = _visit(id=2, patient_id=21, ctas_level=2, risk_score=8, checked_in_at="2026-07-17T10:05:00")
    high_earlier = _visit(id=3, patient_id=22, ctas_level=2, risk_score=9, checked_in_at="2026-07-17T10:01:00")

    queues = queueing.queue_prioritization_agent([low, high_later, high_earlier])

    assert [row["id"] for row in queues[QUEUE_EMERGENCY]] == [3, 2]
    assert [row["id"] for row in queues[QUEUE_NON_URGENT]] == [1]

    async def fake_active():
        return [low, high_later, high_earlier]

    monkeypatch.setattr(queueing, "load_active_visits", fake_active)

    status = asyncio.run(queueing.patient_status_payload(high_later))

    assert status["queue_number"] == 2
    assert status["patients_ahead"] == 1
    assert status["estimated_wait_range"] == "10-25 minutes"
    assert status["submitted_information"]["ctas_urgency_level"] == 2


def test_customer_check_in_missing_symptoms_is_rejected():
    response = client.post(
        "/urgent-care/customer/check-in",
        json={"patient_id": 20, "name": "Jane Doe", "age": 40, "gender": "Female"},
    )

    assert response.status_code == 422


def test_intake_persists_registration_visit_and_medical_history(monkeypatch):
    calls = {}

    async def fake_validate():
        return TableCompatibility(
            required_tables={"healthcare_records": ["record_id"]},
            missing_tables=[],
            missing_fields={},
        )

    async def fake_ensure(patient_id, name, age, gender):
        calls["registration"] = (patient_id, name, age, gender)
        return {"registered": True, "created": False}

    def fake_risk(request, history_rows):
        calls["history"] = history_rows
        return risk.deterministic_risk_analysis(request, history_rows)

    async def fake_create(visit):
        calls["visit"] = visit
        visit.id = 500
        return {"saved_to_database": True, "record_id": 500}

    async def fake_medical(visit):
        calls["medical_history"] = visit.medical_history
        return {"saved_to_database": True}

    monkeypatch.setattr(service, "validate_urgent_care_tables", fake_validate)
    monkeypatch.setattr(service, "next_local_id", lambda: _async_value(100))
    monkeypatch.setattr(service, "ensure_patient_registration", fake_ensure)
    monkeypatch.setattr(service, "fetch_patient_history", lambda patient_id: _async_value([{"row": 1}]))
    monkeypatch.setattr(service, "risk_analysis_agent", fake_risk)
    monkeypatch.setattr(service, "create_healthcare_record", fake_create)
    monkeypatch.setattr(service, "save_medical_history_note", fake_medical)
    monkeypatch.setattr(service, "load_active_visits", lambda: _async_value([]))
    monkeypatch.setattr(service, "load_completed_visits", lambda: _async_value([]))

    result = asyncio.run(
        service.intake(
            UrgentCareIntakeRequest(
                patient_id=42,
                name="Jane Doe",
                age=40,
                gender="Female",
                symptoms="Mild cough",
                medical_history="Hypertension",
            )
        )
    )

    assert calls["registration"] == (42, "Jane Doe", 40, "Female")
    assert calls["history"] == [{"row": 1}]
    assert calls["visit"].patient_id == 42
    assert calls["medical_history"] == "Hypertension"
    assert result["database"]["record_id"] == 500


def test_notify_start_and_complete_use_update_helper(monkeypatch):
    visit = _visit(id=1001, patient_id=42)
    updates = []

    async def fake_find(visit_id):
        assert visit_id == 1001
        return visit

    async def fake_update(record_id, payload):
        updates.append((record_id, payload))
        return {"updated_database": True}

    monkeypatch.setattr(service, "find_visit_anywhere", fake_find)
    monkeypatch.setattr(service, "update_healthcare_record", fake_update)
    monkeypatch.setattr(service, "load_active_visits", lambda: _async_value([visit]))
    monkeypatch.setattr(service, "load_completed_visits", lambda: _async_value([]))

    notified = asyncio.run(service.notify_visit(1001))
    started = asyncio.run(service.start_visit(1001))
    completed = asyncio.run(service.complete_visit(1001))

    assert notified["database"]["updated_database"] is True
    assert updates[0][0] == 1001
    assert "notified_at" in updates[0][1]
    assert started["database"]["updated_database"] is True
    assert updates[1][0] == 1001
    assert updates[1][1]["status"] == "In Consultation"
    assert completed["database"]["updated_database"] is True
    assert updates[2][1]["status"] == "Completed"


def test_unknown_visit_status_returns_not_found(monkeypatch):
    async def fake_find(_visit_id):
        raise HTTPException(status_code=404, detail="Patient not found.")

    monkeypatch.setattr(service, "find_visit_anywhere", fake_find)

    response = client.get("/urgent-care/customer/visits/999/status")

    assert response.status_code == 404


def test_alerts_response_deduplicates_database_rows(monkeypatch):
    async def fake_fetch(table, patient_id=None):
        if table == "patient_feedback":
            return [
                _alert_row(feedback_id=1),
                _alert_row(feedback_id=2),
            ]
        if table == "healthcare_records":
            return [{"record_id": 1001, "patient_id": 42}]
        return []

    monkeypatch.setattr(service, "fetch_ehospital_table", fake_fetch)

    result = asyncio.run(service.alerts_response())

    assert len(result["alerts"]) == 1
    assert result["alerts"][0]["patient_id"] == 42


def test_no_staff_dashboard_mobile_route_registered():
    paths = {route.path for route in app.routes}

    assert "/urgent-care/staff" not in paths
    assert "/urgent-care/admin" not in paths


async def _async_value(value):
    return value


def _alert_row(feedback_id):
    return {
        "feedback_id": feedback_id,
        "record_id": 1001,
        "rating": "Unsure",
        "feedback_message": "I have chest pain",
        "condition_update": "Chest pain",
        "alert_required": "true",
        "alert_reason": "Feedback contains possible symptom worsening or red-flag language.",
        "created_time": "2026-07-17 10:00:00",
    }


def _visit(**overrides):
    payload = {
        "id": 1,
        "patient_id": 20,
        "name": "Patient",
        "age": 40,
        "symptoms": "symptoms",
        "medical_history": "",
        "ctas_level": 4,
        "risk_score": 3,
        "queue_name": "Non-Urgent Queue",
        "clinical_summary": "summary",
        "reasoning": "reasoning",
        "recommended_action": "review",
        "status": "Waiting",
        "checked_in_at": "2026-07-17T10:00:00",
    }
    payload.update(overrides)
    if payload["ctas_level"] in (1, 2):
        payload["queue_name"] = "Emergency Queue"
    elif payload["ctas_level"] == 3:
        payload["queue_name"] = "Normal Queue"
    else:
        payload["queue_name"] = "Non-Urgent Queue"
    return UrgentCareVisit(**payload)
