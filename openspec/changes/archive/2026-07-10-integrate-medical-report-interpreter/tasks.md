## 1. Worktree and Source Inventory

- [x] 1.1 Create and switch to a dedicated Git worktree on branch `integrate-medical-report-interpreter` before implementation.
- [x] 1.2 Locate the extracted `2026-winter-blood-work-and-medical-report-interpreter-develop` source directory in the workspace and record the source paths used for migration.
  - Source directory: `/Users/yuyang/Downloads/2026-winter-blood-work-and-medical-report-interpreter-develop`
- [x] 1.3 Inventory extracted backend files and identify canonical source files, preferring one backend copy if both `server/` and `frontend/server/` exist.
  - Canonical backend source: `/Users/yuyang/Downloads/2026-winter-blood-work-and-medical-report-interpreter-develop/server`
  - `server/` and `frontend/server/` differ only by Python cache artifacts.
- [x] 1.4 Inventory extracted Flutter files and identify only feature source files needed for migration.
  - Canonical Flutter source: `/Users/yuyang/Downloads/2026-winter-blood-work-and-medical-report-interpreter-develop/frontend/flutter_testanalyzer/lib`
  - Dependency/reference files: `frontend/flutter_testanalyzer/pubspec.yaml`, `README.md`, and `INTEGRATION.md`.
- [x] 1.5 Exclude generated or duplicate extracted artifacts from integration scope: `.dart_tool*`, `build*`, `.DS_Store`, duplicate platform folders, `__pycache__`, and standalone app-only metadata.
  - Excluded: `.dart_tool 2`, `build 2`, `.DS_Store`, `.idea`, duplicate `android 2`/`ios 2`, Python `__pycache__`, standalone platform folders, and generated web output.
- [x] 1.6 Confirm current baseline checks before edits: Python compile/tests and Flutter analyze/test where practical.
  - `python3 -m py_compile src/backend/main.py src/backend/clients/ehospital_client.py src/backend/core/config.py` passed.
  - `python3 -m pytest ...` could not run because this local Python environment has no `pytest` module.
  - `cd src/app && flutter analyze` passed with no issues.

## 2. Backend API Namespace and Contracts

- [x] 2.1 Add `src/backend/schemas/report_interpreter.py` with request/response models for chat, follow-up questions, patients, report assignment, analysis result, lab value visuals, test types, and saved records.
- [x] 2.2 Add `src/backend/api/report_interpreter.py` with router prefix `/report-interpreter`.
- [x] 2.3 Register the report interpreter router in `src/backend/main.py` without changing existing assistant/query/wearable/demo routes.
- [x] 2.4 Add a report-interpreter health endpoint that confirms the unified backend is serving the feature.
- [x] 2.5 Ensure old extracted `/api/*` paths are not introduced into the current backend route tree.

## 3. Backend Service Migration

- [x] 3.1 Add `src/backend/services/report_interpreter/` package with focused modules for prompts, extraction, lab values, patients, saved records, analysis, and suggestions.
- [x] 3.2 Migrate prompt-building logic from the extracted backend into prompt helpers with non-diagnostic medical safety wording preserved.
- [x] 3.3 Migrate text extraction for text, JSON, text-based PDF, image, and scanned PDF inputs into an extraction service.
- [x] 3.4 Add OCR capability detection for Tesseract and Poppler and return clear degraded errors when OCR is unavailable on local machines.
- [x] 3.5 Migrate lab-value parsing, normal-range parsing, report-date extraction, report-type detection, and lab-value merging into lab-value services.
- [x] 3.6 Migrate patient lookup, patient creation, patient assignment, and patient response formatting into patient services.
- [x] 3.7 Migrate saved record type/date/result loading into saved-record services.
- [x] 3.8 Migrate follow-up question generation with deterministic fallback questions when model output is invalid or unavailable.
- [x] 3.9 Ensure analysis can return useful results even if optional database saving fails, with save errors included in the response.

## 4. Backend Client and Model Integration

- [x] 4.1 Replace extracted `database_api.py` usage with current `src.backend.clients.ehospital_client` helpers.
- [x] 4.2 Add any missing eHospital helper methods needed for table row creation or SQL selection while keeping all remote database access in backend clients.
- [x] 4.3 Replace extracted direct `OLLAMA_URL` / `OLLAMA_MODEL` globals with current backend settings and model invocation helpers.
- [x] 4.4 Ensure report interpreter model calls use the same configured model provider path as the existing assistant where feasible.
- [x] 4.5 Add configuration for report interpreter limits such as max context characters and OCR thresholds in backend settings if they should be environment-tunable.
- [x] 4.6 Ensure backend logging captures report interpreter requests through the existing middleware and logs useful service-level failures without leaking uploaded file contents.

## 5. Backend Tests

- [x] 5.1 Add tests proving `/report-interpreter/health` works and existing `/assistant/chat` route remains registered.
- [x] 5.2 Add tests for text or JSON report upload using mocked model invocation and mocked eHospital writes.
- [x] 5.3 Add tests for unsupported file type rejection.
- [x] 5.4 Add tests for text-based PDF extraction if test fixtures are practical, or isolate extraction unit tests with small generated fixture content.
- [x] 5.5 Add tests for OCR-unavailable degraded behavior without requiring Tesseract or Poppler in CI.
- [x] 5.10 Add or document a production-like OCR smoke check that verifies image/scanned-PDF extraction when Tesseract and Poppler are installed.
- [x] 5.6 Add tests for patient-scoped saved record date/result endpoints.
- [x] 5.7 Add tests for suggested question fallback when model output is invalid JSON.
- [x] 5.8 Add tests ensuring hard-coded demo patient id is not used when a patient id is supplied.
- [x] 5.9 Add tests for database save failure returning analysis plus save warnings rather than failing the whole analysis.

## 6. Flutter Dependencies and Data Layer

- [x] 6.1 Add required Flutter dependencies to `src/app/pubspec.yaml`, likely `file_selector`, `image_picker`, and `flutter_markdown`.
- [x] 6.2 Add report interpreter models under `src/app/lib/features/report_interpreter/models` or shared data models if cross-feature use is needed.
- [x] 6.3 Add `ReportInterpreterRepository` using `ApiClient` and `ApiConfig.backendBaseUrl`.
- [x] 6.4 Map repository endpoints to `/report-interpreter/*`, not the extracted `/api/*` paths.
- [x] 6.5 Support multipart upload through the repository or shared network layer with normalized error handling.
- [x] 6.6 Ensure repository methods accept active patient id and do not default to patient `20`.
- [x] 6.7 Add repository tests or fakes for endpoint paths, request payloads, multipart fields, and error mapping where practical.

## 7. Flutter Report Interpreter Feature

- [x] 7.1 Create `src/app/lib/features/report_interpreter/report_interpreter.dart` barrel file.
- [x] 7.2 Create `ReportInterpreterScreen` under `features/report_interpreter/screens`.
- [x] 7.3 Split extracted standalone UI into feature-local widgets for upload controls, saved record selectors, analysis messages, lab value visuals, suggested questions, and empty/loading/error states.
- [x] 7.4 Replace extracted standalone app shell/sidebar assumptions with host-app-compatible layout.
- [x] 7.5 Restyle migrated widgets to use current app theme, spacing, cards, and typography conventions.
- [x] 7.6 Wire report upload, analysis display, follow-up chat, suggested questions, saved record loading, and patient assignment flows to the repository.
- [x] 7.7 Add clear medical disclaimer and non-diagnostic wording consistent with existing health assistant tone.
- [x] 7.8 Add screen/widget tests for initial state, upload pending state, analysis result rendering, suggested question taps, and saved record controls where practical.

## 8. AI Chat Module Host

- [x] 8.1 Extract the existing health chat body from `HealthAssistantScreen` into a reusable `HealthChatModule` or equivalent widget.
- [x] 8.2 Add an AI module model/registry that can describe available modules with id, label, icon, and builder.
- [x] 8.3 Convert the `/assistant` route from direct chat entry into an AI module host screen with a responsive module selector.
- [x] 8.4 Register the existing Health Chat module as the default module using the current chat UI and existing assistant backend API path.
- [x] 8.5 Register the Report Interpreter module as a second module using the migrated report UI and new `/report-interpreter/*` backend API path.
- [x] 8.6 Pass logged-in patient context from the host/session layer into modules that need it.
- [x] 8.7 Preserve existing health chat history, new-chat, send-message, login-required, and error behavior.
- [x] 8.8 Add tests or smoke checks proving module switching does not erase existing health chat state unexpectedly within one screen session.
- [x] 8.9 Keep module selection session-local only; do not add cross-session persistence for the last selected AI module.

## 9. Navigation and Entry Points

- [x] 9.1 Keep existing `/assistant` route working as the main AI entry point, but make it show Chat vs Report Interpreter selection instead of immediately showing only the chat conversation.
- [x] 9.2 Decide whether to add a dedicated `/report-interpreter` route for deep linking; if added, route it to the same module or feature screen without duplicating state logic.
- [x] 9.3 Optionally add a dashboard card or action that opens the AI host with the Report Interpreter module selected.
- [x] 9.4 Ensure mobile and web layouts expose the module selector without text overflow or overlapping controls.
- [x] 9.5 Ensure browser/mobile backend URL examples still use `BACKEND_BASE_URL`, not a separate `API_BASE_URL`.

## 10. Documentation and Developer Workflow

- [x] 10.1 Update `src/app/README.md` with the report interpreter module, unified backend prefix, and local run instructions.
- [x] 10.2 Document local OCR prerequisites and degraded behavior: Tesseract and Poppler are optional for local text/PDF-only development but required for full scanned-PDF/image parity.
- [x] 10.3 Update `Makefile`, `tasks.ps1`, or deployment notes so production-like workflows install or verify OCR dependencies instead of silently dropping original scanned-report/image functionality.
- [x] 10.4 Document that the extracted standalone backend is no longer run separately after integration.
- [x] 10.5 Document any model-provider recommendations or runtime settings for report analysis.

## 11. End-to-End Verification

- [x] 11.1 Run Python compile checks for changed backend modules.
- [x] 11.2 Run backend tests covering existing assistant behavior and new report-interpreter behavior.
- [x] 11.3 Run `flutter pub get` after dependency updates.
- [x] 11.4 Run `flutter analyze`.
- [x] 11.5 Run Flutter tests.
- [x] 11.6 Smoke test backend startup with the unified FastAPI app.
- [x] 11.7 Smoke test existing Health Chat module.
- [x] 11.8 Smoke test Report Interpreter with a text or JSON report.
- [x] 11.9 Smoke test PDF/image paths with OCR/PDF tools in at least one production-like or fully provisioned local workflow; if the current developer machine lacks OCR tools, record the local limitation separately.
- [x] 11.10 Smoke test saved record loading and patient-scoped behavior for a logged-in patient.
