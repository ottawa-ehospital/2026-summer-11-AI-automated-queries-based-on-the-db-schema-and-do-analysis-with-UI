from __future__ import annotations

from typing import Any

from pydantic import BaseModel, ConfigDict, Field


class NutritionMonitorModel(BaseModel):
    model_config = ConfigDict(populate_by_name=True)


class NutritionModelCapabilities(NutritionMonitorModel):
    supports_image_input: bool = Field(alias="supportsImageInput")
    provider: str
    model: str
    reason: str | None = None


class NutritionHealthResponse(NutritionMonitorModel):
    status: str
    image_analysis: NutritionModelCapabilities = Field(alias="imageAnalysis")


class NutritionalBreakdown(NutritionMonitorModel):
    total_calories: float = Field(alias="totalCalories")
    total_protein: float = Field(alias="totalProtein")
    total_fat: float = Field(alias="totalFat")
    total_carbs: float = Field(alias="totalCarbs")
    total_sodium: float = Field(alias="totalSodium")
    total_sugar: float = Field(alias="totalSugar")


class PersonalizedInsights(NutritionMonitorModel):
    risks: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)
    positives: list[str] = Field(default_factory=list)


class NutritionAnalysisResponse(NutritionMonitorModel):
    dish_name: str = Field(alias="dishName")
    portion_size: str = Field(alias="portionSize")
    ingredients: list[str] = Field(default_factory=list)
    nutritional_breakdown: NutritionalBreakdown = Field(alias="nutritionalBreakdown")
    insights: PersonalizedInsights
    final_verdict: str = Field(alias="finalVerdict")
    final_verdict_reasoning: str = Field(alias="finalVerdictReasoning")
    is_food: bool = Field(default=True, alias="isFood")
    patient_id: int = Field(alias="patientId")
    model_capabilities: NutritionModelCapabilities = Field(alias="modelCapabilities")


class MealLogRequest(NutritionMonitorModel):
    patient_id: int = Field(alias="patientId")
    dish_name: str = Field(alias="dishName")
    portion_size: str = Field(alias="portionSize")
    ingredients: list[str] = Field(default_factory=list)
    nutritional_breakdown: NutritionalBreakdown = Field(alias="nutritionalBreakdown")
    insights: PersonalizedInsights
    final_verdict: str = Field(default="", alias="finalVerdict")
    is_food: bool = Field(default=True, alias="isFood")


class MealLogRecord(NutritionMonitorModel):
    log_id: int | str | None = Field(default=None, alias="logId")
    patient_id: int = Field(alias="patientId")
    logged_at: str | None = Field(default=None, alias="loggedAt")
    dish_name: str = Field(alias="dishName")
    portion_size: str = Field(alias="portionSize")
    ingredients: list[str] = Field(default_factory=list)
    nutritional_breakdown: NutritionalBreakdown = Field(alias="nutritionalBreakdown")
    risks: list[str] = Field(default_factory=list)
    warnings: list[str] = Field(default_factory=list)
    positives: list[str] = Field(default_factory=list)
    image_storage_path: str | None = Field(default=None, alias="imageStoragePath")


class MealLogResponse(NutritionMonitorModel):
    meal: MealLogRecord
    message: str = "Meal logged successfully."


class DailySummaryResponse(NutritionMonitorModel):
    patient_id: int = Field(alias="patientId")
    date: str
    totals: NutritionalBreakdown


class NutritionGoals(NutritionMonitorModel):
    calories: int = 2000
    protein: int = 120
    carbs: int = 250
    fat: int = 70


class NutritionGoalsResponse(NutritionMonitorModel):
    patient_id: int = Field(alias="patientId")
    goals: NutritionGoals
    source: str = "local_fallback"
    remote_available: bool = Field(default=False, alias="remoteAvailable")


class NutritionGoalsRequest(NutritionMonitorModel):
    patient_id: int = Field(alias="patientId")
    goals: NutritionGoals


class NutritionErrorDetail(NutritionMonitorModel):
    code: str
    message: str
    provider: str | None = None
    model: str | None = None
    reason: str | None = None


def model_to_public_dict(model: BaseModel) -> dict[str, Any]:
    return model.model_dump(by_alias=True)
