from __future__ import annotations

from typing import Any


def build_food_analysis_prompt(context: dict[str, Any], hint: str | None) -> str:
    patient = context.get("patient") or {}
    vitals = context.get("latest_vitals") or {}
    allergies = ", ".join(
        str(row.get("allergen") or "").strip()
        for row in context.get("allergies") or []
        if str(row.get("allergen") or "").strip()
    ) or "none"
    conditions = ", ".join(
        str(row.get("disease_type") or row.get("diagnosis") or "").strip()
        for row in context.get("diagnosed_conditions") or []
        if str(row.get("disease_type") or row.get("diagnosis") or "").strip()
    ) or "none"
    tests = "\n".join(
        "- {name}: {value} {unit} ({date})".format(
            name=row.get("test_name") or row.get("name") or "Test",
            value=row.get("result_value") or row.get("value") or "",
            unit=row.get("unit") or "",
            date=row.get("test_date") or row.get("created_at") or "unknown date",
        )
        for row in context.get("blood_tests") or []
    ) or "none"
    user_hint = hint.strip() if hint and hint.strip() else "No hint provided."
    return f"""
You are an expert nutritionist AI for an e-hospital. Analyze the food image and return only one minified JSON object.

Patient profile:
- Name: {patient.get("name", "unavailable")}
- Gender: {patient.get("gender", "unavailable")}
- Weight kg: {patient.get("weight_kg", "unavailable")}
- Height cm: {patient.get("height_cm", "unavailable")}
- Allergies: [{allergies}]
- Diagnosed conditions: [{conditions}]
- Latest vitals: BP {vitals.get("blood_pressure", "unavailable")}, HR {vitals.get("heart_rate", "unavailable")}
- Recent blood tests:
{tests}

User hint: {user_hint}

Required JSON:
{{
  "dishName": "string",
  "portionSize": "string",
  "ingredients": ["string"],
  "nutritionalBreakdown": {{
    "totalCalories": 0.0,
    "totalProtein": 0.0,
    "totalFat": 0.0,
    "totalCarbs": 0.0,
    "totalSodium": 0.0,
    "totalSugar": 0.0
  }},
  "insights": {{
    "risks": [],
    "warnings": [],
    "positives": []
  }}
}}

Rules:
- If the image does not contain food, set "dishName" to "NOT_FOOD".
- Estimate portions and nutrients; mark estimates as values, not prose.
- Use risks for exact allergy matches only.
- Use warnings for condition/test-related nutritional concerns.
- Keep wording explanatory and non-diagnostic.
""".strip()
