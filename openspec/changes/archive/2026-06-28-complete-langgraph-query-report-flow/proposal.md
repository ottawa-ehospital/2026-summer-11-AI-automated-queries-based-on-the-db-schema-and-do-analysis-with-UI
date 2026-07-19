## Why

The current LangGraph assistant has a workflow router and a health-data query/report scaffold, but it does not yet implement the full agent flow needed for real patient-data analysis: intent analysis, table selection, Sigma construction, Sigma validation, query execution, LLM analysis, and validated report/chart output. This change completes that flow so health assistant answers are grounded in validated backend queries instead of placeholder summaries.

## What Changes

- Extend the health-data query/report LangGraph workflow from a scaffold into an end-to-end query agent flow.
- Add structured intent analysis that determines request kind, required patient context, candidate tables, query goals, output needs, freshness category, and whether clarification is required.
- Integrate Sigma-style query generation into the workflow as the intermediate query contract between LLM planning and backend execution.
- Validate generated Sigma against the backend schema inventory before any eHospital query is executed.
- Convert validated Sigma into the existing structured table query execution path and run patient-scoped searches.
- Add bounded revision loops for Sigma generation and output generation, with deterministic fallback when attempts are exhausted.
- Add LLM-backed analysis of retrieved query rows through the shared model client and configured model provider.
- Generate validated assistant outputs that may include text guidance, Markdown reports, and chart-ready data with selected display types.
- Keep the `/assistant/chat` request and response contract compatible with Flutter's existing `reply` and ordered `results` model.

## Capabilities

### New Capabilities

- `langgraph-query-report-flow`: End-to-end LangGraph health-data query and report workflow from intent analysis through Sigma validation, query execution, LLM analysis, and validated text/report/chart output.

### Modified Capabilities

- `backend-sigma-query-tools`: Add workflow-facing Sigma conversion/execution requirements so validated Sigma can be transformed into patient-scoped backend table queries.
- `ai-chart-results`: Extend chart result requirements so chart data and display type can be selected from query analysis rather than only fixed wearable metric mappings.
- `backend-backed-ai-assistant`: Require backend-mediated assistant chat to use the complete LangGraph query/report flow for eligible health-data analysis and personalized advice requests while preserving the Flutter API contract.

## Impact

- Backend assistant workflow modules under `src/backend/services/assistant/workflows/`.
- Backend query tooling under `src/backend/services/query_tools.py` and `src/backend/schemas/query_tools.py`.
- Shared assistant result validation under `src/backend/services/assistant/result_helpers.py` and `src/backend/schemas/assistant.py`.
- Shared model invocation through `src/backend/clients/model_client.py`.
- Backend assistant tests and query-tool tests.
- Flutter result parsing/rendering tests for text, report, and chart assistant results.
