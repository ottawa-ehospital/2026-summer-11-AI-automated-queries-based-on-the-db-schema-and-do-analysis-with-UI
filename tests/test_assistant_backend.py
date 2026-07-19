import sys
import asyncio
from pathlib import Path

from fastapi.testclient import TestClient

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

from fastapi import HTTPException

from src.backend.main import app
from src.backend.schemas.assistant import ModelInvocationSettings
from src.backend.services import patient_context_service
from src.backend.services import assistant_service
from src.backend.services.assistant.base import AssistantProvider
from src.backend.services.assistant.factory import (
    ASSISTANT_PROVIDER_DIRECT_GEMINI,
    ASSISTANT_PROVIDER_DIRECT_LOCAL,
    ASSISTANT_PROVIDER_WEARABLE_LANGGRAPH,
    AssistantProviderFactory,
)
from src.backend.services.assistant.providers import direct_gemini, direct_local
from src.backend.services.assistant.providers import wearable_langgraph
from src.backend.services.assistant.workflows import health_data_query, wearable_chart
from src.backend.services.assistant.providers.direct_gemini import DirectGeminiAssistantProvider
from src.backend.services.assistant.providers.direct_local import DirectLocalAssistantProvider
from src.backend.services.assistant.providers.wearable_langgraph import (
    WearableLangGraphAssistantProvider,
)
from src.backend.services.assistant.workflow_router import WorkflowRouter
from src.backend.services.assistant.workflows.base import (
    AssistantWorkflowState,
    WorkflowMatch,
)
from src.backend.services.assistant.workflows.general_chat import GeneralChatWorkflow
from src.backend.services.assistant.workflows.health_data_query import (
    MAX_OUTPUT_VALIDATION_ATTEMPTS,
    MAX_QUERY_VALIDATION_ATTEMPTS,
    HealthDataQueryWorkflow,
    analyse_message_intent,
    build_chart_payload,
    build_context_plan,
    build_model_backed_sigma,
    build_sigma_query,
    build_health_data_query_graph,
    build_schema_planning_context,
    model_backed_intent_analysis,
    report_expiration_for_category,
    route_output_validation,
    route_query_validation,
)
from src.backend.services.assistant.workflows.registry import WorkflowRegistry


client = TestClient(app)


def test_assistant_chat(monkeypatch):
    async def fake_context(patient_id):
        return {"patient_id": patient_id, "latest_wearable": [{"steps": 1000}]}

    monkeypatch.setattr(direct_local, "build_patient_context", fake_context)
    monkeypatch.setattr(direct_local, "invoke_model", lambda prompt, system: "hello")

    response = client.post(
        "/assistant/chat",
        json={"patient_id": 20, "message": "What is my health summary?"},
    )

    assert response.status_code == 200
    assert response.json() == {
        "reply": "hello",
        "results": [{"type": "text", "content": "hello"}],
    }


def test_assistant_chat_omits_invocation_uses_default_two_arg_model(monkeypatch):
    captured = {}

    async def fake_context(patient_id):
        return {"patient_id": patient_id}

    def fake_model(prompt, system):
        captured["called"] = True
        return "default model"

    monkeypatch.setattr(direct_local, "build_patient_context", fake_context)
    monkeypatch.setattr(direct_local, "invoke_model", fake_model)

    response = client.post(
        "/assistant/chat",
        json={"patient_id": 20, "message": "hello"},
    )

    assert response.status_code == 200
    assert captured["called"] is True
    assert response.json()["reply"] == "default model"


def test_assistant_chat_routes_supported_runtime_provider(monkeypatch):
    captured = {}

    async def fake_context(patient_id):
        return {"patient_id": patient_id}

    def fake_model(prompt, system, invocation):
        captured["provider_key"] = invocation.provider_key
        captured["model_name"] = invocation.model_name
        return "runtime provider"

    monkeypatch.setattr(direct_gemini, "build_patient_context", fake_context)
    monkeypatch.setattr(direct_gemini, "invoke_model", fake_model)

    response = client.post(
        "/assistant/chat",
        json={
            "patient_id": 20,
            "message": "hello",
            "model_invocation": {
                "provider_key": ASSISTANT_PROVIDER_DIRECT_GEMINI,
                "model_provider": "ollama",
                "model_name": "llama3.1:8b",
                "base_url": "http://127.0.0.1:11434",
                "use_graph_flow": False,
            },
        },
    )

    assert response.status_code == 200
    assert response.json()["reply"] == "runtime provider"
    assert captured == {
        "provider_key": ASSISTANT_PROVIDER_DIRECT_GEMINI,
        "model_name": "llama3.1:8b",
    }


def test_assistant_chat_rejects_unsupported_runtime_provider():
    response = client.post(
        "/assistant/chat",
        json={
            "patient_id": 20,
            "message": "hello",
            "model_invocation": {"provider_key": "not_real"},
        },
    )

    assert response.status_code == 400
    assert "Unsupported assistant provider" in response.json()["detail"]


def test_assistant_chat_rejects_incomplete_runtime_model_settings():
    response = client.post(
        "/assistant/chat",
        json={
            "patient_id": 20,
            "message": "hello",
            "model_invocation": {
                "provider_key": ASSISTANT_PROVIDER_DIRECT_LOCAL,
                "model_provider": "ollama",
                "model_name": "llama3.1:8b",
            },
        },
    )

    assert response.status_code == 400
    assert "base_url is required" in response.json()["detail"]


def test_assistant_chat_includes_history(monkeypatch):
    captured = {}

    async def fake_context(patient_id):
        return {"patient_id": patient_id}

    def fake_model(prompt, system):
        captured["prompt"] = prompt
        return "hello"

    monkeypatch.setattr(direct_local, "build_patient_context", fake_context)
    monkeypatch.setattr(direct_local, "invoke_model", fake_model)

    response = client.post(
        "/assistant/chat",
        json={
            "patient_id": 20,
            "message": "What should I know about my general wellness?",
            "history": [
                {"role": "user", "content": "How were my steps?"},
                {"role": "assistant", "content": "Your steps improved."},
            ],
        },
    )

    assert response.status_code == 200
    assert "Recent conversation context" in captured["prompt"]
    assert "user: How were my steps?" in captured["prompt"]
    assert "assistant: Your steps improved." in captured["prompt"]
    assert captured["prompt"].endswith("What should I know about my general wellness?")


def test_assistant_chat_history_is_bounded(monkeypatch):
    captured = {}

    async def fake_context(patient_id):
        return {"patient_id": patient_id}

    def fake_model(prompt, system):
        captured["prompt"] = prompt
        return "hello"

    monkeypatch.setattr(direct_local, "build_patient_context", fake_context)
    monkeypatch.setattr(direct_local, "invoke_model", fake_model)

    history = [
        {"role": "user" if index % 2 == 0 else "assistant", "content": f"message {index}"}
        for index in range(12)
    ]
    response = client.post(
        "/assistant/chat",
        json={"patient_id": 20, "message": "Continue", "history": history},
    )

    assert response.status_code == 200
    lines = captured["prompt"].splitlines()
    assert "user: message 0" not in lines
    assert "assistant: message 1" not in lines
    assert "user: message 2" in lines
    assert "assistant: message 11" in lines


def test_assistant_chat_response_contract_can_be_implemented_by_multiple_providers():
    class FakeAssistant(AssistantProvider):
        async def chat(self, patient_id, message, history=None):
            return assistant_service.compose_text_response("contract ok")

    fake = FakeAssistant()

    assert isinstance(fake, AssistantProvider)
    response = asyncio.run(fake.chat(20, "hello"))
    assert response.reply == "contract ok"
    assert response.results[0].type == "text"


def test_assistant_provider_factory_selects_default_provider():
    provider = AssistantProviderFactory().create()

    assert isinstance(provider, WearableLangGraphAssistantProvider)


def test_assistant_provider_factory_selects_named_providers():
    factory = AssistantProviderFactory()

    assert isinstance(factory.create(ASSISTANT_PROVIDER_WEARABLE_LANGGRAPH), AssistantProvider)
    assert isinstance(factory.create(ASSISTANT_PROVIDER_DIRECT_GEMINI), DirectGeminiAssistantProvider)
    assert isinstance(factory.create(ASSISTANT_PROVIDER_DIRECT_LOCAL), DirectLocalAssistantProvider)


def test_assistant_provider_factory_rejects_unknown_provider():
    try:
        AssistantProviderFactory().create("made_up_provider")
    except ValueError as exc:
        assert "Unsupported ASSISTANT_PROVIDER" in str(exc)
        assert ASSISTANT_PROVIDER_WEARABLE_LANGGRAPH in str(exc)
    else:
        raise AssertionError("Unknown provider key should be rejected.")


def test_assistant_chat_rejects_empty_message():
    response = client.post(
        "/assistant/chat",
        json={"patient_id": 20, "message": "   "},
    )

    assert response.status_code == 400


def test_validate_assistant_result_payload_accepts_chart():
    valid, errors, normalized = assistant_service.validate_assistant_result_payload(
        {
            "type": "chart",
            "displayType": "line",
            "title": "Recent heart rate",
            "xAxis": {"label": "Time", "type": "time"},
            "yAxis": {"label": "Heart rate", "unit": "bpm"},
            "series": [
                {
                    "name": "Heart rate",
                    "points": [{"x": "2026-06-01T09:00:00Z", "y": 72}],
                }
            ],
        }
    )

    assert valid is True
    assert errors == []
    assert normalized["displayType"] == "line"


def test_validate_assistant_result_payload_rejects_invalid_chart():
    valid, errors, normalized = assistant_service.validate_assistant_result_payload(
        {
            "type": "chart",
            "displayType": "pie",
            "title": "Bad chart",
            "xAxis": {"label": "Time"},
            "yAxis": {"label": "Heart rate"},
            "series": [{"name": "Heart rate", "points": [{"x": "now", "y": "high"}]}],
        }
    )

    assert valid is False
    assert normalized is None
    assert any("displayType" in error for error in errors)
    assert any("must be numeric" in error for error in errors)


def test_validate_assistant_result_payload_accepts_markdown_report():
    valid, errors, normalized = assistant_service.validate_assistant_result_payload(
        {
            "type": "report",
            "format": "markdown",
            "title": "Sleep report",
            "content": "## Summary\nSleep was short.",
            "generatedAt": "2026-06-20T12:00:00Z",
            "expiresAt": "2026-06-21T12:00:00Z",
            "freshnessReason": "Sleep signals can change after the next sleep cycle.",
            "sourceSummary": "Based on wearable sleep records.",
        }
    )

    assert valid is True
    assert errors == []
    assert normalized["type"] == "report"
    assert normalized["format"] == "markdown"


def test_validate_assistant_result_payload_rejects_invalid_report():
    valid, errors, normalized = assistant_service.validate_assistant_result_payload(
        {
            "type": "report",
            "format": "markdown",
            "title": "Bad report",
            "content": "<script>alert(1)</script>",
            "generatedAt": "2026-06-21T12:00:00Z",
            "expiresAt": "2026-06-20T12:00:00Z",
            "freshnessReason": "Bad dates.",
        }
    )

    assert valid is False
    assert normalized is None
    assert any("expiresAt" in error for error in errors)
    assert any("raw HTML" in error for error in errors)


def test_workflow_registry_rejects_duplicate_keys():
    workflow = HealthDataQueryWorkflow()
    registry = WorkflowRegistry([workflow])

    try:
        registry.register(workflow)
    except ValueError as exc:
        assert "Duplicate assistant workflow key" in str(exc)
    else:
        raise AssertionError("Duplicate workflow keys should be rejected.")


def test_workflow_router_falls_back_when_no_workflow_matches():
    class NeverWorkflow:
        key = "never"
        description = "never"

        async def can_handle(self, state):
            return WorkflowMatch(self.key, 0.0, "no")

        async def run(self, state):
            raise AssertionError("Specialized workflow should not run.")

    class FakeFallbackProvider(AssistantProvider):
        async def chat(self, patient_id, message, history=None):
            return assistant_service.compose_text_response("fallback ok")

    router = WorkflowRouter(
        WorkflowRegistry([NeverWorkflow()]),
        GeneralChatWorkflow(FakeFallbackProvider()),
    )

    response = asyncio.run(
        router.route(AssistantWorkflowState(patient_id=20, message="hello"))
    )

    assert response.reply == "fallback ok"


def test_workflow_router_routes_explicit_report_to_health_data_query(monkeypatch):
    async def fake_query_table(request):
        return {
            "count": 2,
            "data": [
                {"timestamp": "2026-06-01T10:00:00Z", "heart_rate": 74},
                {"timestamp": "2026-06-02T10:00:00Z", "heart_rate": 82},
            ],
        }

    monkeypatch.setattr(health_data_query, "query_table", fake_query_table)

    class FakeFallbackProvider(AssistantProvider):
        async def chat(self, patient_id, message, history=None):
            return assistant_service.compose_text_response("fallback")

    router = WorkflowRouter(
        WorkflowRegistry([HealthDataQueryWorkflow()]),
        GeneralChatWorkflow(FakeFallbackProvider()),
    )

    response = asyncio.run(
        router.route(
            AssistantWorkflowState(
                patient_id=20,
                message="Please generate a heart rate analysis report",
            )
        )
    )

    assert response.reply == "Found 2 recent heart rate readings."
    assert response.results[1].type == "report"
    assert response.results[2].type == "chart"


def test_default_orchestrator_routes_metric_request_to_report(monkeypatch):
    async def fake_query_table(request):
        assert request.table == "wearable_vitals"
        assert request.filters[0].field == "patient_id"
        return {
            "count": 2,
            "data": [
                {"timestamp": "2026-06-01T10:00:00Z", "heart_rate": 74},
                {"timestamp": "2026-06-02T10:00:00Z", "heart_rate": 82},
            ],
        }

    monkeypatch.setattr(health_data_query, "query_table", fake_query_table)

    response = client.post(
        "/assistant/chat",
        json={"patient_id": 20, "message": "How has my recent heart rate been?"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["reply"] == "Found 2 recent heart rate readings."
    assert body["results"][1]["type"] == "report"
    assert body["results"][1]["format"] == "markdown"
    assert body["results"][1]["expiresAt"]
    assert (
        "latest available heart rate record at 2026-06-02T10:00:00Z"
        in body["results"][1]["freshnessReason"]
    )
    assert "sleep or readiness" not in body["results"][1]["freshnessReason"]
    assert "latest heart rate value (82 bpm)" in body["results"][1]["content"]
    assert body["results"][2]["type"] == "chart"
    assert body["results"][2]["displayType"] == "line"


def test_default_orchestrator_routes_exercise_plan_request_to_report(monkeypatch):
    async def fake_query_table(request):
        if request.table == "wearable_workouts":
            return {
                "count": 2,
                "data": [
                    {
                        "workout_type": "running",
                        "start_time": "2026-06-01T10:00:00Z",
                        "duration_seconds": 1500,
                        "distance_meters": 3500,
                        "average_heart_rate_bpm": 138,
                    },
                    {
                        "workout_type": "walking",
                        "start_time": "2026-06-02T10:00:00Z",
                        "duration_seconds": 2100,
                        "distance_meters": 3000,
                        "average_heart_rate_bpm": 112,
                    },
                ],
            }
        return {"count": 0, "data": []}

    monkeypatch.setattr(health_data_query, "query_table", fake_query_table)

    response = client.post(
        "/assistant/chat",
        json={"patient_id": 20, "message": "Can you make me a running plan for tomorrow?"},
    )

    assert response.status_code == 200
    body = response.json()
    assert body["reply"].startswith("Found 2 recent workout record")
    report = body["results"][1]
    assert report["type"] == "report"
    assert report["title"] == "Personalized Health Plan Report"
    assert report["content"].startswith("## Answer")
    assert "## Analysis" in report["content"]
    assert "## Recommended action" in report["content"]
    assert "## Context checked" in report["content"]
    assert body["results"][2]["type"] == "chart"
    assert body["results"][2]["displayType"] == "bar"
    assert body["results"][2]["title"] == "Recent Workout Distance"


def test_health_data_query_workflow_returns_markdown_report(monkeypatch):
    async def fake_query_table(request):
        return {
            "count": 2,
            "data": [
                {"timestamp": "2026-06-01T10:00:00Z", "sleep": 6.5},
                {"timestamp": "2026-06-02T10:00:00Z", "sleep": 7.0},
            ],
        }

    monkeypatch.setattr(health_data_query, "query_table", fake_query_table)

    response = asyncio.run(HealthDataQueryWorkflow().run(
        AssistantWorkflowState(patient_id=20, message="Please generate a sleep report")
    ))

    assert response.reply == "Found 2 recent sleep readings."
    report = response.results[1]
    assert report.type == "report"
    assert report.format == "markdown"
    assert "## Answer" in report.content
    assert "## Analysis" in report.content
    assert "## Recommended action" in report.content
    assert report.expiresAt > report.generatedAt


def test_health_data_intent_analysis_identifies_metric_and_planning():
    metric_intent = analyse_message_intent("How has my recent heart rate been?")
    plan_intent = analyse_message_intent("Can I run tomorrow?")
    ambiguous_intent = analyse_message_intent("What is my health summary?")

    assert metric_intent["metric"] == "heart_rate"
    assert metric_intent["candidate_tables"] == ["wearable_vitals"]
    assert plan_intent["kind"] == "health_plan"
    assert plan_intent["requires_query"] is True
    assert ambiguous_intent["needs_clarification"] is True
    assert ambiguous_intent["confidence"] < 0.6


def test_health_data_builds_deterministic_sigma():
    state = {
        "patient_id": 20,
        "message": "heart rate",
        "intent": analyse_message_intent("heart rate"),
    }

    sigma = build_sigma_query(state)

    assert sigma["logsource"]["service"] == "wearable_vitals"
    assert sigma["detection"]["selection"]["patient_id"] == "__CURRENT_PATIENT__"
    assert sigma["fields"] == ["timestamp", "heart_rate"]


def test_health_data_training_readiness_forces_multi_table_context_plan():
    state = {
        "patient_id": 20,
        "message": "can I participate in any intensive training tomorrow",
        "intent": analyse_message_intent(
            "can I participate in any intensive training tomorrow"
        ),
    }

    plan = build_context_plan(state)
    planned_tables = [
        entry["sigma"]["logsource"]["service"]
        for entry in plan["queries"]
    ]

    assert state["intent"]["kind"] == "health_plan"
    assert state["intent"]["metric"] == "heart_rate"
    assert "wearable_workouts" in state["intent"]["candidate_tables"]
    assert planned_tables == [
        "wearable_vitals",
        "vitals_history",
        "lab_tests",
        "bloodtests",
        "diagnosis",
        "medical_history",
        "prescription_form",
        "wearable_workouts",
    ]


def test_health_data_medication_sensitive_context_plan_includes_history_and_medication():
    state = {
        "patient_id": 20,
        "message": "Should I train tomorrow with my blood pressure medication?",
        "intent": analyse_message_intent(
            "Should I train tomorrow with my blood pressure medication?"
        ),
    }

    plan = build_context_plan(state)
    planned_tables = {
        entry["sigma"]["logsource"]["service"]
        for entry in plan["queries"]
    }

    assert {
        "wearable_vitals",
        "vitals_history",
        "lab_tests",
        "bloodtests",
        "diagnosis",
        "medical_history",
        "prescription_form",
        "wearable_workouts",
    }.issubset(planned_tables)


def test_health_data_training_readiness_partial_context_and_safety_hints(monkeypatch):
    async def fake_query_table(request):
        if request.table == "wearable_vitals":
            return {
                "count": 1,
                "data": [
                    {
                        "timestamp": "2026-07-02T09:00:00Z",
                        "heart_rate": 86,
                        "sleep": 3.5,
                        "steps": 500,
                        "calories": 120,
                    }
                ],
            }
        if request.table == "vitals_history":
            return {
                "count": 1,
                "data": [
                    {
                        "recorded_on": "2026-07-02T08:30:00Z",
                        "blood_pressure": "145/92",
                        "heart_rate": 88,
                    }
                ],
            }
        if request.table == "wearable_workouts":
            return {
                "count": 1,
                "data": [
                    {
                        "workout_type": "running",
                        "start_time": "2026-07-01T10:00:00Z",
                        "duration_seconds": 1800,
                        "distance_meters": 5000,
                    }
                ],
            }
        return {"count": 0, "data": []}

    monkeypatch.setattr(health_data_query, "query_table", fake_query_table)

    result = asyncio.run(
        build_health_data_query_graph().ainvoke(
            {
                "patient_id": 20,
                "message": "Can I do intensive training tomorrow?",
                "history": [],
                "model_invocation": None,
                "query_validation_attempts": 0,
                "analysis_validation_attempts": 0,
                "output_validation_attempts": 0,
                "trace": {"selected_workflow": "health_data_query"},
            }
        )
    )

    planned_tables = result["trace"]["selected_tables"]
    assert planned_tables == [
        "wearable_vitals",
        "vitals_history",
        "lab_tests",
        "bloodtests",
        "diagnosis",
        "medical_history",
        "prescription_form",
        "wearable_workouts",
    ]
    assert result["row_counts"]["wearable_vitals"] == 1
    assert result["row_counts"]["vitals_history"] == 1
    assert any(item["table"] == "diagnosis" for item in result["missing_context"])
    assert {item["code"] for item in result["safety_hints"]} == {
        "low_sleep",
        "high_blood_pressure",
    }
    recommendations = " ".join(result["analysis"]["recommendations"]).lower()
    evidence = " ".join(
        str(item.get("value"))
        for item in result["analysis"]["evidence"]
        if isinstance(item, dict)
    ).lower()
    assert "avoid intensive training" in recommendations
    assert "145/92" in evidence
    assert result["analysis"]["chartCandidates"][0]["title"].lower() == "recent heart rate"
    assert any(
        candidate["title"] == "Recent Blood Pressure"
        for candidate in result["analysis"]["chartCandidates"]
    )
    chart_payload = health_data_query.build_chart_payload(
        {**result, "analysis": {"chartCandidates": [result["analysis"]["chartCandidates"][1]]}}
    )
    assert chart_payload is not None
    assert chart_payload["title"] == "Recent Blood Pressure"
    assert chart_payload["series"][0]["points"][0]["y"] == 145
    report_content = result["report_payload"]["content"]
    assert report_content.startswith("## Answer")
    assert report_content.index("## Analysis") < report_content.index("## Recommended action")
    assert report_content.index("## Recommended action") < report_content.index("## Why")
    assert report_content.index("## Why") < report_content.index("## Context checked")
    assert "Avoid intensive training" in report_content
    assert "Recent blood pressure is 145/92 mmHg" in report_content
    assert "Clinical vitals: 1 row(s)" in report_content
    assert "Lab tests: 0 row(s)" in report_content
    assert "Blood tests: 0 row(s)" in report_content
    assert "vitals_history rows" not in report_content
    assert result["trace"]["row_counts"]["wearable_workouts"] == 1


def test_health_data_context_fallback_interprets_small_vitals_set():
    context_package = {
        "rowsByTable": {
            "wearable_vitals": [
                {
                    "timestamp": "2026-07-14T02:30:00Z",
                    "heart_rate": 68,
                    "steps": 420,
                    "calories": 34,
                    "sleep": 7.4,
                },
                {
                    "timestamp": "2026-07-14T03:40:00Z",
                    "heart_rate": 72,
                    "steps": 1260,
                    "calories": 92,
                    "sleep": 7.4,
                },
                {
                    "timestamp": "2026-07-14T04:50:00Z",
                    "heart_rate": 70,
                    "steps": 2180,
                    "calories": 158,
                    "sleep": 7.4,
                },
            ],
            "vitals_history": [
                {
                    "recorded_on": "2026-07-14T02:45:00Z",
                    "blood_pressure": "116/74",
                    "heart_rate": 68,
                    "systolic_bp": 116,
                    "diastolic_bp": 74,
                },
                {
                    "recorded_on": "2026-07-14T04:20:00Z",
                    "blood_pressure": "118/76",
                    "heart_rate": 70,
                    "systolic_bp": 118,
                    "diastolic_bp": 76,
                },
            ],
            "diagnosis": [],
            "medical_history": [],
            "prescription_form": [],
            "wearable_workouts": [],
        },
        "rowCounts": {
            "wearable_vitals": 3,
            "vitals_history": 2,
            "diagnosis": 0,
            "medical_history": 0,
            "prescription_form": 0,
            "wearable_workouts": 0,
        },
        "missingContext": [],
        "safetyHints": [],
    }

    analysis = health_data_query.deterministic_context_analysis(
        {"kind": "health_report", "metric": None, "freshness_category": "short_term"},
        context_package,
    )

    combined = " ".join(
        [
            analysis["summary"],
            " ".join(item["value"] for item in analysis["evidence"]),
            " ".join(analysis["recommendations"]),
        ]
    )

    assert "Found 5 patient context row" not in analysis["summary"]
    assert "Short-term wellness picture looks stable" in analysis["summary"]
    assert "blood pressure stayed in a normal-looking range" in analysis["summary"]
    assert any("Cardiovascular:" in item for item in analysis["findings"])
    assert any("Recovery:" in item for item in analysis["findings"])
    assert any("Activity load:" in item for item in analysis["findings"])
    assert "7.4 hours" in combined
    assert "normal light-to-moderate activity looks reasonable" in combined


def test_health_data_training_safety_hints_detect_symptoms():
    hints = health_data_query.derive_training_safety_hints(
        {
            "patient_feedback": [
                {
                    "datetime": "2026-07-02T09:00:00Z",
                    "feedback": "Chest discomfort and dizziness after walking.",
                    "is_severe": False,
                }
            ]
        }
    )

    assert any(item["code"] == "symptoms_present" for item in hints)


def test_health_data_builds_deterministic_workout_sigma():
    state = {
        "patient_id": 20,
        "message": "Can I start running again after a long break?",
        "intent": analyse_message_intent("Can I start running again after a long break?"),
    }

    sigma = build_sigma_query(state)

    assert state["intent"]["metric"] == "workout_history"
    assert "wearable_workouts" in state["intent"]["candidate_tables"]
    assert sigma["logsource"]["service"] == "wearable_workouts"
    assert sigma["detection"]["selection"]["patient_id"] == "__CURRENT_PATIENT__"
    assert "duration_seconds" in sigma["fields"]
    assert "distance_meters" in sigma["fields"]
    assert sigma["order_by"][0]["field"] == "start_time"


def test_health_data_schema_context_includes_workout_fields():
    context = build_schema_planning_context()
    workout_context = next(
        item for item in context if item["name"] == "wearable_workouts"
    )

    assert "patient_id" in workout_context["patientScopeFields"]
    assert "workout_type" in workout_context["attributes"]
    assert "duration_seconds" in workout_context["attributes"]
    assert "distance_meters" in workout_context["attributes"]


def test_health_data_model_backed_intent_analysis(monkeypatch):
    def fake_model(prompt, system, invocation):
        return (
            '{"kind":"health_report","metric":"sleep","target_metrics":["sleep"],'
            '"candidate_tables":["wearable_vitals"],"output_needs":["text","report"],'
            '"freshness_category":"short_term","requires_query":true,'
            '"needs_clarification":false,"confidence":0.91,"reason":"sleep request"}'
        )

    monkeypatch.setattr(health_data_query, "invoke_model", fake_model)

    intent = model_backed_intent_analysis(
        "Could you check my recovery?",
        ModelInvocationSettings(
            model_provider="ollama",
            model_name="llama3.1:8b",
            base_url="http://127.0.0.1:11434",
        ),
    )

    assert intent is not None
    assert intent["metric"] == "sleep"
    assert intent["confidence"] == 0.91


def test_health_data_model_backed_sigma_planning(monkeypatch):
    def fake_model(prompt, system, invocation):
        assert "Do not return SQL" in prompt
        return (
            '{"title":"Sleep query","logsource":{"service":"wearable_vitals"},'
            '"detection":{"selection":{"patient_id":"__CURRENT_PATIENT__"},"condition":"selection"},'
            '"fields":["timestamp","sleep"],"order_by":[{"field":"timestamp","direction":"desc"}],"limit":20}'
        )

    monkeypatch.setattr(health_data_query, "invoke_model", fake_model)

    sigma = build_model_backed_sigma(
        {
            "message": "sleep report",
            "context": {"schema_context": [{"name": "wearable_vitals"}]},
            "sigma_errors": [],
        },
        ModelInvocationSettings(
            model_provider="ollama",
            model_name="llama3.1:8b",
            base_url="http://127.0.0.1:11434",
        ),
    )

    assert sigma is not None
    assert sigma["logsource"]["service"] == "wearable_vitals"
    assert sigma["fields"] == ["timestamp", "sleep"]


def test_health_data_query_workflow_uses_uploaded_workout_rows(monkeypatch):
    async def fake_query_table(request):
        assert request.filters[0].field == "patient_id"
        if request.table == "wearable_workouts":
            assert request.fields == [
                "workout_type",
                "start_time",
                "end_time",
                "duration_seconds",
                "distance_meters",
                "active_energy_kcal",
                "average_heart_rate_bpm",
                "max_heart_rate_bpm",
                "source_provider",
            ]
            return {
                "count": 1,
                "data": [
                    {
                        "workout_type": "running",
                        "start_time": "2026-06-20T10:00:00Z",
                        "duration_seconds": 1800,
                        "distance_meters": 5000,
                        "average_heart_rate_bpm": 142,
                    }
                ],
            }
        return {"count": 0, "data": []}

    monkeypatch.setattr(health_data_query, "query_table", fake_query_table)

    response = asyncio.run(
        HealthDataQueryWorkflow().run(
            AssistantWorkflowState(
                patient_id=20,
                message="Can I start running again after not exercising recently?",
            )
        )
    )

    assert "Found 1 recent workout record" in response.reply
    report = next(result for result in response.results if result.type == "report")
    assert report.type == "report"
    assert "Latest workout type" in report.content
    assert "running" in report.content
    chart = next(result for result in response.results if result.type == "chart")
    assert chart.displayType == "bar"
    assert chart.title == "Recent Workout Distance"
    assert chart.series[0].points[0].y == 5000


def test_health_data_model_analysis_preserves_workout_chart_candidate(monkeypatch):
    async def fake_query_table(request):
        return {
            "count": 1,
            "data": [
                {
                    "workout_type": "running",
                    "start_time": "2026-06-20T10:00:00Z",
                    "duration_seconds": 1800,
                    "distance_meters": 5000,
                    "average_heart_rate_bpm": 142,
                }
            ],
        }

    def fake_model(prompt, system, invocation):
        return (
            '{"summary":"A careful return-to-running plan is reasonable.",'
            '"evidence":[],"recommendations":[],"limitations":[],'
            '"freshnessCategory":"short_term","chartCandidates":[]}'
        )

    monkeypatch.setattr(health_data_query, "query_table", fake_query_table)
    monkeypatch.setattr(health_data_query, "invoke_model", fake_model)

    response = asyncio.run(
        HealthDataQueryWorkflow().run(
            AssistantWorkflowState(
                patient_id=20,
                message="Can I start running again after not exercising recently?",
                model_invocation=ModelInvocationSettings(
                    model_provider="ollama",
                    model_name="llama3.1:8b",
                    base_url="http://127.0.0.1:11434",
                ),
            )
        )
    )

    assert response.reply == "A careful return-to-running plan is reasonable."
    chart = next(result for result in response.results if result.type == "chart")
    assert chart.title == "Recent Workout Distance"


def test_health_data_query_workflow_hides_missing_workout_table_502(monkeypatch):
    async def fake_query_table(request):
        raise HTTPException(
            status_code=502,
            detail=(
                "Failed to execute eHospital SELECT query: "
                "Table 'DEV01.wearable_workouts' doesn't exist"
            ),
        )

    monkeypatch.setattr(health_data_query, "query_table", fake_query_table)

    response = asyncio.run(
        HealthDataQueryWorkflow().run(
            AssistantWorkflowState(
                patient_id=20,
                message="am I suitable for running",
            )
        )
    )

    assert "could not find matching patient data" in response.reply.lower()
    report = next(result for result in response.results if result.type == "report")
    assert "Workout history is not available" in report.content
    assert "502" not in report.content


def test_health_data_unsupported_chart_candidate_degrades_to_no_chart():
    payload = build_chart_payload(
        {
            "query_result": {
                "data": [{"timestamp": "2026-06-01T10:00:00Z", "heart_rate": 74}],
            },
            "analysis": {
                "chartCandidates": [
                    {
                        "title": "Bad chart",
                        "displayType": "pie",
                        "xField": "timestamp",
                        "yField": "heart_rate",
                    }
                ]
            },
        }
    )

    assert payload is None


def test_health_data_model_analysis_falls_back_on_malformed_output(monkeypatch):
    async def fake_query_table(request):
        return {
            "count": 1,
            "data": [{"timestamp": "2026-06-01T10:00:00Z", "heart_rate": 74}],
        }

    def fake_model(prompt, system, invocation):
        return "not json"

    monkeypatch.setattr(health_data_query, "query_table", fake_query_table)
    monkeypatch.setattr(health_data_query, "invoke_model", fake_model)

    response = asyncio.run(
        HealthDataQueryWorkflow().run(
            AssistantWorkflowState(
                patient_id=20,
                message="heart rate report",
                model_invocation=ModelInvocationSettings(
                    model_provider="ollama",
                    model_name="llama3.1:8b",
                    base_url="http://127.0.0.1:11434",
                ),
            )
        )
    )

    assert response.reply == "Found 1 recent heart rate readings."


def test_health_data_query_workflow_query_retry_limit_routes_to_fallback():
    route = route_query_validation(
        {
            "query_valid": False,
            "query_validation_attempts": MAX_QUERY_VALIDATION_ATTEMPTS,
        }
    )

    assert route == "fallback_response"


def test_health_data_query_workflow_output_retry_limit_routes_to_fallback():
    route = route_output_validation(
        {
            "output_valid": False,
            "output_validation_attempts": MAX_OUTPUT_VALIDATION_ATTEMPTS,
        }
    )

    assert route == "fallback_response"


def test_report_expiration_short_term_is_shorter_than_long_term():
    from datetime import datetime, timezone

    generated_at = datetime(2026, 6, 20, 12, 0, tzinfo=timezone.utc)
    short_expires, _ = report_expiration_for_category("short_term", generated_at)
    long_expires, _ = report_expiration_for_category("long_term", generated_at)

    assert short_expires < long_expires


def test_legacy_heart_rate_graph_builder_returns_chart(monkeypatch):
    async def fake_query_table(request):
        assert request.table == "wearable_vitals"
        assert request.fields == ["timestamp", "heart_rate"]
        assert request.filters[0].field == "patient_id"
        return {
            "count": 2,
            "data": [
                {"timestamp": "2026-06-02T10:00:00Z", "heart_rate": 82},
                {"timestamp": "2026-06-01T10:00:00Z", "heart_rate": 74},
            ],
        }

    monkeypatch.setattr(wearable_chart, "query_table", fake_query_table)

    response = asyncio.run(wearable_langgraph.build_wearable_chart_response(20, "heart rate"))

    assert response is not None
    assert response.reply == "Here is your recent heart rate trend."
    chart = response.results[1]
    assert chart.type == "chart"
    assert chart.displayType == "line"
    assert chart.series[0].points[0].y == 74


def test_direct_gemini_provider_returns_structured_text(monkeypatch):
    async def fake_context(patient_id):
        return {"patient_id": patient_id}

    monkeypatch.setattr(direct_gemini, "build_patient_context", fake_context)
    monkeypatch.setattr(direct_gemini, "invoke_model", lambda prompt, system: "gemini text")

    response = asyncio.run(DirectGeminiAssistantProvider().chat(20, "hello"))

    assert response.reply == "gemini text"
    assert response.results[0].type == "text"


def test_direct_local_provider_returns_structured_text(monkeypatch):
    async def fake_context(patient_id):
        return {"patient_id": patient_id}

    monkeypatch.setattr(direct_local, "build_patient_context", fake_context)
    monkeypatch.setattr(direct_local, "invoke_model", lambda prompt, system: "local text")

    response = asyncio.run(DirectLocalAssistantProvider().chat(20, "hello"))

    assert response.reply == "local text"
    assert response.results[0].type == "text"


def test_patient_context_accepts_ehospital_user_id(monkeypatch):
    async def fake_fetch_table(table, patient_id=None):
        if table == "users":
            return [{"user_id": 20, "username": "jgreen"}]
        return []

    monkeypatch.setattr(patient_context_service, "fetch_ehospital_table", fake_fetch_table)

    context = asyncio.run(patient_context_service.build_patient_context(20))

    assert context["patient"]["username"] == "jgreen"


def test_vitals_summary(monkeypatch):
    async def fake_context(patient_id):
        return {"patient_id": patient_id}

    monkeypatch.setattr(direct_local, "build_patient_context", fake_context)
    monkeypatch.setattr(assistant_service, "invoke_model", lambda prompt, system: "summary")

    response = client.post(
        "/assistant/vitals-summary",
        json={
            "patient_id": 20,
            "metric": "Steps",
            "latest": 1000,
            "average": 900,
            "peak": 1200,
            "unit": "steps",
            "healthy_range": "5000-15000",
        },
    )

    assert response.status_code == 200
    assert response.json() == {"summary": "summary"}


def test_vitals_summary_uses_runtime_invocation(monkeypatch):
    captured = {}

    async def fake_context(patient_id):
        return {"patient_id": patient_id}

    def fake_model(prompt, system, invocation):
        captured["model_name"] = invocation.model_name
        return "runtime summary"

    monkeypatch.setattr(assistant_service, "build_patient_context", fake_context)
    monkeypatch.setattr(assistant_service, "invoke_model", fake_model)

    response = client.post(
        "/assistant/vitals-summary",
        json={
            "patient_id": 20,
            "metric": "Steps",
            "unit": "steps",
            "healthy_range": "5000-15000",
            "model_invocation": {
                "model_provider": "ollama",
                "model_name": "llama3.1:8b",
                "base_url": "http://127.0.0.1:11434",
            },
        },
    )

    assert response.status_code == 200
    assert response.json() == {"summary": "runtime summary"}
    assert captured["model_name"] == "llama3.1:8b"


def test_trend_insights(monkeypatch):
    async def fake_context(patient_id):
        return {"patient_id": patient_id}

    monkeypatch.setattr(assistant_service, "build_patient_context", fake_context)
    monkeypatch.setattr(
        assistant_service,
        "invoke_model",
        lambda prompt, system: "\n".join(
            [
                "STEPS: Steps improved.",
                "CALORIES: Calories improved.",
                "HEART_RATE: Heart rate is stable.",
                "SLEEP: Sleep improved.",
            ]
        ),
    )

    response = client.post(
        "/assistant/trend-insights",
        json={
            "patient_id": 20,
            "steps": {"last_week": 100, "this_week": 200},
            "calories": {"last_week": 100, "this_week": 200},
            "heart_rate": {"last_week": 70, "this_week": 71},
            "sleep": {"last_week": 6, "this_week": 7},
        },
    )

    assert response.status_code == 200
    assert response.json()["insights"]["Steps"] == "Steps improved."


def test_context_unknown_patient(monkeypatch):
    async def fake_context(patient_id):
        raise HTTPException(status_code=404, detail="Unknown patient_id")

    monkeypatch.setattr(assistant_service, "build_patient_context", fake_context)

    response = client.post(
        "/assistant/chat",
        json={"patient_id": 999, "message": "hello"},
    )

    assert response.status_code == 404
