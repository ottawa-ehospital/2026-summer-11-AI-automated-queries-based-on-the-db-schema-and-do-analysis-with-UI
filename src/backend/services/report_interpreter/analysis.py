from __future__ import annotations

import re
from typing import Any

from fastapi import HTTPException

from src.backend.clients.model_client import invoke_model
from src.backend.core.config import settings
from src.backend.services.report_interpreter.extraction import extract_upload_text
from src.backend.services.report_interpreter.lab_values import (
    detect_report_type,
    extract_report_date,
    merge_lab_value_visuals,
    parse_lab_value_visuals,
)
from src.backend.services.report_interpreter.patients import (
    find_patient_by_id,
    resolve_report_patient,
    save_lab_values_for_patient,
)
from src.backend.services.report_interpreter.prompts import (
    add_patient_question_override,
    build_combined_file_analysis_prompt,
    build_file_analysis_prompt,
    build_system_prompt,
)
from src.backend.services.report_interpreter.utils import truncate_text


async def analyze_report(
    *,
    content: bytes,
    file_name: str,
    mime_type: str,
    previous_file_context: str | None = None,
    user_question: str | None = None,
    patient_id: int | None = None,
    from_saved_record: bool = False,
) -> dict[str, Any]:
    normalized_text = extract_upload_text(content, file_name, mime_type)
    if not normalized_text.strip():
        raise HTTPException(
            status_code=400,
            detail="Could not extract text from file. For scanned PDFs, install Poppler and Tesseract.",
        )

    max_context_chars = settings.report_interpreter_max_context_chars
    truncated_text = truncate_text(normalized_text, max_context_chars)
    previous_context = previous_file_context.strip() if previous_file_context else ""
    if previous_context:
        combined_context = truncate_text(
            f"PREVIOUS REPORT CONTEXT:\n{previous_context}\n\n"
            f"NEW REPORT ({file_name}):\n{truncated_text}",
            max_context_chars,
        )
        analysis_prompt = build_combined_file_analysis_prompt(file_name)
        file_content_for_prompt = combined_context
    else:
        combined_context = truncated_text
        analysis_prompt = build_file_analysis_prompt(file_name)
        file_content_for_prompt = truncated_text

    patient_question = user_question.strip() if user_question else ""
    if patient_question:
        analysis_prompt = add_patient_question_override(analysis_prompt, patient_question)

    analysis = invoke_model(
        f"{analysis_prompt}\n\nFILE CONTENT:\n{file_content_for_prompt}",
        system_prompt=build_system_prompt(None),
    )
    if patient_question and "response to your message" not in analysis.lower():
        analysis = (
            "**Response to Your Message**\n"
            "I am sorry you are not feeling well. Your test result can provide useful clues, "
            "but it cannot diagnose the cause on its own. I will explain what the report shows "
            "and what you may want to discuss with your doctor.\n\n"
            f"{analysis}"
        )

    lab_values = merge_lab_value_visuals(
        parse_lab_value_visuals(normalized_text),
        parse_lab_value_visuals(analysis),
    )
    report_date = extract_report_date(normalized_text)
    detected_test_type = detect_report_type(normalized_text, file_name, lab_values)
    saved_record_from_filename = bool(
        re.match(r"^(blood|eye|lab|diagnosis|tumor)-\d{4}-\d{2}-\d{2}\.txt$", file_name, re.IGNORECASE)
    )
    is_saved_record = from_saved_record or saved_record_from_filename

    report_patient = await find_patient_by_id(patient_id) if patient_id is not None else None
    if report_patient is None:
        report_patient = await resolve_report_patient(normalized_text)
    resolved_patient_id = _resolved_patient_id(report_patient)

    saved_lab_record_count = 0
    save_errors: list[str] = []
    if not is_saved_record:
        save_result = await save_lab_values_for_patient(
            resolved_patient_id,
            lab_values,
            report_date,
            detected_test_type,
        )
        saved_lab_record_count = int(save_result["count"])
        save_errors = list(save_result["errors"])

    return {
        "analysis": analysis,
        "fileContext": combined_context,
        "labValues": lab_values,
        "patient": report_patient,
        "savedLabRecordCount": saved_lab_record_count,
        "saveErrors": save_errors,
        "detectedTestType": detected_test_type,
        "patientNameNeeded": not is_saved_record and report_patient is None and bool(lab_values),
        "patientNameQuestion": (
            "I could not clearly detect the patient's name from this report. "
            "What is the patient's full name so I can save these lab results to the database?"
        ),
        "reportDate": report_date,
    }


def _resolved_patient_id(patient: dict[str, Any] | None) -> int | None:
    if not patient:
        return None
    raw_id = patient.get("patient_id")
    try:
        return int(raw_id)
    except (TypeError, ValueError):
        return None


def chat_with_report_context(
    messages: list[dict[str, str]],
    file_context: str | None = None,
) -> str:
    if not messages:
        raise HTTPException(status_code=400, detail="messages array is required")
    latest = messages[-1]["content"]
    history = "\n".join(
        f"{message.get('role', 'user')}: {message.get('content', '')}"
        for message in messages[:-1]
        if message.get("content")
    )
    prompt = f"Recent conversation:\n{history}\n\nUser message:\n{latest}" if history else latest
    return invoke_model(prompt, system_prompt=build_system_prompt(file_context))
