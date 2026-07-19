## Why

The current Flutter app mixes remote API calls, patient-context assembly, and AI provider calls directly inside screens. Moving AI orchestration and health-data aggregation into a Python backend service gives the project a realistic mobile architecture and creates a clean extension point for future LangGraph workflows, tools, and workout recommendation logic.

## What Changes

- Add a Python backend service for AI assistant workflows:
  - Expose HTTP endpoints that Flutter can call for assistant chat and AI summaries.
  - Centralize patient context loading from the remote eHospital API.
  - Provide a foundation for future LangGraph graph/tool expansion.
- Migrate AI orchestration out of Flutter screens:
  - Move Health Assistant prompt/context construction from Flutter to backend service.
  - Move vitals summary and trend insight AI generation to backend service endpoints.
  - Keep Flutter responsible for UI, Apple Health capture/sync, and API calls.
- Refactor Flutter API access into a dedicated API layer:
  - Extract eHospital table reads/writes into reusable client/repository services.
  - Extract backend AI calls into a reusable client.
  - Remove repeated `http.get` / `http.post` logic from individual pages where feasible.
- Preserve current development modes:
  - Local Python backend can call Ollama for testing.
  - Production-like backend can call Gemini/OpenAI-compatible models later.
  - Flutter can still run with CORS-disabled Chrome during development if the remote eHospital API remains browser-CORS limited.

## Capabilities

### New Capabilities
- `python-ai-backend-service`: Defines backend endpoints for chat, health context aggregation, AI summaries, and future LangGraph extension.
- `flutter-api-layer`: Defines a Flutter-side API abstraction that prevents pages from directly mixing HTTP transport code with UI logic.
- `backend-backed-ai-assistant`: Defines the migration of assistant, vitals, and trend AI generation from Flutter-local provider calls to backend service calls.

### Modified Capabilities

## Impact

- Python code under `src/`, likely including a new backend module or extensions to `src/demo2_api.py`.
- Flutter code under `src/app/lib`, especially `services/`, `screens/health_assistant_screen.dart`, `screens/vitals_screen.dart`, `screens/trend_comparison_screen.dart`, and API-related services.
- `tasks.ps1` and `Makefile` startup tasks may need combined backend + Flutter documentation or targets.
- README and config documentation must explain local backend URL, model/provider settings, and mobile-device URL caveats.
