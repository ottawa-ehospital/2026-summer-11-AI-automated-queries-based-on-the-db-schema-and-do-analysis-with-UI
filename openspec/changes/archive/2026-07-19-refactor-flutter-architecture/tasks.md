## 1. Baseline and Structure

- [x] 1.1 Capture current Flutter analyzer/test baseline before refactoring.
- [x] 1.2 Capture current Python backend compile/test baseline before refactoring.
- [x] 1.3 Create target directories under `lib/core`, `lib/data`, and `lib/features`.
- [x] 1.4 Confirm or create target backend directories under `src/backend`.
- [x] 1.5 Add barrel or helper files only where they reduce import noise without hiding ownership.
- [x] 1.6 Document the target frontend/backend architecture in project docs.

## 2. Configuration and Security

- [x] 2.1 Replace scattered runtime constants with typed config helpers in `lib/config`.
- [x] 2.2 Ensure backend URL, eHospital URL, AI provider, model name, and Ollama settings are configurable through Dart defines.
- [x] 2.3 Remove committed secret-like values from tracked Flutter source.
- [x] 2.4 Add backend settings helpers for eHospital URL, model provider, model name, Ollama URL, CORS, host, and port.
- [x] 2.5 Remove or isolate committed secret-like values from Python backend code.
- [x] 2.6 Update `dart_defines.example.json` with safe placeholders and local demo values.
- [x] 2.7 Update README notes explaining that Flutter client values are not secure secret storage.

## 3. Core Network and Error Layer

- [x] 3.1 Add shared API error types under `lib/core/network`.
- [x] 3.2 Add a shared HTTP helper/client for GET/POST JSON requests.
- [x] 3.3 Normalize timeout, status code, JSON parsing, and error message behavior.
- [x] 3.4 Update backend API calls to use the shared network layer.
- [x] 3.5 Update eHospital API calls to use the shared network layer.

## 4. Data Models and Repositories

- [x] 4.1 Add typed or normalized models for assistant chat, vitals summary, trend insights, eHospital user/session, and wearable vitals data.
- [x] 4.2 Add `AssistantRepository` for assistant chat, vitals summaries, and trend insights.
- [x] 4.3 Add `EHospitalRepository` for table reads and wearable vitals uploads.
- [x] 4.4 Add `AuthRepository` or session-facing abstraction for login/current patient lookup.
- [x] 4.5 Keep existing public service method compatibility where needed during migration.

## 5. Python Backend Package Refactor

- [x] 5.1 Move FastAPI app creation into `src/backend/main.py`.
- [x] 5.2 Move assistant router endpoints into `src/backend/api/assistant.py`.
- [x] 5.3 Move request/response Pydantic models into `src/backend/schemas`.
- [x] 5.4 Move remote eHospital HTTP access into `src/backend/clients/ehospital_client.py`.
- [x] 5.5 Move model invocation into `src/backend/clients/model_client.py` or an assistant service boundary.
- [x] 5.6 Move patient context aggregation into `src/backend/services/patient_context_service.py`.
- [x] 5.7 Move assistant chat, vitals summary, and trend insight orchestration into backend service modules.
- [x] 5.8 Keep compatibility shims for existing `src.demo2_api:app` or old assistant backend imports as needed.
- [x] 5.9 Update backend tests to target the new package structure.

## 6. Reusable UI Components

- [x] 6.1 Add shared app card, section header, loading state, empty state, error state, and metric tile widgets.
- [x] 6.2 Add shared or feature-local chart container widgets for vitals/trend presentation.
- [x] 6.3 Replace repeated UI state blocks in high-impact screens with shared components.
- [x] 6.4 Preserve existing app colors, spacing, typography, and interaction style.

## 7. Feature Migration

- [x] 7.1 Move login/auth-related screen logic into `features/auth`.
- [x] 7.2 Move health assistant screen and supporting widgets/controllers into `features/health_assistant`.
- [x] 7.3 Move vitals screen and supporting widgets/controllers into `features/vitals`.
- [x] 7.4 Move trend comparison screen and supporting widgets/controllers into `features/trends`.
- [x] 7.5 Move dashboard/profile/settings screens into feature folders where doing so reduces import or ownership confusion.
- [x] 7.6 Update imports and route references after file moves.

## 8. Screen Responsibility Cleanup

- [x] 8.1 Remove raw HTTP imports from feature screens.
- [x] 8.2 Remove URL construction and JSON response parsing from feature screens.
- [x] 8.3 Remove prompt/AI orchestration logic from feature screens.
- [x] 8.4 Ensure presentation widgets receive data via parameters and do not fetch remote data directly.
- [x] 8.5 Keep loading states, error states, chat history behavior, and visible labels stable.

## 9. Developer Startup Scripts

- [x] 9.1 Update `tasks.ps1` backend commands to use the canonical `src.backend.main:app` entry point.
- [x] 9.2 Update Makefile backend commands to use the canonical `src.backend.main:app` entry point.
- [x] 9.3 Add or align PowerShell and Makefile commands for backend dev, backend run, Flutter backend, Flutter web CORS/backend, and local model checks.
- [x] 9.4 Keep command names and environment variables aligned across PowerShell and Makefile.
- [x] 9.5 Document desktop/web, Android emulator, physical phone, and deployed backend URL examples.

## 10. Verification

- [x] 10.1 Run Python compile checks for backend modules and compatibility shims.
- [x] 10.2 Run backend tests.
- [x] 10.3 Run `flutter pub get`.
- [x] 10.4 Run `flutter analyze` and confirm no new errors are introduced.
- [x] 10.5 Run `flutter test`.
- [x] 10.6 Build Flutter web with backend provider defines.
- [x] 10.7 Manually smoke test backend startup, login, dashboard navigation, Health Assistant, Vitals AI summary, Trend AI insight, and wearable upload entry points.
- [x] 10.8 Run OpenSpec apply status and confirm task progress is accurate.
