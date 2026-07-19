## Context

The Flutter app currently reads Apple Health locally, uploads wearable vitals to the remote eHospital API, and then reads remote eHospital tables for display and AI context. AI calls are still initiated from Flutter screens through `AiService`, while some screens independently construct patient context using direct `http.get` calls.

For a realistic mobile architecture, Python should run as a separate backend service, not inside the Flutter app or on the phone. The Flutter app should call this service over HTTP. This backend can later evolve into a LangGraph service with tools for eHospital data, local mock current-state data, workout readiness, and future recommendation workflows.

## Goals / Non-Goals

**Goals:**
- Add a Python backend service API for AI assistant and summary workflows.
- Move AI prompt construction and patient-context aggregation out of Flutter screens.
- Keep Flutter responsible for UI, login state, Apple Health reading, and wearable upload.
- Introduce a clean Flutter API layer so screens call repositories/services rather than raw HTTP.
- Preserve current app behavior while making future LangGraph expansion straightforward.

**Non-Goals:**
- Running Python inside the Flutter mobile app.
- Replacing the existing remote eHospital API.
- Removing Apple Health sync from Flutter.
- Implementing every future workout recommendation capability in this change.
- Solving production deployment, authentication, or long-term secret management completely.

## Decisions

1. Python backend runs as an external HTTP service.

   The backend will be FastAPI-based and run locally for development or remotely for product-like use. Flutter will configure its backend URL with `--dart-define=BACKEND_BASE_URL=...`.

   Alternative considered: embedding Python into the mobile app. This is rejected because it is not practical for iOS/Android lifecycle, packaging, battery, and security constraints.

2. Backend owns AI orchestration and patient context aggregation.

   The backend will expose endpoints such as:
   - `POST /assistant/chat`
   - `POST /assistant/vitals-summary`
   - `POST /assistant/trend-insights`
   - `GET /patients/{patient_id}/context`

   These endpoints will fetch needed eHospital data, build context, and call the model/agent. LangGraph can initially be a simple workflow and later grow into a multi-tool graph.

   Alternative considered: keep context building in Flutter and only send a prompt to backend. This keeps too much business logic in the client and makes future graph expansion harder.

3. Flutter API layer separates transport from UI.

   Flutter will introduce client/repository classes for:
   - remote eHospital table access,
   - AI backend calls,
   - auth/user lookup,
   - wearable upload.

   Screens should ask these services for typed or structured data instead of directly calling `http.get` / `http.post`.

   Alternative considered: only changing `AiService`. That would help AI but leave the broader page-level API mixing problem untouched.

4. Existing provider modes remain backend-side concerns where possible.

   Flutter should eventually call `backend` as its AI provider. Backend model provider can be configured by environment variables, such as Ollama locally and Gemini/OpenAI-compatible providers later. Existing Flutter-local Gemini/Ollama branches may be kept temporarily as fallback during migration but should not be the primary long-term path.

## Risks / Trade-offs

- Local phone testing cannot call `127.0.0.1` on the development machine -> Document LAN IP and emulator URL behavior.
- Remote eHospital API may still have browser CORS issues -> Backend proxy/aggregation endpoints reduce Flutter Web direct calls for AI workflows, but non-AI pages may still need cleanup.
- Moving logic to backend changes failure modes -> Add clear API errors and Flutter loading/error states.
- LangGraph integration can become too large too early -> Start with a minimal graph-compatible service boundary and add tools incrementally.
- Existing Flutter screens contain many direct HTTP calls -> Migrate in phases, prioritizing assistant/vitals/trends first.

## Migration Plan

1. Add backend configuration and eHospital client utilities in Python.
2. Add backend assistant endpoints that reproduce current Flutter AI behavior.
3. Add Flutter backend API client and route `AiService` through it.
4. Move Health Assistant context construction from Flutter to backend.
5. Move vitals summary and trend insight AI calls to backend endpoints.
6. Extract repeated eHospital HTTP code from key screens into Flutter API/repository services.
7. Update startup tasks and README for running both backend and Flutter.
8. Verify with local backend + Ollama, then optionally production-like model settings.
