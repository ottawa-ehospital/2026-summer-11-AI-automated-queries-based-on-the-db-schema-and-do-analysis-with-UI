from __future__ import annotations

from types import SimpleNamespace

import pytest
from fastapi.testclient import TestClient

from src.backend.main import create_app
from src.backend.schemas.nutrition_monitor import NutritionModelCapabilities
from src.backend.services.nutrition_monitor import analysis, context, meals, model_analysis
from src.backend.services.nutrition_monitor.scoring import (
    apply_exact_allergy_risks,
    final_verdict,
)
from src.backend.schemas.nutrition_monitor import PersonalizedInsights


client = TestClient(create_app())


def _cap(supports: bool = True) -> NutritionModelCapabilities:
    return NutritionModelCapabilities(
        supportsImageInput=supports,
        provider="openai",
        model="gpt-4o-mini",
        reason=None if supports else "text-only",
    )


def test_nutrition_health_route_and_existing_ai_routes_registered():
    response = client.get("/nutrition-monitor/health")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"

    paths = {route.path for route in create_app().routes}
    assert "/nutrition-monitor/health" in paths
    assert "/assistant/chat" in paths
    assert "/report-interpreter/health" in paths


def test_unsupported_image_model_guard_rejects_before_context_or_model(monkeypatch):
    context_called = False
    model_called = False

    async def fake_context(patient_id):
        nonlocal context_called
        context_called = True
        return {}

    def fake_model(**kwargs):
        nonlocal model_called
        model_called = True
        return {}

    monkeypatch.setattr(analysis, "get_model_capabilities", lambda: _cap(False))
    monkeypatch.setattr(analysis, "build_ehr_context", fake_context)
    monkeypatch.setattr(analysis, "invoke_food_image_model", fake_model)

    response = client.post(
        "/nutrition-monitor/analyze-image",
        data={"patientId": "42"},
        files={"file": ("meal.jpg", b"image-bytes", "image/jpeg")},
    )

    assert response.status_code == 409
    assert response.json()["detail"]["code"] == "nutrition_image_model_unsupported"
    assert context_called is False
    assert model_called is False


def test_analyze_image_uses_patient_context_and_returns_normalized_result(monkeypatch):
    async def fake_context(patient_id):
        assert patient_id == 42
        return {
            "allergies": [{"allergen": "Peanuts"}],
            "patient": {"name": "A Patient"},
            "latest_vitals": {},
            "blood_tests": [],
            "diagnosed_conditions": [],
        }

    def fake_model(**kwargs):
        assert kwargs["image_bytes"] == b"image-bytes"
        assert "Patient profile" in kwargs["prompt"]
        return {
            "dishName": "Peanuts",
            "portionSize": "1 cup",
            "ingredients": ["Peanuts"],
            "nutritionalBreakdown": {
                "totalCalories": 828,
                "totalProtein": 38,
                "totalFat": 72,
                "totalCarbs": 24,
                "totalSodium": 10,
                "totalSugar": 6,
            },
            "insights": {"risks": [], "warnings": [], "positives": ["High protein"]},
        }

    monkeypatch.setattr(analysis, "get_model_capabilities", lambda: _cap(True))
    monkeypatch.setattr(analysis, "build_ehr_context", fake_context)
    monkeypatch.setattr(analysis, "invoke_food_image_model", fake_model)

    response = client.post(
        "/nutrition-monitor/analyze-image",
        data={"patientId": "42", "hint": "snack"},
        files={"file": ("meal.jpg", b"image-bytes", "image/jpeg")},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["patientId"] == 42
    assert body["dishName"] == "Peanuts"
    assert body["finalVerdict"] == "not_recommended"
    assert body["insights"]["risks"][0].startswith("HIGH RISK")


def test_ollama_image_model_uses_native_images_payload(monkeypatch):
    captured = {}

    class FakeResponse:
        def raise_for_status(self):
            return None

        def json(self):
            return {
                "message": {
                    "content": '{"dishName":"Salad","nutritionalBreakdown":{}}',
                }
            }

    def fake_post(url, *, json, timeout):
        captured["url"] = url
        captured["json"] = json
        captured["timeout"] = timeout
        return FakeResponse()

    monkeypatch.setattr(
        model_analysis,
        "settings",
        SimpleNamespace(
            ai_model_provider="ollama",
            ai_model_name="gemma3:4b",
            ollama_base_url="http://127.0.0.1:11434",
        ),
    )
    monkeypatch.setattr(model_analysis.httpx, "post", fake_post)

    result = model_analysis.invoke_food_image_model(
        image_bytes=b"image-bytes",
        mime_type="application/octet-stream",
        file_name="meal.jpg",
        prompt="Return JSON.",
    )

    assert result["dishName"] == "Salad"
    assert captured["url"] == "http://127.0.0.1:11434/api/chat"
    assert captured["json"]["format"] == "json"
    assert captured["json"]["messages"][0]["images"] == ["aW1hZ2UtYnl0ZXM="]
    assert "image_url" not in captured["json"]["messages"][0]


def test_langchain_image_model_guesses_image_mime_from_file_name(monkeypatch):
    captured = {}

    class FakeMessage:
        content = '{"dishName":"Soup","nutritionalBreakdown":{}}'

    class FakeModel:
        def invoke(self, messages):
            captured["messages"] = messages
            return FakeMessage()

    monkeypatch.setattr(
        model_analysis,
        "settings",
        SimpleNamespace(ai_model_provider="openai"),
    )
    monkeypatch.setattr(model_analysis, "_build_chat_model", lambda: FakeModel())

    result = model_analysis.invoke_food_image_model(
        image_bytes=b"image-bytes",
        mime_type="application/octet-stream",
        file_name="meal.png",
        prompt="Return JSON.",
    )

    assert result["dishName"] == "Soup"
    content = captured["messages"][0].content
    assert content[1]["image_url"]["url"].startswith("data:image/png;base64,")


def test_non_food_analysis_result_prevents_meal_logging():
    payload = {
        "patientId": 42,
        "dishName": "NOT_FOOD",
        "portionSize": "",
        "ingredients": [],
        "nutritionalBreakdown": {
            "totalCalories": 0,
            "totalProtein": 0,
            "totalFat": 0,
            "totalCarbs": 0,
            "totalSodium": 0,
            "totalSugar": 0,
        },
        "insights": {"risks": [], "warnings": [], "positives": []},
        "isFood": False,
    }

    response = client.post("/nutrition-monitor/meals", json=payload)
    assert response.status_code == 400


def test_exact_allergy_match_does_not_infer_related_terms():
    insights = PersonalizedInsights(risks=[], warnings=[], positives=[])
    result = apply_exact_allergy_risks(
        dish_name="Almonds",
        ingredients=["Almonds"],
        allergy_terms=["Peanuts"],
        insights=insights,
    )
    assert result.risks == []

    result = apply_exact_allergy_risks(
        dish_name="Peanuts",
        ingredients=["Peanuts"],
        allergy_terms=["Peanuts"],
        insights=result,
    )
    assert result.risks
    assert final_verdict(result)[0] == "not_recommended"


def test_meal_log_payload_is_patient_scoped_and_does_not_store_image(monkeypatch):
    captured = {}

    async def fake_write(table, row):
        captured["table"] = table
        captured["row"] = row
        return {"data": {**row, "log_id": 123, "logged_at": "2026-07-10T12:00:00Z"}}

    monkeypatch.setattr(meals, "write_ehospital_table_row", fake_write)
    payload = {
        "patientId": 42,
        "dishName": "Salad",
        "portionSize": "1 bowl",
        "ingredients": ["Lettuce"],
        "nutritionalBreakdown": {
            "totalCalories": 120,
            "totalProtein": 4,
            "totalFat": 6,
            "totalCarbs": 12,
            "totalSodium": 80,
            "totalSugar": 5,
        },
        "insights": {"risks": [], "warnings": [], "positives": ["Fresh vegetables"]},
        "isFood": True,
    }

    response = client.post("/nutrition-monitor/meals", json=payload)
    assert response.status_code == 200
    assert captured["table"] == "app_nutrition_log"
    assert captured["row"]["patient_id"] == 42
    assert captured["row"]["image_storage_path"] is None
    assert "image" not in captured["row"]


def test_meal_history_and_daily_summary_are_patient_scoped(monkeypatch):
    async def fake_fetch(table, patient_id):
        assert table == "app_nutrition_log"
        assert patient_id == 42
        return [
            {
                "log_id": 1,
                "patient_id": 42,
                "logged_at": "2026-07-10T08:00:00Z",
                "identified_foods": "Oatmeal",
                "estimated_portions": "1 bowl",
                "ingredients_list": "Oats",
                "calories": 200,
                "protein_g": 8,
                "fat_g": 4,
                "carbohydrates_g": 36,
                "sodium_mg": 90,
                "sugar_g": 3,
                "insight_positive": "Fiber",
            }
        ]

    monkeypatch.setattr(meals, "fetch_ehospital_table", fake_fetch)

    history = client.get("/nutrition-monitor/meals?patientId=42")
    assert history.status_code == 200
    assert history.json()[0]["dishName"] == "Oatmeal"

    summary = client.get("/nutrition-monitor/summary/daily?patientId=42&date=2026-07-10")
    assert summary.status_code == 200
    assert summary.json()["totals"]["totalCalories"] == 200


def test_goal_validation_local_fallback_contract():
    response = client.get("/nutrition-monitor/goals?patientId=42")
    assert response.status_code == 200
    assert response.json()["source"] == "local_fallback"
    assert response.json()["remoteAvailable"] is False

    invalid = client.put(
        "/nutrition-monitor/goals",
        json={"patientId": 42, "goals": {"calories": -1, "protein": 1, "carbs": 1, "fat": 1}},
    )
    assert invalid.status_code == 400
