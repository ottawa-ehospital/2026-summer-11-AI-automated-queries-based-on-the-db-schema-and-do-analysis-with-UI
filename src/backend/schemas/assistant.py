from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field, field_validator


class ModelInvocationSettings(BaseModel):
    provider_key: str | None = None
    model_provider: str | None = None
    model_name: str | None = None
    base_url: str | None = None
    use_graph_flow: bool | None = None


class AssistantChatRequest(BaseModel):
    patient_id: int | str
    message: str
    history: list["AssistantConversationMessage"] = Field(default_factory=list)
    model_invocation: ModelInvocationSettings | None = None


class AssistantConversationMessage(BaseModel):
    role: str
    content: str


class AssistantTextResult(BaseModel):
    type: Literal["text"] = "text"
    content: str


class AssistantChartAxis(BaseModel):
    label: str
    type: str | None = None
    unit: str | None = None


class AssistantChartPoint(BaseModel):
    x: str | int | float
    y: float
    label: str | None = None
    metadata: dict[str, Any] = Field(default_factory=dict)


class AssistantChartSeries(BaseModel):
    name: str
    points: list[AssistantChartPoint]


class AssistantChartResult(BaseModel):
    type: Literal["chart"] = "chart"
    displayType: Literal["line", "bar"]
    title: str
    subtitle: str | None = None
    xAxis: AssistantChartAxis
    yAxis: AssistantChartAxis
    series: list[AssistantChartSeries]


class AssistantReportResult(BaseModel):
    type: Literal["report"] = "report"
    format: Literal["markdown"] = "markdown"
    title: str
    content: str
    generatedAt: str
    expiresAt: str
    freshnessReason: str
    sourceSummary: str | None = None


AssistantResult = AssistantTextResult | AssistantChartResult | AssistantReportResult


class AssistantChatResponse(BaseModel):
    reply: str
    results: list[AssistantResult] = Field(default_factory=list)


class VitalsSummaryRequest(BaseModel):
    patient_id: int | str
    metric: str
    latest: float | None = None
    average: float | None = None
    peak: float | None = None
    zero_count: int = 0
    total_count: int = 0
    unit: str = ""
    healthy_range: str = ""
    clinical_note: str | None = None
    model_invocation: ModelInvocationSettings | None = None


class VitalsSummaryResponse(BaseModel):
    summary: str


class TrendInsightsRequest(BaseModel):
    patient_id: int | str
    steps: dict[str, float] = Field(default_factory=dict)
    calories: dict[str, float] = Field(default_factory=dict)
    heart_rate: dict[str, float] = Field(default_factory=dict)
    sleep: dict[str, float] = Field(default_factory=dict)
    model_invocation: ModelInvocationSettings | None = None


class TrendInsightsResponse(BaseModel):
    insights: dict[str, str]


class HealthAlertEventRequest(BaseModel):
    patient_id: int | str
    event_type: str
    event_source_id: str
    event_time: str
    values: dict[str, Any] = Field(default_factory=dict)
    unit: str | None = None
    source: str = "apple_health"
    source_mode: Literal["production", "test", "simulation"] = "production"
    source_metadata: dict[str, Any] = Field(default_factory=dict)
    model_invocation: ModelInvocationSettings | None = None

    @field_validator("patient_id")
    @classmethod
    def patient_id_must_not_be_blank(cls, value: int | str) -> int | str:
        if str(value).strip() == "":
            raise ValueError("patient_id must not be empty")
        return value

    @field_validator("event_type", "event_source_id", "event_time")
    @classmethod
    def required_strings_must_not_be_blank(cls, value: str, info: Any) -> str:
        stripped = value.strip()
        if not stripped:
            raise ValueError(f"{info.field_name} must not be empty")
        return stripped


class HealthAlertDecisionResponse(BaseModel):
    status: Literal[
        "notification_decision",
        "no_notification",
        "unsupported_event",
        "invalid_event",
    ]
    patient_id: str
    event_type: str
    event_source_id: str
    source_mode: str
    notify: bool
    severity: Literal["none", "info", "low", "medium", "high"] = "none"
    title: str | None = None
    body: str | None = None
    reason: str
    evidence_summary: list[str] = Field(default_factory=list)
    recommendation_category: str | None = None
    freshness: dict[str, Any] = Field(default_factory=dict)
    trace: dict[str, Any] = Field(default_factory=dict)
