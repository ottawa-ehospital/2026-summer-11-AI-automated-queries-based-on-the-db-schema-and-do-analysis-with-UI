## 1. Backend Result Contract

- [x] 1.1 Add Pydantic assistant result models for text and chart payloads.
- [x] 1.2 Add a backend assistant orchestrator interface that returns the shared assistant response contract.
- [x] 1.3 Extend assistant chat responses with an ordered `results` list while preserving `reply`.
- [x] 1.4 Add and document an agent-facing `validate_assistant_result_payload` function for result payload validation and normalization.
- [x] 1.5 Add backend chart result generation for common chart requests with validated non-empty data.

## 2. LangGraph MVP Query Flow

- [x] 2.1 Add a LangGraph-compatible assistant flow for single-table wearable metric chart queries.
- [x] 2.2 Map recent heart-rate requests to a patient-scoped `wearable_vitals` query for `timestamp` and `heart_rate`.
- [x] 2.3 Route graph-produced chart payloads through `validate_assistant_result_payload` before response composition.
- [x] 2.4 Keep the MVP documented as single-table only with no diagnosis, joins, or complex analysis.

## 3. Flutter Result Models

- [x] 3.1 Add Dart models for assistant text and chart result payloads.
- [x] 3.2 Parse backend assistant `results` in the API/data layer with backward-compatible fallback from `reply`.
- [x] 3.3 Store assistant result items on chat messages without breaking existing session serialization.

## 4. Flutter Chart Rendering

- [x] 4.1 Reuse the existing Flutter chart dependency for assistant chart templates.
- [x] 4.2 Add assistant chart result widgets for line and bar display types, and warn without rendering when an unsupported display type is received.
- [x] 4.3 Render structured result items inside assistant message bubbles.

## 5. Verification

- [x] 5.1 Add backend tests for text-only and chart assistant responses.
- [x] 5.2 Add backend tests proving multiple assistant implementations can satisfy the same response contract.
- [x] 5.3 Add backend tests for valid and invalid agent result payload validation.
- [x] 5.4 Add backend tests for the recent heart-rate single-table graph MVP.
- [x] 5.5 Add Flutter tests for result parsing and chat chart rendering.
- [x] 5.6 Run OpenSpec validation, backend tests, and Flutter analyze/tests for touched areas.
