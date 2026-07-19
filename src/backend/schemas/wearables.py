from __future__ import annotations

from datetime import datetime
from typing import Any, Literal

from pydantic import BaseModel, Field, field_validator, model_validator


WearableSource = Literal["apple_health", "google_health", "manual", "simulation"]
WorkoutSourceProvider = Literal[
    "apple_health",
    "fitbit",
    "google_health",
    "manual",
    "simulation",
]


class WearableIngestionRequest(BaseModel):
    patient_id: int | str
    heart_rate: float | None = Field(default=None, ge=0)
    steps: float | None = Field(default=None, ge=0)
    calories: float | None = Field(default=None, ge=0)
    sleep: float | None = Field(default=None, ge=0)
    timestamp: datetime
    recorded_on: datetime | None = None
    source: WearableSource = "manual"
    source_metadata: dict[str, Any] = Field(default_factory=dict)

    @field_validator("patient_id")
    @classmethod
    def patient_id_must_not_be_blank(cls, value: int | str) -> int | str:
        if str(value).strip() == "":
            raise ValueError("patient_id must not be empty")
        return value

    @model_validator(mode="after")
    def require_at_least_one_metric(self) -> "WearableIngestionRequest":
        if not self.accepted_metrics:
            raise ValueError(
                "At least one wearable metric is required: heart_rate, steps, calories, or sleep."
            )
        return self

    @property
    def accepted_metrics(self) -> list[str]:
        return [
            field
            for field in ("heart_rate", "steps", "calories", "sleep")
            if getattr(self, field) is not None
        ]


class WearableIngestionResponse(BaseModel):
    status: Literal["ingested"] = "ingested"
    patient_id: str
    accepted_metrics: list[str]
    source: str
    timestamp: str
    recorded_on: str
    ehospital_response: dict[str, Any] = Field(default_factory=dict)


class WearableWorkoutIngestionRequest(BaseModel):
    patient_id: int | str
    source_provider: WorkoutSourceProvider
    source_workout_id: str
    source_bundle_id: str | None = None
    source_device_name: str | None = None
    source_device_manufacturer: str | None = None
    source_device_model: str | None = None
    source_device_hardware_version: str | None = None
    source_device_software_version: str | None = None
    workout_type: str
    workout_type_raw: str | None = None
    apple_workout_activity_type: int | None = Field(default=None, ge=0)
    fitbit_activity_id: int | None = Field(default=None, ge=0)
    fitbit_activity_name: str | None = None
    start_time: datetime
    end_time: datetime
    duration_seconds: int = Field(ge=0)
    timezone_offset_minutes: int | None = Field(default=None, ge=-1440, le=1440)
    distance_meters: float | None = Field(default=None, ge=0)
    active_energy_kcal: float | None = Field(default=None, ge=0)
    basal_energy_kcal: float | None = Field(default=None, ge=0)
    total_energy_kcal: float | None = Field(default=None, ge=0)
    steps: int | None = Field(default=None, ge=0)
    flights_climbed: int | None = Field(default=None, ge=0)
    average_heart_rate_bpm: float | None = Field(default=None, ge=0)
    max_heart_rate_bpm: int | None = Field(default=None, ge=0)
    min_heart_rate_bpm: int | None = Field(default=None, ge=0)
    average_speed_mps: float | None = Field(default=None, ge=0)
    max_speed_mps: float | None = Field(default=None, ge=0)
    average_cadence_spm: float | None = Field(default=None, ge=0)
    elevation_gain_meters: float | None = Field(default=None, ge=0)
    has_route: bool = False
    route_source_workout_id: str | None = None
    sync_anchor: str | None = None
    sync_revision: str | None = None
    deleted_at_source: bool = False
    source_metadata: dict[str, Any] = Field(default_factory=dict)
    raw_payload: dict[str, Any] = Field(default_factory=dict)

    @field_validator("patient_id")
    @classmethod
    def patient_id_must_not_be_blank(cls, value: int | str) -> int | str:
        if str(value).strip() == "":
            raise ValueError("patient_id must not be empty")
        return value

    @field_validator(
        "source_workout_id",
        "workout_type",
        "source_bundle_id",
        "source_device_name",
        "source_device_manufacturer",
        "source_device_model",
        "source_device_hardware_version",
        "source_device_software_version",
        "workout_type_raw",
        "fitbit_activity_name",
        "route_source_workout_id",
        "sync_anchor",
        "sync_revision",
    )
    @classmethod
    def blank_strings_become_invalid_or_null(cls, value: str | None, info: Any) -> str | None:
        if value is None:
            return value
        stripped = value.strip()
        if not stripped and info.field_name in {"source_workout_id", "workout_type"}:
            raise ValueError(f"{info.field_name} must not be empty")
        return stripped or None

    @model_validator(mode="after")
    def validate_time_window(self) -> "WearableWorkoutIngestionRequest":
        if self.end_time < self.start_time:
            raise ValueError("end_time must be greater than or equal to start_time")
        return self


class WearableWorkoutIngestionResponse(BaseModel):
    status: Literal["ingested", "already_ingested"] = "ingested"
    patient_id: str
    source_provider: str
    source_workout_id: str
    workout_type: str
    start_time: str
    end_time: str
    duration_seconds: int
    ehospital_response: dict[str, Any] = Field(default_factory=dict)


class WearableWorkoutBatchIngestionRequest(BaseModel):
    workouts: list[WearableWorkoutIngestionRequest] = Field(min_length=1)


class WearableWorkoutBatchIngestionResponse(BaseModel):
    status: Literal["ingested"] = "ingested"
    accepted_count: int
    ingested_count: int
    workouts: list[WearableWorkoutIngestionResponse]
