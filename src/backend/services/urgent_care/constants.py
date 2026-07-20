from __future__ import annotations

from typing import Final


HEALTHCARE_RECORDS_TABLE: Final = "healthcare_records"
FEEDBACK_TABLE: Final = "patient_feedback"
PATIENTS_REGISTRATION_TABLE: Final = "patients_registration"
MEDICAL_HISTORY_TABLE: Final = "medical_history"

STATUS_WAITING: Final = "Waiting"
STATUS_CONSULTATION: Final = "In Consultation"
STATUS_COMPLETED: Final = "Completed"
LEGACY_COMPLETED_STATUS: Final = "Completed / Discharged"

QUEUE_EMERGENCY: Final = "Emergency Queue"
QUEUE_NORMAL: Final = "Normal Queue"
QUEUE_NON_URGENT: Final = "Non-Urgent Queue"

CTAS_LEVELS: Final[dict[int, dict[str, str]]] = {
    1: {
        "label": "Level 1: Resuscitation / Critical",
        "short": "Resuscitation / Critical",
        "color": "#b91c1c",
    },
    2: {"label": "Level 2: Emergent", "short": "Emergent", "color": "#c2410c"},
    3: {"label": "Level 3: Urgent", "short": "Urgent", "color": "#a16207"},
    4: {"label": "Level 4: Less Urgent", "short": "Less Urgent", "color": "#15803d"},
    5: {"label": "Level 5: Non-Urgent", "short": "Non-Urgent", "color": "#475569"},
}

FALLBACK_RISK_SCORES: Final[dict[int, int]] = {
    1: 10,
    2: 8,
    3: 6,
    4: 3,
    5: 1,
}

HIGH_RISK_FEEDBACK_TERMS: Final[tuple[str, ...]] = (
    "worse",
    "worsening",
    "chest pain",
    "shortness of breath",
    "can't breathe",
    "cannot breathe",
    "can't speak",
    "cannot speak",
    "cant speak",
    "unable to speak",
    "trouble speaking",
    "difficulty speaking",
    "need help",
    "need assistance",
    "faint",
    "fainted",
    "passed out",
    "seizure",
    "bleeding",
    "severe pain",
    "stroke",
    "weakness",
    "numbness",
    "confused",
    "suicidal",
    "oxygen",
)

FEEDBACK_MISMATCH_TERMS: Final[tuple[str, ...]] = (
    "too low",
    "undertriaged",
    "not urgent enough",
    "waited too long",
)

REQUIRED_TABLE_FIELDS: Final[dict[str, set[str]]] = {
    PATIENTS_REGISTRATION_TABLE: {"patient_id", "name", "dob", "gender", "contact_info"},
    HEALTHCARE_RECORDS_TABLE: {
        "record_id",
        "patient_id",
        "symptoms",
        "ctas_urgency_level",
        "risk_score",
        "queue_name",
        "status",
        "clinical_summary",
        "recommended_action",
        "check_in_time",
        "consultation_started_at",
        "completed_at",
    },
    FEEDBACK_TABLE: {
        "feedback_id",
        "record_id",
        "rating",
        "feedback_message",
        "condition_update",
        "alert_required",
        "alert_reason",
        "created_time",
    },
    MEDICAL_HISTORY_TABLE: {
        "history_id",
        "patient_id",
        "diagnosed_by",
        "condition",
        "status",
        "severity",
        "diagnosis_date",
        "notes",
        "treatment_given",
        "followup_required",
        "last_updated",
    },
}


def ctas_label(level: int) -> str:
    return CTAS_LEVELS[level]["label"]


def queue_name_for_ctas(level: int) -> str:
    if level in (1, 2):
        return QUEUE_EMERGENCY
    if level == 3:
        return QUEUE_NORMAL
    return QUEUE_NON_URGENT


def fallback_risk_score_from_ctas(level: int) -> int:
    return FALLBACK_RISK_SCORES.get(level, 1)
