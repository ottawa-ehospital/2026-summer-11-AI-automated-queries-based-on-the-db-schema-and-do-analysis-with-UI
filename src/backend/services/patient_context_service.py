from __future__ import annotations

from typing import Any

from fastapi import HTTPException

from src.backend.clients.ehospital_client import fetch_ehospital_table


def latest_by(rows: list[dict[str, Any]], key: str) -> dict[str, Any] | None:
    if not rows:
        return None
    return sorted(rows, key=lambda row: str(row.get(key, "")), reverse=True)[0]


async def build_patient_context(patient_id: int | str) -> dict[str, Any]:
    # Build one patient-scoped context document for AI calls. Every table fetch
    # is filtered by patient_id before the model sees it.
    patient_id_str = str(patient_id)
    users = await fetch_ehospital_table("users")
    patient = next(
        (
            row
            for row in users
            if str(row.get("patient_id", row.get("user_id", row.get("id", ""))))
            == patient_id_str
        ),
        None,
    )
    if patient is None:
        raise HTTPException(status_code=404, detail="Unknown patient_id")

    wearable = await fetch_ehospital_table("wearable_vitals", patient_id)
    vitals_history = await fetch_ehospital_table("vitals_history", patient_id)
    ecg = await fetch_ehospital_table("ecg", patient_id)
    diabetes = await fetch_ehospital_table("diabetes_analysis", patient_id)
    heart = await fetch_ehospital_table("heart_disease_analysis", patient_id)
    stroke = await fetch_ehospital_table("stroke_prediction", patient_id)
    labs = await fetch_ehospital_table("lab_tests", patient_id)
    diagnosis = await fetch_ehospital_table("diagnosis", patient_id)
    medical_history = await fetch_ehospital_table("medical_history", patient_id)

    wearable.sort(key=lambda row: str(row.get("timestamp", "")), reverse=True)
    recent_annotations = [
        str(annotation).strip()
        for row in wearable[:20]
        if (annotation := row.get("annotation")) and str(annotation).strip()
    ][:5]
    return {
        "patient_id": patient_id,
        "patient": patient,
        "latest_wearable": wearable[:5],
        "recent_annotations": recent_annotations,
        "latest_vitals_history": latest_by(vitals_history, "recorded_on"),
        "latest_ecg": latest_by(ecg, "recorded_on"),
        "latest_diabetes_analysis": diabetes[-1] if diabetes else None,
        "latest_heart_disease_analysis": latest_by(heart, "analyzed_on"),
        "latest_stroke_prediction": stroke[-1] if stroke else None,
        "recent_lab_tests": labs[-5:] if labs else [],
        "recent_diagnosis": diagnosis[-5:] if diagnosis else [],
        "recent_medical_history": medical_history[-5:] if medical_history else [],
    }
