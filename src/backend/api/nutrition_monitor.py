from __future__ import annotations

from typing import Any

from fastapi import APIRouter, File, Form, UploadFile

from src.backend.schemas.nutrition_monitor import (
    MealLogRequest,
    MealLogResponse,
    NutritionAnalysisResponse,
    NutritionGoalsRequest,
    NutritionGoalsResponse,
    NutritionHealthResponse,
)
from src.backend.services.nutrition_monitor.analysis import analyze_food_image
from src.backend.services.nutrition_monitor.capabilities import get_model_capabilities
from src.backend.services.nutrition_monitor.goals import default_goals, validate_goals
from src.backend.services.nutrition_monitor.meals import (
    get_daily_summary,
    get_meal_history,
    log_meal,
)


router = APIRouter(prefix="/nutrition-monitor", tags=["nutrition-monitor"])


@router.get("/health", response_model=NutritionHealthResponse)
async def health() -> dict[str, Any]:
    return {"status": "ok", "imageAnalysis": get_model_capabilities().model_dump(by_alias=True)}


@router.post("/analyze-image", response_model=NutritionAnalysisResponse)
async def analyze_image(
    file: UploadFile = File(...),
    patientId: int | None = Form(None),
    hint: str | None = Form(None),
) -> dict[str, Any]:
    content = await file.read()
    return await analyze_food_image(
        image_bytes=content,
        file_name=file.filename or "meal-image",
        mime_type=file.content_type or "image/jpeg",
        patient_id=patientId,
        hint=hint,
    )


@router.post("/meals", response_model=MealLogResponse)
async def create_meal(request: MealLogRequest) -> dict[str, Any]:
    return await log_meal(request)


@router.get("/meals")
async def meal_history(patientId: int) -> list[dict[str, Any]]:
    return await get_meal_history(patientId)


@router.get("/summary/daily")
async def daily_summary(patientId: int, date: str | None = None) -> dict[str, Any]:
    return await get_daily_summary(patientId, date)


@router.get("/goals", response_model=NutritionGoalsResponse)
async def get_goals(patientId: int) -> dict[str, Any]:
    return default_goals(patientId)


@router.put("/goals", response_model=NutritionGoalsResponse)
async def put_goals(request: NutritionGoalsRequest) -> dict[str, Any]:
    return validate_goals(request)
