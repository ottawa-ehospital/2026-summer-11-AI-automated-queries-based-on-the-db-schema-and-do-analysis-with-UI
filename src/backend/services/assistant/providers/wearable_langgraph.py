from __future__ import annotations

from src.backend.services.assistant.orchestrators.langgraph_orchestrator import (
    LangGraphAssistantOrchestrator,
)
from src.backend.services.assistant.workflows.health_data_query import (
    MAX_OUTPUT_VALIDATION_ATTEMPTS,
    MAX_QUERY_VALIDATION_ATTEMPTS,
    HealthDataQueryWorkflow,
    build_health_data_query_graph,
    classify_report_freshness,
    report_expiration_for_category,
)
from src.backend.services.assistant.workflows.wearable_chart import (
    WearableChartState,
    WearableChartWorkflow,
    build_chart_result_node,
    build_single_table_query_node,
    build_wearable_chart_graph,
    build_wearable_chart_response,
    classify_metric_query_node,
    classify_wearable_metric_query,
    query_table,
    should_build_chart,
    validate_assistant_result_node,
)


class WearableLangGraphAssistantProvider(LangGraphAssistantOrchestrator):
    """Compatibility alias for the workflow-capable assistant orchestrator.

    Historically this provider owned one wearable chart LangGraph. New code
    should treat it as an assistant orchestrator that routes across workflows
    while model calls remain behind the shared model client.
    """


__all__ = [
    "HealthDataQueryWorkflow",
    "LangGraphAssistantOrchestrator",
    "MAX_OUTPUT_VALIDATION_ATTEMPTS",
    "MAX_QUERY_VALIDATION_ATTEMPTS",
    "WearableChartState",
    "WearableChartWorkflow",
    "WearableLangGraphAssistantProvider",
    "build_chart_result_node",
    "build_health_data_query_graph",
    "build_single_table_query_node",
    "build_wearable_chart_graph",
    "build_wearable_chart_response",
    "classify_metric_query_node",
    "classify_report_freshness",
    "classify_wearable_metric_query",
    "query_table",
    "report_expiration_for_category",
    "should_build_chart",
    "validate_assistant_result_node",
]
