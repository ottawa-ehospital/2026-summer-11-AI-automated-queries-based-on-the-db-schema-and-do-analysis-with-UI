## 1. Backend Foundation

- [x] 1.1 Add or extend a Python FastAPI backend module dedicated to AI assistant workflows.
- [x] 1.2 Add backend configuration for remote eHospital base URL, AI model provider, model name, and local Ollama settings.
- [x] 1.3 Add a reusable Python eHospital client for fetching patient-scoped remote tables.
- [x] 1.4 Add patient context aggregation for wearable vitals, vitals history, ECG, diabetes analysis, heart disease analysis, stroke prediction, lab tests, and diagnosis.
- [x] 1.5 Add clear backend errors for unknown patient id, empty message, remote API failure, and model failure.

## 2. Backend AI Endpoints

- [x] 2.1 Add `POST /assistant/chat` accepting patient id and user message.
- [x] 2.2 Move Health Assistant prompt construction from Flutter into the backend chat workflow.
- [x] 2.3 Add `POST /assistant/vitals-summary` for metric-specific vitals summaries.
- [x] 2.4 Add `POST /assistant/trend-insights` returning structured insights for steps, calories, heart rate, and sleep.
- [x] 2.5 Structure the backend orchestration so a LangGraph graph/tools can replace or extend the initial workflow without changing Flutter contracts.

## 3. Flutter Backend API Layer

- [x] 3.1 Add `BACKEND_BASE_URL` to Flutter configuration with a safe local default.
- [x] 3.2 Add a Flutter backend API client for assistant chat, vitals summaries, and trend insights.
- [x] 3.3 Add a Flutter eHospital API client for table reads and wearable upload.
- [x] 3.4 Move repeated eHospital URL construction and raw HTTP response handling out of screens into the API layer.
- [x] 3.5 Add consistent Flutter API error mapping for backend and eHospital failures.

## 4. Flutter AI Migration

- [x] 4.1 Update `AiService` to support a backend provider that calls the Python backend.
- [x] 4.2 Update Health Assistant screen to call backend-backed AI and remove local `_buildSystemPrompt`.
- [x] 4.3 Update Vitals screen AI summaries to call backend endpoint instead of local model provider.
- [x] 4.4 Update Trend Comparison screen AI insights to call backend endpoint instead of local model provider.
- [x] 4.5 Keep UI behavior, route names, chat history behavior, loading states, and visible labels stable.

## 5. Developer Tasks and Documentation

- [x] 5.1 Update `tasks.ps1` and `Makefile` with commands for running the Python AI backend.
- [x] 5.2 Add or update commands for launching Flutter with `AI_PROVIDER=backend` and `BACKEND_BASE_URL`.
- [x] 5.3 Document local machine, Android emulator, physical phone, and deployed backend URL behavior.
- [x] 5.4 Document that Python backend is a separate service and does not run inside the Flutter mobile app.
- [x] 5.5 Document local Ollama backend testing and production-like model provider configuration.

## 6. Verification

- [x] 6.1 Run Python compile checks for new backend modules.
- [x] 6.2 Add FastAPI TestClient tests for assistant chat, vitals summary, trend insights, and invalid patient id.
- [x] 6.3 Run Flutter `pub get`, `analyze`, and tests.
- [x] 6.4 Build Flutter web with backend provider defines.
- [x] 6.5 Manually smoke test login, Health Assistant, Vitals AI summary, Trend AI insight, and wearable upload entry points.
