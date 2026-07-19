## Context

The backend already has a model invocation boundary in `src/backend/clients/model_client.py`, and request-level model settings can select Gemini, local/Ollama, or OpenAI-compatible calls. That bottom layer is the AI provider layer: it answers which LLM service, model name, base URL, and invocation settings to use.

The current assistant provider naming blurs that boundary because `wearable_langgraph` is registered next to direct model-call providers. Architecturally, LangGraph is not a bottom-level model provider. It is an assistant orchestration layer that may call the configured model provider one or more times while also using tools, validation, query execution, and fallback logic.

The current LangGraph implementation began with simple wearable chart requests. That chart builder should now be treated as a compatibility/internal building block, not as a standalone chatbot workflow. The chatbot should route into the full health-data query/report workflow when users ask about patient health data, analysis, reports, or personalized health planning/advice such as running plans, exercise readiness, recovery planning, or sleep-improvement guidance.

The target architecture separates three decisions:

- Model provider selection: which underlying LLM adapter handles model calls.
- Assistant orchestration selection: whether the assistant uses direct chat or a workflow-capable orchestrator.
- Workflow selection: which business workflow should handle this chat message inside the orchestrator.

The user-proposed graph for health-data query/report generation becomes one workflow behind this router, not the entire assistant architecture and not a model provider.

## Goals / Non-Goals

**Goals:**

- Add an explicit workflow router inside the backend assistant orchestration layer.
- Keep Flutter's existing `AssistantChatRequest` and `AssistantChatResponse` contract stable.
- Let new workflows be registered without changing the chat API or adding feature branches to orchestrator methods.
- Preserve AI providers as bottom-level LLM invocation adapters that workflows can call through the shared model client.
- Preserve the existing wearable chart builder for compatibility while preventing it from independently routing chatbot messages.
- Support a health-data query/report workflow with clear validation loops, retry limits, and fallback exits for both metric analysis and personalized health planning requests.
- Return health-data reports as Markdown-capable structured results with explicit freshness metadata.
- Render Markdown reports in Flutter and clearly mark expired reports as stale when their validity window has passed.
- Make routing and workflow outcomes testable without requiring a live model for every test.

**Non-Goals:**

- Replace all direct model providers with LangGraph.
- Treat each LangGraph workflow as a separate AI provider.
- Add diagnosis, medication, appointment, or emergency workflows in this change.
- Change the Flutter chat UI or require users to select workflow names manually.
- Build full conversational memory or long-term persistence beyond the existing request history.

## Decisions

### Put workflow routing above model providers

The default workflow-capable assistant orchestrator will own a `WorkflowRouter` that receives an `AssistantWorkflowState` and selects a registered workflow. Workflows call the shared model client when they need LLM output, and the model client uses the configured model provider.

Proposed package shape:

```text
src/backend/services/assistant/
  orchestrators/
    direct_chat.py
    langgraph_orchestrator.py
  workflow_router.py
  workflows/
    __init__.py
    base.py
                    wearable_chart.py
    health_data_query.py
    general_chat.py
```

Each workflow exposes a small contract:

```python
class AssistantWorkflow(Protocol):
    key: str
    description: str

    async def can_handle(self, state: AssistantWorkflowState) -> WorkflowMatch:
        ...

    async def run(self, state: AssistantWorkflowState) -> AssistantChatResponse:
        ...
```

`WorkflowMatch` contains `workflow_key`, `confidence`, and an optional reason. Rule-based workflows can return high confidence without invoking a model. LLM-based classification can be added later for ambiguous messages through the shared model client.

Alternative considered: keep adding branches inside `WearableLangGraphAssistantProvider.chat()`. This is simpler for one or two features, but it couples feature routing to one implementation and makes ordering, fallback, and observability harder as workflows grow.

### Keep model provider routing and workflow routing separate

The current `AssistantProviderFactory` name should be treated as transitional. The target model is:

```text
Assistant Service
  -> Assistant Orchestrator
      -> Workflow Router
          -> Workflow
              -> Model Client
                  -> Model Provider adapter
```

Model provider settings choose Gemini, Ollama/local, or OpenAI-compatible invocation. Workflow routing happens above that layer and should not be represented as another bottom-level model provider.

This preserves the existing configuration model while allowing a workflow-capable orchestrator to host multiple workflows. A future optional `workflow_key` can be added as a testing/debug override without requiring Flutter to send it, but it should not make business workflows look like model providers.

Alternative considered: make every workflow a provider key. That would overload provider selection, expose backend workflow details to request settings, and make fallback between workflows awkward.

### Implement the health-data query/report flow as a workflow graph

The proposed query/report workflow should be a contained LangGraph with a shared state. It is the entry point for user requests that require health context, not only requests that explicitly ask for a report. The final artifact is a report, but the routed intent can be metric analysis, exercise planning, sleep advice, recovery readiness, or another supported health-data task. The graph should use named conditions rather than numbered edges:

```text
START
  -> analyse_question
  -> route_context_needs
      -> web_search
      -> fetch_user_profile
      -> ask_clarification
  -> prepare_context
  -> build_query
  -> validate_query
      -> execute_query
      -> revise_query
      -> fallback_response
  -> analyse_query_results
  -> generate_report
  -> validate_output
      -> END
      -> revise_report
      -> fallback_response
```

The workflow state should include at least:

- patient id, message, and bounded history
- selected intent, request kind, and routing confidence
- gathered context
- query payload or SQL/query intent
- query validation attempts and output validation attempts
- query result, analysis, report, validation errors, and final response

The query validation and output validation loops must include maximum attempts before routing to a fallback response or future human-review path.

### Use deterministic routing first, model routing second

Routing should prefer deterministic checks for well-known cases such as supported health metrics and action-oriented health planning language. A request like "How has my recent heart rate been?", "Can I run tomorrow?", or "Make me a running plan" should route to the health-data query/report workflow, because answering it responsibly requires collecting relevant patient data, validating the query, analyzing results, and generating a time-limited report. Ambiguous cases can use a lightweight model classifier through the model client that returns structured JSON. If confidence is below the configured threshold, the router falls back to general chat or asks a clarification question.

This keeps common paths fast and testable while leaving room for richer intent classification later.

### Validate final responses through the shared result contract

Every workflow returns `AssistantChatResponse`. Structured result payloads, including charts and future report artifacts, must be validated before returning to the API layer. This keeps Flutter rendering simple and avoids workflow-specific response parsing in the app.

### Represent reports as Markdown structured results with expiry metadata

The query/report workflow should return reports as structured assistant result items rather than only as plain `reply` text. The top-level `reply` remains a short summary for compatibility, while the report result carries the full content and freshness metadata.

Proposed result shape:

```json
{
  "type": "report",
  "format": "markdown",
  "title": "Sleep and recovery report",
  "content": "## Summary\n...",
  "generatedAt": "2026-06-20T14:30:00Z",
  "expiresAt": "2026-06-21T14:30:00Z",
  "freshnessReason": "Sleep debt and short-term recovery signals can change after the next sleep cycle.",
  "sourceSummary": "Based on wearable sleep and activity records through 2026-06-20."
}
```

The workflow should choose an expiration time based on the kind of inference:

- Short-term state, such as poor sleep, readiness, acute symptoms, or recent activity effects: hours to 1 day.
- Medium-term trends, such as weekly activity or sleep consistency: several days to 1 week.
- Long-term baseline findings, such as stable historical averages: longer windows, but still explicit.

The generated report should include enough metadata for Flutter to determine staleness locally without calling the backend. When `expiresAt` is in the past, Flutter should render the Markdown content with a visible stale notice and a concise explanation that the user's health data may have changed.

Markdown should be rendered from a controlled subset suitable for assistant reports: headings, paragraphs, bold/italic, ordered/unordered lists, inline code, links if allowed by product policy, and tables only if supported by the Flutter renderer. Raw HTML should not be rendered.

## Risks / Trade-offs

- Router misclassification -> Use confidence thresholds, deterministic high-priority rules, fallback chat, and tests for overlapping intents.
- Too much abstraction too early -> Keep the workflow contract small and route only the query/report workflow by default.
- Validation loops become slow or endless -> Store attempt counters in workflow state and enforce maximum attempts.
- Model-based routing becomes hard to test -> Make the classifier injectable and keep deterministic workflows testable without model calls.
- Existing class names blur provider/orchestrator responsibilities -> Introduce the new orchestration boundary incrementally and keep compatibility aliases during migration.
- Future workflow-specific UI needs richer results -> Extend `AssistantResult` with validated result types rather than changing the chat endpoint shape.
- Expired reports may confuse users -> Show stale state prominently and explain that short-term health signals can change after newer data arrives.
- Markdown rendering can introduce inconsistent UI or unsafe content -> Use a constrained Markdown renderer and reject or sanitize unsupported raw HTML.

## Migration Plan

1. Add workflow state, workflow protocol, registry, and router modules.
2. Introduce assistant orchestrator naming while keeping compatibility with existing assistant provider entry points.
3. Move the wearable chart graph into a compatibility/internal module while preserving direct builder behavior.
4. Add `GeneralChatWorkflow` as the fallback wrapper around the shared model client or existing direct chat path.
5. Add the health-data query/report workflow scaffold with named routing decisions, health-data intent detection, retry counters, and fallback exits.
6. Add the Markdown report result schema and validator, including generated and expiration timestamps.
7. Update Flutter result parsing/rendering to display Markdown reports and expired-report notices.
8. Update the workflow-capable orchestrator to delegate chat requests to `WorkflowRouter`.
9. Add tests for routing, fallback behavior, model-provider compatibility, legacy wearable chart builder output, Markdown report parsing, expiration handling, and validation retry exits.
10. Roll back by selecting the direct-chat orchestrator or restoring the previous `wearable_langgraph` compatibility path.

## Open Questions

- Should a future `workflow_key` override live in `ModelInvocationSettings`, or should it be moved to a separate assistant-debug/request-routing field so model provider settings stay pure?
- Should low-confidence health-data requests ask a clarification question immediately, or fall back to general chat with a brief explanation?
- Which external web-search provider should be used when the query/report workflow needs current medical or domain context?
- What default expiration windows should product use for each report category before real-world tuning data exists?
- Should expired reports offer an explicit "refresh report" action in the first implementation or only display the stale notice?
