## Why

The Flutter app currently mixes UI rendering, API calls, runtime configuration, prompt/AI orchestration glue, and feature state inside large screen files. The Python backend that was extracted earlier also needs cleaner ownership boundaries under `src/backend`, and the project startup scripts now need to coordinate frontend, backend, and model-provider modes consistently.

This change introduces a clearer full-stack architecture so Flutter screens remain focused on user interaction, the backend has stable router/service/config boundaries, and developer commands can reliably launch the right combination of services.

## What Changes

- Reorganize Flutter code under feature-oriented and shared-layer directories:
  - `config/` for runtime configuration and environment-derived settings.
  - `core/network/` for shared HTTP client, API errors, request helpers, and response parsing.
  - `core/widgets/` for reusable UI primitives such as cards, section headers, loading states, empty states, error states, metric tiles, and chart containers.
  - `data/models/` for typed response/domain models.
  - `data/repositories/` for eHospital, assistant backend, auth/session, and wearable data access.
  - `features/<feature>/` for screens, widgets, and controllers belonging to one user-facing area.
- Move raw HTTP calls, repeated URL construction, JSON parsing, and API error handling out of screen widgets.
- Consolidate runtime configuration so backend URLs, AI provider selection, model settings, and eHospital configuration are accessed through typed config helpers.
- Remove hard-coded secrets from Flutter source and document safe configuration using Dart defines or local ignored files.
- Split large screens where appropriate into smaller widgets/controllers without changing visible routes or user flows.
- Preserve current app behavior while improving maintainability:
  - login flow
  - dashboard navigation
  - health assistant
  - vitals upload and charting
  - trend insights
  - backend-backed AI mode
- Reorganize Python backend code under `src/backend`:
  - `api/` for FastAPI app/router definitions.
  - `core/` for backend settings, logging, error helpers, and dependency wiring.
  - `clients/` for remote eHospital and model-provider clients.
  - `services/` for assistant orchestration, patient context aggregation, vitals summary, and trend insight workflows.
  - `schemas/` for request/response models.
  - `tests/` for backend-focused tests where appropriate.
- Move backend startup configuration into a clean entry point that can be referenced by `uvicorn` and scripts.
- Update `Makefile` and `tasks.ps1` so frontend, backend, CORS/dev web, Ollama/local model, and backend-provider modes are clear and consistent.

No intentional breaking API change is planned for the Python backend or the remote eHospital service.

## Capabilities

### New Capabilities

- `flutter-architecture-layering`: Defines the expected Flutter project layering, ownership boundaries, and import direction rules.
- `flutter-api-data-layer`: Defines centralized API access, repository responsibilities, model parsing, and error mapping.
- `flutter-secure-runtime-config`: Defines safe handling of runtime configuration and secret-like values in Flutter.
- `flutter-reusable-ui-components`: Defines reusable UI component expectations for shared cards, loading, empty, error, metric, and chart presentation patterns.
- `python-backend-architecture`: Defines Python backend directory structure, router/service/client/schema boundaries, and LangGraph-ready orchestration ownership.
- `developer-startup-workflows`: Defines expected Makefile/tasks startup commands for backend, Flutter, local model testing, and combined development workflows.

### Modified Capabilities

None.

## Impact

- Affected code:
  - `src/app/lib/config/**`
  - `src/app/lib/services/**`
  - `src/app/lib/screens/**`
  - new `src/app/lib/core/**`
  - new `src/app/lib/data/**`
  - new `src/app/lib/features/**`
  - `src/backend/**`
  - Python backend compatibility shims if existing imports still reference `src/demo2_api.py` or `src/assistant_backend.py`.
- Affected documentation:
  - `src/app/README.md`
  - backend README or project README if present.
  - `src/app/dart_defines.example.json`
  - project run commands in `tasks.ps1` and `Makefile`.
- Affected tests:
  - Flutter tests should cover configuration validation, API client error mapping, and at least one representative repository/controller path.
  - Python tests should cover backend app wiring, assistant endpoints, context aggregation, and error handling through the new `src/backend` modules.
- External systems:
  - No backend contract change is required.
  - No remote eHospital API contract change is required.
