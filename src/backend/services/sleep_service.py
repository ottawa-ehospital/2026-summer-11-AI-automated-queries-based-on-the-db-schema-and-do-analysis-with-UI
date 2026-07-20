from __future__ import annotations

from datetime import datetime, timezone
from typing import Any

from fastapi import HTTPException

from src.backend.clients.ehospital_client import (
    execute_ehospital_select,
    write_ehospital_table_row,
)
from src.backend.clients.model_client import invoke_model
from src.backend.schemas.assistant import ModelInvocationSettings
from src.backend.schemas.sleep import (
    SleepChatMessage,
    SleepChatResponse,
    SleepFeedbackResponse,
    SleepNight,
    SleepNightsRequest,
    SleepNightsResponse,
)
from src.backend.services.assistant_service import validate_model_invocation


_SLEEP_SYSTEM_PROMPT = (
    "You are a supportive sleep-health assistant for a patient dashboard. "
    "Ground feedback in the patient's real numbers. Adults generally need 7-9 "
    "hours with adequate deep and REM sleep. Do not diagnose, recommend "
    "medications, write a letter, use placeholders, or add a sign-off. Keep it "
    "concise and practical."
)


def _now_mysql() -> str:
    return datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S")


async def save_nights(request: SleepNightsRequest) -> SleepNightsResponse:
    patient_id = str(request.patient_id)
    saved = 0
    for night in request.nights:
        if await _sleep_night_exists(patient_id, night.night):
            saved += 1
            continue
        await _insert_sleep_night(patient_id, night)
        saved += 1

    forwarded = False
    if request.forward_to_ehospital and request.nights:
        latest = max(request.nights, key=lambda item: item.night)
        forwarded = await _forward_aggregate_to_wearable_vitals(patient_id, latest)

    return SleepNightsResponse(saved=saved, forwarded_to_ehospital=forwarded)


async def list_nights(patient_id: int | str, days: int = 14) -> list[SleepNight]:
    rows = await _fetch_sleep_nights(str(patient_id), days)
    return [
        SleepNight(**{key: row[key] for key in SleepNight.model_fields if key in row})
        for row in rows
    ]


async def build_feedback(
    patient_id: int | str,
    days: int = 7,
    model_invocation: ModelInvocationSettings | None = None,
) -> SleepFeedbackResponse:
    nights = await list_nights(patient_id, days=days)
    if not nights:
        return SleepFeedbackResponse(
            feedback="No sleep data has been synced yet. Sync from Apple Health to get feedback.",
            nights_analyzed=0,
        )

    lines = "\n".join(_format_night(night) for night in nights)
    prompt = (
        "Here are the patient's recent nights of sleep from Apple Health.\n\n"
        f"{lines}\n\n"
        "Write personalized feedback that references these specific values. "
        "Comment on total sleep versus the 7-9 hour target, on deep and REM "
        "sleep, on overnight oxygen if present, and give two concrete, "
        "non-medical suggestions."
    )
    validated = validate_model_invocation(model_invocation)
    feedback = invoke_model(prompt, _SLEEP_SYSTEM_PROMPT, validated)
    return SleepFeedbackResponse(feedback=feedback, nights_analyzed=len(nights))


async def chat_about_sleep(
    patient_id: int | str,
    message: str,
    history: list[SleepChatMessage] | None = None,
    days: int = 7,
    model_invocation: ModelInvocationSettings | None = None,
) -> SleepChatResponse:
    if not message.strip():
        raise HTTPException(status_code=400, detail="Message must not be empty")

    nights = await list_nights(patient_id, days=days)
    if nights:
        data_context = "The patient's recent sleep nights:\n" + "\n".join(
            _format_night(night) for night in nights
        )
    else:
        data_context = (
            "No sleep data has been synced yet, so there are no specific sleep "
            "numbers to reference."
        )

    prompt = _build_sleep_chat_prompt(message, history or [], data_context)
    validated = validate_model_invocation(model_invocation)
    reply = invoke_model(prompt, _SLEEP_SYSTEM_PROMPT, validated)
    return SleepChatResponse(reply=reply)


async def _sleep_night_exists(patient_id: str, night: str) -> bool:
    payload = await execute_ehospital_select(
        """
        SELECT patient_id, night
        FROM sleep_nights
        WHERE patient_id = :patient_id AND night = :night
        LIMIT 1
        """,
        {"patient_id": patient_id, "night": night},
    )
    return bool(payload.get("data"))


async def _fetch_sleep_nights(patient_id: str, limit: int) -> list[dict[str, Any]]:
    payload = await execute_ehospital_select(
        """
        SELECT patient_id, night, deep_minutes, rem_minutes, core_minutes,
               light_minutes, awake_minutes, asleep_minutes, in_bed_minutes,
               spo2_avg, spo2_min, hr_avg, hr_min, source, updated_at
        FROM sleep_nights
        WHERE patient_id = :patient_id
        ORDER BY night DESC
        LIMIT :limit
        """,
        {"patient_id": patient_id, "limit": limit},
    )
    rows = payload.get("data", [])
    if not isinstance(rows, list):
        return []
    clean_rows = [row for row in rows if isinstance(row, dict)]
    clean_rows.reverse()
    return clean_rows


async def _insert_sleep_night(patient_id: str, night: SleepNight) -> None:
    payload = {
        "patient_id": patient_id,
        "night": night.night,
        "deep_minutes": night.deep_minutes,
        "rem_minutes": night.rem_minutes,
        "core_minutes": night.core_minutes,
        "light_minutes": night.light_minutes,
        "awake_minutes": night.awake_minutes,
        "asleep_minutes": night.asleep_minutes,
        "in_bed_minutes": night.in_bed_minutes,
        "spo2_avg": night.spo2_avg,
        "spo2_min": night.spo2_min,
        "hr_avg": night.hr_avg,
        "hr_min": night.hr_min,
        "source": night.source,
        "updated_at": _now_mysql(),
    }
    await write_ehospital_table_row("sleep_nights", payload)


async def _forward_aggregate_to_wearable_vitals(patient_id: str, night: SleepNight) -> bool:
    try:
        await write_ehospital_table_row(
            "wearable_vitals",
            {
                "patient_id": patient_id,
                "sleep": round(night.asleep_minutes / 60.0, 2),
                "timestamp": _now_mysql(),
            },
        )
        return True
    except HTTPException:
        return False


def _format_night(night: SleepNight) -> str:
    def hrs(minutes: float) -> str:
        return f"{minutes / 60.0:.1f}h"

    parts = [
        f"{night.night}: asleep {hrs(night.asleep_minutes)}",
        f"deep {hrs(night.deep_minutes)}",
        f"REM {hrs(night.rem_minutes)}",
        f"core {hrs(night.core_minutes)}",
        f"awake {int(night.awake_minutes)}m",
    ]
    if night.spo2_avg is not None:
        spo2_text = f"SpO2 avg {night.spo2_avg:.0f}%"
        if night.spo2_min is not None:
            spo2_text += f" (min {night.spo2_min:.0f}%)"
        parts.append(spo2_text)
    if night.hr_avg is not None:
        hr_text = f"sleep HR avg {night.hr_avg:.0f}"
        if night.hr_min is not None:
            hr_text += f" (min {night.hr_min:.0f})"
        parts.append(hr_text)
    return ", ".join(parts)


def _build_sleep_chat_prompt(
    message: str,
    history: list[SleepChatMessage],
    data_context: str,
) -> str:
    lines = [data_context, "", "Recent sleep conversation:"]
    for turn in history[-10:]:
        content = turn.content.strip()
        if content:
            speaker = "User" if turn.role == "user" else "Assistant"
            lines.append(f"{speaker}: {content}")
    lines.extend(
        [
            "",
            f"Current user message: {message}",
            "Reply conversationally in 2-4 sentences, using the sleep data when relevant.",
        ]
    )
    return "\n".join(lines)
