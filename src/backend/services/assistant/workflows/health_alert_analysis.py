from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from typing import Any

from fastapi import HTTPException

from src.backend.clients.ehospital_client import fetch_ehospital_table
from src.backend.clients.model_client import invoke_model
from src.backend.schemas.assistant import (
    HealthAlertDecisionResponse,
    HealthAlertEventRequest,
    ModelInvocationSettings,
)


SUPPORTED_EVENT_TYPES = {"blood_pressure", "heart_rate", "sleep", "activity", "workout"}
ANALYSIS_WINDOW_HOURS = 3
BLOOD_PRESSURE_REFERENCE = {
    "normal": "systolic below 120 and diastolic below 80 mm Hg",
    "elevated": "systolic 120-129 and diastolic below 80 mm Hg",
    "stage_1": "systolic 130-139 or diastolic 80-89 mm Hg",
    "stage_2": "systolic at least 140 or diastolic at least 90 mm Hg",
    "severe": "systolic around 180 or diastolic around 120 mm Hg needs special caution",
}
ANTIHYPERTENSIVE_TERMS = (
    "amlodipine",
    "lisinopril",
    "losartan",
    "valsartan",
    "metoprolol",
    "atenolol",
    "hydrochlorothiazide",
    "hctz",
    "chlorthalidone",
    "enalapril",
    "ramipril",
    "olmesartan",
    "irbesartan",
    "candesartan",
    "nifedipine",
    "diltiazem",
    "verapamil",
    "blood pressure",
    "hypertension",
    "antihypertensive",
    "ace inhibitor",
    "arb",
    "beta blocker",
    "calcium channel blocker",
    "diuretic",
)
HYPERTENSION_TERMS = (
    "hypertension",
    "high blood pressure",
    "blood pressure",
    "cardiovascular",
)


async def analyze_health_alert_event(
    request: HealthAlertEventRequest,
) -> HealthAlertDecisionResponse:
    event_type = request.event_type.strip().lower()
    if event_type not in SUPPORTED_EVENT_TYPES:
        return _decision(
            request,
            status="unsupported_event",
            notify=False,
            severity="none",
            reason=f"Unsupported alert event type: {request.event_type}",
            trace={"selected_workflow": "health_alert_analysis", "supported": False},
        )

    event_time = _parse_datetime(request.event_time)
    if event_time is None:
        return _decision(
            request,
            status="invalid_event",
            notify=False,
            severity="none",
            reason="event_time must be a valid ISO-8601 timestamp.",
            trace={
                "selected_workflow": "health_alert_analysis",
                "validation_error": "event_time",
            },
        )

    if event_type != "blood_pressure":
        return _decision(
            request,
            status="no_notification",
            notify=False,
            severity="info",
            reason="This event is collected as supporting context; blood pressure is the first notification trigger.",
            evidence_summary=[f"Received {event_type} context event."],
            trace={
                "selected_workflow": "health_alert_analysis",
                "event_type": event_type,
            },
        )

    if request.unit and request.unit.strip().lower() not in {"mmhg", "mm hg"}:
        return _decision(
            request,
            status="invalid_event",
            notify=False,
            severity="none",
            reason="Blood pressure events must use mmHg units.",
            trace={
                "selected_workflow": "health_alert_analysis",
                "validation_error": "blood_pressure_unit",
            },
        )

    incoming_bp = _blood_pressure_from_event(request.values)
    if incoming_bp is None:
        return _decision(
            request,
            status="invalid_event",
            notify=False,
            severity="none",
            reason="Blood pressure events require systolic and diastolic numeric values.",
            trace={
                "selected_workflow": "health_alert_analysis",
                "validation_error": "blood_pressure_values",
            },
        )

    context = await _load_alert_context(request.patient_id)
    window_start = event_time - timedelta(hours=ANALYSIS_WINDOW_HOURS)
    bp_window = _blood_pressure_window(
        context["vitals_history"], window_start, event_time
    )
    bp_window.extend(
        _blood_pressure_trend_readings(request.values, window_start, event_time)
    )
    bp_window.append(
        {
            "systolic": incoming_bp[0],
            "diastolic": incoming_bp[1],
            "recorded_on": event_time.isoformat(),
        }
    )
    bp_window.sort(key=lambda row: str(row.get("recorded_on", "")))
    baseline = _blood_pressure_baseline(context["vitals_history"], window_start)

    elevated_count = sum(
        1
        for row in bp_window
        if _is_stage_1_or_higher(row.get("systolic"), row.get("diastolic"))
    )
    enough_evidence = len(bp_window) >= 2 and elevated_count >= 2
    medication_evidence = _active_antihypertensive_evidence(
        context["prescription_form"],
        context["prescription"],
        event_time,
    )
    medication_evidence.extend(
        _metadata_antihypertensive_evidence(request.source_metadata)
    )
    history_evidence = _hypertension_history_evidence(
        context["medical_history"],
        context["diagnosis"],
    )
    support = _supporting_context(context)
    risk_context = _risk_context(context)
    evidence = [
        f"3-hour blood-pressure readings reviewed: {len(bp_window)}",
        f"Elevated readings in window: {elevated_count}",
        f"Latest HealthKit reading: {incoming_bp[0]:.0f}/{incoming_bp[1]:.0f} mm Hg",
        *support,
        *risk_context,
    ]
    improving_trend = _blood_pressure_is_improving(bp_window)
    if improving_trend:
        first_bp = _blood_pressure_from_row(bp_window[0])
        latest_bp = _blood_pressure_from_row(bp_window[-1])
        if first_bp and latest_bp:
            evidence.append(
                "Blood pressure trend in window: "
                f"{first_bp[0]:.0f}/{first_bp[1]:.0f} down to "
                f"{latest_bp[0]:.0f}/{latest_bp[1]:.0f} mm Hg"
            )
    if baseline:
        evidence.append(
            f"Recent baseline before window: {baseline[0]:.0f}/{baseline[1]:.0f} mm Hg"
        )
    if medication_evidence:
        evidence.append(f"Active medication evidence: {medication_evidence[0]}")
    if history_evidence:
        evidence.append(f"History evidence: {history_evidence[0]}")

    model_decision = _model_decision(request, bp_window, context, evidence)
    if model_decision is not None:
        return model_decision

    if not enough_evidence:
        return _decision(
            request,
            status="no_notification",
            notify=False,
            severity="info",
            reason="Not enough sustained elevated blood-pressure evidence in the 3-hour window.",
            evidence_summary=evidence,
            trace=_trace(
                event_type,
                enough_evidence=enough_evidence,
                medication_evidence=bool(medication_evidence),
                history_evidence=bool(history_evidence),
                reference_ranges=BLOOD_PRESSURE_REFERENCE,
            ),
        )

    if improving_trend and not _is_stage_2_or_higher(incoming_bp[0], incoming_bp[1]):
        return _decision(
            request,
            status="no_notification",
            notify=False,
            severity="info",
            reason="Blood pressure readings are trending down and the latest reading is below stage 2, so no reminder was sent.",
            evidence_summary=evidence,
            recommendation_category="monitoring",
            trace=_trace(
                event_type,
                enough_evidence=enough_evidence,
                improving_trend=True,
                medication_evidence=bool(medication_evidence),
                history_evidence=bool(history_evidence),
                reference_ranges=BLOOD_PRESSURE_REFERENCE,
            ),
        )

    if not medication_evidence and not history_evidence:
        return _decision(
            request,
            status="no_notification",
            notify=False,
            severity="low",
            reason="Blood pressure appears elevated, but no medication or relevant history evidence was found.",
            evidence_summary=evidence,
            recommendation_category="monitoring",
            trace=_trace(
                event_type,
                enough_evidence=enough_evidence,
                medication_evidence=False,
                history_evidence=False,
                reference_ranges=BLOOD_PRESSURE_REFERENCE,
            ),
        )

    return _decision(
        request,
        status="notification_decision",
        notify=True,
        severity="medium",
        title=_title_for_mode(request.source_mode),
        body="Your blood pressure has stayed higher than usual recently. If you have a prescribed blood-pressure medicine, consider checking whether you took it as directed.",
        reason="Sustained elevated blood pressure in a 3-hour window with medication or history evidence.",
        evidence_summary=evidence,
        recommendation_category="medication_adherence",
        trace=_trace(
            event_type,
            enough_evidence=True,
            medication_evidence=bool(medication_evidence),
            history_evidence=bool(history_evidence),
            model_provider=_model_provider(request.model_invocation),
            reference_ranges=BLOOD_PRESSURE_REFERENCE,
        ),
    )


async def _load_alert_context(patient_id: int | str) -> dict[str, list[dict[str, Any]]]:
    tables = [
        "medical_history",
        "diagnosis",
        "prescription_form",
        "prescription",
        "patient_feedback",
        "heart_disease_analysis",
        "stroke_prediction",
        "ai_diagnostics",
        "vitals_history",
        "wearable_vitals",
        "wearable_workouts",
    ]
    context: dict[str, list[dict[str, Any]]] = {}
    for table in tables:
        try:
            rows = await fetch_ehospital_table(table, patient_id)
        except HTTPException:
            rows = []
        context[table] = [row for row in rows if isinstance(row, dict)]
    return context


def _blood_pressure_from_event(values: dict[str, Any]) -> tuple[float, float] | None:
    systolic = _coerce_number(values.get("systolic") or values.get("systolic_mm_hg"))
    diastolic = _coerce_number(values.get("diastolic") or values.get("diastolic_mm_hg"))
    if systolic is None or diastolic is None:
        combined = values.get("blood_pressure")
        if isinstance(combined, str) and "/" in combined:
            left, right = combined.split("/", 1)
            systolic = _coerce_number(left)
            diastolic = _coerce_number(right)
    if systolic is None or diastolic is None:
        return None
    if systolic <= 0 or diastolic <= 0 or systolic > 260 or diastolic > 180:
        return None
    return systolic, diastolic


def _blood_pressure_window(
    rows: list[dict[str, Any]],
    start: datetime,
    end: datetime,
) -> list[dict[str, Any]]:
    window = []
    for row in rows:
        recorded_at = _parse_datetime(
            str(row.get("recorded_on") or row.get("timestamp") or "")
        )
        if recorded_at is None or recorded_at < start or recorded_at > end:
            continue
        parsed = _parse_bp_string(row.get("blood_pressure"))
        if parsed is None:
            continue
        window.append(
            {
                "systolic": parsed[0],
                "diastolic": parsed[1],
                "recorded_on": recorded_at.isoformat(),
            }
        )
    return window


def _blood_pressure_trend_readings(
    values: dict[str, Any],
    start: datetime,
    end: datetime,
) -> list[dict[str, Any]]:
    raw_readings = values.get("trend_readings")
    if not isinstance(raw_readings, list):
        return []
    window = []
    for item in raw_readings:
        if not isinstance(item, dict):
            continue
        recorded_at = _parse_datetime(
            str(
                item.get("time")
                or item.get("recorded_on")
                or item.get("timestamp")
                or ""
            )
        )
        if recorded_at is None or recorded_at < start or recorded_at > end:
            continue
        systolic = _coerce_number(item.get("systolic") or item.get("systolic_mm_hg"))
        diastolic = _coerce_number(item.get("diastolic") or item.get("diastolic_mm_hg"))
        if systolic is None or diastolic is None:
            parsed = _parse_bp_string(item.get("blood_pressure"))
            if parsed is None:
                continue
            systolic, diastolic = parsed
        if systolic <= 0 or diastolic <= 0 or systolic > 260 or diastolic > 180:
            continue
        window.append(
            {
                "systolic": systolic,
                "diastolic": diastolic,
                "recorded_on": recorded_at.isoformat(),
            }
        )
    return window


def _blood_pressure_baseline(
    rows: list[dict[str, Any]],
    before: datetime,
) -> tuple[float, float] | None:
    values = []
    for row in rows:
        recorded_at = _parse_datetime(
            str(row.get("recorded_on") or row.get("timestamp") or "")
        )
        if recorded_at is None or recorded_at >= before:
            continue
        parsed = _parse_bp_string(row.get("blood_pressure"))
        if parsed is not None:
            values.append(parsed)
    if not values:
        return None
    systolic = sum(value[0] for value in values) / len(values)
    diastolic = sum(value[1] for value in values) / len(values)
    return systolic, diastolic


def _parse_bp_string(value: Any) -> tuple[float, float] | None:
    if value is None:
        return None
    text = str(value)
    if "/" not in text:
        return None
    left, right = text.split("/", 1)
    systolic = _coerce_number(left)
    diastolic = _coerce_number(right)
    if systolic is None or diastolic is None:
        return None
    return systolic, diastolic


def _is_stage_1_or_higher(systolic: Any, diastolic: Any) -> bool:
    sys_value = _coerce_number(systolic)
    dia_value = _coerce_number(diastolic)
    if sys_value is None or dia_value is None:
        return False
    return sys_value >= 130 or dia_value >= 80


def _is_stage_2_or_higher(systolic: Any, diastolic: Any) -> bool:
    sys_value = _coerce_number(systolic)
    dia_value = _coerce_number(diastolic)
    if sys_value is None or dia_value is None:
        return False
    return sys_value >= 140 or dia_value >= 90


def _blood_pressure_from_row(row: dict[str, Any]) -> tuple[float, float] | None:
    systolic = _coerce_number(row.get("systolic"))
    diastolic = _coerce_number(row.get("diastolic"))
    if systolic is None or diastolic is None:
        return None
    return systolic, diastolic


def _blood_pressure_is_improving(window: list[dict[str, Any]]) -> bool:
    if len(window) < 3:
        return False
    first = _blood_pressure_from_row(window[0])
    latest = _blood_pressure_from_row(window[-1])
    if first is None or latest is None:
        return False
    systolic_drop = first[0] - latest[0]
    diastolic_drop = first[1] - latest[1]
    if systolic_drop < 10 and diastolic_drop < 6:
        return False

    ordered_values = [
        value
        for row in window
        if (value := _blood_pressure_from_row(row)) is not None
    ]
    if len(ordered_values) < 3:
        return False
    improving_steps = sum(
        1
        for previous, current in zip(ordered_values, ordered_values[1:])
        if current[0] <= previous[0] and current[1] <= previous[1]
    )
    return improving_steps >= len(ordered_values) - 2


def _active_antihypertensive_evidence(
    prescription_form: list[dict[str, Any]],
    prescription: list[dict[str, Any]],
    event_time: datetime,
) -> list[str]:
    evidence = []
    for row in prescription_form:
        name = str(row.get("medication_name") or "")
        status = str(row.get("status") or "").lower()
        expiry = _parse_datetime(str(row.get("expiry_date") or ""))
        if _matches_antihypertensive(row, name) and status not in {
            "cancelled",
            "inactive",
            "expired",
        }:
            if expiry is None or expiry >= event_time:
                evidence.append(name or "prescription_form medication")
    for row in prescription:
        name = str(row.get("medicine_name") or "")
        status = str(row.get("status") or "").lower()
        end_date = _parse_datetime(str(row.get("end_date") or ""))
        if _matches_antihypertensive(row, name) and status not in {
            "cancelled",
            "inactive",
            "expired",
        }:
            if end_date is None or end_date >= event_time:
                evidence.append(name or "prescription medication")
    return evidence


def _metadata_antihypertensive_evidence(source_metadata: dict[str, Any]) -> list[str]:
    medication_context = source_metadata.get("medication_context")
    if not isinstance(medication_context, dict):
        return []
    evidence = []
    raw_medications = medication_context.get("active_medications")
    medications = raw_medications if isinstance(raw_medications, list) else []
    for item in medications:
        if not isinstance(item, dict):
            continue
        name = str(item.get("name") or item.get("medication_name") or "")
        if _matches_antihypertensive(item, name):
            evidence.append(name or "debug medication context")
    if (
        not evidence
        and medication_context.get("has_antihypertensive_medication") is True
    ):
        evidence.append("debug antihypertensive medication context")
    return evidence


def _matches_antihypertensive(row: dict[str, Any], name: str) -> bool:
    haystack = " ".join(
        str(value)
        for value in [
            name,
            row.get("notes"),
            row.get("dosage_instructions"),
            row.get("dosage"),
        ]
        if value
    )
    lowered = haystack.lower()
    return any(term in lowered for term in ANTIHYPERTENSIVE_TERMS)


def _hypertension_history_evidence(
    medical_history: list[dict[str, Any]],
    diagnosis: list[dict[str, Any]],
) -> list[str]:
    evidence = []
    for row in medical_history:
        text = " ".join(
            str(value)
            for value in [
                row.get("condition"),
                row.get("notes"),
                row.get("treatment_given"),
            ]
            if value
        )
        if any(term in text.lower() for term in HYPERTENSION_TERMS):
            evidence.append(
                str(row.get("condition") or "medical_history hypertension context")
            )
    for row in diagnosis:
        text = " ".join(
            str(value)
            for value in [row.get("diagnosis_code"), row.get("diagnosis_description")]
            if value
        )
        if (
            any(term in text.lower() for term in HYPERTENSION_TERMS)
            or "i10" in text.lower()
        ):
            evidence.append(
                str(
                    row.get("diagnosis_description")
                    or row.get("diagnosis_code")
                    or "diagnosis context"
                )
            )
    return evidence


def _supporting_context(context: dict[str, list[dict[str, Any]]]) -> list[str]:
    evidence = []
    latest_wearable = _latest_by(context["wearable_vitals"], "timestamp")
    if latest_wearable:
        if latest_wearable.get("heart_rate") is not None:
            evidence.append(f"Recent heart rate: {latest_wearable['heart_rate']} bpm")
        if latest_wearable.get("sleep") is not None:
            evidence.append(f"Recent sleep: {latest_wearable['sleep']} hours")
        if latest_wearable.get("steps") is not None:
            evidence.append(f"Recent steps: {latest_wearable['steps']}")
    latest_workout = _latest_by(context["wearable_workouts"], "start_time")
    if latest_workout:
        evidence.append(
            f"Recent workout: {latest_workout.get('workout_type', 'workout')}"
        )
    latest_feedback = _latest_by(context["patient_feedback"], "datetime")
    if latest_feedback and latest_feedback.get("feedback"):
        evidence.append(f"Recent patient note: {latest_feedback['feedback']}")
    return evidence


def _risk_context(context: dict[str, list[dict[str, Any]]]) -> list[str]:
    evidence = []
    latest_heart = _latest_by(context["heart_disease_analysis"], "analysis_date")
    if latest_heart:
        summary = (
            latest_heart.get("risk_level")
            or latest_heart.get("prediction")
            or latest_heart.get("result")
        )
        if summary:
            evidence.append(f"Heart risk context: {summary}")
    latest_stroke = _latest_by(context["stroke_prediction"], "analysis_date")
    if latest_stroke:
        summary = (
            latest_stroke.get("risk_level")
            or latest_stroke.get("prediction")
            or latest_stroke.get("result")
        )
        if summary:
            evidence.append(f"Stroke risk context: {summary}")
    latest_ai = _latest_by(context["ai_diagnostics"], "created_at")
    if latest_ai:
        summary = (
            latest_ai.get("summary")
            or latest_ai.get("diagnosis")
            or latest_ai.get("result")
        )
        if summary:
            evidence.append(f"AI diagnostic context: {summary}")
    return evidence


def _latest_by(rows: list[dict[str, Any]], key: str) -> dict[str, Any] | None:
    if not rows:
        return None
    return sorted(rows, key=lambda row: str(row.get(key, "")), reverse=True)[0]


def _model_decision(
    request: HealthAlertEventRequest,
    bp_window: list[dict[str, Any]],
    context: dict[str, list[dict[str, Any]]],
    evidence: list[str],
) -> HealthAlertDecisionResponse | None:
    prompt = "\n".join(
        [
            "Return one JSON object for a wellness alert decision.",
            "Schema: notify boolean, severity one of info/low/medium/high, title string, body string, reason string, recommendation_category string.",
            "Do not diagnose. Do not claim emergency detection. Use supportive reminder language.",
            "Use the patient context and trend together; do not rely on a single elevated reading if the overall pattern is improving.",
            f"Blood pressure window: {json.dumps(bp_window, default=str)}",
            f"Evidence: {json.dumps(evidence, default=str)}",
            f"Reference ranges: {json.dumps(BLOOD_PRESSURE_REFERENCE)}",
            f"Context summary: {json.dumps({key: value[:3] for key, value in context.items()}, default=str)}",
        ]
    )
    try:
        raw = invoke_model(prompt, "Return only valid JSON.", request.model_invocation)
        parsed = json.loads(raw.strip().strip("`").removeprefix("json").strip())
    except Exception:
        return None
    if not isinstance(parsed, dict) or not isinstance(parsed.get("notify"), bool):
        return None
    notify = bool(parsed["notify"])
    severity = str(parsed.get("severity") or ("medium" if notify else "info")).lower()
    if severity not in {"info", "low", "medium", "high"}:
        severity = "medium" if notify else "info"
    return _decision(
        request,
        status="notification_decision" if notify else "no_notification",
        notify=notify,
        severity=severity,
        title=(
            str(parsed.get("title") or _title_for_mode(request.source_mode))
            if notify
            else None
        ),
        body=str(parsed.get("body") or "") if notify else None,
        reason=str(parsed.get("reason") or "Model generated alert decision."),
        evidence_summary=evidence,
        recommendation_category=(
            str(parsed.get("recommendation_category") or "medication_adherence")
            if notify
            else None
        ),
        trace=_trace(
            request.event_type,
            model_provider=_model_provider(request.model_invocation),
            model_used=True,
            reference_ranges=BLOOD_PRESSURE_REFERENCE,
        ),
    )


def _decision(
    request: HealthAlertEventRequest,
    *,
    status: str,
    notify: bool,
    severity: str,
    reason: str,
    title: str | None = None,
    body: str | None = None,
    evidence_summary: list[str] | None = None,
    recommendation_category: str | None = None,
    trace: dict[str, Any] | None = None,
) -> HealthAlertDecisionResponse:
    return HealthAlertDecisionResponse(
        status=status,  # type: ignore[arg-type]
        patient_id=str(request.patient_id),
        event_type=request.event_type,
        event_source_id=request.event_source_id,
        source_mode=request.source_mode,
        notify=notify,
        severity=severity,  # type: ignore[arg-type]
        title=title,
        body=body,
        reason=reason,
        evidence_summary=evidence_summary or [],
        recommendation_category=recommendation_category,
        freshness={
            "category": "short_term",
            "window_hours": ANALYSIS_WINDOW_HOURS,
            "generated_at": datetime.now(timezone.utc).isoformat(),
        },
        trace=trace or {},
    )


def _trace(event_type: str, **items: Any) -> dict[str, Any]:
    return {
        "selected_workflow": "health_alert_analysis",
        "event_type": event_type,
        "analysis_window_hours": ANALYSIS_WINDOW_HOURS,
        **items,
    }


def _title_for_mode(source_mode: str) -> str:
    prefix = "[TEST] " if source_mode in {"test", "simulation"} else ""
    return f"{prefix}Blood pressure reminder"


def _model_provider(model_invocation: ModelInvocationSettings | None) -> str | None:
    return model_invocation.model_provider if model_invocation is not None else None


def _parse_datetime(value: str) -> datetime | None:
    try:
        parsed = datetime.fromisoformat(value.replace("Z", "+00:00"))
    except ValueError:
        return None
    if parsed.tzinfo is None:
        return parsed.replace(tzinfo=timezone.utc)
    return parsed.astimezone(timezone.utc)


def _coerce_number(value: Any) -> float | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value.strip())
        except ValueError:
            return None
    return None
