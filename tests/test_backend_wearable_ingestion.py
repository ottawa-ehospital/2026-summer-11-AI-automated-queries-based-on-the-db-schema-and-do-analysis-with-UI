from fastapi import HTTPException
from fastapi.testclient import TestClient

from src.backend.main import app
from src.backend.services import wearable_ingestion


client = TestClient(app)


def test_wearable_ingest_success_posts_normalized_row(monkeypatch):
    captured = {}

    async def fake_write(table, row):
        captured["table"] = table
        captured["row"] = row
        return {"id": 123}

    monkeypatch.setattr(wearable_ingestion, "write_ehospital_table_row", fake_write)

    response = client.post(
        "/wearables/ingest",
        json={
            "patient_id": 20,
            "heart_rate": 82.0,
            "steps": 6400,
            "calories": 320.5,
            "timestamp": "2026-06-20T10:30:00Z",
            "recorded_on": "2026-06-20T10:31:00Z",
            "source": "google_health",
            "source_metadata": {"device": "Pixel Watch"},
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ingested"
    assert body["patient_id"] == "20"
    assert body["accepted_metrics"] == ["heart_rate", "steps", "calories"]
    assert body["source"] == "google_health"
    assert body["timestamp"] == "2026-06-20T10:30:00+00:00"
    assert body["recorded_on"] == "2026-06-20T10:31:00+00:00"
    assert body["ehospital_response"] == {"id": 123}
    assert captured["table"] == "wearable_vitals"
    assert captured["row"] == {
        "patient_id": "20",
        "heart_rate": 82,
        "steps": 6400,
        "calories": 320.5,
        "timestamp": "2026-06-20T10:30:00+00:00",
        "recorded_on": "2026-06-20T10:31:00+00:00",
    }


def test_wearable_ingest_defaults_recorded_on_to_timestamp(monkeypatch):
    captured = {}

    async def fake_write(table, row):
        captured["row"] = row
        return {}

    monkeypatch.setattr(wearable_ingestion, "write_ehospital_table_row", fake_write)

    response = client.post(
        "/wearables/ingest",
        json={
            "patient_id": "p-20",
            "sleep": 7.5,
            "timestamp": "2026-06-20T05:00:00Z",
            "source": "manual",
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["accepted_metrics"] == ["sleep"]
    assert body["recorded_on"] == "2026-06-20T05:00:00+00:00"
    assert captured["row"]["recorded_on"] == "2026-06-20T05:00:00+00:00"


def test_wearable_ingest_rejects_invalid_payloads_without_write(monkeypatch):
    calls = []

    async def fake_write(table, row):
        calls.append((table, row))
        return {}

    monkeypatch.setattr(wearable_ingestion, "write_ehospital_table_row", fake_write)

    invalid_payloads = [
        {"heart_rate": 80, "timestamp": "2026-06-20T10:30:00Z"},
        {"patient_id": "", "heart_rate": 80, "timestamp": "2026-06-20T10:30:00Z"},
        {"patient_id": 20, "timestamp": "2026-06-20T10:30:00Z"},
        {"patient_id": 20, "steps": -1, "timestamp": "2026-06-20T10:30:00Z"},
        {"patient_id": 20, "steps": 100, "timestamp": "not-a-date"},
    ]

    for payload in invalid_payloads:
        response = client.post("/wearables/ingest", json=payload)
        assert response.status_code == 422

    assert calls == []


def test_wearable_ingest_write_failure_returns_gateway_error(monkeypatch):
    async def fake_write(table, row):
        raise HTTPException(status_code=502, detail="remote unavailable")

    monkeypatch.setattr(wearable_ingestion, "write_ehospital_table_row", fake_write)

    response = client.post(
        "/wearables/ingest",
        json={
            "patient_id": 20,
            "heart_rate": 82,
            "timestamp": "2026-06-20T10:30:00Z",
            "source": "apple_health",
        },
    )

    assert response.status_code == 502
    assert "Failed to ingest wearable sample" in response.json()["detail"]


def _valid_workout_payload(**overrides):
    payload = {
        "patient_id": 20,
        "source_provider": "apple_health",
        "source_workout_id": "HK-WORKOUT-1",
        "source_bundle_id": "com.apple.Health",
        "source_device_name": "Apple Watch",
        "source_device_manufacturer": "Apple",
        "source_device_model": "Watch",
        "workout_type": "running",
        "workout_type_raw": "RUNNING",
        "apple_workout_activity_type": 37,
        "start_time": "2026-06-20T10:00:00Z",
        "end_time": "2026-06-20T10:30:00Z",
        "duration_seconds": 1800,
        "timezone_offset_minutes": -240,
        "distance_meters": 5000.25,
        "active_energy_kcal": 310.5,
        "total_energy_kcal": 360,
        "steps": 6200,
        "average_heart_rate_bpm": 142.5,
        "max_heart_rate_bpm": 168,
        "min_heart_rate_bpm": 92,
        "average_speed_mps": 2.8,
        "average_cadence_spm": 172,
        "elevation_gain_meters": 30,
        "has_route": True,
        "sync_anchor": "anchor-1",
        "sync_revision": "rev-1",
        "source_metadata": {"recording_method": "automatic"},
        "raw_payload": {"uuid": "HK-WORKOUT-1"},
    }
    payload.update(overrides)
    return payload


def test_workout_ingest_success_posts_normalized_row(monkeypatch):
    captured = {"fetches": []}

    async def fake_fetch(table, patient_id=None):
        captured["fetches"].append((table, patient_id))
        return []

    async def fake_write(table, row):
        captured["write_table"] = table
        captured["row"] = row
        return {"id": 456}

    monkeypatch.setattr(wearable_ingestion, "fetch_ehospital_table", fake_fetch)
    monkeypatch.setattr(wearable_ingestion, "write_ehospital_table_row", fake_write)

    response = client.post(
        "/wearables/workouts/ingest",
        json=_valid_workout_payload(),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ingested"
    assert body["patient_id"] == "20"
    assert body["source_provider"] == "apple_health"
    assert body["source_workout_id"] == "HK-WORKOUT-1"
    assert body["workout_type"] == "running"
    assert body["duration_seconds"] == 1800
    assert body["ehospital_response"] == {"id": 456}
    assert captured["fetches"] == [("wearable_workouts", 20)]
    assert captured["write_table"] == "wearable_workouts"
    assert captured["row"]["patient_id"] == "20"
    assert captured["row"]["source_provider"] == "apple_health"
    assert captured["row"]["source_workout_id"] == "20:HK-WORKOUT-1"
    assert captured["row"]["workout_type"] == "running"
    assert captured["row"]["start_time"] == "2026-06-20T10:00:00+00:00"
    assert captured["row"]["end_time"] == "2026-06-20T10:30:00+00:00"
    assert captured["row"]["duration_seconds"] == 1800
    assert captured["row"]["distance_meters"] == 5000.25
    assert captured["row"]["active_energy_kcal"] == 310.5
    assert captured["row"]["has_route"] == 1
    assert captured["row"]["source_metadata"] == {"recording_method": "automatic"}
    assert captured["row"]["raw_payload"] == {"uuid": "HK-WORKOUT-1"}


def test_workout_batch_ingest_reports_accepted_and_ingested_counts(monkeypatch):
    writes = []

    async def fake_fetch(table, patient_id=None):
        if patient_id == 21:
            return [
                {
                    "patient_id": "21",
                    "source_provider": "fitbit",
                    "source_workout_id": "FITBIT-2",
                }
            ]
        return []

    async def fake_write(table, row):
        writes.append((table, row))
        return {"stored": row["source_workout_id"]}

    monkeypatch.setattr(wearable_ingestion, "fetch_ehospital_table", fake_fetch)
    monkeypatch.setattr(wearable_ingestion, "write_ehospital_table_row", fake_write)

    response = client.post(
        "/wearables/workouts/batch-ingest",
        json={
            "workouts": [
                _valid_workout_payload(patient_id=20, source_workout_id="HK-1"),
                _valid_workout_payload(
                    patient_id=21,
                    source_provider="fitbit",
                    source_workout_id="FITBIT-2",
                    fitbit_activity_id=123,
                    fitbit_activity_name="Outdoor Bike",
                    workout_type="cycling",
                ),
            ]
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ingested"
    assert body["accepted_count"] == 2
    assert body["ingested_count"] == 1
    assert [item["status"] for item in body["workouts"]] == [
        "ingested",
        "already_ingested",
    ]
    assert len(writes) == 1
    assert writes[0][1]["source_workout_id"] == "20:HK-1"


def test_workout_ingest_rejects_invalid_payloads_without_write(monkeypatch):
    calls = []

    async def fake_fetch(table, patient_id=None):
        calls.append(("fetch", table, patient_id))
        return []

    async def fake_write(table, row):
        calls.append(("write", table, row))
        return {}

    monkeypatch.setattr(wearable_ingestion, "fetch_ehospital_table", fake_fetch)
    monkeypatch.setattr(wearable_ingestion, "write_ehospital_table_row", fake_write)

    invalid_payloads = [
        _valid_workout_payload(patient_id=""),
        _valid_workout_payload(source_workout_id=""),
        _valid_workout_payload(workout_type=""),
        _valid_workout_payload(end_time="2026-06-20T09:59:00Z"),
        _valid_workout_payload(duration_seconds=-1),
        _valid_workout_payload(distance_meters=-1),
        _valid_workout_payload(active_energy_kcal=-1),
        _valid_workout_payload(steps=-1),
        _valid_workout_payload(average_heart_rate_bpm=-1),
        _valid_workout_payload(average_speed_mps=-1),
        _valid_workout_payload(elevation_gain_meters=-1),
    ]

    for payload in invalid_payloads:
        response = client.post("/wearables/workouts/ingest", json=payload)
        assert response.status_code == 422

    assert calls == []


def test_workout_ingest_duplicate_source_identity_is_idempotent(monkeypatch):
    writes = []

    async def fake_fetch(table, patient_id=None):
        return [
            {
                "workout_id": 99,
                "patient_id": "20",
                "source_provider": "apple_health",
                "source_workout_id": "HK-WORKOUT-1",
            }
        ]

    async def fake_write(table, row):
        writes.append((table, row))
        return {}

    monkeypatch.setattr(wearable_ingestion, "fetch_ehospital_table", fake_fetch)
    monkeypatch.setattr(wearable_ingestion, "write_ehospital_table_row", fake_write)

    response = client.post(
        "/wearables/workouts/ingest",
        json=_valid_workout_payload(),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "already_ingested"
    assert body["ehospital_response"]["existing"]["workout_id"] == 99
    assert writes == []


def test_workout_ingest_duplicate_source_identity_across_patients_stores_current_patient(monkeypatch):
    fetches = []
    writes = []

    async def fake_fetch(table, patient_id=None):
        fetches.append((table, patient_id))
        if patient_id == 9102:
            return [
                {
                    "workout_id": 99,
                    "patient_id": "9102",
                    "source_provider": "apple_health",
                    "source_workout_id": "HK-WORKOUT-1",
                }
            ]
        return []

    async def fake_write(table, row):
        writes.append((table, row))
        return {}

    monkeypatch.setattr(wearable_ingestion, "fetch_ehospital_table", fake_fetch)
    monkeypatch.setattr(wearable_ingestion, "write_ehospital_table_row", fake_write)

    response = client.post(
        "/wearables/workouts/ingest",
        json=_valid_workout_payload(patient_id=20),
    )

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "ingested"
    assert body["patient_id"] == "20"
    assert fetches == [("wearable_workouts", 20)]
    assert writes[0][1]["patient_id"] == "20"
    assert writes[0][1]["source_workout_id"] == "20:HK-WORKOUT-1"


def test_workout_ingest_write_failure_returns_gateway_error(monkeypatch):
    async def fake_fetch(table, patient_id=None):
        return []

    async def fake_write(table, row):
        raise HTTPException(status_code=502, detail="remote unavailable")

    monkeypatch.setattr(wearable_ingestion, "fetch_ehospital_table", fake_fetch)
    monkeypatch.setattr(wearable_ingestion, "write_ehospital_table_row", fake_write)

    response = client.post(
        "/wearables/workouts/ingest",
        json=_valid_workout_payload(),
    )

    assert response.status_code == 502
    assert "Failed to ingest wearable workout" in response.json()["detail"]
