## Why

The current LangGraph health-data query flow plans and executes a single table lookup for many user questions, so personalized answers can miss important context from workouts, vitals, history, medications, feedback, and risk analyses. A health question often needs evidence across several patient-scoped tables; if one selected table has no rows, the workflow should still use other relevant data instead of failing into a weak or empty answer.

## What Changes

- Add multi-table context planning for health-data assistant requests, allowing the workflow to select and execute several patient-scoped table queries for one user question.
- Force `health_plan`, `training readiness`, `tomorrow`, and `intensive training` intents through the multi-table context flow with a minimum context set of `wearable_vitals`, `vitals_history`, `diagnosis`, `medical_history`, `prescription_form`, and `wearable_workouts`.
- Aggregate query results into a bounded health context package grouped by domain, including wearable vitals, workout history, vitals history, medical history, diagnoses, prescriptions, patient feedback, and risk/AI analysis records when relevant.
- Update analysis and final-output generation to reason over the combined context package, cite which tables contributed evidence, and explain missing or unavailable context without treating one empty table as a total failure.
- Add deterministic training safety hints so low sleep, high blood pressure, or symptom evidence biases training advice toward conservative recommendations.
- Preserve validation, patient scoping, retry limits, and fallback behavior for every planned table query.
- Extend trace metadata and tests so selected tables, per-table row counts, missing-context reasons, and fallback stages are observable.

## Capabilities

### New Capabilities
- `multi-table-health-context-analysis`: Defines multi-table planning, retrieval, aggregation, evidence handling, and missing-context behavior for personalized health assistant analysis.

### Modified Capabilities
- `langgraph-query-report-flow`: The health-data workflow changes from single-query analysis to multi-table context planning and evidence-grounded synthesis.
- `backend-sigma-query-tools`: Backend query tooling must support workflow execution of validated multi-query plans while preserving patient scoping and per-query validation.

## Impact

- Backend assistant workflow code under `src/backend/services/assistant/workflows/health_data_query.py`.
- Query validation and conversion helpers under `src/backend/services/query_tools.py` and related schemas.
- Health assistant prompts, trace metadata, and result validation for report/text/chart responses.
- Tests covering multi-table planning, partial/no data behavior, patient scoping, and evidence summaries.
