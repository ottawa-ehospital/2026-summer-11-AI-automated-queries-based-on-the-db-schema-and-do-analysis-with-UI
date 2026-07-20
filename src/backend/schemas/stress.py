from __future__ import annotations

from pydantic import BaseModel, Field, field_validator

from src.backend.schemas.assistant import ModelInvocationSettings


class StressSnapshotRequest(BaseModel):
    patient_id: int | str
    hrv_sdnn: float | None = Field(default=None, ge=0)
    resting_heart_rate: float | None = Field(default=None, ge=0)
    respiratory_rate: float | None = Field(default=None, ge=0)
    heart_rate: float | None = Field(default=None, ge=0)
    timestamp: str

    @field_validator("patient_id")
    @classmethod
    def patient_id_must_not_be_blank(cls, value: int | str) -> int | str:
        if str(value).strip() == "":
            raise ValueError("patient_id must not be empty")
        return value

    @field_validator("timestamp")
    @classmethod
    def timestamp_must_not_be_blank(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("timestamp must not be empty")
        return stripped


class AnnotationUpdateRequest(BaseModel):
    annotation: str


class StressAnalysisRequest(BaseModel):
    patient_id: int | str
    model_invocation: ModelInvocationSettings | None = None


class StressAnalysisResponse(BaseModel):
    analysis: str
