## 1. Worktree and Source Inventory

- [x] 1.1 Confirm implementation continues in the dedicated worktree on branch `integrate-urgent-care-queue-dashboard`.
- [x] 1.2 Confirm source project path `/Users/yuyang/Downloads/urgent-care-queue-dashboard-main` is available.
- [x] 1.3 Inventory CareFlow backend endpoints, models, persistence fields, model prompts, queue logic, feedback alert logic, and local fallback behavior from `backend.py`.
- [x] 1.4 Inventory CareFlow patient app flows from `patient_app/lib/main.dart`, including check-in, session storage, status polling, feedback, condition updates, voice input, and completed states.
- [x] 1.5 Inventory CareFlow `flutter_frontend/lib/main.dart` only for backend workflow context and confirm staff web dashboard UI is out of scope.
- [x] 1.6 Create a source-to-target mapping note for backend modules, Flutter patient screens, repository models, routes, and intentionally deferred or excluded source behaviors.
- [x] 1.7 Create a backend behavior parity checklist covering CTAS labels, queue names, statuses, fallback risk scores, prompts, response fields, queue ordering, patient status, feedback alert precedence, and local fallback semantics from CareFlow `backend.py`.
- [x] 1.8 Create a Flutter workflow parity checklist covering the original patient app core workflows.
- [x] 1.9 Verify active eHospital metadata for `patients_registration`, `healthcare_records`, `patient_feedback`, and `medical_history`, including primary keys and fields required by urgent-care persistence.
- [x] 1.10 Document that the staff web dashboard is not migrated into the patient mobile app in this change.

## 2. Backend Schemas and eHospital Client Boundary

- [x] 2.1 Add urgent-care Pydantic request/response schemas for intake, CTAS analysis, patient status, queues, staff actions, feedback, alerts, and health metadata.
- [x] 2.2 Add or extend eHospital client helpers for row updates using `PUT /table/:name/:id` with normalized error handling.
- [x] 2.3 Add urgent-care table metadata validation helpers for required `healthcare_records`, `patient_feedback`, `patients_registration`, and `medical_history` fields, using live `/tables` metadata only and without refreshing or writing `src/backend/ehospital_schema_inventory.json`.
- [x] 2.4 Add urgent-care constants for CTAS labels, queue names, statuses, fallback risk scores, and red-flag terms.
- [x] 2.5 Ensure urgent-care backend code does not construct raw eHospital URLs outside the shared client boundary.

## 3. Shared AI Service Integration

- [x] 3.1 Inventory current shared backend model entry points, including `src/backend/clients/model_client.py`, assistant workflows, health alert analysis, report interpreter, and nutrition monitor model usage.
- [x] 3.2 Decide that urgent-care uses the existing generic `invoke_model`/shared model path and does not introduce urgent-care-specific model provider overrides.
- [x] 3.3 Extend the shared model client only if needed for generic OpenAI-compatible base URL support or JSON parsing support, not for urgent-care-specific settings.
- [x] 3.4 Add tests proving existing assistant, health alert, report interpreter, and nutrition model paths still use their current contracts after any shared model client change.
- [x] 3.5 Add urgent-care model adapter/helper that calls the shared model client and preserves CareFlow's prompt contract and JSON fields.
- [x] 3.6 Add tests for urgent-care model success, model failure, invalid JSON, and fallback behavior through the shared model layer.
- [x] 3.7 Ensure urgent-care service code contains no direct DeepSeek HTTP client calls and no urgent-care-specific model provider/base URL/API key settings.

## 4. Backend Urgent-Care Services

- [x] 4.1 Create `src/backend/services/urgent_care/` package with focused modules for records, queueing, risk analysis, feedback alerts, persistence mapping, and history while preserving CareFlow backend behavior.
- [x] 4.2 Implement patient registration ensure/repair behavior for intake requests with sufficient demographics.
- [x] 4.3 Implement patient history loading from recent healthcare records and linked feedback.
- [x] 4.4 Port CareFlow CTAS labels, queue names, status names, fallback risk scores, and estimated wait semantics without behavior redesign.
- [x] 4.5 Implement deterministic CTAS/risk fallback rules for red-flag symptoms and low-risk symptoms.
- [x] 4.6 Implement model-assisted CTAS analysis that preserves CareFlow's Risk Analysis Agent prompt contract, validates structured JSON, calls the shared model service, and falls back safely when unavailable or invalid.
- [x] 4.7 Implement queue assignment mapping CTAS 1-2 to Emergency Queue, CTAS 3 to Normal Queue, and CTAS 4-5 to Non-Urgent Queue.
- [x] 4.8 Implement active/completed record loading and queue sorting by CTAS level, descending risk score, and check-in time.
- [x] 4.9 Implement CareFlow-compatible patient status payload calculation, including global queue number, patients ahead, estimated wait range, notification state, access token if retained, and submitted information.
- [x] 4.10 Implement staff notify, start-consultation, and complete actions with persisted timestamps and status updates.
- [x] 4.11 Implement feedback persistence linked to the current urgent-care visit.
- [x] 4.12 Implement feedback alert analysis with shared-model result validation and deterministic red-flag fallback taking precedence.
- [x] 4.13 Implement alert listing with de-duplication across local fallback records and eHospital feedback rows if both exist.
- [x] 4.14 Keep any local JSON fallback isolated to development/error fallback behavior and document when it is used.
- [x] 4.15 Complete the backend behavior parity checklist and document any unavoidable API-path or infrastructure-only differences.

## 5. Backend API and Tests

- [x] 5.1 Add `src/backend/api/urgent_care.py` with `/urgent-care` router and health endpoint.
- [x] 5.2 Register the urgent-care router in `src/backend/main.py` without changing existing route prefixes.
- [x] 5.3 Add endpoints for patient check-in, patient status, patient feedback, patient history, queues, patients, alerts, notify, start consultation, and complete visit.
- [x] 5.4 Add backend tests for health route registration and preservation of existing assistant/report/nutrition/wearable routes.
- [x] 5.5 Add tests for intake validation, registration handling, visit persistence payloads, and required-field metadata failures.
- [x] 5.6 Add tests for model CTAS success, invalid model JSON fallback, missing model fallback, red-flag symptom escalation, and queue assignment through the shared model service.
- [x] 5.7 Add tests for queue sorting, summary counts, status payloads, completed visit behavior, and unknown visit errors.
- [x] 5.8 Add tests for staff notify/start/complete actions and eHospital update helper usage.
- [x] 5.9 Add tests for feedback persistence, red-flag feedback alerting, safer fallback precedence, alert listing, and de-duplication.

## 6. Flutter Data Layer

- [x] 6.1 Create `src/app/lib/features/urgent_care/urgent_care.dart` barrel file and feature folders for models, data, screens, widgets, and presentation helpers.
- [x] 6.2 Add Dart models for urgent-care intake, analysis, patient status, feedback, and patient-facing alert acknowledgement data.
- [x] 6.3 Add `UrgentCareRepository` using the existing `ApiClient` and configured backend base URL.
- [x] 6.4 Implement repository methods for health, check-in, status, feedback, and patient history/status needs; do not add staff dashboard repository methods unless needed for patient screens.
- [x] 6.5 Normalize backend errors into screen-consumable messages through the repository rather than widget-level raw HTTP parsing.
- [x] 6.6 Add repository tests or fakes covering endpoint paths, request payloads, patient id handling, response parsing, and error mapping.

## 7. Flutter Patient Urgent-Care Screens

- [x] 7.1 Add patient check-in screen using active patient id by default and collecting symptoms plus optional medical history.
- [x] 7.2 Add local validation for required patient check-in fields before backend submission.
- [x] 7.3 Add loading, success, validation error, backend error, and retry states for check-in.
- [x] 7.4 Add patient status screen showing queue number, status, patients ahead, estimated wait, notification state, check-in time, CTAS/risk, queue name, submitted symptoms, clinical summary, and recommended action.
- [x] 7.5 Add status refresh behavior with manual refresh or polling while preserving last known status on transient errors.
- [x] 7.6 Add completed visit state that stops or reduces active polling.
- [x] 7.7 Add patient feedback and condition-update UI linked to the active urgent-care visit.
- [x] 7.8 Add patient-facing acknowledgement for feedback and alert-required responses without diagnostic or treatment-order wording.
- [x] 7.9 Rebuild CareFlow patient app behaviors with DTI6302 app cards, typography, spacing, buttons, snackbars, and state views.
- [x] 7.10 Verify patient app functional parity for check-in, review, active status, polling/refresh, called/completed states, condition update, and app feedback.

## 8. Flutter Staff Dashboard Exclusion

- [x] 8.1 Do not create staff queue dashboard screens, staff action controls, completed staff history screens, or staff alert review screens in the DTI6302 mobile app.
- [x] 8.2 Ensure `flutter_frontend/lib/main.dart` is not copied or rebuilt as a mobile route.
- [x] 8.3 Verify any backend staff/queue endpoints are not exposed through mobile staff UI in this change.
- [x] 8.4 Document that web/staff/admin UI is out of scope for this change, which only integrates the customer/patient mobile experience.

## 9. Flutter Routing and Entry Points

- [x] 9.1 Register urgent-care routes in `src/app/lib/main.dart` or the existing route structure.
- [x] 9.2 Add a patient-facing urgent-care entry point from the dashboard or emergency area according to the documented decision.
- [x] 9.3 Ensure no staff-dashboard route or entry point is added to the patient mobile app.
- [x] 9.4 Preserve existing route behavior for dashboard, emergency SOS, assistant, vitals, goals, trends, profile, settings, and devices.
- [x] 9.5 Add widget tests for patient check-in/status, patient feedback, route entry behavior, absence of staff route, and existing route preservation where practical.

## 10. Documentation and Verification

- [x] 10.1 Update README or app runbook with urgent-care purpose, backend route prefix, source project path, local run steps, and the requirement that model calls use the existing shared AI service configuration.
- [x] 10.2 Document that CareFlow backend logic is ported into DTI6302's single backend, the CareFlow patient app is source material for the mobile module, and web/staff/admin UI is not part of this change.
- [x] 10.3 Document required eHospital table fields and the behavior when fields are unavailable.
- [x] 10.4 Document urgent-care clinical safety constraints and decision-support wording.
- [x] 10.5 Run Python compile checks for changed backend modules.
- [x] 10.6 Run backend tests covering urgent-care API/services, shared AI service integration, existing AI regression coverage, and route registration.
- [x] 10.7 Run `flutter pub get` if dependencies change.
- [x] 10.8 Run `flutter analyze`.
- [x] 10.9 Run targeted Flutter tests for urgent-care repositories and screens.
- [ ] 10.10 Smoke test patient check-in, queue status refresh, patient feedback, called/completed status display when backend state changes, and alert acknowledgement display.
- [x] 10.11 Complete a CareFlow source-to-target parity checklist covering backend workflow, patient app workflow, persistence, alerts, API path adaptations, and excluded web/staff/admin UI behavior.
- [x] 10.12 Complete a UI style checklist confirming urgent-care screens use DTI6302 visual patterns and do not import standalone CareFlow app shells or generated platform artifacts.
- [x] 10.13 Create an API module map that identifies existing backend modules, planned urgent-care customer endpoints, backend-only workflow endpoints, eHospital table boundaries, and routes that must not be exposed through the mobile UI.
