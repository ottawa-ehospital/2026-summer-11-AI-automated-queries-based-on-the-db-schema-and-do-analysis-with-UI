from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


Gender = Literal["Male", "Female", "Other"]
UrgentCareStatus = Literal["Waiting", "In Consultation", "Completed"]


class UrgentCareHealthResponse(BaseModel):
    status: str
    persistence_ready: bool
    required_tables: dict[str, list[str]]
    missing_tables: list[str] = Field(default_factory=list)
    missing_fields: dict[str, list[str]] = Field(default_factory=dict)
    ai_model_provider: str
    ai_model_name: str


class UrgentCareIntakeRequest(BaseModel):
    patient_id: int | None = Field(
        None,
        description="eHospital patient id. Flutter should pass the logged-in patient id when available.",
    )
    name: str = Field(..., min_length=1)
    age: int = Field(..., ge=0, le=125)
    gender: Gender = "Other"
    symptoms: str = Field(..., min_length=1)
    medical_history: str = ""


class UrgentCareAnalysis(BaseModel):
    ctas_level: int = Field(..., ge=1, le=5)
    urgency_label: str
    risk_score: int = Field(..., ge=1, le=10)
    queue_name: str
    clinical_summary: str
    reasoning: str
    recommended_action: str
    fallback_used: bool = False
    agent_source: str = "shared_model"
    history_used: list[dict[str, Any]] = Field(default_factory=list)


class UrgentCarePatientRecord(BaseModel):
    id: int
    patient_id: int
    name: str
    age: int
    symptoms: str
    medical_history: str = ""
    ctas_level: int = Field(..., ge=1, le=5)
    risk_score: int = Field(..., ge=1, le=10)
    queue_name: str
    clinical_summary: str
    reasoning: str = ""
    recommended_action: str = ""
    status: str = "Waiting"
    checked_in_at: str
    consultation_started_at: str | None = None
    completed_at: str | None = None
    notified_at: str | None = None
    urgency_label: str | None = None
    waiting_minutes: int | None = None


class UrgentCareCheckInResponse(BaseModel):
    message: str
    patient: "UrgentCarePatientStatus"
    analysis: UrgentCareAnalysis
    database: dict[str, Any]
    registration_database: dict[str, Any] | None = None
    medical_history_database: dict[str, Any] | None = None


class UrgentCarePatientStatus(BaseModel):
    local_patient_id: int
    patient_id: int
    queue_number: int | None = None
    status: str
    patients_ahead: int
    estimated_wait_range: str
    notified: bool = False
    notified_at: str | None = None
    checked_in_at: str
    server_time: str
    access_token: str | None = None
    submitted_information: dict[str, Any]


class UrgentCareFeedbackRequest(BaseModel):
    rating: str = Field("Unsure", description="Reasonable, Too high, Too low, Unsure, or app-specific rating.")
    message: str = Field("", description="Queue/app feedback or prefixed patient-app update.")
    feedback_message: str = ""
    condition_update: str = ""
    ctas_level: int | None = Field(None, ge=1, le=5)
    risk_score: int | None = Field(None, ge=1, le=10)


class UrgentCareWorkflowFeedbackRequest(UrgentCareFeedbackRequest):
    patient_id: int


class UrgentCareFeedbackAlert(BaseModel):
    alert_required: bool
    severity: str = "none"
    alert_reason: str = ""
    recommended_staff_action: str = ""
    patient_message: str = ""
    feedback_type: str = "triage_review"
    agent_source: str = "keyword_safety_fallback"


class UrgentCareFeedbackResponse(BaseModel):
    message: str
    feedback: dict[str, Any]
    alert_agent: UrgentCareFeedbackAlert
    database: dict[str, Any]
    alert: dict[str, Any] | None = None


class UrgentCareQueuesResponse(BaseModel):
    summary: dict[str, Any]
    queues: dict[str, list[dict[str, Any]]]


class UrgentCarePatientsResponse(BaseModel):
    active: list[dict[str, Any]]
    completed: list[dict[str, Any]]


class UrgentCareHistoryResponse(BaseModel):
    patient_id: int
    history: list[dict[str, Any]]


class UrgentCareAlertsResponse(BaseModel):
    alerts: list[dict[str, Any]]


class UrgentCareActionResponse(BaseModel):
    message: str
    patient: dict[str, Any]
    database: dict[str, Any] | None = None
    summary: dict[str, Any] | None = None


UrgentCareCheckInResponse.model_rebuild()
