from __future__ import annotations

from datetime import datetime
from typing import Any, Literal

from fastapi import HTTPException

from src.backend.clients.ehospital_client import (
    fetch_ehospital_table,
    write_ehospital_table_row,
)
from src.backend.schemas.wearables import (
    WearableWorkoutBatchIngestionRequest,
    WearableWorkoutBatchIngestionResponse,
    WearableWorkoutIngestionRequest,
    WearableWorkoutIngestionResponse,
    WearableIngestionRequest,
    WearableIngestionResponse,
)


WEARABLE_TABLE = "wearable_vitals"
WORKOUT_TABLE = "wearable_workouts"
METRIC_FIELDS = ("heart_rate", "steps", "calories", "sleep")
WORKOUT_FIELD_NAMES = (
    "patient_id",
    "source_provider",
    "source_workout_id",
    "source_bundle_id",
    "source_device_name",
    "source_device_manufacturer",
    "source_device_model",
    "source_device_hardware_version",
    "source_device_software_version",
    "workout_type",
    "workout_type_raw",
    "apple_workout_activity_type",
    "fitbit_activity_id",
    "fitbit_activity_name",
    "start_time",
    "end_time",
    "duration_seconds",
    "timezone_offset_minutes",
    "distance_meters",
    "active_energy_kcal",
    "basal_energy_kcal",
    "total_energy_kcal",
    "steps",
    "flights_climbed",
    "average_heart_rate_bpm",
    "max_heart_rate_bpm",
    "min_heart_rate_bpm",
    "average_speed_mps",
    "max_speed_mps",
    "average_cadence_spm",
    "elevation_gain_meters",
    "has_route",
    "route_source_workout_id",
    "sync_anchor",
    "sync_revision",
    "deleted_at_source",
    "source_metadata",
    "raw_payload",
)


async def ingest_wearable_sample(
    request: WearableIngestionRequest,
) -> WearableIngestionResponse:
    row = build_wearable_vitals_row(request)
    try:
        ehospital_response = await write_ehospital_table_row(WEARABLE_TABLE, row)
    except HTTPException as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Failed to ingest wearable sample: {exc.detail}",
        ) from exc

    recorded_on = request.recorded_on or request.timestamp
    return WearableIngestionResponse(
        patient_id=str(request.patient_id),
        accepted_metrics=request.accepted_metrics,
        source=request.source,
        timestamp=_isoformat(request.timestamp),
        recorded_on=_isoformat(recorded_on),
        ehospital_response=ehospital_response,
    )


def build_wearable_vitals_row(request: WearableIngestionRequest) -> dict[str, Any]:
    recorded_on = request.recorded_on or request.timestamp
    row: dict[str, Any] = {
        "patient_id": str(request.patient_id),
        "timestamp": _isoformat(request.timestamp),
        "recorded_on": _isoformat(recorded_on),
    }
    for field in METRIC_FIELDS:
        value = getattr(request, field)
        if value is not None:
            row[field] = _normalize_metric_value(value)
    return row


async def ingest_wearable_workout(
    request: WearableWorkoutIngestionRequest,
) -> WearableWorkoutIngestionResponse:
    existing = await find_existing_workout(request)
    if existing is not None:
        return build_wearable_workout_response(
            request,
            status="already_ingested",
            ehospital_response={"existing": existing},
        )

    row = build_wearable_workout_row(request)
    try:
        ehospital_response = await write_ehospital_table_row(WORKOUT_TABLE, row)
    except HTTPException as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Failed to ingest wearable workout: {exc.detail}",
        ) from exc

    return build_wearable_workout_response(
        request,
        status="ingested",
        ehospital_response=ehospital_response,
    )


async def ingest_wearable_workout_batch(
    request: WearableWorkoutBatchIngestionRequest,
) -> WearableWorkoutBatchIngestionResponse:
    results: list[WearableWorkoutIngestionResponse] = []
    for workout in request.workouts:
        results.append(await ingest_wearable_workout(workout))

    return WearableWorkoutBatchIngestionResponse(
        accepted_count=len(results),
        ingested_count=sum(1 for result in results if result.status == "ingested"),
        workouts=results,
    )


async def find_existing_workout(
    request: WearableWorkoutIngestionRequest,
) -> dict[str, Any] | None:
    try:
        rows = await fetch_ehospital_table(WORKOUT_TABLE, patient_id=request.patient_id)
    except HTTPException:
        rows = []

    return _find_matching_workout(rows, request)


def _find_matching_workout(
    rows: list[dict[str, Any]],
    request: WearableWorkoutIngestionRequest,
) -> dict[str, Any] | None:
    for row in rows:
        if _same_source_workout(row, request):
            return row
    return None


def _same_source_workout(
    row: dict[str, Any],
    request: WearableWorkoutIngestionRequest,
) -> bool:
    source_workout_ids = {
        request.source_workout_id,
        _stored_source_workout_id(request),
    }
    return (
        str(row.get("source_provider")) == request.source_provider
        and str(row.get("source_workout_id")) in source_workout_ids
    )


def build_wearable_workout_row(
    request: WearableWorkoutIngestionRequest,
) -> dict[str, Any]:
    row: dict[str, Any] = {}
    payload = request.model_dump()
    for field in WORKOUT_FIELD_NAMES:
        value = payload.get(field)
        if value is None:
            continue
        if isinstance(value, datetime):
            row[field] = _isoformat(value)
        elif isinstance(value, float):
            row[field] = _normalize_metric_value(value)
        elif isinstance(value, bool):
            row[field] = int(value)
        else:
            row[field] = value
    row["patient_id"] = str(request.patient_id)
    row["source_workout_id"] = _stored_source_workout_id(request)
    return row


def _stored_source_workout_id(request: WearableWorkoutIngestionRequest) -> str:
    return f"{request.patient_id}:{request.source_workout_id}"


def build_wearable_workout_response(
    request: WearableWorkoutIngestionRequest,
    *,
    status: Literal["ingested", "already_ingested"],
    ehospital_response: dict[str, Any],
) -> WearableWorkoutIngestionResponse:
    return WearableWorkoutIngestionResponse(
        status=status,
        patient_id=str(request.patient_id),
        source_provider=request.source_provider,
        source_workout_id=request.source_workout_id,
        workout_type=request.workout_type,
        start_time=_isoformat(request.start_time),
        end_time=_isoformat(request.end_time),
        duration_seconds=request.duration_seconds,
        ehospital_response=ehospital_response,
    )


def _normalize_metric_value(value: float) -> int | float:
    return int(value) if float(value).is_integer() else value


def _isoformat(value: datetime) -> str:
    return value.isoformat()
