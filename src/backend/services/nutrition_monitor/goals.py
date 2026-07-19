from __future__ import annotations

from typing import Any

from fastapi import HTTPException

from src.backend.schemas.nutrition_monitor import (
    NutritionGoals,
    NutritionGoalsRequest,
    NutritionGoalsResponse,
    model_to_public_dict,
)


def default_goals(patient_id: int) -> dict[str, Any]:
    return model_to_public_dict(
        NutritionGoalsResponse(
            patientId=patient_id,
            goals=NutritionGoals(),
            source="local_fallback",
            remoteAvailable=False,
        )
    )


def validate_goals(request: NutritionGoalsRequest) -> dict[str, Any]:
    values = request.goals
    if min(values.calories, values.protein, values.carbs, values.fat) < 0:
        raise HTTPException(status_code=400, detail="Nutrition goals cannot be negative")
    return model_to_public_dict(
        NutritionGoalsResponse(
            patientId=request.patient_id,
            goals=values,
            source="local_fallback",
            remoteAvailable=False,
        )
    )
