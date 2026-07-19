## 1. Workflow Infrastructure

- [x] 1.1 Add assistant workflow state, workflow match, and workflow protocol types under `src/backend/services/assistant/workflows/`.
- [x] 1.2 Add a workflow registry that can register workflows by key and expose the ordered workflow list.
- [x] 1.3 Add `WorkflowRouter` to evaluate registered workflows, select the highest-confidence match, and route to fallback when no specialized workflow qualifies.
- [x] 1.4 Add router-level logging or trace metadata for selected workflow key, confidence, fallback reason, and configured model provider.

## 2. Orchestration and Model Provider Boundaries

- [x] 2.1 Introduce assistant orchestrator naming for workflow-capable chat handling while keeping existing provider entry points compatible.
- [x] 2.2 Keep AI provider/model invocation selection in the shared model client and runtime model settings.
- [x] 2.3 Ensure workflows call LLMs through the shared model client instead of directly choosing Gemini, Ollama, or OpenAI-compatible clients.
- [x] 2.4 Document compatibility aliases where existing `AssistantProvider` names are retained during migration.

## 3. Existing Behavior Migration

- [x] 3.1 Move wearable chart classification, graph construction, and response building into a compatibility/internal builder.
- [x] 3.2 Add `GeneralChatWorkflow` that wraps the existing direct chat path and uses the configured model provider.
- [x] 3.3 Update the workflow-capable assistant orchestrator to delegate chat requests to `WorkflowRouter`.
- [x] 3.4 Preserve existing general text response behavior through `/assistant/chat` while preventing chart builder from independently routing chatbot messages.

## 4. Query Report Workflow

- [x] 4.1 Add a `HealthDataQueryWorkflow` scaffold with named graph nodes for question analysis, health-data and planning intent detection, context routing, context preparation, query building, query validation, query execution, result analysis, report generation, and output validation.
- [x] 4.2 Add named conditional routing decisions for context needs, query validation success/failure, output validation success/failure, clarification, and fallback.
- [x] 4.3 Add retry counters and maximum-attempt enforcement for query validation and output validation loops.
- [x] 4.4 Add report freshness classification that assigns `generatedAt`, `expiresAt`, and `freshnessReason` for short-term and long-term report outputs.
- [x] 4.5 Return a validated `AssistantChatResponse` for successful query/report runs and a compatible fallback response for exhausted retries or unsupported requests.

## 5. Schema and Configuration

- [x] 5.1 Keep existing `AssistantChatRequest` and `AssistantChatResponse` compatibility for Flutter.
- [x] 5.2 Evaluate whether a workflow override belongs in `ModelInvocationSettings` or a separate assistant routing/debug field.
- [x] 5.3 Add backend schema support for structured Markdown report results with `format`, `title`, `content`, `generatedAt`, `expiresAt`, `freshnessReason`, and optional source summary metadata.
- [x] 5.4 Ensure all structured workflow result payloads are validated through shared assistant result helpers before returning to the API layer.

## 6. Flutter Report Rendering

- [x] 6.1 Add Flutter assistant model parsing for structured report results while preserving unknown-result fallback behavior.
- [x] 6.2 Add Markdown rendering for assistant report results using a controlled renderer and safe degradation for unsupported markup.
- [x] 6.3 Add expired-report UI state that compares `expiresAt` with the current time and explains that the report may be stale.
- [x] 6.4 Preserve report content visibility after expiration while visually distinguishing expired reports from fresh reports.

## 7. Tests

- [x] 7.1 Add unit tests for workflow registry registration and router fallback selection.
- [x] 7.2 Add tests confirming workflow LLM calls use the configured model provider abstraction.
- [x] 7.3 Add tests confirming wearable chart builder compatibility and no standalone chart routing through the orchestrator.
- [x] 7.4 Add tests confirming non-specialized messages route to the general chat fallback and personalized health planning requests route to the query/report workflow.
- [x] 7.5 Add tests for query/report workflow retry limits on query validation failure.
- [x] 7.6 Add tests for query/report workflow retry limits on output validation failure.
- [x] 7.7 Add backend tests for report result validation, required expiration metadata, and invalid report payload rejection.
- [x] 7.8 Add Flutter tests for Markdown report parsing/rendering and expired-report notice display.
- [x] 7.9 Add API-level regression tests confirming Flutter-facing `/assistant/chat` request and response shapes remain unchanged.

## 8. Verification

- [x] 8.1 Run the backend assistant test suite.
- [x] 8.2 Run existing query tool tests to confirm query validation behavior remains compatible.
- [x] 8.3 Run relevant Flutter tests for assistant response parsing, Markdown report rendering, expired-report UI, and chart result rendering.
