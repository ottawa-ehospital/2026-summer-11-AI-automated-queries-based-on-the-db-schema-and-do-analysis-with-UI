from __future__ import annotations

from typing import Literal

from pydantic import BaseModel, Field, field_validator


class SleepNight(BaseModel):
    night: str
    deep_minutes: float = Field(default=0, ge=0)
    rem_minutes: float = Field(default=0, ge=0)
    core_minutes: float = Field(default=0, ge=0)
    light_minutes: float = Field(default=0, ge=0)
    awake_minutes: float = Field(default=0, ge=0)
    asleep_minutes: float = Field(default=0, ge=0)
    in_bed_minutes: float = Field(default=0, ge=0)
    spo2_avg: float | None = Field(default=None, ge=0)
    spo2_min: float | None = Field(default=None, ge=0)
    hr_avg: float | None = Field(default=None, ge=0)
    hr_min: float | None = Field(default=None, ge=0)
    source: str = "apple_health"

    @field_validator("night")
    @classmethod
    def night_must_not_be_blank(cls, value: str) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError("night must not be empty")
        return stripped


class SleepNightsRequest(BaseModel):
    patient_id: int | str
    nights: list[SleepNight] = Field(default_factory=list)
    forward_to_ehospital: bool = True


class SleepNightsResponse(BaseModel):
    saved: int
    forwarded_to_ehospital: bool


class SleepNightsListResponse(BaseModel):
    count: int
    nights: list[SleepNight]


class SleepFeedbackRequest(BaseModel):
    patient_id: int | str
    days: int = Field(default=7, ge=1, le=60)
    model_invocation: "ModelInvocationSettings | None" = None


class SleepFeedbackResponse(BaseModel):
    feedback: str
    nights_analyzed: int


class SleepChatMessage(BaseModel):
    role: Literal["user", "assistant"]
    content: str


class SleepChatRequest(BaseModel):
    patient_id: int | str
    message: str
    history: list[SleepChatMessage] = Field(default_factory=list)
    days: int = Field(default=7, ge=1, le=60)
    model_invocation: "ModelInvocationSettings | None" = None


class SleepChatResponse(BaseModel):
    reply: str


from src.backend.schemas.assistant import ModelInvocationSettings  # noqa: E402

SleepFeedbackRequest.model_rebuild()
SleepChatRequest.model_rebuild()
