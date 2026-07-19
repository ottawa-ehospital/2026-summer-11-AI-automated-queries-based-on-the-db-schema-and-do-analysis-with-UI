from __future__ import annotations

from fastapi import APIRouter

from src.backend.schemas.sleep import (
    SleepChatRequest,
    SleepChatResponse,
    SleepFeedbackRequest,
    SleepFeedbackResponse,
    SleepNightsListResponse,
    SleepNightsRequest,
    SleepNightsResponse,
)
from src.backend.services import sleep_service


router = APIRouter(prefix="/sleep", tags=["sleep"])


@router.post("/nights", response_model=SleepNightsResponse)
async def sync_nights(request: SleepNightsRequest) -> SleepNightsResponse:
    return await sleep_service.save_nights(request)


@router.get("/nights", response_model=SleepNightsListResponse)
async def get_nights(patient_id: int | str, days: int = 14) -> SleepNightsListResponse:
    nights = await sleep_service.list_nights(patient_id, days=days)
    return SleepNightsListResponse(count=len(nights), nights=nights)


@router.post("/feedback", response_model=SleepFeedbackResponse)
async def sleep_feedback(request: SleepFeedbackRequest) -> SleepFeedbackResponse:
    return await sleep_service.build_feedback(
        request.patient_id,
        days=request.days,
        model_invocation=request.model_invocation,
    )


@router.post("/chat", response_model=SleepChatResponse)
async def sleep_chat(request: SleepChatRequest) -> SleepChatResponse:
    return await sleep_service.chat_about_sleep(
        request.patient_id,
        request.message,
        history=request.history,
        days=request.days,
        model_invocation=request.model_invocation,
    )
