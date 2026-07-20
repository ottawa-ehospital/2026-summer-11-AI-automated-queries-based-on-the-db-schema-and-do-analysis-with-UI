from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any

from fastapi import HTTPException

from src.backend.clients.ehospital_client import write_ehospital_table_row
from src.backend.clients.model_client import invoke_model
from src.backend.schemas.assistant import (
    AssistantChatResponse,
    AssistantConversationMessage,
    ModelInvocationSettings,
    TrendInsightsRequest,
    VitalsSummaryRequest,
)
from src.backend.schemas.stress import StressAnalysisRequest, StressAnalysisResponse
from src.backend.services.assistant.base import AssistantProvider as AssistantOrchestrator
from src.backend.services.assistant.factory import (
    ASSISTANT_PROVIDER_WEARABLE_LANGGRAPH,
    AssistantProviderFactory,
    get_assistant_provider,
)
from src.backend.services.assistant.prompt_helpers import (
    build_chat_prompt,
    build_system_prompt,
)
from src.backend.services.assistant.providers.wearable_langgraph import (
    WearableLangGraphAssistantProvider as DefaultAssistantOrchestrator,
    build_wearable_chart_graph,
    build_wearable_chart_response,
    classify_wearable_metric_query,
    query_table,
)
from src.backend.services.assistant.result_helpers import (
    compose_text_response,
    validate_assistant_result_payload,
)
from src.backend.services.patient_context_service import build_patient_context


def get_assistant_orchestrator() -> AssistantOrchestrator:
    # Compatibility name for older tests/callers. New code should use
    # get_assistant_provider() or AssistantProviderFactory.
    return get_assistant_provider()


async def chat_with_assistant(
    patient_id: int | str,
    message: str,
    history: list[AssistantConversationMessage] | None = None,
    model_invocation: ModelInvocationSettings | None = None,
) -> AssistantChatResponse:
    validated = validate_model_invocation(model_invocation)
    return await get_assistant_provider(
        validated.provider_key if validated else None,
        validated,
    ).chat(patient_id, message, history)


async def summarize_vitals(request: VitalsSummaryRequest) -> str:
    model_invocation = validate_model_invocation(request.model_invocation)
    context = await build_patient_context(request.patient_id)
    prompt = f"""Write 1-3 plain English sentences for a patient health dashboard.
Metric: {request.metric}
Latest: {request.latest} {request.unit}
Average: {request.average} {request.unit}
Peak: {request.peak} {request.unit}
Missing/zero readings: {request.zero_count} of {request.total_count}
Healthy range: {request.healthy_range}
Clinical note: {request.clinical_note or ""}

Be specific with numbers. Do not suggest medications. Keep it under 70 words."""
    return _invoke_model(prompt, build_system_prompt(context), model_invocation)


async def build_trend_insights(request: TrendInsightsRequest) -> dict[str, str]:
    model_invocation = validate_model_invocation(request.model_invocation)
    context = await build_patient_context(request.patient_id)
    prompt = f"""Analyze this patient's week-over-week wearable data and write ONE plain English sentence, max 25 words, for each metric.

Steps: {request.steps}
Active Calories: {request.calories}
Heart Rate: {request.heart_rate}
Sleep: {request.sleep}

Reply in this exact format:
STEPS: [sentence]
CALORIES: [sentence]
HEART_RATE: [sentence]
SLEEP: [sentence]"""
    text = _invoke_model(prompt, build_system_prompt(context), model_invocation)
    # The model is asked for a rigid text format; parse defensively so Flutter
    # receives a simple metric-name map instead of model-specific text.
    insights: dict[str, str] = {}
    for line in text.splitlines():
        cleaned = line.strip()
        if cleaned.startswith("STEPS:"):
            insights["Steps"] = cleaned.replace("STEPS:", "", 1).strip()
        elif cleaned.startswith("CALORIES:"):
            insights["Active Calories"] = cleaned.replace("CALORIES:", "", 1).strip()
        elif cleaned.startswith("HEART_RATE:"):
            insights["Heart Rate"] = cleaned.replace("HEART_RATE:", "", 1).strip()
        elif cleaned.startswith("SLEEP:"):
            insights["Sleep"] = cleaned.replace("SLEEP:", "", 1).strip()
    return insights


async def analyze_stress(request: StressAnalysisRequest) -> StressAnalysisResponse:
    model_invocation = validate_model_invocation(request.model_invocation)
    context = await build_patient_context(request.patient_id)
    stress_vitals = [
        {
            "timestamp": row.get("timestamp"),
            "hrv_sdnn": row.get("hrv_sdnn"),
            "resting_heart_rate": row.get("resting_heart_rate"),
            "respiratory_rate": row.get("respiratory_rate"),
            "stress_score": row.get("stress_score"),
        }
        for row in context.get("latest_wearable", [])
        if any(
            row.get(field) is not None
            for field in (
                "hrv_sdnn",
                "resting_heart_rate",
                "respiratory_rate",
                "stress_score",
            )
        )
    ]
    prompt = f"""Write a supportive 3-5 sentence stress and wellness assessment for a patient dashboard.

Combine these sources:
1. Recent medical history: {json.dumps(context.get("recent_medical_history", []), ensure_ascii=False)}
2. Recent wearable stress vitals: {json.dumps(stress_vitals, ensure_ascii=False)}
3. User-provided stress annotations: {json.dumps(context.get("recent_annotations", []), ensure_ascii=False)}

Explain what the stress score trend suggests, reference specific vitals when present, and acknowledge annotations or relevant history.
Do not diagnose or suggest medications. Keep it under 120 words."""
    text = _invoke_model(prompt, build_system_prompt(context), model_invocation)
    await _persist_ai_analysis(request.patient_id, "stress", text)
    return StressAnalysisResponse(analysis=text)


def validate_model_invocation(
    model_invocation: ModelInvocationSettings | None,
) -> ModelInvocationSettings | None:
    if model_invocation is None:
        return None

    provider_key = _blank_to_none(model_invocation.provider_key)
    model_provider = _blank_to_none(model_invocation.model_provider)
    model_name = _blank_to_none(model_invocation.model_name)
    base_url = _blank_to_none(model_invocation.base_url)

    if model_invocation.use_graph_flow is not None:
        provider_key = (
            ASSISTANT_PROVIDER_WEARABLE_LANGGRAPH
            if model_invocation.use_graph_flow
            else provider_key
        )

    if provider_key is not None:
        factory = AssistantProviderFactory()
        normalized_key = provider_key.strip().lower()
        if normalized_key not in factory.supported_provider_keys:
            supported = ", ".join(factory.supported_provider_keys)
            raise HTTPException(
                status_code=400,
                detail=(
                    f"Unsupported assistant provider '{provider_key}'. "
                    f"Supported providers: {supported}."
                ),
            )
        provider_key = normalized_key

    if model_provider is not None:
        normalized_provider = model_provider.strip().lower()
        if normalized_provider in {"ollama", "local"} and base_url is None:
            raise HTTPException(
                status_code=400,
                detail="Model invocation base_url is required for local/Ollama providers.",
            )
        if model_name is None:
            raise HTTPException(
                status_code=400,
                detail="Model invocation model_name is required when model_provider is set.",
            )
        model_provider = normalized_provider

    return ModelInvocationSettings(
        provider_key=provider_key,
        model_provider=model_provider,
        model_name=model_name,
        base_url=base_url,
        use_graph_flow=model_invocation.use_graph_flow,
    )


def _invoke_model(
    prompt: str,
    system_prompt: str | None,
    model_invocation: ModelInvocationSettings | None,
) -> str:
    if model_invocation is None:
        return invoke_model(prompt, system_prompt)
    return invoke_model(prompt, system_prompt, model_invocation)


async def _persist_ai_analysis(patient_id: int | str, type_: str, text: str) -> None:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")
    await write_ehospital_table_row(
        "ai_analysis",
        {
            "patient_id": patient_id,
            "type": type_,
            "ai_analysis": text,
            "timestamp": now,
        },
    )


def _blank_to_none(value: str | None) -> str | None:
    normalized = (value or "").strip()
    return normalized if normalized else None


__all__ = [
    "Any",
    "AssistantOrchestrator",
    "AssistantProviderFactory",
    "DefaultAssistantOrchestrator",
    "analyze_stress",
    "build_chat_prompt",
    "build_system_prompt",
    "build_trend_insights",
    "build_wearable_chart_graph",
    "build_wearable_chart_response",
    "chat_with_assistant",
    "classify_wearable_metric_query",
    "compose_text_response",
    "get_assistant_orchestrator",
    "get_assistant_provider",
    "invoke_model",
    "query_table",
    "summarize_vitals",
    "validate_model_invocation",
    "validate_assistant_result_payload",
]
