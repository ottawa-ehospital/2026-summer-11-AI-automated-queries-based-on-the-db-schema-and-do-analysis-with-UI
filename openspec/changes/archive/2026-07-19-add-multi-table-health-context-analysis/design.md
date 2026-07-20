## Context

The current `health_data_query` LangGraph workflow stores one `sigma_payload`, validates one normalized Sigma query, converts it to one `TableQueryRequest`, and analyzes one `query_result`. This works for simple metric questions, but personalized health questions often require context across `wearable_vitals`, `wearable_workouts`, `vitals_history`, `medical_history`, `diagnosis`, `prescription_form`, `prescription`, `patient_feedback`, `heart_disease_analysis`, `stroke_prediction`, and `ai_diagnostics`.

The first deterministic target is training readiness. Requests classified as `health_plan`, `training readiness`, `tomorrow`, or `intensive training` must enter the multi-table context flow and must attempt at least `wearable_vitals`, `vitals_history`, `diagnosis`, `medical_history`, `prescription_form`, and `wearable_workouts`. These tables may be empty, but absence is treated as partial context instead of a hard failure.

The alert-analysis workflow already demonstrates a bounded multi-table context pattern for event-triggered analysis. This change applies the same principle to chat/report requests while preserving the existing query-tool safety model: known schema inventory, field validation, patient scoping, parameterized queries, bounded limits, and validated outputs.

## Goals / Non-Goals

**Goals:**
- Let one health assistant request plan and execute multiple patient-scoped context queries.
- Force training-readiness and near-term intensive-training requests through the multi-table path with a fixed minimum context set.
- Combine returned rows into a bounded health context package organized by table/domain.
- Continue when optional or relevant tables return no rows, and produce useful missing-context explanations.
- Ground the final report/text/chart output in evidence across all successful query results.
- Add deterministic safety hints for training advice when sleep is under 4 hours, blood pressure is high, or symptom evidence exists.
- Record trace metadata for selected tables, per-table validation/execution status, row counts, and missing-context reasons.

**Non-Goals:**
- Do not add free-form SQL generation, unvalidated joins, or model-controlled patient identifiers.
- Do not change the frontend assistant API contract unless existing response metadata cannot carry the new trace data.
- Do not attempt clinical diagnosis or medication instructions beyond the existing wellness/advice safety boundaries.
- Do not require every possible patient table for every request; context selection remains relevant and bounded.

## Decisions

1. Represent the workflow plan as a multi-query context plan instead of one Sigma payload.

   The plan contains a list of query entries with stable ids, purpose labels, relevance category, Sigma payload, required/optional flag, result limit, and domain tags. Deterministic planning handles common needs such as vitals plus workouts for exercise planning and medications/history plus vitals for blood-pressure questions. For `health_plan`, `training readiness`, `tomorrow`, and `intensive training` intents, deterministic planning always includes `wearable_vitals`, `vitals_history`, `diagnosis`, `medical_history`, `prescription_form`, and `wearable_workouts`; model-backed planning may add relevant optional tables but may not remove that minimum set.

   Alternative considered: generate one SQL statement with joins. This was rejected because patient scoping, schema validation, and table-specific date fields are already safer and simpler through independent table queries.

2. Validate and execute each query independently.

   Each planned Sigma payload is validated with existing schema inventory rules, converted with patient scoping, and executed through the table query service. For the forced training-readiness context set, no-row results are recorded as missing context and do not cancel the flow. Validation or unsafe-scoping failures still block the unsafe query; required-query failures trigger bounded revision or fallback.

   Alternative considered: fail the whole workflow on the first validation or empty result. This keeps behavior simple but recreates the current weak-answer/no-answer failure mode.

3. Build a bounded context package before model analysis.

   The workflow stores `context_package` with `sources`, `rowsByTable`, `sourceSummaries`, `missingContext`, `rowCounts`, and `evidenceHints`. Rows are capped per table and normalized only enough for prompt construction; the original table and fields remain visible for evidence references.

   Alternative considered: merge rows into one flat list. This loses source provenance and makes it harder to explain which domain influenced a recommendation.

4. Analyze combined context with explicit evidence rules.

   The analysis prompt receives the user question, current backend time, intent, selected tables, source summaries, compact rows, and explicit recent-window framing. For training-readiness style questions, it must instruct the model to judge readiness using current time, the most recent 3 hours and most recent day of data, medical history, medication context, symptoms or feedback, vitals, and workout load. It must distinguish present evidence from unavailable context, cite table/source names, and avoid recommendations that depend on missing medication/history evidence.

   Alternative considered: reuse the single-query prompt unchanged. That would leave the model unaware that missing rows from one table are only partial context.

5. Keep chart generation tied to chartable source rows.

   Charts remain optional and are generated only when at least one successful source contains numeric/time-series data suitable for the existing chart schema. Report and text outputs can use all context domains.

6. Add deterministic safety hints before model analysis.

   The context package includes derived safety hints when recent sleep is under 4 hours, recent blood pressure is high, or patient feedback/symptom rows indicate symptoms. Training recommendations must become conservative when any of these hints are present, even if the model would otherwise suggest intensive training.

## Risks / Trade-offs

- More queries per assistant request can increase latency and eHospital load -> cap plan size, table limits, and execute only relevant allowlisted tables.
- Model-backed planning can over-select tables -> require allowlisted schema context, deterministic defaults, max query count, and per-entry validation.
- Partial context can be misread as complete context -> include `missingContext` in analysis prompts and final report limitations.
- Multi-table prompts can grow too large -> summarize rows per table, cap rows, and prefer recent records.
- Optional table absence, especially local `wearable_workouts` setup gaps, can create noisy errors -> classify optional missing-table errors as missing context rather than workflow failure.
- Conservative safety hints can over-limit a healthy user's training recommendation -> phrase them as readiness constraints and cite the triggering evidence or missing evidence.

## Migration Plan

1. Add multi-query plan and context package state fields while keeping the existing single-query fields until tests pass.
2. Implement deterministic multi-table planning for vitals, workouts, blood pressure, medication/history, feedback, and risk context.
3. Add forced deterministic routing for `health_plan`, `training readiness`, `tomorrow`, and `intensive training` intents with the minimum context set.
4. Add model-backed plan parsing and validation with fallback to deterministic plans.
5. Replace single-query validation/execution nodes with per-query validation/execution aggregation.
6. Update analysis/output prompts and trace metadata to consume the context package, current time, recent 3-hour/day windows, and deterministic safety hints.
7. Keep existing single-table behavior as a degenerate one-entry plan for simple chartable metric requests.

Rollback can restore the previous single-query graph nodes because no database migration is required by this change.

## Open Questions

- Should `patients_registration` profile fields be included for chat analysis, or kept out until explicit profile requirements are defined?
- What default lookback windows should each context domain use when the user does not specify a time range?
