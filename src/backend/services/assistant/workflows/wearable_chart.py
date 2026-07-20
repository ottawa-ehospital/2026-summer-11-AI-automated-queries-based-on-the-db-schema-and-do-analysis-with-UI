from __future__ import annotations

from typing import Any, Literal, TypedDict

from fastapi import HTTPException
from langgraph.graph import END, START, StateGraph

from src.backend.schemas.assistant import (
    AssistantChartResult,
    AssistantChatResponse,
    AssistantTextResult,
)
from src.backend.schemas.query_tools import QueryFilter, QueryOrder, TableQueryRequest
from src.backend.services.assistant.result_helpers import (
    compose_text_response,
    validate_assistant_result_payload,
)
from src.backend.services.assistant.workflows.base import (
    AssistantWorkflowState,
    WorkflowMatch,
)
from src.backend.services.query_tools import query_table


class WearableChartState(TypedDict, total=False):
    patient_id: int | str
    message: str
    metric: dict[str, str] | None
    query_result: dict[str, Any]
    chart_payload: dict[str, Any]
    response: AssistantChatResponse


class WearableChartWorkflow:
    key = "wearable_chart"
    description = "Builds simple wearable metric chart responses."

    async def can_handle(self, state: AssistantWorkflowState) -> WorkflowMatch:
        metric = classify_wearable_metric_query(state.message)
        if metric is None:
            return WorkflowMatch(self.key, 0.0, "no wearable metric found")
        return WorkflowMatch(self.key, 0.95, f"wearable metric: {metric['field']}")

    async def run(self, state: AssistantWorkflowState) -> AssistantChatResponse:
        response = await build_wearable_chart_response(state.patient_id, state.message)
        if response is None:
            return compose_text_response("No chartable wearable metric was found.")
        return response


async def build_wearable_chart_response(
    patient_id: int | str,
    message: str,
) -> AssistantChatResponse | None:
    graph = build_wearable_chart_graph()
    result = await graph.ainvoke({"patient_id": patient_id, "message": message})
    return result.get("response")


def build_wearable_chart_graph() -> Any:
    graph = StateGraph(WearableChartState)
    graph.add_node("classify_metric_query", classify_metric_query_node)
    graph.add_node("build_single_table_query", build_single_table_query_node)
    graph.add_node("build_chart_result", build_chart_result_node)
    graph.add_node("validate_assistant_result", validate_assistant_result_node)
    graph.add_edge(START, "classify_metric_query")
    graph.add_conditional_edges(
        "classify_metric_query",
        should_build_chart,
        ["build_single_table_query", END],
    )
    graph.add_edge("build_single_table_query", "build_chart_result")
    graph.add_edge("build_chart_result", "validate_assistant_result")
    graph.add_edge("validate_assistant_result", END)
    return graph.compile()


def classify_metric_query_node(state: WearableChartState) -> WearableChartState:
    return {"metric": classify_wearable_metric_query(state.get("message", ""))}


def should_build_chart(state: WearableChartState) -> Literal["build_single_table_query", "__end__"]:
    return "build_single_table_query" if state.get("metric") is not None else END


async def build_single_table_query_node(state: WearableChartState) -> WearableChartState:
    metric = state.get("metric")
    if metric is None:
        return {}

    request = TableQueryRequest(
        table="wearable_vitals",
        fields=["timestamp", metric["field"]],
        filters=[QueryFilter(field="patient_id", operator="eq", value=state["patient_id"])],
        order_by=[QueryOrder(field="timestamp", direction="desc")],
        limit=20,
    )
    query_result = await query_table(request)
    return {"query_result": query_result}


def build_chart_result_node(state: WearableChartState) -> WearableChartState:
    metric = state.get("metric")
    if metric is None:
        return {}

    query_result = state.get("query_result", {})
    rows = [
        row
        for row in query_result.get("data", [])
        if isinstance(row, dict) and row.get(metric["field"]) is not None
    ]
    if not rows:
        return {"response": compose_text_response(f"No recent {metric['label'].lower()} data is available to chart.")}

    rows = sorted(rows, key=lambda row: str(row.get("timestamp", "")))
    points = []
    for row in rows:
        y_value = _coerce_number(row.get(metric["field"]))
        if y_value is None:
            continue
        x_value = row.get("timestamp")
        if x_value is None:
            continue
        points.append({"x": str(x_value), "y": y_value, "label": str(x_value)})

    if not points:
        return {"response": compose_text_response(f"No recent {metric['label'].lower()} data is available to chart.")}

    reply = f"Here is your recent {metric['label'].lower()} trend."
    payload = {
        "type": "chart",
        "displayType": metric["display_type"],
        "title": f"Recent {metric['label']}",
        "subtitle": "Latest wearable readings",
        "xAxis": {"label": "Time", "type": "time"},
        "yAxis": {"label": metric["label"], "unit": metric["unit"]},
        "series": [{"name": metric["label"], "points": points}],
    }
    return {"chart_payload": payload, "response": compose_text_response(reply)}


def validate_assistant_result_node(state: WearableChartState) -> WearableChartState:
    payload = state.get("chart_payload")
    response = state.get("response")
    if payload is None:
        return {"response": response} if response is not None else {}

    valid, errors, normalized = validate_assistant_result_payload(payload)
    if not valid or normalized is None:
        raise HTTPException(status_code=500, detail={"chart_result_errors": errors})
    reply = response.reply if response is not None else "Here is your recent wearable trend."
    return {
        "response": AssistantChatResponse(
            reply=reply,
            results=[AssistantTextResult(content=reply), AssistantChartResult(**normalized)],
        )
    }


def classify_wearable_metric_query(message: str) -> dict[str, str] | None:
    lowered = message.lower()
    metric_catalog = {
        "heart_rate": {
            "field": "heart_rate",
            "label": "Heart rate",
            "unit": "bpm",
            "display_type": "line",
            "terms": ["heart rate", "heartrate", "pulse", "\u5fc3\u7387"],
        },
        "steps": {
            "field": "steps",
            "label": "Steps",
            "unit": "steps",
            "display_type": "line",
            "terms": ["steps", "step count", "\u6b65\u6570"],
        },
        "calories": {
            "field": "calories",
            "label": "Calories",
            "unit": "kcal",
            "display_type": "line",
            "terms": ["calories", "calorie", "\u5361\u8def\u91cc"],
        },
        "sleep": {
            "field": "sleep",
            "label": "Sleep",
            "unit": "hours",
            "display_type": "bar",
            "terms": ["sleep", "\u7761\u7720"],
        },
    }
    for metric in metric_catalog.values():
        if any(term in lowered or term in message for term in metric["terms"]):
            return metric
    return None


def _coerce_number(value: Any) -> float | None:
    if isinstance(value, bool):
        return None
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        try:
            return float(value)
        except ValueError:
            return None
    return None
