from __future__ import annotations

from typing import Any

from fastapi import APIRouter

from src.backend.clients.ehospital_client import (
    update_ehospital_table_row,
    write_ehospital_table_row,
)
from src.backend.schemas.stress import AnnotationUpdateRequest, StressSnapshotRequest
from src.backend.services.stress_score import compute_stress_score


router = APIRouter(prefix="/vitals", tags=["stress"])


@router.post("/stress-snapshot")
async def create_stress_snapshot(request: StressSnapshotRequest) -> dict[str, Any]:
    stress_score = compute_stress_score(
        request.hrv_sdnn,
        request.resting_heart_rate,
        request.respiratory_rate,
    )
    payload: dict[str, Any] = {
        "patient_id": request.patient_id,
        "heart_rate": request.heart_rate,
        "hrv_sdnn": request.hrv_sdnn,
        "resting_heart_rate": request.resting_heart_rate,
        "respiratory_rate": request.respiratory_rate,
        "stress_score": stress_score,
        "timestamp": request.timestamp,
    }
    return await write_ehospital_table_row("wearable_vitals", payload)


@router.patch("/{vital_id}/annotation")
async def update_stress_annotation(
    vital_id: int | str,
    request: AnnotationUpdateRequest,
) -> dict[str, Any]:
    return await update_ehospital_table_row(
        "wearable_vitals",
        vital_id,
        {"annotation": request.annotation},
    )
