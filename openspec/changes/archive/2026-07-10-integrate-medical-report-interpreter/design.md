## Context

The current project is already organized as a Flutter app under `src/app` and a canonical FastAPI backend under `src/backend/main.py`. Existing backend routers are registered as distinct modules such as assistant, query tools, demo, and wearables. The existing Flutter Health Assistant screen is a single-purpose chat UI backed by `AiService` and `AssistantRepository`.

The extracted Patient Results Interpreter project is a separate Flutter + FastAPI application. Its backend is concentrated in a large `server/app.py` with routes under `/api/*`, direct Ollama configuration, OCR/PDF extraction helpers, database helper functions, and a hard-coded demo patient id. Its Flutter app is concentrated mostly in a large `lib/main.dart`, with reusable models and API client files already separated enough to serve as a migration starting point.

The integration should treat the extracted code as source material, not as a drop-in subtree.

## Goals / Non-Goals

**Goals:**

- Integrate report-interpreter backend behavior into the current FastAPI app under an isolated API namespace.
- Preserve existing Smart Health backend routes and Flutter assistant behavior.
- Reuse current backend configuration, eHospital client helpers, model invocation configuration, logging, and startup commands.
- Clean imported frontend code before merging and avoid committing generated artifacts.
- Add a report-interpreter Flutter feature that follows current feature-first structure.
- Refactor the existing AI chatbot surface into an extensible module host before adding the report interpreter UI.
- Keep Health Chat and Report Interpreter as separate AI modules with separate UI/state ownership.
- Use the logged-in patient id for report analysis, saved records, and optional persistence.
- Preserve the extracted report interpreter's existing file-analysis capabilities, including PDF/image/scanned-report flows that depend on OCR tooling.
- Provide tests and smoke checks that make the integration safe to implement incrementally.

**Non-Goals:**

- Replace the existing health assistant with the report interpreter.
- Preserve the extracted app's standalone route names, app shell, or `API_BASE_URL` naming exactly.
- Run a second backend server on port `3001` after integration.
- Redesign the entire Smart Health visual system.
- Guarantee OCR support when host system tools such as Tesseract or Poppler are absent from a developer's local machine.
- Build full clinical diagnosis logic; report responses must remain explanatory, non-diagnostic, and doctor-follow-up oriented.

## Decisions

### Decision 1: Isolate imported backend routes under `/report-interpreter`

The backend will expose report-interpreter endpoints under a dedicated prefix, for example:

```text
GET  /report-interpreter/health
GET  /report-interpreter/patients
POST /report-interpreter/patients
POST /report-interpreter/reports/assign-patient
POST /report-interpreter/analyze-file
POST /report-interpreter/chat
POST /report-interpreter/suggest-questions
GET  /report-interpreter/test-types
GET  /report-interpreter/tests/{test_type}/dates
GET  /report-interpreter/tests/{test_type}/{test_date}
```

Rationale: the extracted backend uses generic `/api/*` routes that would collide conceptually with the current backend and make ownership unclear. A report-specific namespace lets the feature evolve independently while still sharing the same FastAPI process.

Alternative considered: preserve `/api/*` route names for minimal frontend changes. Rejected because it makes the imported backend look like the root API and increases collision risk.

### Decision 2: Split backend code into router, schemas, and services

Target structure:

```text
src/backend/
  api/report_interpreter.py
  schemas/report_interpreter.py
  services/report_interpreter/
    __init__.py
    analysis.py
    extraction.py
    lab_values.py
    patients.py
    prompts.py
    saved_records.py
    suggestions.py
```

The FastAPI router should only parse request/response boundaries and delegate to services. Pydantic request/response models belong in schemas. OCR/PDF/text extraction belongs in extraction services. Patient and eHospital table operations belong behind service functions that call the existing eHospital client.

Rationale: this follows the current backend architecture and prevents the imported `app.py` from becoming another monolith.

Alternative considered: copy `server/app.py` as `src/backend/api/report_interpreter.py`. Rejected because it would mix routing, prompting, OCR, database access, and model calls in one file.

### Decision 3: Reuse current backend clients and model settings

Report interpreter services should use:

- `src.backend.clients.ehospital_client` for table reads/writes and SQL select calls.
- `src.backend.core.config.settings` for eHospital URL, model URL, model name, CORS, host, and port.
- Existing model invocation helpers or a small shared model-client adapter rather than direct `OLLAMA_URL` globals.
- Existing request logging by registering the router in `src/backend/main.py`.

Rationale: one backend configuration path keeps local web, emulator, physical device, and deployment behavior consistent.

Alternative considered: keep `database_api.py` and direct `OLLAMA_URL` logic. Rejected because it duplicates clients and model configuration already owned by the current backend.

### Decision 4: Preserve OCR/PDF/image extraction and make production-like OCR explicit

The extraction service will support:

- UTF-8 text and JSON files.
- Text-based PDFs using `pypdf`.
- Images and scanned PDFs through OCR when dependencies are present.
- Clear failure or degraded messages when OCR tools are not installed.

The original extracted app's report-reading behavior must not disappear during integration. Tesseract/Poppler may still be optional on an individual developer's local machine, but production-like runbooks or deployment scripts should install them or perform an explicit startup/deployment check that reports OCR as unavailable.

Rationale: local environments may not always have Tesseract/Poppler, but the integrated app should preserve the original report interpreter feature set. Text-based PDFs should continue working without OCR, while scanned PDFs and images should remain supported in environments that are meant to demonstrate or deploy the complete feature.

Alternative considered: document OCR only as optional local setup. Rejected because it would quietly drop existing scanned-report/image functionality in production-like environments.

### Decision 5: Clean imported frontend before feature migration

Only source files needed for the feature should be migrated. Generated or duplicated artifacts must be excluded:

- `.dart_tool*`
- `build*`
- `.DS_Store`
- duplicate `android 2` / `ios 2` folders
- Python `__pycache__`
- standalone app metadata not needed by `src/app`

Rationale: the extracted project includes build products and duplicate platform folders that should not become part of the main app.

Alternative considered: copy the entire extracted Flutter project into `src/app`. Rejected because the host app already has its own Flutter project and platform folders.

### Decision 6: Convert report UI into a feature module

Target frontend structure:

```text
src/app/lib/features/report_interpreter/
  report_interpreter.dart
  models/
  data/
    report_interpreter_repository.dart
  screens/
    report_interpreter_screen.dart
  widgets/
  presentation/
```

Large widget code from the extracted `main.dart` should be split around natural responsibilities: session state, upload controls, saved record selectors, analysis result rendering, follow-up question chips, and report chat messages.

Rationale: this keeps the imported feature aligned with the already-refactored Smart Health app and makes future maintenance possible.

Alternative considered: import `results_interpreter_feature.dart` and use the extracted `ResultsHomePage` directly. This may be useful as a temporary spike, but it should not be the final integrated shape because it preserves standalone app assumptions and a large single-file UI.

### Decision 7: Replace direct assistant chat entry with an AI module selection host

The current `/assistant` route currently opens directly into a chat conversation. It should instead open an AI module host where the user chooses between separate AI experiences. Initial modules:

```text
Assistant Route (/assistant)
├─ Health Chat
│  ├─ UI: existing HealthAssistantScreen chat experience
│  └─ API: existing assistant backend APIs such as /assistant/chat
└─ Report Interpreter
   ├─ UI: migrated report interpreter experience from the extracted app
   └─ API: new isolated report interpreter APIs under /report-interpreter/*
```

The host may use a segmented control, tab bar, or compact module selector depending on viewport width. Existing health chat logic should remain in its own widget/screen and be embedded as the Chat module. The report interpreter should remain a distinct module with its own upload/report UI and feature state. The host should default to Health Chat when opened and does not need to remember the user's last selected module across app sessions.

Rationale: the user-facing AI area becomes extensible while keeping modules visually and behaviorally separate. This also leaves room for future AI modules such as medication review, trend analysis, or emergency preparation.

Alternative considered: add a separate `/report-interpreter` route only. Rejected as the only entry point because the requirement specifically calls for changing the AI chatbot page into a choice between Chat and Report Interpreter. A separate route may still be added for deep linking or dashboard cards.

### Decision 8: Use logged-in patient context, not demo patient defaults

Flutter should derive patient id from the same session storage used by the existing assistant. Backend requests should require or accept the active patient id explicitly. The hard-coded extracted default `20` should only survive in tests or fixtures.

Rationale: report analysis, saved records, and lab-value persistence must be patient-scoped in the integrated app.

Alternative considered: keep `20` as a fallback. Rejected because it risks saving or reading report data for the wrong patient.

### Decision 9: Persistence is explicit and defensively handled

The report interpreter may save parsed lab values to eHospital tables only when the backend has a resolved patient id or the user completes patient assignment. Save failures should not block returning the analysis; they should be returned as warnings/details in the response.

Rationale: AI analysis and database persistence have different failure modes. Users should still receive report interpretation when persistence fails.

Alternative considered: fail the whole analysis if saving fails. Rejected because it makes the main value depend on optional persistence.

### Decision 10: Verify with isolated backend tests and module-host frontend tests

Backend tests should instantiate the existing FastAPI app and assert the new namespace works without breaking existing assistant endpoints. Frontend tests should verify module switching and repository paths without requiring live OCR or model calls.

Rationale: this change touches both backend routing and the assistant UI shell, so both isolation and regression tests matter.

## Risks / Trade-offs

- The extracted `server/app.py` has many helper functions and route behaviors intertwined -> mitigate by migrating service-by-service and adding tests around behavior before deeper cleanup.
- OCR dependencies may be unavailable in CI or on developer machines -> make OCR capability checks explicit, test degraded paths, and install or verify OCR tools in production-like workflows so original scanned-report/image behavior is preserved.
- Report interpreter UI is large and may not match current design language -> first preserve function, then refactor widgets and styling to current theme.
- Existing health chat may regress while being embedded in a module host -> keep the existing health chat widget intact and add host-level tests.
- Generic route names from the extracted app may leak into frontend repositories -> centralize endpoint paths in `ReportInterpreterRepository`.
- Model prompts are medical-adjacent and high-stakes -> keep non-diagnostic wording, include doctor-consultation guidance, and avoid expanding into diagnosis claims.
- Saving parsed lab values from unstructured reports can be imperfect -> return save warnings, require patient scoping, and keep parsed values reviewable in the UI.

## Migration Plan

1. Create a dedicated Git worktree and branch named `integrate-medical-report-interpreter` before implementation, per repository instructions.
2. Inventory the extracted project location and identify only source files needed for migration.
3. Add/adjust ignore rules or remove generated extracted artifacts from the integration scope.
4. Add backend schemas and service modules for report interpreter data contracts.
5. Migrate backend helper logic from extracted `server/app.py` into focused services.
6. Replace extracted database helper calls with current eHospital client helpers.
7. Replace direct model invocation globals with current backend model configuration/invocation helpers.
8. Add the `/report-interpreter` router and include it in `src/backend/main.py`.
9. Add backend tests for health check, text analysis, unsupported file handling, suggested questions fallback, saved record loading, and route isolation.
10. Add Flutter dependencies required by the report feature.
11. Add report interpreter models and repository using `BACKEND_BASE_URL`.
12. Split and migrate the extracted report UI into `features/report_interpreter`.
13. Refactor existing Health Assistant route into a module host with Health Chat as the first module.
14. Add the Report Interpreter as a separate second module and pass active patient context to it.
15. Optionally add dashboard/deep-link entry to open the AI host directly on the report module.
16. Update docs and startup/deployment commands to describe and verify OCR prerequisites while keeping local degraded behavior understandable.
17. Run backend tests, Python compile checks, `flutter pub get`, `flutter analyze`, Flutter tests, and manual smoke tests.

Rollback strategy: the integration is additive. The report-interpreter router can be unregistered and the AI module host can default back to Health Chat if the new feature needs to be disabled. Existing assistant backend and UI should remain independently functional.

## Open Questions

- Should report analysis automatically save parsed lab values by default, or should users confirm before persistence?
- Should the report interpreter be reachable from dashboard as a separate card in addition to the AI chatbot module selector?
- Which model provider should be the recommended default for report analysis: current app default, a report-specific model name, or runtime-selected model invocation settings?
