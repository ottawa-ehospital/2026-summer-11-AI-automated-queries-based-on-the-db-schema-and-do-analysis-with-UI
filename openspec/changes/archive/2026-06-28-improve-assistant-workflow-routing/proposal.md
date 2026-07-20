## Why

The assistant backend currently mixes two ideas: bottom-level AI provider selection for model invocation and higher-level assistant orchestration for LangGraph workflows. As the chatbot grows beyond wearable charts into personalized health planning, query analysis, report generation, and future health assistant actions, workflow routing should become an explicit orchestration capability built on top of model providers.

This change introduces a scalable workflow-routing design so the Health Assistant can keep one stable chat API while the backend dispatches each message to the most appropriate workflow and uses the configured AI provider only for underlying LLM calls.

## What Changes

- Add backend workflow routing for assistant chat messages, separating model provider selection from assistant workflow selection.
- Clarify the architecture so AI providers represent bottom-level LLM invocation adapters, while LangGraph workflows live in the assistant orchestration layer.
- Introduce a workflow registry so new LangGraph-backed or direct workflows can be added without changing Flutter or expanding orchestrator-level if/else chains.
- Keep the existing wearable chart LangGraph behavior as a compatibility/internal builder, but do not expose it as an independent chatbot workflow.
- Add a health-data query/report workflow design based on the proposed graph: question analysis, optional context gathering, query building, query validation, query execution, result analysis, report generation, and output validation.
- Route patient health data questions and personalized health planning/advice requests, such as recent heart rate, sleep, steps, calories, blood pressure, running plans, exercise readiness, and sleep-improvement advice, into the query/report workflow even when the user does not explicitly say "report".
- Add a structured Markdown report result type with generation time, expiration time, and a reason explaining why the report may become stale.
- Require the frontend to render Markdown report content and show a clear stale/expired state after the report expiration time.
- Add routing fallbacks for low-confidence classification, unsupported requests, and general chat.
- Add retry limits and failure exits for validation loops so query and report workflows cannot loop indefinitely.
- Preserve the existing `/assistant/chat` request and `AssistantChatResponse` contract for Flutter.

## Capabilities

### New Capabilities
- `assistant-workflow-routing`: Backend-owned routing of assistant chat messages to registered workflows with fallback behavior and stable response contracts.

### Modified Capabilities
- `backend-backed-ai-assistant`: The assistant backend will route chat messages across multiple orchestration workflows while using the configured model provider only for underlying LLM calls.
- `ai-chart-results`: The structured assistant result contract will expand beyond charts to include Markdown report results with freshness metadata and frontend expiration handling.

## Impact

- Backend assistant service, model invocation, and orchestration structure under `src/backend/services/assistant/` and `src/backend/clients/model_client.py`.
- Existing wearable LangGraph implementation in `src/backend/services/assistant/providers/wearable_langgraph.py`, which should be migrated toward an orchestrator/workflow role rather than treated as a model provider.
- Assistant schemas may gain optional backend-only routing hints and a new structured Markdown report result while preserving existing Flutter request compatibility.
- Flutter assistant result models and rendering widgets will need Markdown report rendering and expired-report messaging.
- Tests for workflow routing, model-provider compatibility, legacy chart builder compatibility, fallback chat, query/report workflow routing, and validation retry exits.
- No breaking change to Flutter `AiService`, `BackendApiService.assistantChat`, or the existing chat UI response rendering.
