from __future__ import annotations

from fastapi import APIRouter

from src.backend.schemas.wearables import (
    WearableWorkoutBatchIngestionRequest,
    WearableWorkoutBatchIngestionResponse,
    WearableWorkoutIngestionRequest,
    WearableWorkoutIngestionResponse,
    WearableIngestionRequest,
    WearableIngestionResponse,
)
from src.backend.services.wearable_ingestion import (
    ingest_wearable_sample,
    ingest_wearable_workout,
    ingest_wearable_workout_batch,
)


router = APIRouter(prefix="/wearables", tags=["wearables"])


@router.post("/ingest", response_model=WearableIngestionResponse)
async def ingest_wearable(
    request: WearableIngestionRequest,
) -> WearableIngestionResponse:
    return await ingest_wearable_sample(request)


@router.post("/workouts/ingest", response_model=WearableWorkoutIngestionResponse)
async def ingest_workout(
    request: WearableWorkoutIngestionRequest,
) -> WearableWorkoutIngestionResponse:
    return await ingest_wearable_workout(request)


@router.post(
    "/workouts/batch-ingest",
    response_model=WearableWorkoutBatchIngestionResponse,
)
async def ingest_workout_batch(
    request: WearableWorkoutBatchIngestionRequest,
) -> WearableWorkoutBatchIngestionResponse:
    return await ingest_wearable_workout_batch(request)
