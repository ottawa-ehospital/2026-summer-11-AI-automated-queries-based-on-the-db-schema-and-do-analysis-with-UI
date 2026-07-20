## Why

The downloaded CareFlow urgent-care prototype provides a useful CTAS-style intake, queue prioritization, patient wait-status, and operational queue workflow, but it currently lives as a separate FastAPI app plus two separate Flutter apps under Downloads. Integrating it into DTI6302 will make the patient-facing urgent-care experience part of the existing Smart Health mobile app and Python backend while leaving the standalone staff web dashboard out of scope.

## What Changes

- Port the CareFlow backend business logic from `/Users/yuyang/Downloads/urgent-care-queue-dashboard-main/backend.py` into DTI6302's FastAPI backend as faithfully as possible, changing API paths and framework wiring only where needed to keep a single backend service.
- Add backend support for patient check-in, CTAS/risk analysis, three-queue prioritization, active/completed patient lists, patient status polling, consultation actions, patient feedback, feedback alerting, and patient visit history.
- Keep CareFlow's workflow decisions, data transformations, CTAS queue mapping, fallback safety behavior, patient status semantics, feedback alert semantics, and response content while adapting transport/persistence calls to DTI6302 backend boundaries.
- Reuse DTI6302's existing eHospital client, backend AI/model service, logging, CORS, and test structure for integration plumbing, but do not redesign the urgent-care backend workflow beyond what is required to run inside the single backend.
- Route urgent-care model calls through the shared backend AI service/model client instead of direct DeepSeek HTTP calls; extend that shared layer if needed while preserving existing AI features.
- Migrate the CareFlow Flutter patient app functionality into one new DTI6302 mobile module, not as a dropped-in standalone Flutter project.
- Add patient-facing urgent-care check-in/status/feedback screens reachable from the existing app shell, with the current logged-in patient used by default.
- Do not migrate the CareFlow staff web dashboard UI from `flutter_frontend`; this change only integrates the customer/patient mobile experience.
- Preserve the source prototype's decision-support safety framing and CTAS-style fallback rules while adapting API paths, layout, persistence wiring, and routing to DTI6302 conventions.
- Do not introduce breaking changes to existing assistant, emergency SOS, wearable, report interpreter, nutrition monitor, or eHospital login flows.

## Capabilities

### New Capabilities

- `backend-urgent-care-queue-api`: Backend API contract for a faithful single-backend port of CareFlow urgent-care intake, CTAS/risk analysis, queue prioritization, patient status, staff actions, patient feedback, alerting, and eHospital persistence.
- `flutter-urgent-care-queue-feature`: Flutter feature contract for a new DTI6302 mobile module whose patient check-in/status/feedback functionality matches the original CareFlow patient app while using the current mobile app visual style.

### Modified Capabilities

- `flutter-project-structure`: The Flutter app must expose the urgent-care feature through the existing application routing and feature-first organization rather than a separate standalone Flutter app.

## Impact

- Source reference: `/Users/yuyang/Downloads/urgent-care-queue-dashboard-main`.
- Backend: new urgent-care router, schemas, and services under `src/backend`; registration in `src/backend/main.py`; faithful port of CareFlow backend logic with only endpoint/path, async/client-boundary, shared-AI-service, and single-backend integration changes.
- Flutter app: new `src/app/lib/features/urgent_care` module, route registration in `src/app/lib/main.dart`, dashboard/emergency entry points, repositories/models using the existing `ApiClient`, with feature parity against the original urgent patient app only.
- Database/API: read/write live eHospital tables including `patients_registration`, `healthcare_records`, `patient_feedback`, and `medical_history`; urgent-care schema checks use live `/tables` metadata and do not maintain `src/backend/ehospital_schema_inventory.json`.
- Configuration: urgent-care model analysis uses the existing generic runtime model settings (`AI_MODEL_PROVIDER`, `AI_MODEL_NAME`, and related shared model-client configuration) only, with deterministic rule-based fallback where model output is unavailable or unsafe.
- API documentation: `api-module-map.md` groups existing and planned endpoints by module, identifies urgent-care customer vs backend-only workflow routes, and documents that urgent-care mobile UI must not expose staff/web/admin surfaces.
- Tests and docs: backend service/API tests, Flutter repository/widget tests, README/runbook updates, explicit API module documentation, and source-to-target parity notes for the CareFlow backend and patient app; document that staff web dashboard migration is intentionally out of scope.
