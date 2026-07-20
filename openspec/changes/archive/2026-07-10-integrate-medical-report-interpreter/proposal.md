## Why

The workspace now contains a separate Patient Results Interpreter project that can upload medical reports, extract report text, analyze findings with an AI assistant, save lab-style values, load saved records, and answer follow-up questions. The current Smart Health app already has a Flutter AI chatbot and a Python FastAPI backend, but it does not yet provide a dedicated report-interpreter workflow.

Directly copying the extracted project would create duplicated backend apps, duplicated model configuration, hard-coded demo patient behavior, generated build artifacts in source control, and a large standalone Flutter `main.dart` that does not match the current feature-first app structure. The integration needs a planned fusion: keep backend concerns isolated from existing APIs, clean the imported frontend first, then extend the current AI chatbot into a multi-module AI surface that can host both the existing health chat and the report interpreter.

## What Changes

- Add a dedicated backend report-interpreter namespace under `src/backend` instead of running the extracted backend as a second FastAPI app.
- Keep imported report-interpreter endpoints isolated from existing assistant, query-tools, demo, and wearable APIs with a stable prefix such as `/report-interpreter`.
- Move report extraction, OCR, report analysis, suggested questions, patient lookup, saved record loading, and lab-value save logic into backend schemas/services/routers that follow the current backend package boundaries.
- Reuse current backend settings, eHospital client helpers, model invocation settings, logging, CORS, and app startup instead of preserving the extracted backend's standalone `localhost:3001` configuration.
- Clean the extracted Flutter project before integration by excluding generated and duplicated folders such as `.dart_tool`, `build`, `.DS_Store`, duplicate platform folders, and Python cache artifacts.
- Convert the extracted Flutter report UI from a standalone app into a feature under `src/app/lib/features/report_interpreter`.
- Extend the current Health Assistant area into an extensible AI module host that supports multiple AI modules, initially:
  - existing health chat
  - medical report interpreter
- Add a report-interpreter frontend repository/API boundary that uses the current `BACKEND_BASE_URL` and shared network/error patterns rather than the extracted `API_BASE_URL=http://localhost:3001` contract.
- Ensure the report interpreter uses the logged-in patient context instead of hard-coded demo patient id `20`.
- Add tests and smoke checks for backend API isolation, report upload behavior, patient-scoped saved records, frontend module switching, and existing chatbot behavior.

## Capabilities

### New Capabilities

- `backend-report-interpreter-api`: Backend API namespace and service boundary for medical report upload, text extraction, AI analysis, suggested follow-up questions, saved record lookup, and optional patient-scoped record saving.
- `flutter-report-interpreter-feature`: Flutter feature module for report upload, saved report loading, report analysis display, follow-up chat, and report-specific session state.
- `ai-chat-module-host`: Extensible Health Assistant surface that can host multiple AI modules while preserving the existing health chat as one module.

### Modified Capabilities

- `backend-backed-ai-assistant`: The existing assistant remains available, but the UI can route users between multiple AI modules rather than assuming one chat experience.
- `flutter-api-layer`: Add a report-interpreter repository/client using the shared backend base URL, common error mapping, and typed response models.
- `flutter-project-structure`: Add a new feature-first report-interpreter module and avoid importing a standalone Flutter app entry point directly.
- `runtime-model-invocation-settings`: Report analysis and follow-up chat should use the current backend model configuration path rather than a separate hard-coded Ollama configuration.

## Impact

- Backend code under `src/backend`, especially:
  - `api/`
  - `schemas/`
  - `services/`
  - `clients/ehospital_client.py`
  - `core/config.py`
  - `main.py`
- Flutter code under `src/app/lib`, especially:
  - `features/health_assistant`
  - new `features/report_interpreter`
  - `data/repositories`
  - `data/models`
  - `core/network`
  - `main.dart` route wiring if a dedicated route is added
  - dashboard entry points if the report interpreter is surfaced outside the assistant tab host
- Flutter dependencies in `src/app/pubspec.yaml`, likely including:
  - `file_selector`
  - `image_picker`
  - `flutter_markdown`
- Python dependencies or environment docs, likely including:
  - `python-multipart`
  - `pillow`
  - `pytesseract`
  - `pypdf`
  - `pdf2image`
  - Tesseract and Poppler as optional system tools for OCR/scanned PDFs
- Tests under `tests/` and `src/app/test/`.
- Documentation and developer commands in `src/app/README.md`, `Makefile`, and `tasks.ps1`.

The change is additive but user-facing: the AI chatbot area will gain a module selector, and the backend will expose a new isolated report-interpreter API namespace.
