from __future__ import annotations

import json

from fastapi import HTTPException

from src.backend.clients.model_client import invoke_model
from src.backend.services.report_interpreter.constants import DATABASE_RECORD_TYPES
from src.backend.services.report_interpreter.patients import select_rows
from src.backend.services.report_interpreter.saved_records import require_test_type
from src.backend.services.report_interpreter.utils import (
    format_date_value,
    truncate_text,
    unique_suggested_questions,
)


FALLBACK_QUESTIONS = [
    "How does this result compare with my previous report?",
    "Are any values changing over time based on my records?",
    "Which abnormal values from the previous analysis should I ask my doctor about?",
    "Based on the previous analysis, what symptoms or changes should I monitor?",
    "What safe next steps should I consider before my next appointment?",
]


async def suggest_questions(
    latest_response: str,
    file_context: str | None = None,
    patient_id: int | None = None,
) -> list[str]:
    if not latest_response.strip():
        raise HTTPException(status_code=400, detail="latestResponse is required")

    patient_history = ""
    if patient_id is not None:
        try:
            patient_history = await build_patient_history_context(patient_id)
        except Exception:
            patient_history = ""

    prompt = (
        "Generate 4 or 5 short, non-repeated follow-up questions a patient might ask a medical report "
        "assistant after reading the previous response. Return valid JSON only in this format:\n"
        '{"questions":["question 1","question 2","question 3","question 4","question 5"]}\n\n'
        f"Previous analysis response:\n{truncate_text(latest_response, 4000)}"
    )
    if file_context:
        prompt += f"\n\nReport context:\n{truncate_text(file_context, 3500)}"
    if patient_history:
        prompt += f"\n\n{truncate_text(patient_history, 3500)}"

    try:
        content = invoke_model(
            prompt,
            system_prompt=(
                "You create concise, safe, non-repeated patient follow-up questions. "
                "Use previous test-report history and the previous analysis result when available. "
                "Return valid JSON only."
            ),
        )
        json_start = content.find("{")
        json_end = content.rfind("}")
        json_text = content[json_start:json_end + 1] if json_start >= 0 and json_end >= json_start else content
        parsed = json.loads(json_text)
        questions = unique_suggested_questions(parsed.get("questions", []), limit=5)
        if len(questions) < 4:
            return unique_suggested_questions([*questions, *FALLBACK_QUESTIONS], limit=5)
        return questions
    except Exception:
        return FALLBACK_QUESTIONS


async def build_patient_history_context(patient_id: int) -> str:
    sections: list[str] = []
    for config in DATABASE_RECORD_TYPES:
        table = config["table"]
        date_field = config["dateField"]
        rows = await select_rows(
            f"""
            SELECT *
            FROM {table}
            WHERE patient_id = :patient_id
            ORDER BY {date_field} DESC
            LIMIT 5
            """,
            {"patient_id": patient_id},
        )
        if not rows:
            continue
        lines = [f"{config['name']}:"]
        for row in rows:
            lines.append(f"- {_format_history_row(config['id'], row)}")
        sections.append("\n".join(lines))

    if not sections:
        return ""
    return "Patient database history for comparison:\n" + "\n\n".join(sections)


def _format_history_row(record_type: str, row: dict) -> str:
    require_test_type(record_type)
    if record_type == "blood":
        return (
            f"{format_date_value(row.get('test_date'))}: "
            f"{row.get('test_name')} {row.get('result_value')} {row.get('unit')} "
            f"(normal: {row.get('normal_range')})"
        )
    if record_type == "eye":
        return (
            f"{format_date_value(row.get('test_date'))}: "
            f"{row.get('test_type')} - {row.get('result')}; "
            f"vision {row.get('vision_metric')} score {row.get('vision_score')}"
        )
    if record_type == "lab":
        return (
            f"{format_date_value(row.get('test_date'))}: "
            f"{row.get('test_type')} - {row.get('result')} "
            f"({row.get('status')}, sample: {row.get('sample_type')})"
        )
    if record_type == "diagnosis":
        return (
            f"{format_date_value(row.get('diagnosis_date'))}: "
            f"{row.get('diagnosis_code')} - {row.get('diagnosis_description')}"
        )
    if record_type == "tumor":
        return (
            f"{format_date_value(row.get('diagnosed_on'))}: "
            f"{row.get('tumor_type')} at {row.get('location')}, "
            f"{row.get('size_cm')} cm, status {row.get('status')}"
        )
    return json.dumps(row, ensure_ascii=False)
