from __future__ import annotations

from typing import Any

from src.backend.clients.ehospital_client import fetch_ehospital_table


async def build_ehr_context(patient_id: int | str) -> dict[str, Any]:
    registration = await fetch_ehospital_table("patients_registration", patient_id)
    vitals = await fetch_ehospital_table("vitals_history", patient_id)
    blood_tests = await fetch_ehospital_table("bloodtests", patient_id)
    allergies = await fetch_ehospital_table("allergy_records", patient_id)
    diagnostics = await fetch_ehospital_table("ai_diagnostics", patient_id)
    latest_vitals = _latest(vitals, "recorded_on")
    return {
        "patient": registration[0] if registration else {},
        "latest_vitals": latest_vitals or {},
        "blood_tests": blood_tests,
        "allergies": allergies,
        "diagnosed_conditions": diagnostics,
    }


def allergy_terms(context: dict[str, Any]) -> list[str]:
    terms: list[str] = []
    for row in context.get("allergies") or []:
        allergen = str(row.get("allergen") or "").strip()
        if allergen:
            terms.append(allergen)
    return terms


def _latest(rows: list[dict[str, Any]], field: str) -> dict[str, Any] | None:
    if not rows:
        return None
    return max(rows, key=lambda row: str(row.get(field) or ""))
