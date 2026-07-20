from __future__ import annotations

from typing import Any

from fastapi import HTTPException

from src.backend.schemas.nutrition_monitor import (
    NutritionAnalysisResponse,
    NutritionalBreakdown,
    PersonalizedInsights,
    model_to_public_dict,
)
from src.backend.services.nutrition_monitor.capabilities import get_model_capabilities
from src.backend.services.nutrition_monitor.context import allergy_terms, build_ehr_context
from src.backend.services.nutrition_monitor.model_analysis import invoke_food_image_model
from src.backend.services.nutrition_monitor.prompts import build_food_analysis_prompt
from src.backend.services.nutrition_monitor.scoring import (
    apply_exact_allergy_risks,
    ensure_neutral_positive,
    final_verdict,
)


UNSUPPORTED_MODEL_CODE = "nutrition_image_model_unsupported"


async def analyze_food_image(
    *,
    image_bytes: bytes,
    file_name: str,
    mime_type: str,
    patient_id: int | None,
    hint: str | None = None,
) -> dict[str, Any]:
    capabilities = get_model_capabilities()
    if not capabilities.supports_image_input:
        raise HTTPException(
            status_code=409,
            detail={
                "code": UNSUPPORTED_MODEL_CODE,
                "message": "The current model does not support food image analysis.",
                "provider": capabilities.provider,
                "model": capabilities.model,
                "reason": capabilities.reason,
            },
        )
    if patient_id is None or patient_id <= 0:
        raise HTTPException(status_code=400, detail="patient_id is required for nutrition analysis")
    if not image_bytes:
        raise HTTPException(status_code=400, detail="Image file is required")

    context = await build_ehr_context(patient_id)
    raw = invoke_food_image_model(
        image_bytes=image_bytes,
        file_name=file_name,
        mime_type=mime_type,
        prompt=build_food_analysis_prompt(context, hint),
    )
    response = normalize_analysis(raw, patient_id=patient_id, capabilities=capabilities, context=context)
    return model_to_public_dict(response)


def normalize_analysis(
    raw: dict[str, Any],
    *,
    patient_id: int,
    capabilities,
    context: dict[str, Any],
) -> NutritionAnalysisResponse:
    dish_name = str(raw.get("dishName") or raw.get("dish_name") or "").strip()
    if not dish_name:
        raise HTTPException(status_code=502, detail="AI model did not return a dish name")
    is_food = dish_name.lower() not in {"not_food", "not food", "string"}
    nutrients = raw.get("nutritionalBreakdown") or raw.get("nutritional_breakdown") or {}
    if not isinstance(nutrients, dict):
        raise HTTPException(status_code=502, detail="AI model returned invalid nutrient data")
    breakdown = NutritionalBreakdown(
        totalCalories=_num(nutrients, "totalCalories", "total_calories"),
        totalProtein=_num(nutrients, "totalProtein", "total_protein"),
        totalFat=_num(nutrients, "totalFat", "total_fat"),
        totalCarbs=_num(nutrients, "totalCarbs", "total_carbs"),
        totalSodium=_num(nutrients, "totalSodium", "total_sodium"),
        totalSugar=_num(nutrients, "totalSugar", "total_sugar"),
    )
    raw_insights = raw.get("insights") if isinstance(raw.get("insights"), dict) else {}
    insights = PersonalizedInsights(
        risks=_list(raw_insights.get("risks")),
        warnings=_list(raw_insights.get("warnings")),
        positives=_list(raw_insights.get("positives")),
    )
    ingredients = _list(raw.get("ingredients"))
    if is_food:
        insights = apply_exact_allergy_risks(
            dish_name=dish_name,
            ingredients=ingredients,
            allergy_terms=allergy_terms(context),
            insights=insights,
        )
        insights = ensure_neutral_positive(insights)
    verdict, reasoning = final_verdict(insights)
    return NutritionAnalysisResponse(
        dishName=dish_name,
        portionSize=str(raw.get("portionSize") or raw.get("portion_size") or "Estimated portion unavailable"),
        ingredients=ingredients,
        nutritionalBreakdown=breakdown,
        insights=insights,
        finalVerdict=verdict,
        finalVerdictReasoning=reasoning,
        isFood=is_food,
        patientId=patient_id,
        modelCapabilities=capabilities,
    )


def _num(payload: dict[str, Any], *keys: str) -> float:
    for key in keys:
        if key in payload:
            try:
                return float(payload[key])
            except (TypeError, ValueError):
                break
    raise HTTPException(status_code=502, detail=f"AI model returned invalid numeric field {keys[0]}")


def _list(value: Any) -> list[str]:
    if not isinstance(value, list):
        return []
    return [str(item).strip() for item in value if str(item).strip()]
