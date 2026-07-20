from __future__ import annotations

from typing import Any
from datetime import datetime

from src.backend.schemas.assistant import (
    AssistantChartResult,
    AssistantChatResponse,
    AssistantReportResult,
    AssistantTextResult,
)


SUPPORTED_CHART_DISPLAY_TYPES = {"line", "bar"}


def compose_text_response(reply: str) -> AssistantChatResponse:
    text = reply.strip()
    return AssistantChatResponse(
        reply=text,
        results=[AssistantTextResult(content=text)],
    )


def validate_assistant_result_payload(
    payload: dict[str, Any],
) -> tuple[bool, list[str], dict[str, Any] | None]:
    """Validate and normalize agent-proposed assistant result payloads.

    Agent and LangGraph nodes must call this gate before result payloads are
    composed into `AssistantChatResponse`. Accepted payloads are:

    - text: {"type": "text", "content": "..."}
    - chart: {"type": "chart", "displayType": "line"|"bar", "title": ...,
      "xAxis": {"label": ..., "type": ...}, "yAxis": {"label": ..., "unit": ...},
      "series": [{"name": ..., "points": [{"x": ..., "y": number}]}]}
    - report: {"type": "report", "format": "markdown", "title": ...,
      "content": ..., "generatedAt": ISO timestamp, "expiresAt": ISO timestamp,
      "freshnessReason": ...}

    Unsupported display types, empty series, empty points, and non-numeric y
    values are rejected so Flutter never renders approximate charts.
    """
    result_type = payload.get("type")
    if result_type == "text":
        content = payload.get("content")
        if not isinstance(content, str) or not content.strip():
            return False, ["text.content must be a non-empty string."], None
        result = AssistantTextResult(content=content.strip())
        return True, [], _model_to_dict(result)

    if result_type == "report":
        return _validate_report_payload(payload)

    if result_type != "chart":
        return False, ["type must be 'text', 'chart', or 'report'."], None

    errors: list[str] = []
    if payload.get("displayType") not in SUPPORTED_CHART_DISPLAY_TYPES:
        errors.append("chart.displayType must be one of: bar, line.")
    if not isinstance(payload.get("title"), str) or not payload.get("title", "").strip():
        errors.append("chart.title must be a non-empty string.")
    if not isinstance(payload.get("xAxis"), dict):
        errors.append("chart.xAxis must be an object.")
    if not isinstance(payload.get("yAxis"), dict):
        errors.append("chart.yAxis must be an object.")

    raw_series = payload.get("series")
    if not isinstance(raw_series, list) or not raw_series:
        errors.append("chart.series must be a non-empty list.")
    else:
        for series_index, series in enumerate(raw_series):
            if not isinstance(series, dict):
                errors.append(f"chart.series[{series_index}] must be an object.")
                continue
            if not isinstance(series.get("name"), str) or not series.get("name", "").strip():
                errors.append(f"chart.series[{series_index}].name must be a non-empty string.")
            points = series.get("points")
            if not isinstance(points, list) or not points:
                errors.append(f"chart.series[{series_index}].points must be a non-empty list.")
                continue
            for point_index, point in enumerate(points):
                if not isinstance(point, dict):
                    errors.append(
                        f"chart.series[{series_index}].points[{point_index}] must be an object."
                    )
                    continue
                if "x" not in point:
                    errors.append(f"chart.series[{series_index}].points[{point_index}].x is required.")
                y_value = point.get("y")
                if not isinstance(y_value, (int, float)) or isinstance(y_value, bool):
                    errors.append(
                        f"chart.series[{series_index}].points[{point_index}].y must be numeric."
                    )

    if errors:
        return False, errors, None

    try:
        result = AssistantChartResult(**payload)
    except Exception as exc:
        return False, [str(exc)], None
    return True, [], _model_to_dict(result)


def _validate_report_payload(payload: dict[str, Any]) -> tuple[bool, list[str], dict[str, Any] | None]:
    errors: list[str] = []
    if payload.get("format") != "markdown":
        errors.append("report.format must be 'markdown'.")
    for field in ("title", "content", "generatedAt", "expiresAt", "freshnessReason"):
        if not isinstance(payload.get(field), str) or not payload.get(field, "").strip():
            errors.append(f"report.{field} must be a non-empty string.")

    generated_at = _parse_iso_timestamp(payload.get("generatedAt"))
    expires_at = _parse_iso_timestamp(payload.get("expiresAt"))
    if payload.get("generatedAt") and generated_at is None:
        errors.append("report.generatedAt must be an ISO timestamp.")
    if payload.get("expiresAt") and expires_at is None:
        errors.append("report.expiresAt must be an ISO timestamp.")
    if generated_at is not None and expires_at is not None and expires_at <= generated_at:
        errors.append("report.expiresAt must be after report.generatedAt.")
    content = payload.get("content")
    if isinstance(content, str) and _contains_raw_html(content):
        errors.append("report.content must not contain raw HTML.")

    if errors:
        return False, errors, None

    try:
        result = AssistantReportResult(**payload)
    except Exception as exc:
        return False, [str(exc)], None
    return True, [], _model_to_dict(result)


def _parse_iso_timestamp(value: Any) -> datetime | None:
    if not isinstance(value, str) or not value.strip():
        return None
    normalized = value.strip().replace("Z", "+00:00")
    try:
        return datetime.fromisoformat(normalized)
    except ValueError:
        return None


def _contains_raw_html(value: str) -> bool:
    return "<script" in value.lower() or "</" in value or "<div" in value.lower()


def _model_to_dict(model: Any) -> dict[str, Any]:
    if hasattr(model, "model_dump"):
        return model.model_dump()
    return model.dict()
