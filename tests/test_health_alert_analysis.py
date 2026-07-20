import json
import sys
from pathlib import Path

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.backend.main import app
from src.backend.services.assistant.workflows import health_alert_analysis


client = TestClient(app)


@pytest.fixture(autouse=True)
def disable_real_model(monkeypatch):
    def unavailable_model(*_args, **_kwargs):
        raise HTTPException(status_code=502, detail="model disabled in test")

    monkeypatch.setattr(health_alert_analysis, "invoke_model", unavailable_model)


def test_health_alert_rejects_unsupported_event():
    response = client.post(
        "/assistant/health-alert/analyze",
        json=_event(event_type="glucose"),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "unsupported_event"
    assert body["notify"] is False


def test_health_alert_rejects_invalid_blood_pressure_values():
    response = client.post(
        "/assistant/health-alert/analyze",
        json=_event(values={"systolic": 132}),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "invalid_event"
    assert body["notify"] is False


def test_health_alert_rejects_invalid_blood_pressure_units():
    response = client.post(
        "/assistant/health-alert/analyze",
        json=_event(unit="kPa"),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "invalid_event"
    assert body["notify"] is False
    assert "mmHg" in body["reason"]


def test_health_alert_notifies_for_sustained_bp_with_medication(monkeypatch):
    monkeypatch.setattr(health_alert_analysis, "fetch_ehospital_table", _fake_context)

    response = client.post(
        "/assistant/health-alert/analyze",
        json=_event(values={"systolic": 146, "diastolic": 92}),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "notification_decision"
    assert body["notify"] is True
    assert body["severity"] == "medium"
    assert body["recommendation_category"] == "medication_adherence"
    assert any("Amlodipine" in item for item in body["evidence_summary"])
    assert body["trace"]["analysis_window_hours"] == 3


def test_health_alert_waits_for_sustained_bp_evidence(monkeypatch):
    async def sparse_context(table, patient_id):
        if table == "prescription_form":
            return [{"medication_name": "Amlodipine", "status": "active"}]
        if table == "medical_history":
            return [{"condition": "Hypertension"}]
        return []

    monkeypatch.setattr(health_alert_analysis, "fetch_ehospital_table", sparse_context)

    response = client.post(
        "/assistant/health-alert/analyze",
        json=_event(values={"systolic": 146, "diastolic": 92}),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "no_notification"
    assert body["notify"] is False
    assert "Not enough sustained" in body["reason"]


def test_health_alert_suppresses_improving_debug_trend(monkeypatch):
    async def empty_context(table, patient_id):
        return []

    monkeypatch.setattr(health_alert_analysis, "fetch_ehospital_table", empty_context)

    response = client.post(
        "/assistant/health-alert/analyze",
        json=_event(
            values={
                "systolic": 136,
                "diastolic": 84,
                "trend_readings": [
                    {
                        "time": "2026-07-02T09:00:00+00:00",
                        "systolic": 166,
                        "diastolic": 102,
                    },
                    {
                        "time": "2026-07-02T10:00:00+00:00",
                        "systolic": 158,
                        "diastolic": 96,
                    },
                    {
                        "time": "2026-07-02T11:00:00+00:00",
                        "systolic": 146,
                        "diastolic": 90,
                    },
                ],
            },
            source_mode="test",
            source_metadata={
                "debug_scenario": "falling_blood_pressure",
                "medication_context": {
                    "has_antihypertensive_medication": True,
                    "active_medications": [
                        {
                            "name": "Lisinopril",
                            "class": "ACE inhibitor",
                            "purpose": "blood pressure control",
                        }
                    ],
                },
            },
        ),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "no_notification"
    assert body["notify"] is False
    assert body["recommendation_category"] == "monitoring"
    assert body["trace"]["improving_trend"] is True
    assert any("Lisinopril" in item for item in body["evidence_summary"])
    assert any(
        "Elevated readings in window: 4" in item for item in body["evidence_summary"]
    )
    assert any(
        "166/102 down to 136/84" in item for item in body["evidence_summary"]
    )


def test_health_alert_suppresses_when_no_medication_or_history(monkeypatch):
    async def bp_only_context(table, patient_id):
        if table == "vitals_history":
            return [
                {
                    "blood_pressure": "142/91",
                    "recorded_on": "2026-07-02T11:15:00+00:00",
                }
            ]
        return []

    monkeypatch.setattr(health_alert_analysis, "fetch_ehospital_table", bp_only_context)

    response = client.post(
        "/assistant/health-alert/analyze",
        json=_event(values={"systolic": 146, "diastolic": 92}),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "no_notification"
    assert body["notify"] is False
    assert body["recommendation_category"] == "monitoring"


def test_health_alert_uses_valid_model_decision(monkeypatch):
    monkeypatch.setattr(health_alert_analysis, "fetch_ehospital_table", _fake_context)

    def fake_invoke_model(prompt, system, invocation):
        return json.dumps(
            {
                "notify": True,
                "severity": "high",
                "title": "Medication check",
                "body": "Please check whether you took your blood-pressure medicine.",
                "reason": "Model reviewed the 3-hour window.",
                "recommendation_category": "medication_adherence",
            }
        )

    monkeypatch.setattr(health_alert_analysis, "invoke_model", fake_invoke_model)

    response = client.post(
        "/assistant/health-alert/analyze",
        json=_event(
            values={"systolic": 146, "diastolic": 92},
            model_invocation={
                "provider_key": "direct_gemini",
                "model_provider": "gemini",
                "model_name": "gemini-test",
            },
        ),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["notify"] is True
    assert body["severity"] == "high"
    assert body["title"] == "Medication check"
    assert body["trace"]["model_used"] is True


def test_health_alert_uses_default_model_before_rule_fallback(monkeypatch):
    async def sparse_context(table, patient_id):
        if table == "prescription_form":
            return [{"medication_name": "Amlodipine", "status": "active"}]
        if table == "medical_history":
            return [{"condition": "Hypertension"}]
        return []

    calls = []

    def fake_invoke_model(prompt, system, invocation):
        calls.append((prompt, system, invocation))
        return json.dumps(
            {
                "notify": False,
                "severity": "info",
                "reason": "Model saw limited evidence and chose monitoring.",
                "recommendation_category": "monitoring",
            }
        )

    monkeypatch.setattr(health_alert_analysis, "fetch_ehospital_table", sparse_context)
    monkeypatch.setattr(health_alert_analysis, "invoke_model", fake_invoke_model)

    response = client.post(
        "/assistant/health-alert/analyze",
        json=_event(values={"systolic": 146, "diastolic": 92}),
    )

    assert response.status_code == 200
    body = response.json()
    assert calls
    assert calls[0][2] is None
    assert body["status"] == "no_notification"
    assert body["notify"] is False
    assert body["reason"] == "Model saw limited evidence and chose monitoring."
    assert body["trace"]["model_used"] is True


def test_health_alert_falls_back_after_malformed_model_decision(monkeypatch):
    monkeypatch.setattr(health_alert_analysis, "fetch_ehospital_table", _fake_context)
    monkeypatch.setattr(health_alert_analysis, "invoke_model", lambda *_: "not json")

    response = client.post(
        "/assistant/health-alert/analyze",
        json=_event(
            values={"systolic": 146, "diastolic": 92},
            model_invocation={
                "provider_key": "direct_gemini",
                "model_provider": "gemini",
                "model_name": "gemini-test",
            },
        ),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "notification_decision"
    assert body["notify"] is True
    assert body["trace"].get("model_used") is None


async def _fake_context(table, patient_id):
    data = {
        "vitals_history": [
            {
                "blood_pressure": "124/78",
                "recorded_on": "2026-07-02T08:00:00+00:00",
            },
            {
                "blood_pressure": "142/91",
                "recorded_on": "2026-07-02T11:15:00+00:00",
            },
        ],
        "prescription_form": [
            {
                "medication_name": "Amlodipine",
                "status": "active",
                "expiry_date": "2026-08-01T00:00:00+00:00",
            }
        ],
        "medical_history": [{"condition": "Hypertension"}],
        "wearable_vitals": [
            {
                "timestamp": "2026-07-02T11:50:00+00:00",
                "heart_rate": 88,
                "sleep": 6.2,
                "steps": 1200,
            }
        ],
        "wearable_workouts": [
            {
                "start_time": "2026-07-02T08:00:00+00:00",
                "workout_type": "walking",
            }
        ],
        "patient_feedback": [
            {
                "datetime": "2026-07-02T09:00:00+00:00",
                "feedback": "Felt tired this morning.",
            }
        ],
    }
    return data.get(table, [])


def _event(**overrides):
    payload = {
        "patient_id": 20,
        "event_type": "blood_pressure",
        "event_source_id": "hk-bp-1",
        "event_time": "2026-07-02T12:00:00+00:00",
        "values": {"systolic": 146, "diastolic": 92},
        "unit": "mmHg",
        "source": "apple_health",
        "source_mode": "production",
    }
    payload.update(overrides)
    return payload
