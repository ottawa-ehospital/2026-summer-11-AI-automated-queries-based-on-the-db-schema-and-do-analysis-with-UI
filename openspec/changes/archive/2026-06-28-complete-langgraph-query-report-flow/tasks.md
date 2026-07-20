## 1. Workflow State And Intent Analysis

- [x] 1.1 Add typed workflow state fields for intent analysis, context needs, Sigma plan, query execution metadata, analysis output, output plan, validation attempts, and trace metadata.
- [x] 1.2 Add structured intent analysis models for request kind, target metrics, candidate tables, time range, output needs, freshness category, confidence, and clarification needs.
- [x] 1.3 Implement deterministic intent detection for common health metrics and personalized advice/planning requests.
- [x] 1.4 Add model-backed intent analysis for supported requests that deterministic rules cannot classify confidently.
- [x] 1.5 Add clarification or fallback routing for ambiguous requests that cannot be queried safely.

## 2. Sigma Query Planning

- [x] 2.1 Add deterministic metric-to-Sigma mappings for recent heart rate, sleep, steps, calories, and other currently supported wearable metrics.
- [x] 2.2 Add schema-context builder for model-backed Sigma planning using allowlisted eHospital schema inventory tables and fields.
- [x] 2.3 Implement the `build_sigma_query` graph node for deterministic and model-backed Sigma generation.
- [x] 2.4 Include patient-scope hints and output needs in Sigma planning prompts without asking the model to generate raw SQL.
- [x] 2.5 Add retry-aware Sigma revision prompts that incorporate backend validation errors.

## 3. Sigma Validation And Query Execution

- [x] 3.1 Add conversion from normalized Sigma payloads to `TableQueryRequest`.
- [x] 3.2 Enforce current patient id filters during Sigma-to-table-query conversion for patient-scoped tables.
- [x] 3.3 Reject or fallback for workflow queries targeting tables that cannot be safely patient-scoped.
- [x] 3.4 Replace placeholder query execution in `HealthDataQueryWorkflow` with real backend query-tool execution.
- [x] 3.5 Store returned rows, row count, executed query metadata, source summary, and empty-result state in workflow state.
- [x] 3.6 Add bounded Sigma validation and revision loops with fallback after maximum attempts.

## 4. Query Result Analysis

- [x] 4.1 Add structured query-analysis output models for summary, evidence, recommendations, limitations, freshness category, and chart candidates.
- [x] 4.2 Implement the `analyse_query_results` node using the shared model client and configured model provider.
- [x] 4.3 Add defensive parsing and validation for model-generated analysis output.
- [x] 4.4 Add no-data analysis behavior that explains missing data without generating empty charts.
- [x] 4.5 Add analysis fallback behavior when model output is malformed after allowed retries.

## 5. Output Planning And Generation

- [x] 5.1 Implement an output planner that selects text, Markdown report, chart, or combined results based on intent and analysis.
- [x] 5.2 Generate Markdown reports with summary, data/evidence, recommendations, limitations, source summary, generated timestamp, expiration timestamp, and freshness reason.
- [x] 5.3 Generate chart payloads from validated query rows or validated aggregate analysis for supported `line` and `bar` display types.
- [x] 5.4 Reject unsupported chart display types and degrade to text/report output when chart generation is unsafe.
- [x] 5.5 Route text, report, and chart payloads through shared assistant result validation before composing `AssistantChatResponse`.
- [x] 5.6 Add bounded output revision loops with fallback after maximum attempts.

## 6. Backend API And Compatibility

- [x] 6.1 Preserve the existing `/assistant/chat` request and response shape for Flutter callers.
- [x] 6.2 Ensure workflow LLM calls honor request-level and runtime model invocation settings through the shared model client.
- [x] 6.3 Preserve the general chat fallback for non-health-data messages and failed workflow paths.
- [x] 6.4 Keep the legacy wearable chart builder available for compatibility tests while routing assistant chat through the completed query/report workflow.
- [x] 6.5 Add route or log metadata for selected tables, selected result types, retry counts, fallback reason, and model provider.

## 7. Tests And Verification

- [x] 7.1 Add backend tests for structured intent analysis across metric, report, planning, ambiguous, and non-health-data requests.
- [x] 7.2 Add backend tests for deterministic Sigma generation and model-backed Sigma planning with mocked model output.
- [x] 7.3 Add backend tests for Sigma validation retry, revision, and retry-exhausted fallback.
- [x] 7.4 Add backend tests for Sigma-to-`TableQueryRequest` conversion and patient-scope enforcement.
- [x] 7.5 Add backend tests for real query execution using mocked eHospital query responses.
- [x] 7.6 Add backend tests for LLM analysis parsing, malformed analysis fallback, and no-data behavior.
- [x] 7.7 Add backend tests for report output generation, chart output generation, validation failures, and unsupported chart degradation.
- [x] 7.8 Add API-level regression tests proving `/assistant/chat` remains Flutter-compatible.
- [x] 7.9 Add or update Flutter tests for receiving combined text/report/chart results from the assistant response model.
- [x] 7.10 Run `openspec validate complete-langgraph-query-report-flow --strict`.
- [x] 7.11 Run assistant backend tests and relevant query-tool tests in the `langgraph` conda environment.
- [x] 7.12 Run relevant Flutter analyze/tests for assistant result parsing and rendering.
