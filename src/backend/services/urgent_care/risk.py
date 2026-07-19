from __future__ import annotations

from typing import Any

from fastapi import HTTPException

from src.backend.clients.model_client import invoke_model_json
from src.backend.schemas.urgent_care import UrgentCareAnalysis, UrgentCareIntakeRequest

from .constants import (
    CTAS_LEVELS,
    ctas_label,
    fallback_risk_score_from_ctas,
    queue_name_for_ctas,
)


RED_FLAG_SYMPTOM_RULES: tuple[tuple[tuple[str, ...], int, int], ...] = (
    (("cardiac arrest", "not breathing", "unconscious", "blue lips"), 1, 10),
    (
        (
            "chest pain",
            "shortness of breath",
            "can't breathe",
            "cannot breathe",
            "stroke",
            "seizure",
            "severe bleeding",
            "suicidal",
            "passed out",
        ),
        2,
        8,
    ),
    (
        (
            "high fever",
            "severe pain",
            "abdominal pain",
            "dehydration",
            "dizzy",
            "confusion",
            "weakness",
            "numbness",
        ),
        3,
        6,
    ),
)

LOW_RISK_TERMS = ("mild", "rash", "cold", "cough", "sore throat", "sprain", "minor")


def format_history_for_prompt(history_rows: list[dict[str, Any]]) -> str:
    if not history_rows:
        return "No previous visit or feedback records found."

    lines: list[str] = []
    for row in history_rows:
        source = row.get("_history_source", "record")
        if source == "healthcare_record":
            date = row.get("check_in_time") or "unknown date"
            lines.append(
                f"- Previous visit on {date}: symptoms={row.get('symptoms', '')}; "
                f"CTAS={row.get('ctas_urgency_level', 'unknown')}; "
                f"risk_score={row.get('risk_score', 'unknown')}; "
                f"summary={row.get('clinical_summary', '')}; "
                f"recommended_action={row.get('recommended_action', '')}; "
                f"status={row.get('status', '')}"
            )
            continue

        date = row.get("created_time") or row.get("datetime") or row.get("created_at") or "unknown date"
        feedback = row.get("feedback_message") or row.get("feedback") or row.get("message") or row.get("comment") or ""
        detail = (
            f"- Feedback on {date}: rating={row.get('rating') or ''}; "
            f"feedback={feedback}; condition_update={row.get('condition_update') or ''}"
        )
        if row.get("alert_required") is not None:
            detail += (
                f" | alert_required={row.get('alert_required')}; "
                f"alert_severity={row.get('alert_severity', '')}; "
                f"alert_reason={row.get('alert_reason', '')}"
            )
        lines.append(detail)
    return "\n".join(lines)


def deterministic_risk_analysis(
    request: UrgentCareIntakeRequest,
    history_rows: list[dict[str, Any]] | None = None,
    *,
    reason: str = "deterministic_fallback",
) -> UrgentCareAnalysis:
    text = f"{request.symptoms} {request.medical_history}".lower()
    level = 4
    score = fallback_risk_score_from_ctas(level)
    matched_terms: list[str] = []

    for terms, candidate_level, candidate_score in RED_FLAG_SYMPTOM_RULES:
        found = [term for term in terms if term in text]
        if found:
            level = candidate_level
            score = candidate_score
            matched_terms = found
            break

    if not matched_terms and any(term in text for term in LOW_RISK_TERMS):
        level = 5
        score = fallback_risk_score_from_ctas(level)

    summary = (
        "Decision-support fallback reviewed the submitted symptoms and assigned "
        f"{ctas_label(level)}."
    )
    reasoning = (
        "Model output was unavailable or unsafe, so deterministic triage rules were used. "
        f"Matched red-flag terms: {', '.join(matched_terms) if matched_terms else 'none'}. "
        "Clinical staff should review the queue assignment before care decisions."
    )
    return UrgentCareAnalysis(
        ctas_level=level,
        urgency_label=ctas_label(level),
        risk_score=score,
        queue_name=queue_name_for_ctas(level),
        clinical_summary=summary,
        reasoning=reasoning,
        recommended_action="Review the patient using standard urgent-care triage workflow.",
        fallback_used=True,
        agent_source=reason,
        history_used=history_rows or [],
    )


def risk_analysis_agent(
    request: UrgentCareIntakeRequest,
    history_rows: list[dict[str, Any]],
) -> UrgentCareAnalysis:
    prompt = _risk_prompt(request, history_rows)
    try:
        result = invoke_model_json(
            prompt,
            "Return JSON only. Be concise, cautious, and clinically conservative.",
        )
        level = int(result["ctas_level"])
        if level not in CTAS_LEVELS:
            raise ValueError(f"Unsupported CTAS level: {level}")
        try:
            score = int(result.get("risk_score", fallback_risk_score_from_ctas(level)))
        except (TypeError, ValueError):
            score = fallback_risk_score_from_ctas(level)
        return UrgentCareAnalysis(
            ctas_level=level,
            urgency_label=ctas_label(level),
            risk_score=max(1, min(10, score)),
            queue_name=queue_name_for_ctas(level),
            clinical_summary=str(result.get("clinical_summary", "")).strip(),
            reasoning=str(result.get("reasoning", "")).strip(),
            recommended_action=str(result.get("recommended_action", "")).strip(),
            fallback_used=False,
            agent_source="shared_model_risk_analysis_agent",
            history_used=history_rows,
        )
    except (HTTPException, KeyError, TypeError, ValueError):
        return deterministic_risk_analysis(
            request,
            history_rows,
            reason="shared_model_risk_analysis_fallback",
        )


def _risk_prompt(request: UrgentCareIntakeRequest, history_rows: list[dict[str, Any]]) -> str:
    history_text = format_history_for_prompt(history_rows)
    return f"""
You are the Risk Analysis Agent for an urgent care queue system.

Task:
Analyze the current patient intake together with previous database feedback.
Generate decision-support output only. Do not diagnose, prescribe treatment, or replace clinician judgment.

CTAS urgency levels:
- Level 1: Resuscitation / Critical
- Level 2: Emergent
- Level 3: Urgent
- Level 4: Less Urgent
- Level 5: Non-Urgent

Current intake:
- Patient ID: {request.patient_id or "local demo patient"}
- Name: {request.name}
- Age: {request.age}
- Symptoms: {request.symptoms}
- Optional medical history: {request.medical_history or "Not provided"}

Previous patient feedback/history from database:
{history_text}

Return valid JSON only:
{{
  "ctas_level": 1,
  "urgency_label": "Level 1: Resuscitation / Critical",
  "risk_score": 10,
  "clinical_summary": "Short neutral summary.",
  "reasoning": "3-5 sentences explaining CTAS level, risk score, prior history impact, red flags, and uncertainty.",
  "recommended_action": "Practical next staff action."
}}
"""
