from __future__ import annotations

from collections.abc import Iterable
from datetime import date, datetime, timezone
from typing import Any

from fastapi import HTTPException

from src.backend.clients.ehospital_client import fetch_ehospital_table, write_ehospital_table_row
from src.backend.schemas.nutrition_monitor import (
    DailySummaryResponse,
    MealLogRecord,
    MealLogRequest,
    NutritionalBreakdown,
    model_to_public_dict,
)


TABLE = "app_nutrition_log"


async def log_meal(request: MealLogRequest) -> dict[str, Any]:
    if not request.is_food:
        raise HTTPException(status_code=400, detail="Cannot log a non-food analysis")
    row = {
        "patient_id": request.patient_id,
        "image_storage_path": None,
        "identified_foods": request.dish_name,
        "estimated_portions": request.portion_size,
        "ingredients_list": ",".join(request.ingredients),
        "calories": request.nutritional_breakdown.total_calories,
        "protein_g": request.nutritional_breakdown.total_protein,
        "fat_g": request.nutritional_breakdown.total_fat,
        "carbohydrates_g": request.nutritional_breakdown.total_carbs,
        "sodium_mg": request.nutritional_breakdown.total_sodium,
        "sugar_g": request.nutritional_breakdown.total_sugar,
        "insight_risk": "\n".join(request.insights.risks),
        "insight_warning": "\n".join(request.insights.warnings),
        "insight_positive": "\n".join(
            item for item in request.insights.positives if not item.startswith("NEUTRAL:")
        ),
    }
    result = await write_ehospital_table_row(TABLE, row)
    data = result.get("data") if isinstance(result, dict) else None
    created = data[0] if isinstance(data, list) and data else data if isinstance(data, dict) else row
    meal = normalize_meal_row(created)
    return {"meal": model_to_public_dict(meal), "message": "Meal logged successfully."}


async def get_meal_history(patient_id: int) -> list[dict[str, Any]]:
    rows = await fetch_ehospital_table(TABLE, patient_id)
    return [
        model_to_public_dict(record)
        for record in sorted(
            (normalize_meal_row(row) for row in rows),
            key=lambda meal: meal.logged_at or "",
            reverse=True,
        )
    ]


async def get_daily_summary(patient_id: int, summary_date: str | None = None) -> dict[str, Any]:
    target = summary_date or date.today().isoformat()
    rows = await fetch_ehospital_table(TABLE, patient_id)
    totals = _sum_rows(row for row in rows if _date_part(row.get("logged_at")) == target)
    summary = DailySummaryResponse(patientId=patient_id, date=target, totals=totals)
    return model_to_public_dict(summary)


def normalize_meal_row(row: dict[str, Any]) -> MealLogRecord:
    return MealLogRecord(
        logId=row.get("log_id"),
        patientId=int(row.get("patient_id") or 0),
        loggedAt=str(row.get("logged_at")) if row.get("logged_at") is not None else None,
        dishName=str(row.get("identified_foods") or ""),
        portionSize=str(row.get("estimated_portions") or ""),
        ingredients=_split(row.get("ingredients_list")),
        nutritionalBreakdown=NutritionalBreakdown(
            totalCalories=_float(row.get("calories")),
            totalProtein=_float(row.get("protein_g")),
            totalFat=_float(row.get("fat_g")),
            totalCarbs=_float(row.get("carbohydrates_g")),
            totalSodium=_float(row.get("sodium_mg")),
            totalSugar=_float(row.get("sugar_g")),
        ),
        risks=_split(row.get("insight_risk"), "\n"),
        warnings=_split(row.get("insight_warning"), "\n"),
        positives=_split(row.get("insight_positive"), "\n"),
        imageStoragePath=row.get("image_storage_path"),
    )


def _sum_rows(rows: Iterable[dict[str, Any]]) -> NutritionalBreakdown:
    totals = {
        "totalCalories": 0.0,
        "totalProtein": 0.0,
        "totalFat": 0.0,
        "totalCarbs": 0.0,
        "totalSodium": 0.0,
        "totalSugar": 0.0,
    }
    for row in rows:
        totals["totalCalories"] += _float(row.get("calories"))
        totals["totalProtein"] += _float(row.get("protein_g"))
        totals["totalFat"] += _float(row.get("fat_g"))
        totals["totalCarbs"] += _float(row.get("carbohydrates_g"))
        totals["totalSodium"] += _float(row.get("sodium_mg"))
        totals["totalSugar"] += _float(row.get("sugar_g"))
    return NutritionalBreakdown(**totals)


def _date_part(value: Any) -> str:
    if value is None:
        return datetime.now(timezone.utc).date().isoformat()
    text = str(value)
    return text.split("T", 1)[0].split(" ", 1)[0]


def _float(value: Any) -> float:
    try:
        return float(value or 0)
    except (TypeError, ValueError):
        return 0.0


def _split(value: Any, sep: str = ",") -> list[str]:
    if value is None:
        return []
    return [item.strip() for item in str(value).split(sep) if item.strip()]
