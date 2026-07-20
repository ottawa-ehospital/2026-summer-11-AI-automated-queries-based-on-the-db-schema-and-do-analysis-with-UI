## 1. Query Plan Models

- [x] 1.1 Add backend schema types or typed helpers for context-plan query entries, required/optional markers, query ids, purpose labels, and aggregated context-package metadata.
- [x] 1.2 Define the allowlisted health context domains and table-to-field defaults for wearable vitals, workout history, vitals history, history, diagnosis, prescriptions, feedback, and risk/AI analysis.
- [x] 1.3 Add deterministic context-plan builders for simple metric requests, exercise planning, blood-pressure/medication-sensitive questions, workout-history questions, and broad health-report requests.
- [x] 1.4 Add forced deterministic multi-table planning for `health_plan`, `training readiness`, `tomorrow`, and `intensive training` intents with at least `wearable_vitals`, `vitals_history`, `diagnosis`, `medical_history`, `prescription_form`, and `wearable_workouts`.

## 2. Backend Query Tool Support

- [x] 2.1 Add validation helpers for bounded multi-query plans that validate each Sigma payload independently and preserve query id/table-specific errors.
- [x] 2.2 Add conversion helpers that turn validated multi-query entries into patient-scoped `TableQueryRequest` objects using existing patient-scope enforcement.
- [x] 2.3 Add execution/result aggregation helpers that return per-query table name, row count, selected fields, SQL metadata, replacements metadata, rows, and no-data status.
- [x] 2.4 Cover invalid table, invalid field, unsafe patient scoping, optional no-data, and valid multi-query conversion cases with backend unit tests.

## 3. LangGraph Workflow Integration

- [x] 3.1 Extend `HealthDataQueryState` to store context plans, normalized query entries, per-query errors, context packages, missing-context reasons, and per-table row counts.
- [x] 3.2 Replace the single `build_query_node` behavior with context-plan construction while keeping one-entry plans for simple metric/chart requests.
- [x] 3.3 Ensure the forced training-readiness table set can produce empty-source missing-context records without failing the whole workflow.
- [x] 3.4 Replace single-query validation/revision routing with per-entry validation and bounded revision behavior for required entries.
- [x] 3.5 Replace single-query execution with multi-query execution that continues past optional missing/no-data sources and falls back only for required unrecoverable failures.
- [x] 3.6 Update trace metadata to include selected tables, query ids, row counts, missing-context reasons, validation attempts, execution status, fallback stage, and model provider.

## 4. Analysis and Output Generation

- [x] 4.1 Build a compact context package grouped by source table/domain with capped rows, source summaries, freshness hints, and missing-context details.
- [x] 4.2 Add current backend time, recent 3-hour window, recent one-day window, history, medication, symptom, vitals, and workout framing to training-readiness analysis prompts.
- [x] 4.3 Add deterministic safety hints for sleep under 4 hours, high blood pressure, and symptom evidence, and require conservative intensive-training advice when triggered.
- [x] 4.4 Update model-backed analysis prompts to reason over combined context, cite source tables, distinguish evidence from missing context, and avoid unsupported medication/history claims.
- [x] 4.5 Update no-data and partial-data handling so one empty optional or forced-empty context table does not force fallback when other patient context exists.
- [x] 4.6 Keep chart output generation limited to chartable numeric/time-series sources and preserve existing result validation gates.

## 5. Tests and Validation

- [x] 5.1 Add LangGraph workflow tests for exercise advice using wearable vitals plus workout context.
- [x] 5.2 Add workflow tests for medication-sensitive questions using measurements plus medication/history context.
- [x] 5.3 Add workflow tests proving `health_plan`, `training readiness`, `tomorrow`, and `intensive training` intents include the forced minimum table set.
- [x] 5.4 Add workflow tests for optional table no-data/unavailable behavior, forced-table empty behavior, and required-query validation failure behavior.
- [x] 5.5 Add training safety hint tests for sleep under 4 hours, high blood pressure, and symptom evidence.
- [x] 5.6 Add trace metadata tests for selected tables, per-table row counts, missing-context reasons, and fallback stages.
- [x] 5.7 Run the relevant backend test suite and `openspec validate add-multi-table-health-context-analysis --strict`.
