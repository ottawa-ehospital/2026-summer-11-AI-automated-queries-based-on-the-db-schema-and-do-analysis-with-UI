from __future__ import annotations

from fastapi import APIRouter

from src.backend.schemas.assistant import (
    AssistantChatRequest,
    AssistantChatResponse,
    HealthAlertDecisionResponse,
    HealthAlertEventRequest,
    TrendInsightsRequest,
    TrendInsightsResponse,
    VitalsSummaryRequest,
    VitalsSummaryResponse,
)
from src.backend.schemas.stress import StressAnalysisRequest, StressAnalysisResponse
from src.backend.services.assistant_service import (
    analyze_stress,
    build_trend_insights,
    chat_with_assistant,
    summarize_vitals,
    validate_model_invocation,
)
from src.backend.services.assistant.workflows.health_alert_analysis import (
    analyze_health_alert_event,
)
from src.backend.services.patient_context_service import build_patient_context


router = APIRouter(prefix="/assistant", tags=["assistant"])


@router.get("/patients/{patient_id}/context")
async def patient_context(patient_id: str) -> dict:
    # Exposes the aggregated context for debugging and UI inspection while the
    # service layer remains responsible for joining eHospital tables.
    return await build_patient_context(patient_id)


@router.post("/chat", response_model=AssistantChatResponse)
async def assistant_chat(request: AssistantChatRequest) -> AssistantChatResponse:
    # Routers keep the HTTP contract thin; prompt construction and model choice
    # live behind assistant_service for future LangGraph replacement.
    return await chat_with_assistant(
        request.patient_id,
        request.message,
        request.history,
        request.model_invocation,
    )


@router.post("/vitals-summary", response_model=VitalsSummaryResponse)
async def vitals_summary(request: VitalsSummaryRequest) -> VitalsSummaryResponse:
    # The request shape is stable for Flutter charts even if the backend model
    # provider changes between Gemini, Ollama, or LangGraph later.
    summary = await summarize_vitals(request)
    return VitalsSummaryResponse(summary=summary)


@router.post("/trend-insights", response_model=TrendInsightsResponse)
async def trend_insights(request: TrendInsightsRequest) -> TrendInsightsResponse:
    # Trend insight labels are normalized by the service before crossing back to
    # Flutter, keeping chart widgets free of LLM response parsing.
    insights = await build_trend_insights(request)
    return TrendInsightsResponse(insights=insights)


@router.post("/health-alert/analyze", response_model=HealthAlertDecisionResponse)
async def health_alert_analysis(
    request: HealthAlertEventRequest,
) -> HealthAlertDecisionResponse:
    request.model_invocation = validate_model_invocation(request.model_invocation)
    return await analyze_health_alert_event(request)


@router.post("/stress-analysis", response_model=StressAnalysisResponse)
async def stress_analysis(request: StressAnalysisRequest) -> StressAnalysisResponse:
    request.model_invocation = validate_model_invocation(request.model_invocation)
    return await analyze_stress(request)
