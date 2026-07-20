from __future__ import annotations

import json
from datetime import datetime, timedelta, timezone
from typing import Any, Literal, TypedDict

from fastapi import HTTPException
from langgraph.graph import END, START, StateGraph

from src.backend.clients.model_client import invoke_model
from src.backend.schemas.assistant import (
    AssistantChartResult,
    AssistantChatResponse,
    AssistantReportResult,
    AssistantTextResult,
    ModelInvocationSettings,
)
from src.backend.services.assistant.result_helpers import (
    compose_text_response,
    validate_assistant_result_payload,
)
from src.backend.services.assistant.workflows.base import (
    AssistantWorkflowState,
    WorkflowMatch,
)
from src.backend.services.query_tools import (
    load_schema_inventory,
    multi_query_result_metadata,
    normalized_sigma_to_table_query,
    query_table,
    validate_sigma_payload,
)


MAX_QUERY_VALIDATION_ATTEMPTS = 2
MAX_OUTPUT_VALIDATION_ATTEMPTS = 2
MAX_ANALYSIS_VALIDATION_ATTEMPTS = 2
DEFAULT_QUERY_LIMIT = 20


class HealthDataQueryState(TypedDict, total=False):
    patient_id: int | str
    message: str
    history: list[dict[str, str]]
    model_invocation: ModelInvocationSettings | None
    intent: dict[str, Any]
    context: dict[str, Any]
    sigma_payload: dict[str, Any]
    normalized_sigma: dict[str, Any]
    sigma_errors: list[str]
    context_plan: dict[str, Any]
    normalized_query_entries: list[dict[str, Any]]
    table_query_entries: list[dict[str, Any]]
    query_errors: list[str]
    query_results: list[dict[str, Any]]
    context_package: dict[str, Any]
    missing_context: list[dict[str, Any]]
    row_counts: dict[str, int]
    safety_hints: list[dict[str, str]]
    query_payload: dict[str, Any]
    query_valid: bool
    query_validation_attempts: int
    query_result: dict[str, Any]
    query_error: str
    empty_result: bool
    analysis: dict[str, Any]
    analysis_validation_attempts: int
    output_plan: dict[str, Any]
    report_payload: dict[str, Any]
    chart_payload: dict[str, Any]
    text_payload: dict[str, Any]
    output_errors: list[str]
    output_valid: bool
    output_validation_attempts: int
    response: AssistantChatResponse
    trace: dict[str, Any]


class IntentAnalysis(TypedDict, total=False):
    kind: str
    metric: str
    target_metrics: list[str]
    candidate_tables: list[str]
    time_range: str
    output_needs: list[str]
    freshness_category: str
    needs_profile: bool
    requires_query: bool
    needs_clarification: bool
    clarification: str
    confidence: float
    reason: str


class QueryAnalysis(TypedDict, total=False):
    summary: str
    evidence: list[dict[str, str]]
    recommendations: list[str]
    limitations: list[str]
    freshnessCategory: str
    chartCandidates: list[dict[str, Any]]


METRIC_CATALOG: dict[str, dict[str, Any]] = {
    "heart_rate": {
        "label": "Heart rate",
        "field": "heart_rate",
        "unit": "bpm",
        "display_type": "line",
        "terms": ["heart rate", "heartrate", "pulse", "心率"],
    },
    "steps": {
        "label": "Steps",
        "field": "steps",
        "unit": "steps",
        "display_type": "line",
        "terms": ["steps", "step count", "步数"],
    },
    "calories": {
        "label": "Calories",
        "field": "calories",
        "unit": "kcal",
        "display_type": "line",
        "terms": ["calories", "calorie", "卡路里"],
    },
    "sleep": {
        "label": "Sleep",
        "field": "sleep",
        "unit": "hours",
        "display_type": "bar",
        "terms": ["sleep", "睡眠"],
    },
}

HEALTH_DATA_TERMS = [
    "heart rate",
    "heartrate",
    "pulse",
    "blood pressure",
    "bp",
    "sleep",
    "steps",
    "calories",
    "activity",
    "readiness",
    "wearable",
    "workout",
    "workouts",
    "exercise history",
    "exercise",
    "running",
    "run",
    "cycling",
    "ride",
    "bike",
    "biking",
    "inactivity",
    "inactive",
    "long-distance",
    "recent",
    "心率",
    "血压",
    "睡眠",
    "步数",
    "卡路里",
    "运动",
    "跑步",
    "骑行",
    "长途",
]
WORKOUT_HISTORY_TERMS = [
    "workout",
    "workouts",
    "exercise",
    "exercise history",
    "activity history",
    "running",
    "run",
    "cycling",
    "ride",
    "bike",
    "biking",
    "inactivity",
    "inactive",
    "long-distance",
    "运动",
    "跑步",
    "骑行",
    "长途",
]
PLANNING_ACTION_TERMS = [
    "plan",
    "routine",
    "schedule",
    "workout",
    "exercise",
    "running",
    "run",
    "training",
    "fitness",
    "goal",
    "improve",
    "计划",
    "运动",
    "跑步",
    "改善",
]
PLANNING_ADVICE_TERMS = ["recommend", "recommendation", "should i", "can i", "advice", "suggest", "建议"]
REPORT_TERMS = ["report", "analysis", "analyze", "analyse", "insight report", "报告", "分析"]
TRAINING_READINESS_TERMS = [
    "training readiness",
    "readiness",
    "tomorrow",
    "intensive training",
    "hard training",
    "train hard",
    "can i run",
    "can i train",
    "适合训练",
    "明天",
    "高强度",
]
FORCED_TRAINING_CONTEXT_TABLES = [
    "wearable_vitals",
    "vitals_history",
    "lab_tests",
    "bloodtests",
    "diagnosis",
    "medical_history",
    "prescription_form",
    "wearable_workouts",
]
HEALTH_CONTEXT_TABLE_DEFAULTS: dict[str, dict[str, Any]] = {
    "wearable_vitals": {
        "domain": "wearable_vitals",
        "purpose": "recent wearable vitals, sleep, steps, calories, and heart rate",
        "fields": ["timestamp", "heart_rate", "steps", "calories", "sleep"],
        "order_field": "timestamp",
        "limit": DEFAULT_QUERY_LIMIT,
    },
    "vitals_history": {
        "domain": "clinical_vitals",
        "purpose": "recent clinical vitals including blood pressure and heart rate",
        "fields": ["recorded_on", "blood_pressure", "heart_rate", "temperature", "respiratory_rate", "notes"],
        "order_field": "recorded_on",
        "limit": DEFAULT_QUERY_LIMIT,
    },
    "lab_tests": {
        "domain": "labs",
        "purpose": "recent lab test results and clinical comments",
        "fields": ["test_type", "status", "sample_type", "result", "comments", "test_date", "uploaded_on"],
        "order_field": "test_date",
        "limit": 10,
    },
    "bloodtests": {
        "domain": "labs",
        "purpose": "recent blood test values and normal ranges",
        "fields": ["test_name", "result_value", "unit", "normal_range", "test_date"],
        "order_field": "test_date",
        "limit": 10,
    },
    "requisition_form": {
        "domain": "labs",
        "purpose": "recent ordered or pending lab requisitions",
        "fields": ["department", "test_type", "test_code", "clinical_info", "date_requested", "priority", "status", "result_date", "notes"],
        "order_field": "date_requested",
        "limit": 10,
    },
    "diagnosis": {
        "domain": "diagnosis",
        "purpose": "diagnosis context that may affect health planning",
        "fields": ["diagnosis_code", "diagnosis_description", "diagnosis_date"],
        "order_field": "diagnosis_date",
        "limit": 10,
    },
    "medical_history": {
        "domain": "medical_history",
        "purpose": "medical history and condition severity context",
        "fields": ["condition", "status", "severity", "diagnosis_date", "notes", "treatment_given", "followup_required", "last_updated"],
        "order_field": "last_updated",
        "limit": 10,
    },
    "prescription_form": {
        "domain": "medication",
        "purpose": "active or recent medication context from prescription forms",
        "fields": ["medication_name", "medication_strength", "dosage_instructions", "date_prescribed", "expiry_date", "status", "notes"],
        "order_field": "date_prescribed",
        "limit": 10,
    },
    "prescription": {
        "domain": "medication",
        "purpose": "active or recent medication context from prescriptions",
        "fields": ["medicine_name", "dosage", "start_date", "end_date", "issued_on", "status", "notes"],
        "order_field": "issued_on",
        "limit": 10,
    },
    "patient_feedback": {
        "domain": "symptoms",
        "purpose": "patient-reported symptoms or feedback",
        "fields": ["treatment", "feedback", "datetime", "is_severe", "feedback_type"],
        "order_field": "datetime",
        "limit": 10,
    },
    "heart_disease_analysis": {
        "domain": "risk_analysis",
        "purpose": "heart disease risk-analysis context",
        "fields": ["resting_bp", "risk_score", "prediction", "analyzed_on", "comments"],
        "order_field": "analyzed_on",
        "limit": 5,
    },
    "diabetes_analysis": {
        "domain": "risk_analysis",
        "purpose": "diabetes risk-analysis context including glucose level",
        "fields": ["glucose_level", "insulin", "prediction"],
        "order_field": "diabetes_id",
        "limit": 5,
    },
    "ecg": {
        "domain": "clinical_vitals",
        "purpose": "recent ECG result context",
        "fields": ["ecg_result", "recorded_on", "comments"],
        "order_field": "recorded_on",
        "limit": 5,
    },
    "stroke_prediction": {
        "domain": "risk_analysis",
        "purpose": "stroke risk prediction context",
        "fields": ["risk_score", "predicted_on", "comments"],
        "order_field": "predicted_on",
        "limit": 5,
    },
    "ai_diagnostics": {
        "domain": "risk_analysis",
        "purpose": "AI diagnostic context",
        "fields": ["disease_type", "prediction", "confidence_score", "created_at"],
        "order_field": "created_at",
        "limit": 5,
    },
    "wearable_workouts": {
        "domain": "workout_history",
        "purpose": "recent workout load, duration, distance, and effort context",
        "fields": [
            "workout_type",
            "start_time",
            "end_time",
            "duration_seconds",
            "distance_meters",
            "active_energy_kcal",
            "average_heart_rate_bpm",
            "max_heart_rate_bpm",
            "source_provider",
        ],
        "order_field": "start_time",
        "limit": DEFAULT_QUERY_LIMIT,
    },
}


class HealthDataQueryWorkflow:
    key = "health_data_query"
    description = "Personalized health data query, analysis, and Markdown report workflow."

    async def can_handle(self, state: AssistantWorkflowState) -> WorkflowMatch:
        intent = analyse_message_intent(state.message)
        if float(intent.get("confidence", 0.0)) < 0.6 and state.model_invocation is not None:
            intent = model_backed_intent_analysis(state.message, state.model_invocation) or intent
        confidence = float(intent.get("confidence", 0.0))
        if confidence <= 0:
            return WorkflowMatch(self.key, 0.0, "no report intent")
        return WorkflowMatch(self.key, confidence, str(intent.get("reason", "health-data request")))

    async def run(self, state: AssistantWorkflowState) -> AssistantChatResponse:
        graph = build_health_data_query_graph()
        result = await graph.ainvoke(
            {
                "patient_id": state.patient_id,
                "message": state.message,
                "history": [
                    {"role": item.role, "content": item.content}
                    for item in state.history
                ],
                "model_invocation": state.model_invocation,
                "query_validation_attempts": 0,
                "analysis_validation_attempts": 0,
                "output_validation_attempts": 0,
                "trace": {
                    "selected_workflow": self.key,
                    "model_provider": (
                        state.model_invocation.model_provider
                        if state.model_invocation is not None
                        else None
                    ),
                },
            }
        )
        response = result.get("response")
        if response is None:
            return compose_text_response("I could not generate a validated report for this request.")
        return response


def build_health_data_query_graph() -> Any:
    graph = StateGraph(HealthDataQueryState)
    graph.add_node("analyse_question", analyse_question_node)
    graph.add_node("route_context_needs", route_context_needs_node)
    graph.add_node("prepare_context", prepare_context_node)
    graph.add_node("build_query", build_query_node)
    graph.add_node("validate_query", validate_query_node)
    graph.add_node("revise_query", revise_query_node)
    graph.add_node("execute_query", execute_query_node)
    graph.add_node("analyse_query_results", analyse_query_results_node)
    graph.add_node("decide_output_plan", decide_output_plan_node)
    graph.add_node("generate_report", generate_report_node)
    graph.add_node("validate_output", validate_output_node)
    graph.add_node("revise_report", revise_report_node)
    graph.add_node("fallback_response", fallback_response_node)

    graph.add_edge(START, "analyse_question")
    graph.add_conditional_edges(
        "analyse_question",
        route_after_question_analysis,
        ["route_context_needs", "fallback_response"],
    )
    graph.add_edge("route_context_needs", "prepare_context")
    graph.add_edge("prepare_context", "build_query")
    graph.add_edge("build_query", "validate_query")
    graph.add_conditional_edges(
        "validate_query",
        route_query_validation,
        ["execute_query", "revise_query", "fallback_response"],
    )
    graph.add_edge("revise_query", "validate_query")
    graph.add_edge("execute_query", "analyse_query_results")
    graph.add_edge("analyse_query_results", "decide_output_plan")
    graph.add_edge("decide_output_plan", "generate_report")
    graph.add_edge("generate_report", "validate_output")
    graph.add_conditional_edges(
        "validate_output",
        route_output_validation,
        ["__end__", "revise_report", "fallback_response"],
    )
    graph.add_edge("revise_report", "validate_output")
    graph.add_edge("fallback_response", END)
    return graph.compile()


def analyse_question_node(state: HealthDataQueryState) -> HealthDataQueryState:
    intent = analyse_message_intent(state.get("message", ""))
    if float(intent.get("confidence", 0.0)) < 0.6 and state.get("model_invocation") is not None:
        intent = model_backed_intent_analysis(
            state.get("message", ""),
            state["model_invocation"],
        ) or intent
    return {
        "intent": intent,
        "trace": {
            **state.get("trace", {}),
            "intent_kind": intent.get("kind"),
            "target_metric": intent.get("metric"),
        },
    }


def route_after_question_analysis(
    state: HealthDataQueryState,
) -> Literal["route_context_needs", "fallback_response"]:
    intent = state.get("intent", {})
    if intent.get("needs_clarification"):
        return "fallback_response"
    if not intent.get("requires_query"):
        return "fallback_response"
    return "route_context_needs"


def route_context_needs_node(state: HealthDataQueryState) -> HealthDataQueryState:
    intent = state.get("intent", {})
    return {
        "context": {
            "patient_id": state.get("patient_id"),
            "needs_profile": intent.get("needs_profile", True),
            "needs_web": False,
            "source": "assistant request",
        }
    }


def prepare_context_node(state: HealthDataQueryState) -> HealthDataQueryState:
    context = dict(state.get("context", {}))
    context["prepared"] = True
    context["schema_context"] = build_schema_planning_context()
    return {"context": context}


def build_query_node(state: HealthDataQueryState) -> HealthDataQueryState:
    context_plan = build_context_plan(state)
    selected_tables = [
        entry.get("sigma", {}).get("logsource", {}).get("service")
        for entry in context_plan.get("queries", [])
        if isinstance(entry, dict)
    ]
    return {
        "context_plan": context_plan,
        "query_payload": context_plan,
        "trace": {
            **state.get("trace", {}),
            "selected_tables": selected_tables,
            "query_ids": [
                entry.get("query_id")
                for entry in context_plan.get("queries", [])
                if isinstance(entry, dict)
            ],
        },
    }


def validate_query_node(state: HealthDataQueryState) -> HealthDataQueryState:
    attempts = state.get("query_validation_attempts", 0) + 1
    entries = state.get("context_plan", {}).get("queries", [])
    if not isinstance(entries, list) or not entries:
        entries = [
            {
                "query_id": "legacy_query",
                "purpose": "single health-data query",
                "required": True,
                "domain": "health_data",
                "sigma": state.get("sigma_payload", {}),
            }
        ]

    normalized_entries: list[dict[str, Any]] = []
    table_query_entries: list[dict[str, Any]] = []
    errors: list[str] = []
    missing_context: list[dict[str, Any]] = []
    for index, entry in enumerate(entries):
        if not isinstance(entry, dict):
            errors.append(f"query_{index + 1}: query entry must be an object.")
            continue
        query_id = str(entry.get("query_id") or f"query_{index + 1}")
        required = bool(entry.get("required", False))
        sigma = entry.get("sigma")
        if not isinstance(sigma, dict):
            detail = f"{query_id}: sigma must be an object."
            (errors if required else missing_context).append(
                detail if required else {"queryId": query_id, "reason": detail}
            )
            continue
        valid, sigma_errors, normalized = validate_sigma_payload(sigma)
        if not valid or normalized is None:
            detail = "; ".join(sigma_errors) or "Sigma validation failed."
            if required:
                errors.append(f"{query_id}: {detail}")
            else:
                missing_context.append(
                    {
                        "queryId": query_id,
                        "table": sigma.get("logsource", {}).get("service"),
                        "reason": detail,
                    }
                )
            continue
        normalized_entry = {
            "query_id": query_id,
            "purpose": str(entry.get("purpose") or query_id),
            "required": required,
            "domain": entry.get("domain") if isinstance(entry.get("domain"), str) else None,
            "normalized_sigma": normalized,
        }
        try:
            table_request = normalized_sigma_to_table_query(normalized, state["patient_id"])
        except HTTPException as exc:
            detail = exc.detail if isinstance(exc.detail, str) else str(exc.detail)
            if required:
                errors.append(f"{query_id}: {detail}")
            else:
                missing_context.append(
                    {
                        "queryId": query_id,
                        "table": normalized.get("table"),
                        "reason": detail,
                    }
                )
            continue
        normalized_entries.append(normalized_entry)
        table_query_entries.append({**normalized_entry, "table_request": table_request})

    selected_tables = [
        item["table_request"].table
        for item in table_query_entries
        if hasattr(item.get("table_request"), "table")
    ]
    if errors or not table_query_entries:
        all_errors = errors or ["No context queries could be safely converted."]
        return {
            "query_valid": False,
            "query_validation_attempts": attempts,
            "sigma_errors": all_errors,
            "query_errors": all_errors,
            "missing_context": missing_context,
            "trace": {
                **state.get("trace", {}),
                "query_validation_attempts": attempts,
                "selected_tables": selected_tables,
                "missing_context": missing_context,
                "fallback_stage": "validate_context_plan",
            },
        }
    return {
        "query_valid": True,
        "query_validation_attempts": attempts,
        "normalized_query_entries": normalized_entries,
        "table_query_entries": table_query_entries,
        "normalized_sigma": normalized_entries[0]["normalized_sigma"],
        "query_payload": [_model_to_dict(entry["table_request"]) for entry in table_query_entries],
        "missing_context": missing_context,
        "trace": {
            **state.get("trace", {}),
            "query_validation_attempts": attempts,
            "selected_tables": selected_tables,
            "query_ids": [entry["query_id"] for entry in table_query_entries],
            "missing_context": missing_context,
        },
    }


def route_query_validation(
    state: HealthDataQueryState,
) -> Literal["execute_query", "revise_query", "fallback_response"]:
    if state.get("query_valid") or state.get("sigma_valid"):
        return "execute_query"
    if state.get("query_validation_attempts", 0) < MAX_QUERY_VALIDATION_ATTEMPTS:
        return "revise_query"
    return "fallback_response"


def revise_query_node(state: HealthDataQueryState) -> HealthDataQueryState:
    context_plan = build_context_plan(state)
    return {"context_plan": context_plan, "query_payload": context_plan}


async def execute_query_node(state: HealthDataQueryState) -> HealthDataQueryState:
    query_results: list[dict[str, Any]] = []
    missing_context = list(state.get("missing_context", []))
    query_errors: list[str] = []
    for entry in state.get("table_query_entries", []):
        if not isinstance(entry, dict):
            continue
        table_request = entry.get("table_request")
        if table_request is None:
            continue
        try:
            result = await query_table(table_request)
        except Exception as exc:
            detail = _safe_query_error_message(exc)
            if entry.get("required"):
                query_errors.append(f"{entry.get('query_id')}: {detail}")
            else:
                missing_context.append(
                    {
                        "queryId": entry.get("query_id"),
                        "table": getattr(table_request, "table", None),
                        "reason": detail,
                    }
                )
            continue
        metadata = multi_query_result_metadata(entry, table_request, result)
        if metadata["empty"]:
            missing_context.append(
                {
                    "queryId": entry.get("query_id"),
                    "table": getattr(table_request, "table", None),
                    "reason": "No rows returned for this context source.",
                }
            )
        query_results.append(metadata)

    context_package = build_context_package(state, query_results, missing_context)
    rows_by_table = context_package.get("rowsByTable", {})
    all_rows = [
        row
        for rows in rows_by_table.values()
        if isinstance(rows, list)
        for row in rows
        if isinstance(row, dict)
    ]
    if query_errors:
        return {
            "empty_result": not all_rows,
            "query_error": "; ".join(query_errors),
            "query_errors": query_errors,
            "query_results": query_results,
            "context_package": context_package,
            "missing_context": missing_context,
            "row_counts": context_package.get("rowCounts", {}),
            "safety_hints": context_package.get("safetyHints", []),
            "trace": {
                **state.get("trace", {}),
                "row_counts": context_package.get("rowCounts", {}),
                "missing_context": missing_context,
                "fallback_stage": "execute_context_plan",
            },
        }
    clean_rows = all_rows
    return {
        "empty_result": not clean_rows,
        "query_result": {
            "data": clean_rows,
            "count": len(clean_rows),
            "sourceSummary": source_summary_for_context(context_package),
        },
        "query_results": query_results,
        "context_package": context_package,
        "missing_context": missing_context,
        "row_counts": context_package.get("rowCounts", {}),
        "safety_hints": context_package.get("safetyHints", []),
        "trace": {
            **state.get("trace", {}),
            "row_counts": context_package.get("rowCounts", {}),
            "missing_context": missing_context,
            "execution_status": [
                {
                    "queryId": item.get("queryId"),
                    "table": item.get("table"),
                    "count": item.get("count"),
                    "empty": item.get("empty"),
                }
                for item in query_results
            ],
        },
    }


def _is_missing_optional_workout_table_error(exc: Exception) -> bool:
    message = str(exc).lower()
    return "wearable_workouts" in message and (
        "doesn't exist" in message
        or "does not exist" in message
        or "unknown table" in message
    )


def analyse_query_results_node(state: HealthDataQueryState) -> HealthDataQueryState:
    intent = state.get("intent", {})
    query_result = state.get("query_result", {})
    context_package = state.get("context_package", {})
    rows = query_result.get("data", [])
    if state.get("empty_result") or not rows:
        missing_reasons = [
            str(item.get("reason"))
            for item in state.get("missing_context", [])
            if isinstance(item, dict) and item.get("reason")
        ]
        return {
            "analysis": {
                "summary": "No matching patient data was available for this request.",
                "evidence": [],
                "recommendations": [
                    "Try again after new wearable or health records are available."
                ],
                "limitations": missing_reasons
                or [state.get("query_error", "The validated query returned no rows.")],
                "freshnessCategory": intent.get("freshness_category", "short_term"),
                "chartCandidates": [],
            }
        }

    deterministic = deterministic_context_analysis(intent, context_package) if context_package else deterministic_analysis(intent, query_result)
    model_invocation = state.get("model_invocation")
    if model_invocation is None:
        return {"analysis": deterministic}

    attempts = state.get("analysis_validation_attempts", 0) + 1
    try:
        model_analysis = parse_json_object(
            invoke_model(
                build_analysis_prompt(intent, query_result, context_package),
                "Return only valid JSON for the requested health-data analysis.",
                model_invocation,
            )
        )
    except Exception:
        model_analysis = None

    if isinstance(model_analysis, dict) and isinstance(model_analysis.get("summary"), str):
        return {
            "analysis": normalize_analysis(model_analysis, deterministic),
            "analysis_validation_attempts": attempts,
        }
    return {"analysis": deterministic, "analysis_validation_attempts": attempts}


def decide_output_plan_node(state: HealthDataQueryState) -> HealthDataQueryState:
    analysis = state.get("analysis", {})
    chart_candidates = analysis.get("chartCandidates", [])
    include_chart = bool(chart_candidates) and not state.get("empty_result")
    intent = state.get("intent", {})
    include_report = intent.get("kind") in {"health_report", "health_plan"} or include_chart
    return {
        "output_plan": {
            "include_text": True,
            "include_report": include_report,
            "include_chart": include_chart,
            "result_types": [
                item
                for item, enabled in [
                    ("text", True),
                    ("report", include_report),
                    ("chart", include_chart),
                ]
                if enabled
            ],
        },
        "trace": {
            **state.get("trace", {}),
            "selected_result_types": [
                item
                for item, enabled in [
                    ("text", True),
                    ("report", include_report),
                    ("chart", include_chart),
                ]
                if enabled
            ],
        },
    }


def generate_report_node(state: HealthDataQueryState) -> HealthDataQueryState:
    generated_at = datetime.now(timezone.utc)
    analysis = state.get("analysis", {})
    intent = state.get("intent", {})
    category = analysis.get("freshnessCategory", intent.get("freshness_category", "short_term"))
    expires_at, default_reason = report_expiration_for_category(category, generated_at)
    reason = freshness_reason_for_result(
        category,
        default_reason,
        intent,
        state.get("query_result", {}),
        state.get("context_package", {}),
    )
    intent_kind = intent.get("kind", "health_report")
    source_summary = state.get("query_result", {}).get(
        "sourceSummary",
        "Based on the current assistant request and available health context.",
    )
    reply = reply_for_analysis(analysis, state.get("empty_result", False))
    report_payload = {
        "type": "report",
        "format": "markdown",
        "title": _title_for_intent_kind(intent_kind),
        "content": build_report_content(analysis, source_summary, reason, intent_kind),
        "generatedAt": generated_at.isoformat().replace("+00:00", "Z"),
        "expiresAt": expires_at.isoformat().replace("+00:00", "Z"),
        "freshnessReason": reason,
        "sourceSummary": source_summary,
    }
    text_payload = {"type": "text", "content": reply}
    chart_payload = build_chart_payload(state)
    result: HealthDataQueryState = {
        "text_payload": text_payload,
        "report_payload": report_payload,
    }
    if chart_payload is not None:
        result["chart_payload"] = chart_payload
    return result


def validate_output_node(state: HealthDataQueryState) -> HealthDataQueryState:
    attempts = state.get("output_validation_attempts", 0) + 1
    payloads = [state.get("text_payload"), state.get("report_payload"), state.get("chart_payload")]
    results = []
    errors: list[str] = []
    for payload in payloads:
        if not isinstance(payload, dict):
            continue
        valid, payload_errors, normalized = validate_assistant_result_payload(payload)
        if not valid or normalized is None:
            if payload.get("type") == "chart":
                continue
            errors.extend(payload_errors)
            continue
        if normalized["type"] == "text":
            results.append(AssistantTextResult(**normalized))
        elif normalized["type"] == "report":
            results.append(AssistantReportResult(**normalized))
        elif normalized["type"] == "chart":
            results.append(AssistantChartResult(**normalized))

    if errors or not results:
        return {
            "output_valid": False,
            "output_validation_attempts": attempts,
            "output_errors": errors or ["No valid assistant results were generated."],
            "trace": {
                **state.get("trace", {}),
                "output_validation_attempts": attempts,
                "fallback_stage": "validate_output",
            },
        }

    reply = next((item.content for item in results if isinstance(item, AssistantTextResult)), "")
    return {
        "output_valid": True,
        "output_validation_attempts": attempts,
        "response": AssistantChatResponse(reply=reply, results=results),
        "trace": {
            **state.get("trace", {}),
            "output_validation_attempts": attempts,
        },
    }


def route_output_validation(
    state: HealthDataQueryState,
) -> Literal["__end__", "revise_report", "fallback_response"]:
    if state.get("output_valid"):
        return END
    if state.get("output_validation_attempts", 0) < MAX_OUTPUT_VALIDATION_ATTEMPTS:
        return "revise_report"
    return "fallback_response"


def revise_report_node(state: HealthDataQueryState) -> HealthDataQueryState:
    payload = dict(state.get("report_payload", {}))
    payload.setdefault("type", "report")
    payload.setdefault("format", "markdown")
    payload.setdefault("freshnessReason", "This report may change when new health data is available.")
    payload.setdefault("content", "## Summary\nThe assistant could not validate the first report draft.")
    return {"report_payload": payload}


def fallback_response_node(state: HealthDataQueryState) -> HealthDataQueryState:
    intent = state.get("intent", {})
    if intent.get("needs_clarification"):
        reply = str(intent.get("clarification", "Which health metric or time range should I analyze?"))
    else:
        reply = "I could not generate a validated health report from the available information."
    return {
        "response": compose_text_response(reply),
        "trace": {
            **state.get("trace", {}),
            "fallback_reason": state.get("query_error") or state.get("sigma_errors") or state.get("output_errors"),
        },
    }


def analyse_message_intent(message: str) -> dict[str, Any]:
    lowered = message.lower()
    metric_key = classify_metric_key(message)
    has_report = any(term in lowered for term in REPORT_TERMS)
    has_health_data = any(term in lowered for term in HEALTH_DATA_TERMS)
    has_workout_history = any(term in lowered for term in WORKOUT_HISTORY_TERMS)
    has_planning = any(term in lowered for term in PLANNING_ACTION_TERMS)
    has_advice = any(term in lowered for term in PLANNING_ADVICE_TERMS)
    freshness = classify_report_freshness(message)

    if metric_key is not None:
        metric = metric_for_key(metric_key)
        return {
            "kind": "health_plan" if has_planning else "health_report",
            "metric": metric_key,
            "target_metrics": [metric_key],
            "candidate_tables": ["wearable_vitals"],
            "time_range": "recent",
            "output_needs": ["text", "report", "chart"],
            "freshness_category": freshness,
            "needs_profile": True,
            "requires_query": True,
            "needs_clarification": False,
            "confidence": 0.96,
            "reason": f"supported metric: {metric['field'] if metric else metric_key}",
        }
    if has_planning or (has_advice and has_health_data):
        return {
            "kind": "health_plan",
            "metric": "workout_history" if has_workout_history else "heart_rate",
            "target_metrics": (
                ["workout_type", "duration_seconds", "distance_meters", "average_heart_rate_bpm"]
                if has_workout_history
                else ["heart_rate", "steps", "calories", "sleep"]
            ),
            "candidate_tables": ["wearable_vitals", "wearable_workouts"],
            "time_range": "recent",
            "output_needs": ["text", "report"],
            "freshness_category": freshness,
            "needs_profile": True,
            "requires_query": True,
            "needs_clarification": False,
            "confidence": 0.94,
            "reason": "personalized health planning or advice",
        }
    if has_workout_history:
        return {
            "kind": "health_report",
            "metric": "workout_history",
            "target_metrics": ["workout_type", "duration_seconds", "distance_meters", "average_heart_rate_bpm"],
            "candidate_tables": ["wearable_workouts"],
            "time_range": "recent",
            "output_needs": ["text", "report"],
            "freshness_category": freshness,
            "needs_profile": True,
            "requires_query": True,
            "needs_clarification": False,
            "confidence": 0.91,
            "reason": "workout-history analysis request",
        }
    if has_report or has_health_data:
        return {
            "kind": "health_report",
            "metric": "heart_rate",
            "target_metrics": ["heart_rate", "steps", "calories", "sleep"],
            "candidate_tables": ["wearable_vitals"],
            "time_range": "recent",
            "output_needs": ["text", "report"],
            "freshness_category": freshness,
            "needs_profile": True,
            "requires_query": True,
            "needs_clarification": False,
            "confidence": 0.88 if has_health_data else 0.82,
            "reason": "health-data analysis request",
        }
    if any(term in lowered for term in ["health", "wellness", "data"]):
        return {
            "kind": "clarification",
            "requires_query": False,
            "needs_clarification": True,
            "clarification": "Which health metric or time range should I analyze?",
            "confidence": 0.4,
            "reason": "ambiguous health-data request",
        }
    return {"kind": "general", "requires_query": False, "confidence": 0.0, "reason": "not health data"}


def model_backed_intent_analysis(
    message: str,
    model_invocation: ModelInvocationSettings,
) -> dict[str, Any] | None:
    try:
        parsed = parse_json_object(
            invoke_model(
                "\n".join(
                    [
                        "Classify this assistant message for a health-data query workflow.",
                        "Return JSON with kind, metric, target_metrics, candidate_tables, output_needs, freshness_category, requires_query, needs_clarification, confidence, reason.",
                        "Choose known patient-scoped health tables such as wearable_vitals or wearable_workouts when relevant.",
                        f"Message: {message}",
                    ]
                ),
                "Return only valid JSON.",
                model_invocation,
            )
        )
    except Exception:
        return None
    if not isinstance(parsed, dict):
        return None
    confidence = parsed.get("confidence")
    if not isinstance(confidence, (int, float)) or isinstance(confidence, bool):
        return None
    return {
        "kind": str(parsed.get("kind") or "health_report"),
        "metric": parsed.get("metric") if isinstance(parsed.get("metric"), str) else "heart_rate",
        "target_metrics": parsed.get("target_metrics") if isinstance(parsed.get("target_metrics"), list) else ["heart_rate"],
        "candidate_tables": parsed.get("candidate_tables") if isinstance(parsed.get("candidate_tables"), list) else ["wearable_vitals"],
        "time_range": str(parsed.get("time_range") or "recent"),
        "output_needs": parsed.get("output_needs") if isinstance(parsed.get("output_needs"), list) else ["text", "report"],
        "freshness_category": str(parsed.get("freshness_category") or "short_term"),
        "needs_profile": True,
        "requires_query": bool(parsed.get("requires_query", True)),
        "needs_clarification": bool(parsed.get("needs_clarification", False)),
        "clarification": str(parsed.get("clarification") or "Which health metric or time range should I analyze?"),
        "confidence": float(confidence),
        "reason": str(parsed.get("reason") or "model-backed intent analysis"),
    }


def build_context_plan(state: HealthDataQueryState) -> dict[str, Any]:
    intent = state.get("intent", {})
    model_invocation = state.get("model_invocation")
    if is_forced_training_readiness_intent(intent, state.get("message", "")):
        return deterministic_multi_table_context_plan(intent, FORCED_TRAINING_CONTEXT_TABLES)
    if intent.get("kind") == "health_plan":
        tables = [
            "wearable_vitals",
            "wearable_workouts",
            "vitals_history",
            "lab_tests",
            "bloodtests",
            "medical_history",
            "diagnosis",
        ]
        if _mentions_medication_or_bp(state.get("message", "")):
            tables.extend(["prescription_form", "prescription", "requisition_form"])
        return deterministic_multi_table_context_plan(intent, tables)
    if intent.get("metric") == "workout_history":
        return deterministic_multi_table_context_plan(intent, ["wearable_workouts", "wearable_vitals"])
    if _mentions_medication_or_bp(state.get("message", "")):
        return deterministic_multi_table_context_plan(
            intent,
            [
                "vitals_history",
                "wearable_vitals",
                "lab_tests",
                "bloodtests",
                "medical_history",
                "diagnosis",
                "prescription_form",
            ],
        )
    if model_invocation is not None:
        planned = build_model_backed_context_plan(state, model_invocation)
        if planned is not None:
            return planned
    return {
        "queries": [
            {
                "query_id": "primary_metric",
                "purpose": "single metric health-data query",
                "required": True,
                "domain": "health_metric",
                "sigma": build_sigma_query(state),
            }
        ]
    }


def deterministic_multi_table_context_plan(intent: dict[str, Any], tables: list[str]) -> dict[str, Any]:
    entries = []
    for table in _dedupe_tables(tables):
        defaults = HEALTH_CONTEXT_TABLE_DEFAULTS.get(table)
        if defaults is None:
            continue
        entries.append(
            {
                "query_id": table,
                "purpose": defaults["purpose"],
                "required": False,
                "domain": defaults["domain"],
                "sigma": deterministic_table_sigma(table, intent),
            }
        )
    return {"queries": entries}


def deterministic_table_sigma(table: str, intent: dict[str, Any]) -> dict[str, Any]:
    defaults = HEALTH_CONTEXT_TABLE_DEFAULTS[table]
    order_field = defaults["order_field"]
    return {
        "title": f"Recent {table}",
        "logsource": {"service": table},
        "detection": {
            "selection": {"patient_id": "__CURRENT_PATIENT__"},
            "condition": "selection",
        },
        "fields": defaults["fields"],
        "order_by": [{"field": order_field, "direction": "desc"}],
        "limit": defaults["limit"],
    }


def build_model_backed_context_plan(
    state: HealthDataQueryState,
    model_invocation: ModelInvocationSettings,
) -> dict[str, Any] | None:
    prompt = "\n".join(
        [
            "Create a bounded multi-query context plan for this patient health-data request.",
            "Return JSON with queries: [{query_id, purpose, required, domain, sigma}].",
            "Each sigma must use known patient-scoped health tables and fields only. Do not return SQL.",
            f"Maximum queries: {len(HEALTH_CONTEXT_TABLE_DEFAULTS)}",
            f"Request: {state.get('message', '')}",
            f"Schema context: {json.dumps(state.get('context', {}).get('schema_context', []))}",
            f"Previous validation errors: {state.get('sigma_errors', [])}",
        ]
    )
    try:
        parsed = parse_json_object(
            invoke_model(prompt, "Return only a multi-query context plan JSON object.", model_invocation)
        )
    except Exception:
        return None
    if not isinstance(parsed, dict) or not isinstance(parsed.get("queries"), list):
        return None
    allowed_tables = set(HEALTH_CONTEXT_TABLE_DEFAULTS)
    clean_entries = []
    for entry in parsed["queries"]:
        if not isinstance(entry, dict) or not isinstance(entry.get("sigma"), dict):
            continue
        table = entry["sigma"].get("logsource", {}).get("service")
        if table not in allowed_tables:
            continue
        clean_entries.append(
            {
                "query_id": str(entry.get("query_id") or table),
                "purpose": str(entry.get("purpose") or HEALTH_CONTEXT_TABLE_DEFAULTS[table]["purpose"]),
                "required": bool(entry.get("required", False)),
                "domain": str(entry.get("domain") or HEALTH_CONTEXT_TABLE_DEFAULTS[table]["domain"]),
                "sigma": entry["sigma"],
            }
        )
    return {"queries": clean_entries} if clean_entries else None


def is_forced_training_readiness_intent(intent: dict[str, Any], message: str) -> bool:
    lowered = message.lower()
    if intent.get("kind") == "health_plan":
        return True
    return any(term in lowered for term in TRAINING_READINESS_TERMS)


def _mentions_medication_or_bp(message: str) -> bool:
    lowered = message.lower()
    return any(
        term in lowered
        for term in [
            "blood pressure",
            "bp",
            "hypertension",
            "medication",
            "medicine",
            "prescription",
            "药",
            "血压",
        ]
    )


def _dedupe_tables(tables: list[str]) -> list[str]:
    result = []
    for table in tables:
        if table not in result:
            result.append(table)
    return result


def build_sigma_query(state: HealthDataQueryState) -> dict[str, Any]:
    intent = state.get("intent", {})
    if intent.get("metric") == "workout_history":
        return deterministic_workout_sigma(intent)
    metric = metric_for_key(intent.get("metric"))
    if metric is not None:
        return deterministic_metric_sigma(metric, intent)
    model_invocation = state.get("model_invocation")
    if model_invocation is not None:
        planned = build_model_backed_sigma(state, model_invocation)
        if planned is not None:
            return planned
    return deterministic_metric_sigma(METRIC_CATALOG["heart_rate"], intent)


def deterministic_metric_sigma(metric: dict[str, Any], intent: dict[str, Any]) -> dict[str, Any]:
    fields = ["timestamp", metric["field"]]
    if intent.get("kind") == "health_plan":
        fields = ["timestamp", "heart_rate", "steps", "calories", "sleep"]
    return {
        "title": f"Recent {metric['label']}",
        "logsource": {"service": "wearable_vitals"},
        "detection": {
            "selection": {"patient_id": "__CURRENT_PATIENT__"},
            "condition": "selection",
        },
        "fields": fields,
        "order_by": [{"field": "timestamp", "direction": "desc"}],
        "limit": DEFAULT_QUERY_LIMIT,
    }


def deterministic_workout_sigma(intent: dict[str, Any]) -> dict[str, Any]:
    return {
        "title": "Recent workouts",
        "logsource": {"service": "wearable_workouts"},
        "detection": {
            "selection": {"patient_id": "__CURRENT_PATIENT__"},
            "condition": "selection",
        },
        "fields": [
            "workout_type",
            "start_time",
            "end_time",
            "duration_seconds",
            "distance_meters",
            "active_energy_kcal",
            "average_heart_rate_bpm",
            "max_heart_rate_bpm",
            "source_provider",
        ],
        "order_by": [{"field": "start_time", "direction": "desc"}],
        "limit": DEFAULT_QUERY_LIMIT,
    }


def build_model_backed_sigma(
    state: HealthDataQueryState,
    model_invocation: ModelInvocationSettings,
) -> dict[str, Any] | None:
    prompt = "\n".join(
        [
            "Create one Sigma JSON payload for this patient health-data request.",
            "Return only JSON. Do not return SQL.",
            f"Request: {state.get('message', '')}",
            f"Schema context: {json.dumps(state.get('context', {}).get('schema_context', []))}",
            f"Previous validation errors: {state.get('sigma_errors', [])}",
        ]
    )
    try:
        parsed = parse_json_object(
            invoke_model(prompt, "Return only a Sigma JSON object.", model_invocation)
        )
    except Exception:
        return None
    return parsed if isinstance(parsed, dict) else None


def build_schema_planning_context() -> list[dict[str, Any]]:
    try:
        inventory = load_schema_inventory()
    except Exception:
        return []
    allowlist = {
        "wearable_vitals",
        "wearable_workouts",
        "wearable_workout_segments",
        "vitals_history",
        "lab_tests",
        "bloodtests",
        "requisition_form",
        "medical_history",
        "diagnosis",
        "prescription_form",
        "prescription",
        "patient_feedback",
        "heart_disease_analysis",
        "diabetes_analysis",
        "stroke_prediction",
        "ai_diagnostics",
        "ecg",
    }
    context = []
    for table in inventory.get("tables", []):
        if not isinstance(table, dict) or table.get("name") not in allowlist:
            continue
        attributes = [item for item in table.get("attributes", []) if isinstance(item, str)]
        context.append(
            {
                "name": table.get("name"),
                "primaryKeys": table.get("primaryKeys", []),
                "attributes": attributes,
                "patientScopeFields": [
                    field for field in ("patient_id", "user_id") if field in attributes
                ],
            }
        )
    return context


def build_context_package(
    state: HealthDataQueryState,
    query_results: list[dict[str, Any]],
    missing_context: list[dict[str, Any]],
) -> dict[str, Any]:
    generated_at = datetime.now(timezone.utc)
    rows_by_table: dict[str, list[dict[str, Any]]] = {}
    sources = []
    row_counts: dict[str, int] = {}
    for result in query_results:
        table = str(result.get("table") or "unknown")
        rows = result.get("data", [])
        clean_rows = [row for row in rows if isinstance(row, dict)] if isinstance(rows, list) else []
        if table == "vitals_history":
            clean_rows = [_with_blood_pressure_fields(row) for row in clean_rows]
        rows_by_table.setdefault(table, []).extend(clean_rows[: DEFAULT_QUERY_LIMIT])
        row_counts[table] = row_counts.get(table, 0) + len(clean_rows)
        sources.append(
            {
                "queryId": result.get("queryId"),
                "table": table,
                "domain": result.get("domain"),
                "purpose": result.get("purpose"),
                "count": len(clean_rows),
                "fields": result.get("fields", []),
                "empty": not clean_rows,
            }
        )
    safety_hints = derive_training_safety_hints(rows_by_table)
    return {
        "generatedAt": generated_at.isoformat().replace("+00:00", "Z"),
        "currentTime": generated_at.isoformat().replace("+00:00", "Z"),
        "recentWindows": {
            "last3Hours": (generated_at - timedelta(hours=3)).isoformat().replace("+00:00", "Z"),
            "last1Day": (generated_at - timedelta(days=1)).isoformat().replace("+00:00", "Z"),
        },
        "sources": sources,
        "rowsByTable": rows_by_table,
        "rowCounts": row_counts,
        "missingContext": missing_context,
        "sourceSummaries": [
            f"{source['table']}: {source['count']} row(s) for {source.get('purpose') or 'health context'}"
            for source in sources
        ],
        "safetyHints": safety_hints,
    }


def derive_training_safety_hints(rows_by_table: dict[str, list[dict[str, Any]]]) -> list[dict[str, str]]:
    hints: list[dict[str, str]] = []
    wearable_rows = rows_by_table.get("wearable_vitals", [])
    sleep_values = [
        value
        for value in (_coerce_number(row.get("sleep")) for row in wearable_rows)
        if value is not None
    ]
    if sleep_values and min(sleep_values) < 4:
        lowest_sleep = min(sleep_values)
        hints.append(
            {
                "code": "low_sleep",
                "severity": "caution",
                "message": f"Recent sleep is {lowest_sleep:.1f} hours, below the 4-hour safety threshold.",
                "recommendation": "Choose rest, mobility, or very light activity instead of intensive training until sleep improves.",
            }
        )

    bp_rows = rows_by_table.get("vitals_history", [])
    high_bp_row = next((row for row in bp_rows if _row_has_high_blood_pressure(row)), None)
    if high_bp_row is not None:
        systolic, diastolic = _blood_pressure_values(high_bp_row)
        bp_value = (
            f"{systolic:.0f}/{diastolic:.0f} mmHg"
            if systolic is not None and diastolic is not None
            else str(high_bp_row.get("blood_pressure") or "elevated")
        )
        hints.append(
            {
                "code": "high_blood_pressure",
                "severity": "caution",
                "message": f"Recent blood pressure is {bp_value}, which is elevated for training-readiness screening.",
                "recommendation": "Avoid intensive training for now; prefer rest or light activity and re-check blood pressure.",
            }
        )

    feedback_rows = rows_by_table.get("patient_feedback", [])
    symptom_terms = ["pain", "dizzy", "dizziness", "shortness", "breath", "chest", "fatigue", "symptom", "疼", "晕", "胸"]
    symptom_row = next((
        row
        for row in feedback_rows
        if row.get("is_severe") is True
        or any(term in str(row.get("feedback", "")).lower() for term in symptom_terms)
    ), None)
    if symptom_row is not None:
        hints.append(
            {
                "code": "symptoms_present",
                "severity": "caution",
                "message": f"Patient feedback includes symptom evidence: {str(symptom_row.get('feedback') or 'symptoms reported')}.",
                "recommendation": "Do not intensify training while symptoms are present; consider rest and appropriate care if symptoms persist.",
            }
        )
    return hints


def deterministic_multi_table_context_analysis(
    intent: dict[str, Any],
    rows_by_table: dict[str, Any],
) -> dict[str, Any]:
    wearable_rows = _context_rows(rows_by_table, "wearable_vitals")
    vitals_rows = _context_rows(rows_by_table, "vitals_history")
    diagnosis_rows = _context_rows(rows_by_table, "diagnosis")
    history_rows = _context_rows(rows_by_table, "medical_history")
    prescription_rows = _context_rows(rows_by_table, "prescription_form")
    workout_rows = _context_rows(rows_by_table, "wearable_workouts")
    total_rows = sum(
        len(rows)
        for rows in (wearable_rows, vitals_rows, diagnosis_rows, history_rows, prescription_rows, workout_rows)
    )

    evidence: list[dict[str, str]] = [{"label": "Context rows reviewed", "value": str(total_rows)}]
    summary_parts: list[str] = []

    wearable_summary, wearable_evidence = _wearable_context_summary(wearable_rows)
    if wearable_summary:
        summary_parts.append(wearable_summary)
        evidence.extend(wearable_evidence)

    vitals_summary, vitals_evidence = _vitals_context_summary(vitals_rows)
    if vitals_summary:
        summary_parts.append(vitals_summary)
        evidence.extend(vitals_evidence)

    condition_labels = _condition_context_labels(diagnosis_rows, history_rows)
    if condition_labels:
        evidence.append({"label": "Relevant condition context", "value": "; ".join(condition_labels)})
        summary_parts.append(f"Clinical context includes {', '.join(condition_labels)}.")

    medication_labels = _medication_context_labels(prescription_rows)
    if medication_labels:
        evidence.append({"label": "Medication context", "value": "; ".join(medication_labels)})
        summary_parts.append(f"Medication context includes {', '.join(medication_labels)}.")

    symptom_notes = _symptom_notes(vitals_rows)
    if symptom_notes:
        evidence.append({"label": "Symptom notes", "value": "; ".join(symptom_notes[:2])})

    if workout_rows:
        evidence.extend(workout_evidence_for_rows(workout_rows))

    findings = _multi_table_findings(
        wearable_rows,
        vitals_rows,
        condition_labels,
        medication_labels,
        symptom_notes,
    )
    recommendations = _multi_table_recommendations(
        wearable_rows,
        vitals_rows,
        condition_labels,
        medication_labels,
        symptom_notes,
    )
    if not recommendations:
        recommendations = [
            "The available recent readings look limited but usable for a cautious wellness snapshot; refresh after the next sync for a stronger trend."
        ]

    summary = _multi_table_summary(
        wearable_rows,
        vitals_rows,
        condition_labels,
        medication_labels,
        symptom_notes,
    ) or (
        " ".join(summary_parts)
        if summary_parts
        else f"Found {total_rows} patient context row(s), but none contained chartable vitals or wearable values."
    )
    return {
        "summary": summary,
        "findings": findings,
        "evidence": evidence,
        "recommendations": recommendations,
        "limitations": [
            "This is based on the currently available rows only and is informational, not a diagnosis."
        ],
        "freshnessCategory": intent.get("freshness_category", "short_term"),
        "chartCandidates": [],
    }


def _multi_table_summary(
    wearable_rows: list[dict[str, Any]],
    vitals_rows: list[dict[str, Any]],
    condition_labels: list[str],
    medication_labels: list[str],
    symptom_notes: list[str],
) -> str | None:
    bp_values = _blood_pressure_pairs(vitals_rows)
    high_bp = any(systolic >= 140 or diastolic >= 90 for systolic, diastolic in bp_values)
    heart_rates = _numeric_values(wearable_rows, "heart_rate")
    clinical_heart_rates = _numeric_values(vitals_rows, "heart_rate")
    sleep_values = _numeric_values(wearable_rows, "sleep")
    steps_latest = _latest_numeric_value(wearable_rows, "steps", "timestamp")

    if high_bp:
        bp_text = _blood_pressure_range_text(bp_values)
        hr_text = (
            f"wearable heart rate averaged {sum(heart_rates) / len(heart_rates):.0f} bpm"
            if heart_rates
            else "heart-rate context is limited"
        )
        context_bits = []
        if condition_labels:
            context_bits.append(f"history includes {', '.join(condition_labels)}")
        if medication_labels:
            context_bits.append(f"active medication context includes {', '.join(medication_labels)}")
        if symptom_notes:
            context_bits.append("symptom notes mention headache or dizziness")
        context_text = f" {'; '.join(context_bits)}." if context_bits else ""
        return (
            f"Caution: recent readings show repeated elevated blood pressure ({bp_text}) and {hr_text}."
            f"{context_text} This is a conservative wellness signal to avoid hard training and re-check vitals."
        )

    if bp_values or heart_rates or sleep_values:
        parts = ["Short-term wellness picture looks stable"]
        if bp_values:
            parts.append(f"blood pressure stayed in a normal-looking range ({_blood_pressure_range_text(bp_values)})")
        if heart_rates:
            parts.append(f"wearable heart rate averaged {sum(heart_rates) / len(heart_rates):.0f} bpm")
        elif clinical_heart_rates:
            parts.append(f"clinical heart rate averaged {sum(clinical_heart_rates) / len(clinical_heart_rates):.0f} bpm")
        if sleep_values:
            parts.append(f"sleep was steady around {sum(sleep_values) / len(sleep_values):.1f} hours")
        if steps_latest is not None:
            parts.append(f"latest step count was {steps_latest:.0f} in this recent window")
        return "; ".join(parts) + ". No acute caution flag stands out from these rows."
    return None


def _multi_table_findings(
    wearable_rows: list[dict[str, Any]],
    vitals_rows: list[dict[str, Any]],
    condition_labels: list[str],
    medication_labels: list[str],
    symptom_notes: list[str],
) -> list[str]:
    findings: list[str] = []
    bp_values = _blood_pressure_pairs(vitals_rows)
    if bp_values:
        high_count = sum(1 for systolic, diastolic in bp_values if systolic >= 140 or diastolic >= 90)
        if high_count:
            findings.append(
                f"Cardiovascular: {high_count}/{len(bp_values)} blood-pressure readings were elevated, ranging {_blood_pressure_range_text(bp_values)}."
            )
        else:
            findings.append(
                f"Cardiovascular: blood pressure stayed in a normal-looking range ({_blood_pressure_range_text(bp_values)}), without an elevated reading in this window."
            )

    heart_rates = _numeric_values(wearable_rows, "heart_rate")
    if heart_rates:
        findings.append(
            f"Heart-rate trend: wearable heart rate averaged {sum(heart_rates) / len(heart_rates):.0f} bpm and ranged {min(heart_rates):.0f}-{max(heart_rates):.0f} bpm."
        )

    sleep_values = _numeric_values(wearable_rows, "sleep")
    if sleep_values:
        if min(sleep_values) < 4:
            findings.append(f"Recovery: sleep fell as low as {min(sleep_values):.1f} hours, which weakens training readiness.")
        elif min(sleep_values) < 6:
            findings.append(f"Recovery: sleep was below ideal at {min(sleep_values):.1f}-{max(sleep_values):.1f} hours, so recovery may be incomplete.")
        else:
            findings.append(f"Recovery: sleep was steady at {min(sleep_values):.1f}-{max(sleep_values):.1f} hours, which supports normal activity.")

    step_values = _numeric_values(wearable_rows, "steps")
    if step_values:
        findings.append(
            f"Activity load: steps increased from {step_values[0]:.0f} to {step_values[-1]:.0f} in the recent window, suggesting light-to-moderate movement rather than heavy exertion."
        )

    if condition_labels or medication_labels:
        context = []
        if condition_labels:
            context.append(f"conditions: {', '.join(condition_labels)}")
        if medication_labels:
            context.append(f"medications: {', '.join(medication_labels)}")
        findings.append("Clinical context: " + "; ".join(context) + ".")

    if symptom_notes:
        findings.append("Symptoms: recent notes include " + "; ".join(symptom_notes[:2]) + ".")
    return findings


def _context_rows(rows_by_table: dict[str, Any], table: str) -> list[dict[str, Any]]:
    rows = rows_by_table.get(table, [])
    return [row for row in rows if isinstance(row, dict)] if isinstance(rows, list) else []


def _wearable_context_summary(rows: list[dict[str, Any]]) -> tuple[str | None, list[dict[str, str]]]:
    if not rows:
        return None, []
    evidence: list[dict[str, str]] = [{"label": "Wearable readings", "value": str(len(rows))}]
    summary_bits: list[str] = []

    heart_rates = _numeric_values(rows, "heart_rate")
    if heart_rates:
        latest = _latest_numeric_value(rows, "heart_rate", "timestamp")
        evidence.append({"label": "Average heart rate", "value": f"{sum(heart_rates) / len(heart_rates):.0f} bpm"})
        if latest is not None:
            evidence.append({"label": "Latest heart rate", "value": f"{latest:.0f} bpm"})
        summary_bits.append(f"average heart rate {sum(heart_rates) / len(heart_rates):.0f} bpm")

    sleep_values = _numeric_values(rows, "sleep")
    if sleep_values:
        latest = _latest_numeric_value(rows, "sleep", "timestamp")
        evidence.append({"label": "Recent sleep range", "value": f"{min(sleep_values):.1f}-{max(sleep_values):.1f} h"})
        if latest is not None:
            evidence.append({"label": "Latest sleep", "value": f"{latest:.1f} h"})
        summary_bits.append(f"sleep around {sum(sleep_values) / len(sleep_values):.1f} h")

    steps_values = _numeric_values(rows, "steps")
    if steps_values:
        latest = _latest_numeric_value(rows, "steps", "timestamp")
        if latest is not None:
            evidence.append({"label": "Latest steps", "value": f"{latest:.0f}"})
        summary_bits.append(f"latest steps {latest:.0f}" if latest is not None else f"{len(steps_values)} step readings")

    if not summary_bits:
        return f"Reviewed {len(rows)} wearable row(s), but no numeric heart-rate, sleep, or step values were present.", evidence
    return f"Wearable context shows {', '.join(summary_bits)}.", evidence


def _vitals_context_summary(rows: list[dict[str, Any]]) -> tuple[str | None, list[dict[str, str]]]:
    if not rows:
        return None, []
    evidence: list[dict[str, str]] = [{"label": "Clinical vitals readings", "value": str(len(rows))}]
    summary_bits: list[str] = []

    bp_values = [
        (systolic, diastolic)
        for systolic, diastolic in (_blood_pressure_values(row) for row in rows)
        if systolic is not None and diastolic is not None
    ]
    if bp_values:
        latest_row = latest_row_for_field(rows, "recorded_on") or rows[0]
        latest_systolic, latest_diastolic = _blood_pressure_values(latest_row)
        max_systolic = max(value[0] for value in bp_values)
        max_diastolic = max(value[1] for value in bp_values)
        evidence.append({"label": "Highest blood pressure", "value": f"{max_systolic:.0f}/{max_diastolic:.0f} mmHg"})
        if latest_systolic is not None and latest_diastolic is not None:
            evidence.append({"label": "Latest blood pressure", "value": f"{latest_systolic:.0f}/{latest_diastolic:.0f} mmHg"})
            summary_bits.append(f"latest blood pressure {latest_systolic:.0f}/{latest_diastolic:.0f} mmHg")

    heart_rates = _numeric_values(rows, "heart_rate")
    if heart_rates:
        latest = _latest_numeric_value(rows, "heart_rate", "recorded_on")
        if latest is not None:
            evidence.append({"label": "Latest clinical heart rate", "value": f"{latest:.0f} bpm"})
        summary_bits.append(f"clinical heart rate average {sum(heart_rates) / len(heart_rates):.0f} bpm")

    if not summary_bits:
        return f"Reviewed {len(rows)} clinical vitals row(s), but no numeric blood-pressure or heart-rate values were present.", evidence
    return f"Clinical vitals show {', '.join(summary_bits)}.", evidence


def _multi_table_recommendations(
    wearable_rows: list[dict[str, Any]],
    vitals_rows: list[dict[str, Any]],
    condition_labels: list[str],
    medication_labels: list[str],
    symptom_notes: list[str],
) -> list[str]:
    recommendations: list[str] = []
    high_bp = next((row for row in vitals_rows if _row_has_high_blood_pressure(row)), None)
    if high_bp is not None:
        systolic, diastolic = _blood_pressure_values(high_bp)
        bp = f"{systolic:.0f}/{diastolic:.0f} mmHg" if systolic is not None and diastolic is not None else "elevated"
        recommendations.append(
            f"Treat the recent elevated blood pressure ({bp}) as a caution signal; avoid intensive training until it is rechecked and symptoms are considered."
        )

    sleep_values = _numeric_values(wearable_rows, "sleep")
    if sleep_values and min(sleep_values) < 4:
        recommendations.append(
            f"Recent sleep dropped to {min(sleep_values):.1f} hours, so choose rest or very light activity before any hard workout."
        )
    elif sleep_values:
        recommendations.append(
            f"Recent sleep is around {sum(sleep_values) / len(sleep_values):.1f} hours; use that recovery signal when deciding activity intensity."
        )

    if symptom_notes:
        recommendations.append(
            "Because symptom notes are present, keep the plan conservative and seek appropriate care if symptoms worsen or persist."
        )
    if medication_labels:
        recommendations.append(
            "Interpret vitals alongside the active medication context rather than judging the readings in isolation."
        )
    if condition_labels and not high_bp:
        recommendations.append(
            "Use the known condition history as background context and keep monitoring recent vitals for changes."
        )
    if not high_bp and not symptom_notes and (not sleep_values or min(sleep_values) >= 4):
        recommendations.append(
            "No obvious acute caution flag appears in this window; normal light-to-moderate activity looks reasonable if the patient feels well."
        )
    if not recommendations and (wearable_rows or vitals_rows):
        recommendations.append(
            "The available readings do not show an obvious acute caution flag; continue normal monitoring and refresh after the next wearable sync."
        )
    return recommendations


def _blood_pressure_pairs(rows: list[dict[str, Any]]) -> list[tuple[float, float]]:
    return [
        (systolic, diastolic)
        for systolic, diastolic in (_blood_pressure_values(row) for row in rows)
        if systolic is not None and diastolic is not None
    ]


def _blood_pressure_range_text(values: list[tuple[float, float]]) -> str:
    if not values:
        return "not available"
    systolic_values = [value[0] for value in values]
    diastolic_values = [value[1] for value in values]
    if min(systolic_values) == max(systolic_values) and min(diastolic_values) == max(diastolic_values):
        return f"{systolic_values[0]:.0f}/{diastolic_values[0]:.0f} mmHg"
    return (
        f"{min(systolic_values):.0f}-{max(systolic_values):.0f}/"
        f"{min(diastolic_values):.0f}-{max(diastolic_values):.0f} mmHg"
    )


def _condition_context_labels(
    diagnosis_rows: list[dict[str, Any]],
    history_rows: list[dict[str, Any]],
) -> list[str]:
    labels: list[str] = []
    for row in diagnosis_rows:
        label = row.get("diagnosis_description") or row.get("diagnosis_code")
        if label:
            labels.append(str(label))
    for row in history_rows:
        label = row.get("condition") or row.get("notes")
        if label:
            labels.append(str(label))
    return _dedupe_strings(labels)


def _medication_context_labels(rows: list[dict[str, Any]]) -> list[str]:
    labels = [
        str(row.get("medication_name") or row.get("drug_name") or row.get("notes"))
        for row in rows
        if row.get("medication_name") or row.get("drug_name") or row.get("notes")
    ]
    return _dedupe_strings(labels)


def _symptom_notes(rows: list[dict[str, Any]]) -> list[str]:
    notes = []
    for row in rows:
        note = str(row.get("notes") or "")
        if "symptom" in note.lower() or "dizz" in note.lower() or "fatigue" in note.lower():
            notes.append(note)
    return _dedupe_strings(notes)


def _numeric_values(rows: list[dict[str, Any]], field: str) -> list[float]:
    return [
        value
        for value in (_coerce_number(row.get(field)) for row in rows)
        if value is not None
    ]


def _latest_numeric_value(rows: list[dict[str, Any]], field: str, time_field: str) -> float | None:
    latest = latest_row_for_field(rows, time_field) or (rows[0] if rows else None)
    if latest is None:
        return None
    return _coerce_number(latest.get(field))


def _dedupe_strings(values: list[str]) -> list[str]:
    result = []
    seen = set()
    for value in values:
        normalized = value.strip()
        key = normalized.lower()
        if not normalized or key in seen:
            continue
        seen.add(key)
        result.append(normalized)
    return result


def deterministic_context_analysis(intent: dict[str, Any], context_package: dict[str, Any]) -> dict[str, Any]:
    rows_by_table = context_package.get("rowsByTable", {})
    if not isinstance(rows_by_table, dict):
        rows_by_table = {}
    metric = metric_for_key(intent.get("metric"))
    if metric is not None and rows_by_table.get("wearable_vitals"):
        base = deterministic_analysis(
            intent,
            {
                "data": rows_by_table["wearable_vitals"],
                "count": len(rows_by_table["wearable_vitals"]),
            },
        )
    elif rows_by_table.get("wearable_workouts"):
        base = deterministic_analysis(
            {**intent, "metric": "workout_history"},
            {
                "data": rows_by_table["wearable_workouts"],
                "count": len(rows_by_table["wearable_workouts"]),
            },
        )
    else:
        base = deterministic_multi_table_context_analysis(intent, rows_by_table)

    row_counts = context_package.get("rowCounts", {})
    missing_context = context_package.get("missingContext", [])
    safety_hints = context_package.get("safetyHints", [])
    evidence = list(base.get("evidence", []))
    evidence.extend(
        {"label": f"{table} rows", "value": str(count)}
        for table, count in row_counts.items()
    )
    limitations = list(base.get("limitations", []))
    if missing_context:
        limitations.append(
            "Some context sources were empty or unavailable: "
            + ", ".join(
                str(item.get("table") or item.get("queryId"))
                for item in missing_context
                if isinstance(item, dict)
            )
        )
    recommendations = list(base.get("recommendations", []))
    if safety_hints:
        recommendations = [
            str(item.get("recommendation") or item.get("message"))
            for item in safety_hints
            if isinstance(item, dict)
        ] + [
            item
            for item in recommendations
            if isinstance(item, str)
            and not item.lower().startswith("use the combined context cautiously")
        ]
        evidence.extend(
            {"label": f"Safety: {item.get('code')}", "value": str(item.get("message"))}
            for item in safety_hints
            if isinstance(item, dict)
        )
        limitations.append(
            "Training intensity was reduced because one or more readiness safety indicators were present."
        )
    chart_candidates = list(base.get("chartCandidates", []))
    chart_candidates.extend(context_chart_candidates(rows_by_table))

    return {
        **base,
        "evidence": evidence,
        "recommendations": recommendations,
        "limitations": limitations,
        "chartCandidates": _dedupe_chart_candidates(chart_candidates),
    }


def deterministic_analysis(intent: dict[str, Any], query_result: dict[str, Any]) -> dict[str, Any]:
    rows = query_result.get("data", [])
    metric = metric_for_key(intent.get("metric"))
    if metric is not None:
        metric_rows = [
            row
            for row in rows
            if isinstance(row, dict)
            and _coerce_number(row.get(metric["field"])) is not None
        ]
        values = [_coerce_number(row.get(metric["field"])) for row in metric_rows]
        values = [value for value in values if value is not None]
        summary = (
            f"Found {len(values)} recent {metric['label'].lower()} readings."
            if values
            else f"No chartable {metric['label'].lower()} readings were found."
        )
        evidence = []
        if values:
            latest_row = latest_row_for_field(metric_rows, "timestamp") or metric_rows[0]
            latest_value = _coerce_number(latest_row.get(metric["field"])) or values[0]
            evidence = [
                {
                    "label": f"Average {metric['label'].lower()}",
                    "value": f"{sum(values) / len(values):.1f} {metric['unit']}",
                },
                {
                    "label": f"Latest {metric['label'].lower()}",
                    "value": f"{latest_value:.1f} {metric['unit']}",
                },
            ]
        return {
            "summary": summary,
            "evidence": evidence,
            "recommendations": metric_recommendations_for_rows(
                str(intent.get("metric")),
                metric,
                metric_rows,
            ),
            "limitations": ["This is an informational summary, not a diagnosis."],
            "freshnessCategory": intent.get("freshness_category", "short_term"),
            "chartCandidates": [
                {
                    "title": f"Recent {metric['label']}",
                    "displayType": metric["display_type"],
                    "xField": "timestamp",
                    "yField": metric["field"],
                    "label": metric["label"],
                    "unit": metric["unit"],
                }
            ] if values else [],
        }
    return {
        "summary": workout_summary_for_rows(rows)
        if intent.get("metric") == "workout_history"
        else f"Found {len(rows) if isinstance(rows, list) else 0} recent wearable records for this request.",
        "evidence": workout_evidence_for_rows(rows)
        if intent.get("metric") == "workout_history"
        else [{"label": "Rows reviewed", "value": str(len(rows) if isinstance(rows, list) else 0)}],
        "recommendations": workout_recommendations_for_rows(rows)
        if intent.get("metric") == "workout_history"
        else [
            "Use recent wearable trends as context and adjust plans conservatively when sleep, heart rate, or activity signals change."
        ],
        "limitations": ["This guidance is informational and should not replace clinical advice."],
        "freshnessCategory": intent.get("freshness_category", "short_term"),
        "chartCandidates": workout_chart_candidates_for_rows(rows)
        if intent.get("metric") == "workout_history"
        else [],
    }


def normalize_analysis(candidate: dict[str, Any], fallback: dict[str, Any]) -> dict[str, Any]:
    normalized = dict(fallback)
    for key in ("summary", "freshnessCategory"):
        if isinstance(candidate.get(key), str) and candidate[key].strip():
            normalized[key] = candidate[key].strip()
    for key in ("findings", "evidence", "recommendations", "limitations"):
        if isinstance(candidate.get(key), list) and candidate[key]:
            normalized[key] = candidate[key]
    if isinstance(candidate.get("chartCandidates"), list) and candidate["chartCandidates"]:
        normalized["chartCandidates"] = candidate["chartCandidates"]
    return normalized


def build_analysis_prompt(
    intent: dict[str, Any],
    query_result: dict[str, Any],
    context_package: dict[str, Any] | None = None,
) -> str:
    rows = query_result.get("data", [])
    sample_rows = rows[:20] if isinstance(rows, list) else []
    context_package = context_package or {}
    prompt_lines = [
        "Analyze these validated patient health-data rows.",
        "Return JSON with summary, findings, evidence, recommendations, limitations, freshnessCategory, chartCandidates.",
        "Make summary a clinical-style wellness interpretation, not a row-count recap.",
        "Use findings for 3-6 concise bullets covering cardiovascular status, recovery/sleep, activity load, symptoms, medication/history context, and risk/readiness.",
        f"Intent: {json.dumps(intent)}",
    ]
    if context_package:
        prompt_lines.extend(
            [
                f"Current backend time: {context_package.get('currentTime')}",
                f"Recent windows: {json.dumps(context_package.get('recentWindows', {}))}",
                "For training-readiness, tomorrow-training, or intensive-training requests, synthesize current time, recent 3-hour data, recent one-day data, medical history, medication context, symptom or feedback context, vitals, and workout history before recommending intensity.",
                "If sleep is under 4 hours, blood pressure is high, or symptom evidence exists, make training advice conservative and cite the evidence.",
                f"Context sources: {json.dumps(context_package.get('sources', []), default=str)}",
                f"Missing context: {json.dumps(context_package.get('missingContext', []), default=str)}",
                f"Safety hints: {json.dumps(context_package.get('safetyHints', []), default=str)}",
                f"Rows by table: {json.dumps(_sample_rows_by_table(context_package), default=str)}",
            ]
        )
    prompt_lines.append(f"Rows: {json.dumps(sample_rows, default=str)}")
    return "\n".join(
        prompt_lines
    )


def workout_summary_for_rows(rows: Any) -> str:
    if not isinstance(rows, list) or not rows:
        return "No matching workout history was found for this request."
    latest = rows[0] if isinstance(rows[0], dict) else {}
    workout_type = latest.get("workout_type") or "workout"
    duration = latest.get("duration_seconds")
    distance = latest.get("distance_meters")
    details = []
    if duration is not None:
        details.append(f"{round(float(duration) / 60)} min")
    if distance is not None:
        details.append(f"{float(distance) / 1000:.1f} km")
    detail_text = f" ({', '.join(details)})" if details else ""
    return f"Found {len(rows)} recent workout record(s); latest was {workout_type}{detail_text}."


def workout_evidence_for_rows(rows: Any) -> list[dict[str, str]]:
    if not isinstance(rows, list) or not rows:
        return [{"label": "Workout rows reviewed", "value": "0"}]
    evidence = [{"label": "Workout rows reviewed", "value": str(len(rows))}]
    latest = rows[0] if isinstance(rows[0], dict) else {}
    if latest:
        if latest.get("start_time") is not None:
            evidence.append({"label": "Latest workout start", "value": str(latest["start_time"])})
        if latest.get("workout_type") is not None:
            evidence.append({"label": "Latest workout type", "value": str(latest["workout_type"])})
        if latest.get("distance_meters") is not None:
            evidence.append(
                {
                    "label": "Latest workout distance",
                    "value": f"{float(latest['distance_meters']) / 1000:.1f} km",
                }
            )
    return evidence


def metric_recommendations_for_rows(
    metric_key: str,
    metric: dict[str, Any],
    rows: list[dict[str, Any]],
) -> list[str]:
    values = [_coerce_number(row.get(metric["field"])) for row in rows]
    values = [value for value in values if value is not None]
    if not values:
        return [f"Sync more {metric['label'].lower()} readings before relying on this trend."]

    latest_row = latest_row_for_field(rows, "timestamp") or rows[0]
    latest = _coerce_number(latest_row.get(metric["field"])) or values[0]
    average = sum(values) / len(values)
    recommendations = [
        (
            f"Compare the latest {metric['label'].lower()} value "
            f"({latest:.0f} {metric['unit']}) with your recent average "
            f"({average:.0f} {metric['unit']}) before changing your routine."
        ),
    ]
    if metric_key == "heart_rate":
        recommendations.append(
            "Interpret heart-rate changes alongside activity, sleep, caffeine, stress, and symptoms from the same period."
        )
    elif metric_key == "sleep":
        recommendations.append(
            "Look for repeated sleep patterns across several nights before making a major schedule change."
        )
    else:
        recommendations.append(
            "Use this as a recent trend check and refresh it after the next wearable sync."
        )
    return recommendations


def workout_recommendations_for_rows(rows: Any) -> list[str]:
    if not isinstance(rows, list) or not rows:
        return ["Sync recent workouts before relying on a personalized training recommendation."]
    latest = rows[0] if isinstance(rows[0], dict) else {}
    workout_type = str(latest.get("workout_type") or "workout").lower()
    distance = _coerce_number(latest.get("distance_meters"))
    duration = _coerce_number(latest.get("duration_seconds"))
    recommendations = []
    if "run" in workout_type:
        if distance is not None:
            recommendations.append(
                (
                    "Base the next run on your latest logged distance "
                    f"({distance / 1000:.1f} km), keeping the first increase conservative."
                )
            )
        elif duration is not None:
            recommendations.append(
                (
                    "Base the next run on your latest logged duration "
                    f"({round(duration / 60)} min), adding time gradually."
                )
            )
        else:
            recommendations.append(
                "Use the recent running log as a starting point and keep the next session easy if you are returning after a break."
            )
    else:
        recommendations.append(
            "Use the latest workout type and effort as context before adding a harder session."
        )
    recommendations.append(
        "Adjust the plan downward if sleep, soreness, symptoms, or unusually high workout heart rate suggest recovery is incomplete."
    )
    return recommendations


def workout_chart_candidates_for_rows(rows: Any) -> list[dict[str, Any]]:
    if not isinstance(rows, list) or not rows:
        return []
    if any(
        isinstance(row, dict) and _coerce_number(row.get("distance_meters")) is not None
        for row in rows
    ):
        return [
            {
                "title": "Recent Workout Distance",
                "displayType": "bar",
                "xField": "start_time",
                "yField": "distance_meters",
                "label": "Distance",
                "unit": "m",
            }
        ]
    if any(
        isinstance(row, dict) and _coerce_number(row.get("duration_seconds")) is not None
        for row in rows
    ):
        return [
            {
                "title": "Recent Workout Duration",
                "displayType": "bar",
                "xField": "start_time",
                "yField": "duration_seconds",
                "label": "Duration",
                "unit": "sec",
            }
        ]
    return []


def context_chart_candidates(rows_by_table: dict[str, Any]) -> list[dict[str, Any]]:
    candidates: list[dict[str, Any]] = []
    vitals_history = rows_by_table.get("vitals_history", [])
    if isinstance(vitals_history, list) and any(
        isinstance(row, dict)
        and row.get("recorded_on") is not None
        and _coerce_number(row.get("systolic_bp")) is not None
        for row in vitals_history
    ):
        candidates.append(
            {
                "title": "Recent Blood Pressure",
                "displayType": "line",
                "xField": "recorded_on",
                "yField": "systolic_bp",
                "label": "Systolic BP",
                "unit": "mmHg",
            }
        )
    wearable_vitals = rows_by_table.get("wearable_vitals", [])
    if isinstance(wearable_vitals, list) and any(
        isinstance(row, dict)
        and row.get("timestamp") is not None
        and _coerce_number(row.get("heart_rate")) is not None
        for row in wearable_vitals
    ):
        candidates.append(
            {
                "title": "Recent Heart Rate",
                "displayType": "line",
                "xField": "timestamp",
                "yField": "heart_rate",
                "label": "Heart Rate",
                "unit": "bpm",
            }
        )
    return candidates


def _dedupe_chart_candidates(candidates: list[dict[str, Any]]) -> list[dict[str, Any]]:
    result = []
    seen: set[tuple[str, str]] = set()
    for candidate in candidates:
        if not isinstance(candidate, dict):
            continue
        key = (str(candidate.get("xField")), str(candidate.get("yField")))
        if key in seen:
            continue
        seen.add(key)
        result.append(candidate)
    return result


def build_report_content(
    analysis: dict[str, Any],
    source_summary: str,
    freshness_reason: str,
    intent_kind: str,
) -> str:
    recommendations = analysis.get("recommendations", [])
    findings = analysis.get("findings", [])
    limitations = analysis.get("limitations", [])
    evidence = analysis.get("evidence", [])
    key_evidence = [
        item for item in evidence if isinstance(item, dict) and not _is_context_coverage_evidence(item)
    ]
    context_coverage = _context_coverage_lines(evidence, source_summary)
    limitation_lines = [item for item in limitations if isinstance(item, str)]
    return "\n".join(
        [
            "## Answer",
            str(analysis.get("summary", "No analysis was available.")),
            "",
            "## Analysis",
            *[f"- {item}" for item in findings if isinstance(item, str)],
            "",
            "## Recommended action",
            *[f"- {item}" for item in recommendations if isinstance(item, str)],
            "",
            "## Why",
            *[_format_evidence_line(item) for item in key_evidence],
            "",
            "## Context checked",
            *context_coverage,
            "",
            "## Limitations",
            *[f"- {item}" for item in limitation_lines],
            "",
            "## Freshness",
            freshness_reason,
            "",
            "## Next step",
            _next_step_for_analysis(intent_kind, analysis),
        ]
    )


def _is_context_coverage_evidence(item: dict[str, Any]) -> bool:
    label = str(item.get("label", "")).lower()
    return label.endswith(" rows") or label in {"rows reviewed", "context rows reviewed", "workout rows reviewed"}


def _format_evidence_line(item: dict[str, Any]) -> str:
    label = _humanize_context_label(str(item.get("label") or "Evidence"))
    value = str(item.get("value") or "").strip()
    return f"- **{label}:** {value}" if value else f"- **{label}**"


def _context_coverage_lines(evidence: Any, source_summary: str) -> list[str]:
    lines: list[str] = []
    if isinstance(evidence, list):
        for item in evidence:
            if not isinstance(item, dict) or not _is_context_coverage_evidence(item):
                continue
            label = str(item.get("label") or "")
            value = str(item.get("value") or "0")
            lines.append(f"- {_humanize_context_label(label)}: {value} row(s)")
    if not lines and source_summary:
        summaries = source_summary
        prefixes = [
            "Based on validated patient-scoped context sources: ",
            "No validated patient context rows were available. Missing context: ",
        ]
        for prefix in prefixes:
            summaries = summaries.replace(prefix, "")
        for part in summaries.split(";"):
            clean = part.strip()
            if clean:
                lines.append(f"- {_humanize_context_label(clean)}")
    return lines or ["- No patient context sources returned usable rows."]


def _humanize_context_label(label: str) -> str:
    replacements = {
        "wearable_vitals": "Wearable vitals",
        "vitals_history": "Clinical vitals",
        "lab_tests": "Lab tests",
        "bloodtests": "Blood tests",
        "requisition_form": "Lab requisitions",
        "medical_history": "Medical history",
        "diagnosis": "Diagnoses",
        "prescription_form": "Prescription forms",
        "prescription": "Prescriptions",
        "patient_feedback": "Symptoms and feedback",
        "wearable_workouts": "Workout history",
        "heart_disease_analysis": "Heart risk analysis",
        "diabetes_analysis": "Diabetes risk analysis",
        "stroke_prediction": "Stroke risk analysis",
        "ai_diagnostics": "AI diagnostics",
        "ecg": "ECG results",
        "Safety: low_sleep": "Low sleep safety signal",
        "Safety: high_blood_pressure": "High blood pressure safety signal",
        "Safety: symptoms_present": "Symptom safety signal",
    }
    result = label
    for raw, human in replacements.items():
        result = result.replace(raw, human)
    result = result.replace("_", " ")
    if result.endswith(" rows"):
        result = result[:-5]
    return result[:1].upper() + result[1:] if result else result


def build_chart_payload(state: HealthDataQueryState) -> dict[str, Any] | None:
    analysis = state.get("analysis", {})
    candidates = analysis.get("chartCandidates", [])
    if not isinstance(candidates, list) or not candidates:
        return None
    candidate = candidates[0]
    if not isinstance(candidate, dict):
        return None
    display_type = candidate.get("displayType")
    if display_type not in {"line", "bar"}:
        return None
    x_field = candidate.get("xField")
    y_field = candidate.get("yField")
    if not isinstance(x_field, str) or not isinstance(y_field, str):
        return None
    rows = chart_rows_for_candidate(state, x_field, y_field)
    if not rows:
        return None
    points = []
    for row in sorted(rows, key=lambda item: str(item.get(x_field, "")) if isinstance(item, dict) else ""):
        if not isinstance(row, dict):
            continue
        y_value = _coerce_number(row.get(y_field))
        x_value = row.get(x_field)
        if y_value is None or x_value is None:
            continue
        points.append({"x": str(x_value), "y": y_value, "label": str(x_value)})
    if not points:
        return None
    return {
        "type": "chart",
        "displayType": display_type,
        "title": str(candidate.get("title") or "Health data chart"),
        "subtitle": state.get("query_result", {}).get("sourceSummary"),
        "xAxis": {"label": x_field, "type": "time" if "time" in x_field or "date" in x_field else None},
        "yAxis": {"label": str(candidate.get("label") or y_field), "unit": candidate.get("unit")},
        "series": [{"name": str(candidate.get("label") or y_field), "points": points}],
    }


def chart_rows_for_candidate(
    state: HealthDataQueryState,
    x_field: str,
    y_field: str,
) -> list[dict[str, Any]]:
    rows_by_table = state.get("context_package", {}).get("rowsByTable", {})
    if isinstance(rows_by_table, dict):
        for rows in rows_by_table.values():
            if not isinstance(rows, list):
                continue
            clean_rows = [row for row in rows if isinstance(row, dict)]
            if any(row.get(x_field) is not None and _coerce_number(row.get(y_field)) is not None for row in clean_rows):
                return clean_rows
    rows = state.get("query_result", {}).get("data", [])
    return [row for row in rows if isinstance(row, dict)] if isinstance(rows, list) else []


def source_summary_for_query(normalized_sigma: dict[str, Any], result: dict[str, Any]) -> str:
    table = normalized_sigma.get("table", "selected health table")
    count = result.get("count", len(result.get("data", [])) if isinstance(result.get("data"), list) else 0)
    fields = normalized_sigma.get("fields", [])
    return f"Based on {count} patient-scoped rows from {table} fields: {', '.join(fields)}."


def source_summary_for_context(context_package: dict[str, Any]) -> str:
    summaries = context_package.get("sourceSummaries", [])
    if isinstance(summaries, list) and summaries:
        return "Based on validated patient-scoped context sources: " + "; ".join(
            str(item) for item in summaries
        )
    missing = context_package.get("missingContext", [])
    reasons = [
        str(item.get("reason"))
        for item in missing
        if isinstance(item, dict) and item.get("reason")
    ]
    if reasons:
        return "No validated patient context rows were available. Missing context: " + "; ".join(reasons)
    return "No validated patient context rows were available for this request."


def reply_for_analysis(analysis: dict[str, Any], empty_result: bool) -> str:
    if empty_result:
        return "I could not find matching patient data for that request."
    summary = str(analysis.get("summary", "")).strip()
    return summary or "I generated a health data report."


def classify_metric_key(message: str) -> str | None:
    lowered = message.lower()
    for key, metric in METRIC_CATALOG.items():
        if any(term in lowered or term in message for term in metric["terms"]):
            return key
    return None


def metric_for_key(key: Any) -> dict[str, Any] | None:
    return METRIC_CATALOG.get(str(key)) if key is not None else None


def classify_report_freshness(message: str) -> str:
    lowered = message.lower()
    if any(term in lowered for term in ["sleep", "readiness", "today", "recent", "acute", "tomorrow"]):
        return "short_term"
    if any(term in lowered for term in ["week", "weekly", "trend", "consistency"]):
        return "medium_term"
    if any(term in lowered for term in ["baseline", "long-term", "long term", "history"]):
        return "long_term"
    return "short_term"


def classify_request_kind(message: str) -> str:
    return str(analyse_message_intent(message).get("kind", "health_report"))


def parse_json_object(text: str) -> dict[str, Any] | None:
    stripped = text.strip()
    if stripped.startswith("```"):
        stripped = stripped.strip("`")
        stripped = stripped.removeprefix("json").strip()
    try:
        parsed = json.loads(stripped)
    except json.JSONDecodeError:
        return None
    return parsed if isinstance(parsed, dict) else None


def _title_for_intent_kind(intent_kind: str) -> str:
    if intent_kind == "health_plan":
        return "Personalized Health Plan Report"
    return "Health Data Report"


def _next_step_for_intent_kind(intent_kind: str) -> str:
    if intent_kind == "health_plan":
        return "Refresh this plan after new wearable data, sleep records, symptoms, or goals change."
    return "Review this report again after new wearable or health data is available."


def _next_step_for_analysis(intent_kind: str, analysis: dict[str, Any]) -> str:
    if intent_kind != "health_plan":
        return _next_step_for_intent_kind(intent_kind)
    text = " ".join(
        str(item)
        for item in analysis.get("recommendations", [])
        if isinstance(item, str)
    ).lower()
    if "avoid intensive training" in text or "very light activity" in text:
        return "Use a rest, mobility, or light-activity plan now; reassess after blood pressure, sleep, and symptoms improve."
    return _next_step_for_intent_kind(intent_kind)


def report_expiration_for_category(category: str, generated_at: datetime) -> tuple[datetime, str]:
    if category == "medium_term":
        return (
            generated_at + timedelta(days=7),
            "Weekly trends can change after several days of new wearable readings.",
        )
    if category == "long_term":
        return (
            generated_at + timedelta(days=30),
            "Longer-term baselines change more slowly, but newer records can still update this report.",
        )
    return (
        generated_at + timedelta(days=1),
        "Short-term wearable signals can change after the next synced reading.",
    )


def freshness_reason_for_result(
    category: str,
    default_reason: str,
    intent: dict[str, Any],
    query_result: dict[str, Any],
    context_package: dict[str, Any] | None = None,
) -> str:
    context_package = context_package or {}
    rows_by_table = context_package.get("rowsByTable", {})
    if isinstance(rows_by_table, dict) and rows_by_table:
        if intent.get("metric") == "workout_history" and isinstance(rows_by_table.get("wearable_workouts"), list):
            rows = rows_by_table["wearable_workouts"]
        elif isinstance(rows_by_table.get("wearable_vitals"), list):
            rows = rows_by_table["wearable_vitals"]
        else:
            rows = next((rows for rows in rows_by_table.values() if isinstance(rows, list) and rows), [])
    else:
        rows = query_result.get("data", [])
    if not isinstance(rows, list) or not rows:
        return default_reason
    sample = rows[0] if isinstance(rows[0], dict) else {}
    time_field = (
        "start_time"
        if "start_time" in sample
        else "recorded_on"
        if "recorded_on" in sample
        else "diagnosis_date"
        if "diagnosis_date" in sample
        else "timestamp"
    )
    latest_row = latest_row_for_field(
        [row for row in rows if isinstance(row, dict)],
        time_field,
    )
    latest = str(latest_row.get(time_field)) if latest_row is not None else ""
    metric_label = (
        "workout history"
        if intent.get("metric") == "workout_history"
        else (metric_for_key(intent.get("metric")) or {})
        .get("label", "health data")
        .lower()
    )
    if not latest:
        return default_reason
    if category == "medium_term":
        window = "weekly trend"
    elif category == "long_term":
        window = "baseline"
    else:
        window = "recent snapshot"
    return (
        f"This {window} is based on the latest available {metric_label} record at {latest}. "
        "Refresh it after the next wearable sync or health-record update."
    )


def latest_row_for_field(rows: list[dict[str, Any]], field: str) -> dict[str, Any] | None:
    candidates = [row for row in rows if row.get(field) is not None]
    if not candidates:
        return None
    return max(candidates, key=lambda row: str(row.get(field)))


def _sample_rows_by_table(context_package: dict[str, Any]) -> dict[str, list[dict[str, Any]]]:
    rows_by_table = context_package.get("rowsByTable", {})
    if not isinstance(rows_by_table, dict):
        return {}
    return {
        str(table): [row for row in rows if isinstance(row, dict)][:10]
        for table, rows in rows_by_table.items()
        if isinstance(rows, list)
    }


def _row_has_high_blood_pressure(row: dict[str, Any]) -> bool:
    systolic, diastolic = _blood_pressure_values(row)
    if systolic is not None and systolic >= 140:
        return True
    if diastolic is not None and diastolic >= 90:
        return True
    return False


def _with_blood_pressure_fields(row: dict[str, Any]) -> dict[str, Any]:
    systolic, diastolic = _blood_pressure_values(row)
    if systolic is None and diastolic is None:
        return row
    enriched = dict(row)
    if systolic is not None:
        enriched["systolic_bp"] = systolic
    if diastolic is not None:
        enriched["diastolic_bp"] = diastolic
    return enriched


def _blood_pressure_values(row: dict[str, Any]) -> tuple[float | None, float | None]:
    value = row.get("blood_pressure")
    systolic = _coerce_number(row.get("systolic") or row.get("systolic_bp"))
    diastolic = _coerce_number(row.get("diastolic") or row.get("diastolic_bp"))
    if isinstance(value, str):
        parts = value.replace("\\", "/").split("/")
        if len(parts) >= 2:
            systolic = systolic or _coerce_number(parts[0].strip())
            diastolic = diastolic or _coerce_number(parts[1].strip())
    return systolic, diastolic


def _safe_query_error_message(exc: Exception) -> str:
    if isinstance(exc, HTTPException):
        detail = exc.detail if isinstance(exc.detail, str) else str(exc.detail)
    else:
        detail = str(exc)
    if _is_missing_optional_workout_table_error(exc) or _looks_like_missing_workout_table(detail):
        return "Workout history is not available in the configured eHospital data source yet."
    return detail


def _looks_like_missing_workout_table(message: str) -> bool:
    lowered = message.lower()
    return "wearable_workouts" in lowered and (
        "doesn't exist" in lowered
        or "does not exist" in lowered
        or "unknown table" in lowered
    )


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


def _model_to_dict(model: Any) -> dict[str, Any]:
    if hasattr(model, "model_dump"):
        return model.model_dump()
    return model.dict()
