import os
import sys
import types

os.environ.setdefault("OPENAI_API_KEY", "test-key")

from fastapi import HTTPException
from fastapi.testclient import TestClient

from src.backend.main import app
from src.backend.services.report_interpreter import analysis, patients, saved_records, suggestions
from src.backend.services.report_interpreter.extraction import extract_upload_text


client = TestClient(app)


def test_report_interpreter_health_and_route_isolation():
    response = client.get("/report-interpreter/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

    paths = client.get("/openapi.json").json()["paths"]
    assert "/report-interpreter/health" in paths
    assert "/assistant/chat" in paths
    assert not any(path.startswith("/api/") for path in paths)


def test_analyze_text_report_uses_patient_id_and_returns_analysis(monkeypatch):
    captured = {}

    def fake_model(prompt, system_prompt=None, model_invocation=None):
        captured["prompt"] = prompt
        captured["system_prompt"] = system_prompt
        return (
            "**Summary**\nBlood sugar is slightly high.\n\n"
            "**1. Key Findings**\n- Glucose: 150 mg/dL (normal: 70-99)\n\n"
            "**2. Explanation**\n- This can happen for several reasons.\n\n"
            "**3. Suggested Doctor Diagnosis Discussion**\n- Ask about glucose control.\n\n"
            "**4. Recommendation**\n- Follow up with your doctor.\n\n"
            "**5. Questions?**\nWhat would you like to review?"
        )

    async def fake_find_patient_by_id(patient_id):
        captured["patient_id"] = patient_id
        return {"patient_id": patient_id, "name": f"Patient {patient_id}"}

    async def fake_save(patient_id, lab_values, report_date, detected_test_type):
        captured["saved_patient_id"] = patient_id
        captured["detected_test_type"] = detected_test_type
        return {"count": len(lab_values), "errors": []}

    monkeypatch.setattr(analysis, "invoke_model", fake_model)
    monkeypatch.setattr(analysis, "find_patient_by_id", fake_find_patient_by_id)
    monkeypatch.setattr(analysis, "save_lab_values_for_patient", fake_save)

    response = client.post(
        "/report-interpreter/analyze-file",
        data={"patientId": "42"},
        files={
            "file": (
                "blood.txt",
                b"Patient Name: Test User\nReport Date: 2026-02-01\nGlucose: 150 mg/dL (normal: 70-99)",
                "text/plain",
            )
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert "Blood sugar" in body["analysis"]
    assert body["patient"]["patient_id"] == 42
    assert body["savedLabRecordCount"] >= 1
    assert captured["patient_id"] == 42
    assert captured["saved_patient_id"] == 42
    assert captured["detected_test_type"] == "blood"


def test_analyze_unsupported_file_type_rejected_before_model(monkeypatch):
    calls = []

    def fake_model(*args, **kwargs):
        calls.append((args, kwargs))
        return "should not be called"

    monkeypatch.setattr(analysis, "invoke_model", fake_model)

    response = client.post(
        "/report-interpreter/analyze-file",
        data={"patientId": "42"},
        files={"file": ("report.exe", b"nope", "application/octet-stream")},
    )

    assert response.status_code == 415
    assert calls == []


def test_text_based_pdf_extraction_uses_embedded_text_without_ocr(monkeypatch):
    class FakePage:
        def extract_text(self):
            return (
                "Report Date: 2026-02-01\nGlucose: 150 mg/dL\n"
                "Hemoglobin: 14 g/dL\nCholesterol: 180 mg/dL\n"
                "This embedded PDF text is long enough to avoid OCR fallback. " * 3
            )

    class FakePdfReader:
        def __init__(self, stream):
            self.pages = [FakePage()]

    fake_pypdf = types.SimpleNamespace(PdfReader=FakePdfReader)
    monkeypatch.setitem(sys.modules, "pypdf", fake_pypdf)
    monkeypatch.setattr(
        "src.backend.services.report_interpreter.extraction.extract_text_from_images",
        lambda *args, **kwargs: (_ for _ in ()).throw(AssertionError("OCR should not run")),
    )

    text = extract_upload_text(b"%PDF-1.4 fake", "report.pdf", "application/pdf")

    assert "Glucose: 150 mg/dL" in text


def test_suggest_questions_falls_back_on_invalid_model_json(monkeypatch):
    monkeypatch.setattr(suggestions, "invoke_model", lambda *args, **kwargs: "not json")

    response = client.post(
        "/report-interpreter/suggest-questions",
        json={"latestResponse": "Glucose was high.", "patientId": 42},
    )

    assert response.status_code == 200
    assert len(response.json()["questions"]) >= 4


def test_saved_record_dates_are_patient_scoped(monkeypatch):
    captured = {}

    async def fake_select(sql, replacements=None):
        captured["sql"] = sql
        captured["replacements"] = replacements
        return [{"test_date": "2026-02-01T00:00:00.000Z"}]

    monkeypatch.setattr(saved_records, "select_rows", fake_select)

    response = client.get("/report-interpreter/tests/blood/dates?patientId=42")

    assert response.status_code == 200
    assert response.json() == ["2026-02-01"]
    assert captured["replacements"] == {"patient_id": 42}


def test_database_save_failure_returns_analysis_with_warnings(monkeypatch):
    monkeypatch.setattr(
        analysis,
        "invoke_model",
        lambda *args, **kwargs: "**Summary**\nReport reviewed.\n\nGlucose: 150 mg/dL (normal: 70-99)",
    )

    async def fake_find_patient_by_id(patient_id):
        return {"patient_id": patient_id, "name": f"Patient {patient_id}"}

    async def fake_save(patient_id, lab_values, report_date, detected_test_type):
        return {"count": 0, "errors": ["remote unavailable"]}

    monkeypatch.setattr(analysis, "find_patient_by_id", fake_find_patient_by_id)
    monkeypatch.setattr(analysis, "save_lab_values_for_patient", fake_save)

    response = client.post(
        "/report-interpreter/analyze-file",
        data={"patientId": "42"},
        files={
            "file": (
                "blood.txt",
                b"Report Date: 2026-02-01\nGlucose: 150 mg/dL (normal: 70-99)",
                "text/plain",
            )
        },
    )

    assert response.status_code == 200
    body = response.json()
    assert body["analysis"]
    assert body["saveErrors"] == ["remote unavailable"]


def test_assign_patient_handles_save_failure(monkeypatch):
    async def fake_find_or_create(name):
        return {"patient_id": 42, "name": name}

    async def fake_save(patient_id, lab_values, report_date, detected_test_type):
        return {"count": 0, "errors": ["write failed"]}

    monkeypatch.setattr(patients, "find_or_create_patient_by_name", fake_find_or_create)
    monkeypatch.setattr("src.backend.api.report_interpreter.find_or_create_patient_by_name", fake_find_or_create)
    monkeypatch.setattr("src.backend.api.report_interpreter.save_lab_values_for_patient", fake_save)

    response = client.post(
        "/report-interpreter/reports/assign-patient",
        json={
            "name": "Test User",
            "labValues": [
                {
                    "name": "Glucose",
                    "value": 150,
                    "normalMin": 70,
                    "normalMax": 99,
                    "unit": "mg/dL",
                    "status": "high",
                }
            ],
            "reportDate": "2026-02-01",
            "detectedTestType": "blood",
        },
    )

    assert response.status_code == 200
    assert response.json()["saveErrors"] == ["write failed"]


def test_ocr_unavailable_returns_degraded_error(monkeypatch):
    monkeypatch.setattr(
        "src.backend.services.report_interpreter.extraction.ocr_status",
        lambda: {"tesseract": False, "poppler": False},
    )

    response = client.post(
        "/report-interpreter/analyze-file",
        files={"file": ("scan.png", b"not really an image", "image/png")},
    )

    assert response.status_code == 500
    assert "Tesseract OCR is required" in response.json()["detail"]
