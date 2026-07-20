from __future__ import annotations

from typing import Any

from src.backend.clients.model_client import invoke_model_json
from src.backend.schemas.urgent_care import (
    UrgentCareFeedbackAlert,
    UrgentCareWorkflowFeedbackRequest,
)

from .constants import FEEDBACK_MISMATCH_TERMS, HIGH_RISK_FEEDBACK_TERMS


def keyword_feedback_alert(request: UrgentCareWorkflowFeedbackRequest) -> UrgentCareFeedbackAlert:
    text = f"{request.condition_update} {request.message} {request.feedback_message}".lower()
    has_high_risk_term = any(term in text for term in HIGH_RISK_FEEDBACK_TERMS)
    has_mismatch = request.rating in {"Too low", "Unsure"} or any(
        term in text for term in FEEDBACK_MISMATCH_TERMS
    )

    if has_high_risk_term:
        return UrgentCareFeedbackAlert(
            alert_required=True,
            severity="high",
            alert_reason="Feedback contains possible symptom worsening or red-flag language.",
            recommended_staff_action="Ask clinical staff to reassess the patient as soon as possible.",
            patient_message=(
                "Thank you for telling us. Your feedback suggests symptoms may need prompt review, "
                "so staff should reassess the case."
            ),
            feedback_type="symptom_alert",
        )

    if has_mismatch:
        return UrgentCareFeedbackAlert(
            alert_required=True,
            severity="medium",
            alert_reason="Feedback suggests the urgency level may not have matched the patient's condition.",
            recommended_staff_action="Flag this case for staff review and future triage quality improvement.",
            patient_message=(
                "Thank you for the feedback. This case will be flagged for clinical review and system improvement."
            ),
            feedback_type="urgency_mismatch",
        )

    return UrgentCareFeedbackAlert(
        alert_required=False,
        severity="none",
        alert_reason="No immediate clinical warning signs were detected in the feedback.",
        recommended_staff_action="Store feedback for future visit context.",
        patient_message=(
            "Thank you. We are glad the urgency level matched your expectation. "
            "We hope the patient feels better soon."
        ),
        feedback_type="triage_review",
    )


def feedback_alert_agent(request: UrgentCareWorkflowFeedbackRequest) -> UrgentCareFeedbackAlert:
    fallback = keyword_feedback_alert(request)
    prompt = _feedback_prompt(request)
    try:
        result = invoke_model_json(
            prompt,
            "You are a concise clinical safety feedback agent. Return valid JSON only.",
        )
        alert = UrgentCareFeedbackAlert(**result)
    except Exception:
        return fallback

    if fallback.alert_required and not alert.alert_required:
        return fallback
    alert.agent_source = "shared_model_feedback_alert_agent"
    return alert


def alert_display_key(alert: dict[str, Any]) -> str:
    return "|".join(
        [
            str(alert.get("record_id") or "").strip(),
            str(alert.get("patient_id") or "").strip(),
            str(alert.get("condition_update") or "").strip().lower(),
            str(alert.get("feedback") or alert.get("feedback_message") or "").strip().lower(),
            str(alert.get("alert_reason") or "").strip().lower(),
        ]
    )


def _feedback_prompt(request: UrgentCareWorkflowFeedbackRequest) -> str:
    return f"""
You are a healthcare feedback alert agent for an urgent care triage system.
Analyze the patient/staff feedback after check-in.

Current triage context:
- Patient ID: {request.patient_id}
- CTAS level: {request.ctas_level if request.ctas_level is not None else "not provided"}
- Risk score: {request.risk_score if request.risk_score is not None else "not provided"}
- Rating: {request.rating}
- Queue/urgency feedback: {request.message or request.feedback_message or "No queue feedback provided."}
- Current patient condition update: {request.condition_update or "No condition update provided."}

Task:
Focus especially on the current patient condition update. Decide whether it contains
signs of symptom worsening, red-flag symptoms, under-triage concern, or urgent need
for staff review. Use the queue feedback only as supporting context.

Trigger an alert when the update suggests acute deterioration or immediate staff review,
including but not limited to: cannot speak, trouble speaking, cannot breathe, shortness
of breath, chest pain, fainting, confusion, severe pain, bleeding, seizure, stroke-like
symptoms, suicidal thoughts, or the patient explicitly asks for urgent help.

Do not require exact keyword matches. Infer risk from the meaning of the patient's words.
When uncertain, be conservative and recommend staff review.

Return JSON only with:
{{
  "alert_required": true or false,
  "severity": "none", "low", "medium", or "high",
  "alert_reason": "short reason",
  "recommended_staff_action": "short action for clinic staff",
  "patient_message": "brief patient-facing reply in English",
  "feedback_type": "triage_review", "urgency_mismatch", "symptom_alert", or "service_experience",
  "agent_source": "deepseek_feedback_alert_agent"
}}

This is decision support only and does not diagnose or treat.
"""
