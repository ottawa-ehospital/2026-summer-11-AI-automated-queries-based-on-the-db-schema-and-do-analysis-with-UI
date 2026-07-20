import sys
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from src.backend.api import stress as stress_api
from src.backend.main import app
from src.backend.schemas.stress import StressAnalysisResponse
from src.backend.services import sleep_service
from src.backend.services.stress_score import compute_stress_score
from src.backend.api import assistant as assistant_api


client = TestClient(app)


def test_sleep_sync_inserts_missing_remote_night(monkeypatch):
    calls = []

    async def fake_select(sql, replacements=None):
        assert "sleep_nights" in sql
        return {"count": 0, "data": []}

    async def fake_write(table, row):
        calls.append((table, row))
        return {"ok": True}

    monkeypatch.setattr(sleep_service, "execute_ehospital_select", fake_select)
    monkeypatch.setattr(sleep_service, "write_ehospital_table_row", fake_write)

    response = client.post(
        "/sleep/nights",
        json={
            "patient_id": 20,
            "forward_to_ehospital": False,
            "nights": [
                {
                    "night": "2026-07-17",
                    "deep_minutes": 62,
                    "rem_minutes": 88,
                    "core_minutes": 260,
                    "awake_minutes": 20,
                    "asleep_minutes": 410,
                    "in_bed_minutes": 430,
                    "spo2_avg": 96,
                    "spo2_min": 93,
                    "hr_avg": 58,
                    "hr_min": 49,
                }
            ],
        },
    )

    assert response.status_code == 200
    assert response.json() == {"saved": 1, "forwarded_to_ehospital": False}
    assert calls[0][0] == "sleep_nights"
    assert calls[0][1]["patient_id"] == "20"
    assert calls[0][1]["night"] == "2026-07-17"


def test_sleep_sync_skips_existing_remote_night(monkeypatch):
    writes = []

    async def fake_select(sql, replacements=None):
        return {"count": 1, "data": [{"patient_id": "20", "night": "2026-07-17"}]}

    async def fake_write(table, row):
        writes.append((table, row))
        return {}

    monkeypatch.setattr(sleep_service, "execute_ehospital_select", fake_select)
    monkeypatch.setattr(sleep_service, "write_ehospital_table_row", fake_write)

    response = client.post(
        "/sleep/nights",
        json={
            "patient_id": 20,
            "forward_to_ehospital": False,
            "nights": [{"night": "2026-07-17", "asleep_minutes": 400}],
        },
    )

    assert response.status_code == 200
    assert response.json()["saved"] == 1
    assert writes == []


def test_sleep_feedback_handles_empty_data(monkeypatch):
    async def fake_select(sql, replacements=None):
        return {"count": 0, "data": []}

    monkeypatch.setattr(sleep_service, "execute_ehospital_select", fake_select)

    response = client.post("/sleep/feedback", json={"patient_id": 20, "days": 7})

    assert response.status_code == 200
    body = response.json()
    assert body["nights_analyzed"] == 0
    assert "No sleep data" in body["feedback"]


def test_stress_score_supports_complete_partial_and_missing_inputs():
    assert compute_stress_score(50, 60, 14) == 0
    assert compute_stress_score(25, None, None) == 50
    assert compute_stress_score(None, None, None) is None


def test_stress_snapshot_derives_score_server_side(monkeypatch):
    captured = {}

    async def fake_write(table, row):
        captured["table"] = table
        captured["row"] = row
        return {"id": 1}

    monkeypatch.setattr(stress_api, "write_ehospital_table_row", fake_write)

    response = client.post(
        "/vitals/stress-snapshot",
        json={
            "patient_id": 20,
            "hrv_sdnn": 25,
            "resting_heart_rate": 80,
            "respiratory_rate": 18,
            "heart_rate": 82,
            "timestamp": "2026-07-18T10:00:00Z",
        },
    )

    assert response.status_code == 200
    assert captured["table"] == "wearable_vitals"
    assert captured["row"]["stress_score"] == 46.4
    assert "stress_score" in captured["row"]


def test_stress_annotation_updates_remote_row(monkeypatch):
    captured = {}

    async def fake_update(table, row_id, row):
        captured["table"] = table
        captured["row_id"] = row_id
        captured["row"] = row
        return {"ok": True}

    monkeypatch.setattr(stress_api, "update_ehospital_table_row", fake_update)

    response = client.patch(
        "/vitals/123/annotation",
        json={"annotation": "Felt tense after meeting."},
    )

    assert response.status_code == 200
    assert captured == {
        "table": "wearable_vitals",
        "row_id": "123",
        "row": {"annotation": "Felt tense after meeting."},
    }


def test_assistant_stress_analysis_endpoint_coexists_with_health_alert(monkeypatch):
    async def fake_analyze(request):
        return StressAnalysisResponse(analysis=f"stress for {request.patient_id}")

    monkeypatch.setattr(assistant_api, "analyze_stress", fake_analyze)

    stress_response = client.post(
        "/assistant/stress-analysis",
        json={"patient_id": 20},
    )

    assert stress_response.status_code == 200
    assert stress_response.json() == {"analysis": "stress for 20"}
    route_paths = {route.path for route in app.routes}
    assert "/assistant/health-alert/analyze" in route_paths
