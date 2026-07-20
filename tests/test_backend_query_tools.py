import json

import pytest
from fastapi.testclient import TestClient

from src.backend.main import app
from src.backend.schemas.query_tools import TableQueryRequest
from src.backend.services import query_tools


client = TestClient(app)


TEST_INVENTORY = {
    "generated_at": "2026-06-03T00:00:00+00:00",
    "source": "test",
    "count": 3,
    "tables": [
        {
            "name": "wearable_vitals",
            "qualifiedName": "wearable_vitals",
            "modelName": "WearableVitals",
            "primaryKeys": ["vital_id"],
            "attributes": [
                "vital_id",
                "patient_id",
                "heart_rate",
                "steps",
                "calories",
                "sleep",
                "timestamp",
                "recorded_on",
            ],
        },
        {
            "name": "wearable_workouts",
            "qualifiedName": "wearable_workouts",
            "modelName": "WearableWorkouts",
            "primaryKeys": ["workout_id"],
            "attributes": [
                "workout_id",
                "patient_id",
                "source_provider",
                "source_workout_id",
                "workout_type",
                "start_time",
                "end_time",
                "duration_seconds",
                "distance_meters",
                "active_energy_kcal",
                "average_heart_rate_bpm",
                "max_heart_rate_bpm",
                "sync_anchor",
            ],
        },
        {
            "name": "patients_registration",
            "qualifiedName": "patients_registration",
            "modelName": "PatientsRegistration",
            "primaryKeys": ["patient_id"],
            "attributes": ["patient_id", "name", "dob", "gender"],
        },
    ],
}


@pytest.fixture(autouse=True)
def schema_file(tmp_path, monkeypatch):
    schema_path = tmp_path / "ehospital_schema_inventory.json"
    schema_path.write_text(json.dumps(TEST_INVENTORY), encoding="utf-8")
    monkeypatch.setattr(query_tools, "SCHEMA_INVENTORY_PATH", schema_path)
    return schema_path


def test_validate_sigma_payload_accepts_known_table_and_fields():
    response = client.post(
        "/query-tools/sigma/validate",
        json={
            "sigma": {
                "title": "latest vitals",
                "logsource": {"service": "wearable_vitals"},
                "detection": {
                    "selection": {
                        "patient_id": 1,
                        "timestamp|gte": "2026-04-01T00:00:00.000Z",
                    },
                    "condition": "selection",
                },
                "fields": ["heart_rate", "steps", "timestamp"],
                "date_filter": {
                    "field": "timestamp",
                    "start": "2026-04-01T00:00:00.000Z",
                    "end": "2026-04-30T23:59:59.999Z",
                },
                "order_by": [{"field": "timestamp", "direction": "desc"}],
                "limit": 20,
            }
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["valid"] is True
    assert body["normalized"]["table"] == "wearable_vitals"
    assert body["normalized"]["fields"] == ["heart_rate", "steps", "timestamp"]
    assert body["normalized"]["date_filter"]["field"] == "timestamp"
    assert body["normalized"]["order_by"][0]["field"] == "timestamp"


def test_validate_sigma_payload_rejects_unknown_field():
    response = client.post(
        "/query-tools/sigma/validate",
        json={
            "sigma": {
                "title": "bad vitals",
                "logsource": {"service": "wearable_vitals"},
                "detection": {
                    "selection": {"made_up_field": "x"},
                    "condition": "selection",
                },
                "fields": ["heart_rate"],
            }
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["valid"] is False
    assert "made_up_field" in body["errors"][0]


def test_validate_sigma_payload_accepts_workout_table_and_fields():
    response = client.post(
        "/query-tools/sigma/validate",
        json={
            "sigma": {
                "title": "recent workouts",
                "logsource": {"service": "wearable_workouts"},
                "detection": {
                    "selection": {
                        "patient_id": "__CURRENT_PATIENT__",
                        "start_time|gte": "2026-06-01T00:00:00Z",
                    },
                    "condition": "selection",
                },
                "fields": [
                    "workout_type",
                    "start_time",
                    "duration_seconds",
                    "distance_meters",
                    "average_heart_rate_bpm",
                ],
                "order_by": [{"field": "start_time", "direction": "desc"}],
                "limit": 20,
            }
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["valid"] is True
    assert body["normalized"]["table"] == "wearable_workouts"
    assert body["normalized"]["fields"] == [
        "workout_type",
        "start_time",
        "duration_seconds",
        "distance_meters",
        "average_heart_rate_bpm",
    ]


def test_validate_sigma_payload_rejects_unknown_workout_field():
    response = client.post(
        "/query-tools/sigma/validate",
        json={
            "sigma": {
                "title": "bad workouts",
                "logsource": {"service": "wearable_workouts"},
                "detection": {
                    "selection": {"patient_id": "__CURRENT_PATIENT__"},
                    "condition": "selection",
                },
                "fields": ["workout_type", "missing_workout_field"],
            }
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["valid"] is False
    assert "missing_workout_field" in body["errors"][0]


def test_schema_refresh_writes_inventory(monkeypatch, schema_file):
    async def fake_metadata():
        return {
            "count": 1,
            "tables": [
                {
                    "name": "lab_tests",
                    "qualifiedName": "lab_tests",
                    "modelName": "LabTests",
                    "primaryKeys": ["lab_test_id"],
                    "attributes": ["lab_test_id", "patient_id", "test_date"],
                }
            ],
        }

    monkeypatch.setattr(query_tools, "fetch_ehospital_tables_metadata", fake_metadata)

    response = client.post("/query-tools/schema/refresh")

    assert response.status_code == 200
    assert response.json()["count"] == 1
    written = json.loads(schema_file.read_text(encoding="utf-8"))
    assert written["tables"][0]["name"] == "lab_tests"


def test_validate_sql_references_accepts_known_table_and_fields():
    response = client.post(
        "/query-tools/sql/validate",
        json={
            "sql": (
                "SELECT heart_rate, steps FROM wearable_vitals "
                "WHERE patient_id = :patient_id ORDER BY timestamp DESC LIMIT 20"
            )
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["valid"] is True
    assert body["normalized"]["tables"] == ["wearable_vitals"]


def test_validate_sql_references_rejects_unknown_field():
    response = client.post(
        "/query-tools/sql/validate",
        json={"sql": "SELECT secret_field FROM wearable_vitals LIMIT 20"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["valid"] is False
    assert "secret_field" in body["errors"][0]


def test_build_table_query_sql_uses_parameterized_date_filter():
    request = TableQueryRequest(
        table="wearable_vitals",
        fields=["heart_rate", "steps", "timestamp"],
        filters=[{"field": "patient_id", "operator": "eq", "value": 1}],
        date_filter={
            "field": "timestamp",
            "start": "2026-04-01T00:00:00.000Z",
            "end": "2026-04-30T23:59:59.999Z",
        },
        order_by=[{"field": "timestamp", "direction": "desc"}],
        limit=20,
    )

    sql, replacements = query_tools.build_table_query_sql(request)

    assert "FROM `wearable_vitals`" in sql
    assert "`timestamp` >= :date_start" in sql
    assert "`timestamp` <= :date_end" in sql
    assert replacements["filter_0"] == 1
    assert replacements["date_start"] == "2026-04-01T00:00:00.000Z"
    assert replacements["limit"] == 20


def test_filtered_table_query_executes_validated_request(monkeypatch):
    captured = {}

    async def fake_select(sql, replacements):
        captured["sql"] = sql
        captured["replacements"] = replacements
        return {"count": 1, "data": [{"heart_rate": 83}]}

    monkeypatch.setattr(query_tools, "execute_ehospital_select", fake_select)

    response = client.post(
        "/query-tools/table/query",
        json={
            "table": "wearable_vitals",
            "fields": ["heart_rate"],
            "filters": [{"field": "patient_id", "operator": "eq", "value": 1}],
            "date_filter": {"field": "timestamp", "start": "2026-04-01"},
            "limit": 10,
        },
    )

    assert response.status_code == 200
    assert response.json()["data"] == [{"heart_rate": 83}]
    assert captured["replacements"]["filter_0"] == 1
    assert captured["replacements"]["date_start"] == "2026-04-01"


def test_filtered_table_query_rejects_invalid_filter_field():
    response = client.post(
        "/query-tools/table/query",
        json={
            "table": "wearable_vitals",
            "filters": [{"field": "missing", "operator": "eq", "value": 1}],
        },
    )

    assert response.status_code == 400
    assert "missing" in response.text


def test_normalized_sigma_to_table_query_enforces_patient_scope():
    request = query_tools.normalized_sigma_to_table_query(
        {
            "table": "wearable_vitals",
            "fields": ["timestamp", "heart_rate"],
            "filters": [
                {"field": "patient_id", "modifiers": ["eq"], "value": 999},
                {"field": "heart_rate", "modifiers": ["gte"], "value": 70},
            ],
            "order_by": [{"field": "timestamp", "direction": "desc"}],
            "limit": 20,
        },
        patient_id=20,
    )

    assert request.table == "wearable_vitals"
    assert request.filters[0].field == "patient_id"
    assert request.filters[0].value == 20
    assert request.filters[1].field == "heart_rate"
    assert request.order_by[0].field == "timestamp"


def test_normalized_workout_sigma_to_table_query_enforces_patient_scope():
    request = query_tools.normalized_sigma_to_table_query(
        {
            "table": "wearable_workouts",
            "fields": ["workout_type", "start_time", "duration_seconds"],
            "filters": [
                {"field": "patient_id", "modifiers": ["eq"], "value": 999},
                {"field": "workout_type", "modifiers": ["eq"], "value": "running"},
            ],
            "order_by": [{"field": "start_time", "direction": "desc"}],
            "limit": 20,
        },
        patient_id=20,
    )

    assert request.table == "wearable_workouts"
    assert request.filters[0].field == "patient_id"
    assert request.filters[0].value == 20
    assert request.filters[1].field == "workout_type"
    assert request.order_by[0].field == "start_time"


def test_normalized_sigma_to_table_query_rejects_unscoped_table():
    with pytest.raises(Exception) as exc:
        query_tools.normalized_sigma_to_table_query(
            {
                "table": "exercise_catalog",
                "fields": ["*"],
                "filters": [],
            },
            patient_id=20,
        )

    assert "Unknown table" in str(exc.value) or "cannot be safely scoped" in str(exc.value)


def test_normalized_sigma_to_table_query_rejects_unsupported_modifier():
    with pytest.raises(Exception) as exc:
        query_tools.normalized_sigma_to_table_query(
            {
                "table": "wearable_vitals",
                "fields": ["timestamp"],
                "filters": [{"field": "timestamp", "modifiers": ["exists"], "value": True}],
            },
            patient_id=20,
        )

    assert "exists" in str(exc.value)


def test_validate_multi_query_plan_accepts_multiple_patient_scoped_entries():
    valid, errors, normalized = query_tools.validate_multi_query_plan(
        {
            "queries": [
                {
                    "query_id": "vitals",
                    "purpose": "recent wearable vitals",
                    "required": False,
                    "domain": "wearable_vitals",
                    "sigma": {
                        "title": "Recent vitals",
                        "logsource": {"service": "wearable_vitals"},
                        "detection": {
                            "selection": {"patient_id": "__CURRENT_PATIENT__"},
                            "condition": "selection",
                        },
                        "fields": ["timestamp", "heart_rate", "sleep"],
                        "order_by": [{"field": "timestamp", "direction": "desc"}],
                        "limit": 20,
                    },
                },
                {
                    "query_id": "workouts",
                    "purpose": "recent workouts",
                    "required": False,
                    "domain": "workout_history",
                    "sigma": {
                        "title": "Recent workouts",
                        "logsource": {"service": "wearable_workouts"},
                        "detection": {
                            "selection": {"patient_id": "__CURRENT_PATIENT__"},
                            "condition": "selection",
                        },
                        "fields": ["workout_type", "start_time", "duration_seconds"],
                        "order_by": [{"field": "start_time", "direction": "desc"}],
                        "limit": 20,
                    },
                },
            ]
        }
    )

    assert valid is True
    assert errors == []
    assert normalized is not None
    assert [entry["query_id"] for entry in normalized] == ["vitals", "workouts"]

    table_queries = query_tools.normalized_multi_query_plan_to_table_queries(
        normalized,
        patient_id=20,
    )

    assert table_queries[0]["table_request"].table == "wearable_vitals"
    assert table_queries[0]["table_request"].filters[0].value == 20
    assert table_queries[1]["table_request"].table == "wearable_workouts"


def test_validate_multi_query_plan_preserves_entry_specific_errors():
    valid, errors, normalized = query_tools.validate_multi_query_plan(
        {
            "queries": [
                {
                    "query_id": "bad_vitals",
                    "purpose": "bad vitals",
                    "required": True,
                    "sigma": {
                        "title": "Bad vitals",
                        "logsource": {"service": "wearable_vitals"},
                        "detection": {
                            "selection": {"made_up_field": "x"},
                            "condition": "selection",
                        },
                        "fields": ["heart_rate"],
                    },
                }
            ]
        }
    )

    assert valid is False
    assert normalized is None
    assert errors
    assert errors[0].startswith("bad_vitals:")
