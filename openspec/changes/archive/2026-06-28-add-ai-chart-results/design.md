## Context

The Python backend now owns assistant orchestration and Flutter consumes backend-backed assistant responses. The existing chat contract exposes a text `reply`, which is not enough for chart UI because Flutter would have to infer data points and chart type from prose. The app already has feature-local presentation widgets and chart dependencies, so chart rendering should stay in Flutter while the backend owns data lookup and result shaping.

## Goals / Non-Goals

**Goals:**
- Define a typed assistant result envelope that supports both text and chart results.
- Define a backend AI assistant interface so different LangGraph/model implementations can produce the same validated output contract.
- Let backend responses include chart-ready data, labels, units, axes, series, and the requested display template.
- Keep `reply` stable for existing callers and chat history.
- Add a minimum LangGraph-compatible flow for natural-language single-table chart queries such as "How has my recent heart rate been?".
- Provide an agent-facing validation function for proposed result payloads.
- Render chart results inside Health Assistant messages using Flutter templates selected by `displayType`.
- Cover line and bar chart templates first, and treat unknown or unsupported chart types as invalid chart output rather than rendering an approximate chart.

**Non-Goals:**
- Build a fully generic BI/dashboard grammar.
- Let Flutter execute SQL, call query tools, or fetch chart data after receiving a result.
- Replace existing vitals or trend screens.
- Require the model to produce final chart JSON without backend validation.
- Perform multi-table joins, diagnosis, or complex trend analysis in the MVP chart flow.
- Expose model-provider-specific output shapes to Flutter or FastAPI routers.

## Decisions

1. Use an ordered `results` list on assistant chat responses.

   The response keeps `reply` as the canonical text answer for compatibility, and adds `results` as the richer rendering contract. Existing callers can ignore `results`, while new Flutter UI can render all supported items.

2. Define chart payloads as normalized points and series rather than raw table rows.

   A chart result contains `displayType`, `title`, optional `subtitle`, optional axis metadata, and one or more series. Each series has points with `x`, `y`, optional `label`, and optional metadata. This keeps backend table shapes out of UI code.

3. Keep chart template selection explicit.

   The backend sends `displayType` values such as `line` and `bar`. Flutter maps these values to fixed templates. Unknown display types must not render a substitute chart because inaccurate chart rendering is worse than no chart. If an unsupported chart type reaches Flutter, Flutter logs or reports a warning and skips rendering that chart item while preserving the text reply.

4. Validate chart payloads in backend-owned code.

   The model or future agent tooling can decide that a chart is useful, but backend code must normalize and validate the final result before returning it to Flutter.

5. Introduce a stable backend assistant interface.

   Backend assistant orchestration should be abstracted behind a small interface that accepts the normalized chat request context and returns a validated assistant response shape. Concrete implementations can use different model providers or graph internals, but they must all return the same `reply` and `results` contract.

   The router should depend on the interface instead of a specific model or graph implementation:

   ```text
   FastAPI router
     -> AssistantOrchestrator interface
       -> LangGraphWearableChartAssistant
       -> FutureProviderSpecificAssistant
     -> validate/compose AssistantChatResponse
   ```

   This keeps LangGraph as the workflow mechanism while preventing provider-specific model output from leaking into Flutter.

6. Add a narrow LangGraph MVP for single-table chart generation.

   The first graph path should focus on the "recent heart rate" class of requests. A small intent node maps natural language to a whitelisted metric query, a query node reads patient-scoped `wearable_vitals` rows, a result node shapes a line chart, and a validation node calls `validate_assistant_result_payload` before the HTTP response is composed.

   The intended MVP graph shape is:

   ```text
   classify_metric_query
     -> build_single_table_query
     -> build_chart_result
     -> validate_assistant_result
     -> compose_response
   ```

7. Keep the MVP metric catalog explicit.

   The initial supported metric catalog should be small and documented in backend code comments: `heart_rate`, `steps`, `calories`, and `sleep` from `wearable_vitals`, with `heart_rate` as the required smoke-test scenario. This avoids asking the model to invent table names, field names, or display types.

## Risks / Trade-offs

- Model or heuristic chooses the wrong chart type -> Backend limits display types to known templates and includes a text explanation alongside charts.
- Large query results make messages heavy -> Backend caps chart points and can summarize or aggregate before returning data.
- Contract drift between Python and Dart models -> Add backend schema tests and Flutter model parsing/widget tests around representative payloads.
- Provider-specific model behavior changes output shape -> Route all implementations through the assistant interface and result validator before response composition.
- Unknown chart requests are initially unsupported -> Return text-only answers until the backend can produce valid chart data.
- Unsupported chart output reaches Flutter despite backend validation -> Flutter emits a warning and skips the chart item rather than rendering an approximate or meaningless chart.
- LangGraph scope can grow too quickly -> Keep the MVP to one patient-scoped table and documented metric mappings.

## Migration Plan

1. Add backend result schemas and include `results` in assistant chat responses.
2. Add a backend assistant orchestrator interface that constrains implementations to the shared response contract.
3. Add the agent-facing assistant result validator function and document its accepted payload shape.
4. Add a minimum LangGraph-compatible assistant flow for single-table `wearable_vitals` chart queries.
5. Add backend chart result shaping for common health-data queries.
6. Add Flutter result models and parse `results` while preserving old `reply` behavior.
7. Add assistant chart templates for line and bar display types.
8. Add tests for backend response shape, graph MVP behavior, validator failures, implementation swapping, and Flutter parsing/rendering.
