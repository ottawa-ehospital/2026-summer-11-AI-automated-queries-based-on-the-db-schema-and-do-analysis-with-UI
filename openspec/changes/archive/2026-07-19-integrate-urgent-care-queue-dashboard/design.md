## Context

CareFlow currently exists outside DTI6302 at `/Users/yuyang/Downloads/urgent-care-queue-dashboard-main`. It has a single-file FastAPI backend, a staff-facing Flutter web dashboard, and a patient-facing Flutter app. The prototype's backend writes to the same eHospital API family that DTI6302 already uses, but it uses synchronous `requests`, its own CORS/app setup, its own direct DeepSeek HTTP call path, local JSON fallbacks, and separate `/patient/*`, `/queues`, `/patients`, `/alerts`, and `/intake` endpoints.

DTI6302 already has a Python FastAPI backend, an eHospital client boundary, model invocation configuration, backend logging, a Flutter app with feature-first structure, and existing Emergency/AI/dashboard areas. The urgent-care integration should therefore split into two tracks: backend workflow migration into DTI6302's FastAPI service, and Flutter feature migration into the existing app shell. The backend workflow itself should be treated as source-of-truth logic and ported closely; integration work should change paths and plumbing, not reinterpret the urgent-care product behavior.

## Goals / Non-Goals

**Goals:**

- Integrate CareFlow urgent-care queue behavior into the DTI6302 backend under a dedicated API namespace while preserving the original backend workflow logic.
- Provide patient check-in, CTAS/risk analysis, queue status, patient feedback, and the backend queue/status actions needed to preserve CareFlow workflow state.
- Store and read urgent-care state through the existing live eHospital tables verified for CareFlow compatibility.
- Expose patient-facing Flutter screens inside the existing DTI6302 mobile app with functional parity to the original CareFlow patient app.
- Preserve existing login, assistant, report interpreter, nutrition, wearable, emergency SOS, and settings flows.
- Route urgent-care AI calls through DTI6302's shared backend AI/model service so model configuration and failures are handled consistently.
- Keep clinical output framed as decision support, not diagnosis or treatment.

**Non-Goals:**

- Do not run the downloaded CareFlow FastAPI backend as a second required local service.
- Do not copy `flutter_frontend` or `patient_app` as standalone Flutter projects into `src/app`.
- Do not migrate the CareFlow staff-facing web dashboard UI into the DTI6302 mobile app in this change.
- Do not add new native Android/iOS app shells, duplicate Gradle projects, or generated platform artifacts.
- Do not require creating new remote database tables during the first implementation; the active eHospital deployment already exposes the needed urgent-care tables.
- Do not add urgent-care-only direct DeepSeek HTTP calls that bypass DTI6302's shared backend AI service.
- Do not replace or regress DTI6302's existing assistant, health alert, report interpreter, or nutrition model behavior while adding urgent-care model support.
- Do not redesign urgent-care triage, queue, status, or feedback semantics beyond changes required to run inside DTI6302's single backend.

## Decisions

1. **Use DTI6302 FastAPI as the only Flutter-facing backend.**

   The urgent-care API will be registered in `src/backend/main.py` under `/urgent-care`. Flutter will call `BACKEND_BASE_URL` only. This avoids forcing the app to coordinate DTI6302 backend on one port and CareFlow backend on another.

   Alternative considered: keep CareFlow backend on `8001` and point urgent-care Flutter screens to it. This was rejected because it duplicates configuration, CORS, logging, model setup, and eHospital client behavior.

2. **Port backend logic faithfully while splitting only for DTI6302 maintainability.**

   CareFlow's `backend.py` combines Pydantic models, database access, risk prompting, queue sorting, feedback alerting, and routes. DTI6302 should migrate this into `schemas/urgent_care.py`, `api/urgent_care.py`, and `services/urgent_care/` modules, but the behavior inside those modules should mirror the source backend: same CTAS labels, queue mapping, status names, estimated wait semantics, alert fallback precedence, visit history usage, response meanings, and persistence payload intent.

   Alternative considered: copy `backend.py` mostly intact as a second FastAPI app. This was rejected because it would introduce a second app object, duplicate CORS, synchronous HTTP boundaries, and a second service to run. The selected approach is a faithful port of logic, not a product redesign.

3. **Reuse eHospital client helpers and add update support only where needed.**

   Current DTI6302 helpers already fetch, write, and run SELECT queries against eHospital. Urgent-care needs the same database behavior as CareFlow, including row updates for consultation state and completion; implementation should add a small `update_ehospital_table_row` helper if no existing update boundary exists, rather than embedding raw URLs in service code.

   Alternative considered: keep CareFlow's `requests.put` calls inside urgent-care services. This was rejected because it bypasses DTI6302's normalized error handling and async HTTP conventions.

4. **Use the shared backend AI service for CareFlow model calls.**

   CareFlow uses DeepSeek for CTAS/risk and feedback alerting, with keyword safety fallback for feedback. DTI6302 should preserve the prompt contract, JSON normalization, conservative fallback, and "safer path wins" feedback behavior, but model invocation must go through the existing generic backend AI/model path (`src/backend/clients/model_client.py` using `AI_MODEL_PROVIDER`, `AI_MODEL_NAME`, and related shared settings). If the shared model client needs broader provider/base URL support, add it as shared model infrastructure, not as urgent-care-specific configuration.

   Alternative considered: keep CareFlow's direct DeepSeek `http.client.HTTPSConnection("api.deepseek.com")` code inside urgent-care services. This was rejected because it would create a second AI integration path, duplicate error handling, and make model configuration inconsistent. Another alternative, requiring `DEEPSEEK_API_KEY` for all intake, was rejected because DTI6302 local development commonly uses Ollama/local providers and tests should not depend on external model access.

5. **Refactor the shared model client only as generic infrastructure and behind compatibility tests.**

   Urgent-care may require structured JSON convenience helpers or broader OpenAI-compatible base URL support. These changes should be added behind the existing `invoke_model` contract or adjacent shared helpers as generic model-client capability, with tests proving current assistant, health alert, report interpreter, and nutrition behavior still works. Urgent-care must not introduce its own model provider, model name, base URL, or API key settings.

   Alternative considered: create a parallel urgent-care model client. This was rejected because the user's goal is a unified backend AI service and one model configuration surface.

6. **Use verified live eHospital urgent-care tables.**

   The source prototype assumes `healthcare_records` columns such as `ctas_urgency_level`, `risk_score`, `queue_name`, `clinical_summary`, and `recommended_action`. Live metadata from `https://aetab8pjmb.us-east-1.awsapprunner.com/tables` confirms that `patients_registration`, `healthcare_records`, `patient_feedback`, and `medical_history` exist with CareFlow-compatible fields. Urgent-care implementation should use live `/tables` metadata for health checks and schema validation, and should not refresh, write, or depend on `src/backend/ehospital_schema_inventory.json`.

   Alternative considered: create new tables or always rely on local JSON fallback. This was rejected because the active remote tables already support the CareFlow workflow and app state should follow patient ids across devices through eHospital.

7. **Create one Flutter mobile module with patient-app parity only.**

   The Flutter implementation should live under `features/urgent_care/` with models, repository, screens, widgets, and presentation helpers. Functionality should match the original urgent patient app closely enough that the same patient demo workflows work after integration: check-in, review, active status, polling/refresh, called/completed state, and feedback/condition update. The CareFlow `flutter_frontend` staff web dashboard is source context for backend workflow semantics only and will not be migrated as UI in this change. Routing can expose `/urgent-care` and `/urgent-care/status` or equivalent patient-facing route names.

   Alternative considered: copy `patient_app/lib/main.dart` and `flutter_frontend/lib/main.dart` into separate app entries, or rebuild the staff dashboard as a mobile screen. This was rejected because DTI6302 already has a single `SmartHealthApp` shell, the current user request explicitly excludes web dashboard migration, and the selected frontend scope is patient-app parity with DTI6302 mobile visual style.

8. **Document API ownership by module before implementation.**

   The integrated backend already has several feature routers, so this change adds `api-module-map.md` as the route ownership guide. Existing assistant, report interpreter, nutrition, wearables, query tools, and legacy demo/auth endpoints keep their current module boundaries. New patient-facing urgent-care routes should live under `/urgent-care/customer`, while preserved CareFlow queue workflow routes should live under `/urgent-care/workflow` and remain backend-only for this change.

   Alternative considered: add urgent-care endpoints wherever the source prototype named them, such as `/patient/*`, `/queues`, and `/alerts`. This was rejected because it would make it harder to distinguish patient mobile APIs from backend workflow APIs after integration.

9. **Use logged-in patient identity by default.**

   The patient-facing check-in should default to the current `patient_id` and known profile data from SharedPreferences/eHospital where available, while still allowing required intake fields such as symptoms and optional medical history.

   Alternative considered: require patients to manually type patient id for every check-in as in the source prototype. This was rejected because DTI6302 already has authenticated patient context.

## Risks / Trade-offs

- **Remote schema drift** -> Live metadata confirms the urgent-care tables are usable today. Urgent-care health checks should query live `/tables` metadata each time they need schema validation and fail clearly if a configured `EHOSPITAL_BASE_URL` lacks the verified fields, without maintaining a local inventory snapshot.
- **Model JSON is invalid or unavailable** -> Invoke models through the shared backend AI service, validate structured output, and fall back to conservative CTAS/rule behavior where safe; never block feedback red-flag alerting solely because the model is down.
- **Shared model client refactor regresses existing AI features** -> Keep existing `invoke_model` behavior compatible, add focused regression tests for assistant chat, health alert analysis, report interpreter, and nutrition model paths before wiring urgent-care through the shared service.
- **Clinical safety overstatement** -> Use decision-support wording, CTAS uncertainty notes, and staff review language; avoid diagnosis/treatment finality in UI and model prompts.
- **Staff dashboard scope confusion** -> Do not migrate the staff web dashboard UI into the patient mobile app. This change exposes only customer/patient-facing urgent-care mobile screens.
- **Queue order race conditions** -> Compute queue position server-side from persisted active records, sorted by CTAS level, risk score, and check-in time.
- **Copied UI feels foreign** -> Rebuild patient screens with DTI6302 mobile widgets/styles while preserving CareFlow patient functionality; verify no standalone CareFlow app shell or web dashboard chrome leaks into the host app.
- **Over-refactoring changes behavior** -> Maintain a source-to-target parity checklist for backend logic and UI workflows; tests should assert source-equivalent CTAS mapping, statuses, queue ordering, feedback alerts, and patient status semantics.

## Migration Plan

1. Use `database-compatibility.md` as the field compatibility baseline, then create source inventory notes from CareFlow `backend.py` and `patient_app/lib/main.dart`; use `flutter_frontend/lib/main.dart` only as backend workflow context, not as UI migration source.
2. Implement backend schemas and service modules by porting CareFlow logic first, then adapting only API paths, eHospital client boundaries, and shared AI service calls for DTI6302.
3. Add eHospital metadata checks and table read/write/update helpers needed by urgent-care workflow.
4. Register `/urgent-care` endpoints and add backend route/service tests with mocked eHospital/shared-model calls plus regression coverage for existing model users.
5. Add Flutter urgent-care models and repository using the existing `ApiClient` and `BACKEND_BASE_URL`.
6. Build patient check-in/status/feedback screens under `features/urgent_care` with source workflow parity and DTI6302 mobile styling.
7. Add patient-facing dashboard/emergency route entry points without disrupting existing routes.
8. Run backend and Flutter tests, then smoke test local patient check-in, queue status, and patient feedback paths.

Rollback is straightforward before release: remove the urgent-care router registration and Flutter routes/entry cards while leaving untouched existing app features. Persisted eHospital rows are additive urgent-care records and should not alter existing wearable or assistant behavior.

## Open Questions

None.
