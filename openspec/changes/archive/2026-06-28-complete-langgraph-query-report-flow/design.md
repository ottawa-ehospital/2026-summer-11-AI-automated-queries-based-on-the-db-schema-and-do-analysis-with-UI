## Context

The repository already contains the building blocks for a complete backend-mediated health assistant: a LangGraph-capable assistant orchestrator, a workflow router, shared model invocation settings, Sigma-style query validation, table query execution, structured assistant result models, Markdown report rendering, and chart rendering. The current `HealthDataQueryWorkflow` is intentionally still a scaffold: it names the graph nodes and retry loops, but it does not yet select real tables, generate Sigma, execute patient-scoped searches, or analyze query results with the configured LLM.

The previous workflow-routing design correctly moved LangGraph above model providers and made the query/report flow a workflow behind the assistant router. This change completes that workflow without changing Flutter's chat request shape. Sigma becomes the controlled intermediate contract between model-generated query planning and backend execution.

## Goals / Non-Goals

**Goals:**

- Complete the health-data LangGraph workflow from user intent to validated assistant response.
- Use structured intent analysis to identify request kind, candidate tables, context needs, output needs, and freshness category.
- Generate Sigma-style query payloads through the configured model provider or deterministic shortcuts for known metrics.
- Validate Sigma before execution and retry bounded revisions when validation fails.
- Convert validated Sigma into backend table query requests and execute patient-scoped eHospital queries.
- Analyze retrieved rows with the shared model client and produce structured analysis that can drive reports and charts.
- Generate validated text, Markdown report, and chart result items through the shared assistant result contract.
- Preserve `/assistant/chat` compatibility and existing Flutter result parsing.

**Non-Goals:**

- Add medical diagnosis, medication changes, emergency triage, or appointment scheduling.
- Expose raw SQL generation to Flutter.
- Let the model execute arbitrary SQL or bypass backend schema validation.
- Build multi-table joins unless the backend query tools already expose a validated structured path for them.
- Require live web search for the first implementation.
- Replace direct Gemini/local providers; workflows continue using the shared model client.

## Decisions

### Use Sigma as the workflow query plan contract

The workflow will use Sigma-shaped payloads as the first generated query artifact:

```text
intent_analysis
  -> build_sigma_query
  -> validate_sigma_query
  -> sigma_to_table_query
  -> execute_table_query
```

Sigma is stricter than free-form SQL, is already validated against the backend schema inventory, and can be revised with concrete validation errors. Validated Sigma will be normalized into the existing `TableQueryRequest` shape before execution.

Alternative considered: ask the LLM to generate SQL directly, then validate references. SQL is more expressive, but it increases the risk of unsupported joins, unsafe clauses, and harder retry prompts. Sigma keeps the first version narrow and testable.

### Keep the graph explicit and bounded

The completed graph should use named nodes and named conditional edges:

```text
START
  -> analyse_question
  -> route_context_needs
      -> fetch_patient_context
      -> ask_clarification
      -> prepare_context
  -> choose_query_strategy
      -> build_sigma_query
      -> no_query_needed
  -> validate_sigma_query
      -> execute_query
      -> revise_sigma_query
      -> fallback_response
  -> analyse_query_results
  -> decide_output_plan
      -> generate_report
      -> generate_chart
      -> generate_text_guidance
  -> validate_output
      -> END
      -> revise_output
      -> fallback_response
```

The state should carry:

- patient id, message, bounded history
- intent analysis with confidence, request kind, target metrics, candidate tables, date range, context needs, output needs, and freshness category
- patient context and optional clarification prompt
- generated Sigma payload, normalized Sigma, validation errors, revision attempts
- table query request, executed SQL metadata, query rows, row counts, query errors
- LLM analysis with summary, evidence, recommended visualizations, report sections, caveats, and freshness reasoning
- output plan and validated assistant result items
- trace metadata for selected workflow, selected tables, retry counts, fallback reason, and model provider

Attempt counters for Sigma and output validation must be enforced in state. The graph must never loop indefinitely.

Alternative considered: collapse the workflow into one large model call. That is faster to wire, but it hides validation boundaries and makes failures harder to test.

### Split deterministic metric shortcuts from general Sigma planning

Known simple requests such as recent heart rate, sleep, steps, or calories can be mapped deterministically to Sigma using a metric catalog. More complex health-data analysis or personalized advice requests should use the model to propose a Sigma payload from a schema-aware prompt.

This keeps common demo paths reliable while still letting the workflow grow into broader table coverage.

Alternative considered: use the model for every query plan. That makes behavior less predictable for simple metric requests and requires more live-model coverage in tests.

### Analyse query results before choosing outputs

Output selection should be driven by query results and request intent, not by raw user wording alone. The analysis step should produce a structured object such as:

```json
{
  "summary": "...",
  "evidence": [{"label": "Average heart rate", "value": "72 bpm"}],
  "recommendations": ["..."],
  "chartCandidates": [
    {
      "title": "Recent heart rate",
      "displayType": "line",
      "xField": "timestamp",
      "yField": "heart_rate"
    }
  ],
  "reportSections": ["summary", "data", "recommendations", "freshness"],
  "freshnessCategory": "short_term",
  "limitations": ["..."]
}
```

The output planner can then decide whether to return text only, a Markdown report, chart data, or a combination. Chart payloads still go through `validate_assistant_result_payload`.

Alternative considered: always return a report and chart. That would create empty or misleading charts for non-chartable requests.

### Keep patient scoping and schema validation in backend code

The model may propose which table and fields to use, but backend code must enforce patient scoping whenever the selected table has a patient identifier field. The workflow should reject or revise Sigma that cannot be scoped safely for the current patient.

Alternative considered: include patient id in the model-generated Sigma and trust it. Backend enforcement is safer and easier to test.

### Preserve response compatibility

The final response remains `AssistantChatResponse` with a concise `reply` and ordered `results`. The workflow may return:

- text result for a short answer or summary
- report result for Markdown report content and freshness metadata
- chart result for chart-ready series, axes, and display type

Flutter should not need to parse natural-language prose to decide what to render.

## Risks / Trade-offs

- Model generates invalid Sigma -> Feed validation errors into a bounded revision loop and fallback after the maximum attempts.
- Model chooses the wrong table -> Use deterministic metric mappings, schema-aware prompts, candidate table constraints, and tests for known health domains.
- Patient data leakage across users -> Enforce patient scoping in backend conversion/execution, not only in prompts.
- Empty query results -> Return a validated text/report explanation and avoid empty chart payloads.
- Overly broad table queries -> Apply default limits, date ranges for recent requests, and schema-aware field selection.
- Slow workflow execution -> Keep simple metric paths deterministic and restrict model calls to planning, analysis, and output generation.
- Chart recommendations become misleading -> Validate numeric point values, reject unsupported display types, and include source/freshness metadata.
- Incomplete schema inventory -> Fallback with actionable errors and tests for missing inventory behavior.

## Migration Plan

1. Add workflow state fields and typed helper models for intent analysis, Sigma plan, analysis result, output plan, and trace metadata.
2. Add deterministic metric-to-Sigma mappings for current wearable metrics.
3. Add model-backed Sigma generation for supported health-data requests using schema inventory context.
4. Add Sigma validation and revision nodes using backend query-tool validation errors.
5. Add conversion from normalized Sigma to `TableQueryRequest` and enforce patient scoping.
6. Replace placeholder query execution with real table query execution.
7. Add model-backed result analysis using the shared model client.
8. Add output planning and generation for text, Markdown report, and chart payloads.
9. Route every output payload through shared assistant result validation.
10. Expand backend and Flutter tests for routing, validation loops, query execution, analysis, reports, charts, and fallback behavior.
11. Roll back by keeping the existing general-chat fallback and disabling the complete query/report workflow registration if needed.

## Open Questions

- Which eHospital tables should be included in the first schema-aware prompt allowlist beyond `wearable_vitals`?
- Should low-confidence intent analysis ask a clarification question immediately or fall back to general chat?
- Should chart recommendations be limited to line/bar in this change, or should the backend add additional display types after Flutter support exists?
- Should web search be added as a later optional context source with citations, or excluded from health-data analysis until the query flow is stable?
