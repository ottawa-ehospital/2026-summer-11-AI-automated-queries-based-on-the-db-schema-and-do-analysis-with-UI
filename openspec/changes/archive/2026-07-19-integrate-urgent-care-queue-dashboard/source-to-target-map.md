# Source-to-Target Map

This map identifies where each CareFlow source behavior lands in DTI6302.

## Backend

| CareFlow Source | DTI6302 Target | Notes |
| --- | --- | --- |
| `backend.py` Pydantic models | `src/backend/schemas/urgent_care.py` | Convert dataclass/Pydantic shapes into request/response schemas. |
| CTAS constants, queue names, statuses, red-flag terms | `src/backend/services/urgent_care/constants.py` | Preserve labels, fallback risk scores, queue mapping, and status names. |
| `db_get_table`, `db_create_row`, `db_update_row`, `/sql/select` calls | `src/backend/clients/ehospital_client.py` helpers | Use shared client boundary; add row update helper if needed. |
| `ensure_patient_registration`, age/DOB helpers | `src/backend/services/urgent_care/records.py` | Preserve create/repair behavior using live eHospital tables. |
| `fetch_patient_history`, `format_history_for_prompt` | `src/backend/services/urgent_care/history.py` | Use backend eHospital client helpers and SQL select helper. |
| `risk_analysis_agent`, `call_deepseek_json` | `src/backend/services/urgent_care/risk.py` | Replace direct DeepSeek call with shared `invoke_model`; preserve prompt/JSON contract and fallback. |
| `queue_prioritization_agent`, `summary_payload`, `patient_status_payload` | `src/backend/services/urgent_care/queueing.py` | Preserve queue ordering, summary fields, and patient status semantics. |
| `save_feedback`, `feedback_alert_agent`, `keyword_feedback_alert` | `src/backend/services/urgent_care/feedback.py` | Use shared model client and deterministic safety fallback. |
| `load_json_list` fallback files | Isolated dev fallback service or documented local fallback | Keep fallback optional/error-only; eHospital remains primary. |
| Source route wrappers | `src/backend/api/urgent_care.py` | Expose adapted `/urgent-care/customer/*` and `/urgent-care/workflow/*` paths. |
| FastAPI app/CORS in source | Existing `src/backend/main.py` app | Do not run a second FastAPI service. |

## Backend Route Mapping

| CareFlow Endpoint | DTI6302 Endpoint | Consumer |
| --- | --- | --- |
| `GET /health` | `GET /urgent-care/health` plus `GET /urgent-care/customer/health` and/or `/urgent-care/workflow/health` | Health/smoke tests. |
| `GET /ctas-levels` | `GET /urgent-care/workflow/ctas-levels` if needed | Backend-only/reference. |
| `POST /patient/check-in` | `POST /urgent-care/customer/check-in` | Patient mobile UI. |
| `GET /patient/{local_patient_id}/status` | `GET /urgent-care/customer/visits/{visit_id}/status` | Patient mobile UI. |
| `POST /patient/{local_patient_id}/feedback` | `POST /urgent-care/customer/visits/{visit_id}/feedback` | Patient mobile UI. |
| `GET /patient/{patient_id}/history` | `GET /urgent-care/customer/patients/{patient_id}/history` | Patient context/debugging if needed. |
| `POST /intake` | `POST /urgent-care/workflow/intake` | Backend-only workflow parity; customer check-in wraps this behavior. |
| `GET /queues` | `GET /urgent-care/workflow/queues` | Backend-only workflow parity. |
| `GET /patients` | `GET /urgent-care/workflow/patients` | Backend-only workflow parity. |
| `GET /feedback` | `GET /urgent-care/workflow/feedback` | Backend-only workflow parity. |
| `GET /alerts` | `GET /urgent-care/workflow/alerts` | Backend-only workflow parity. |
| `POST /patient/{id}/notify` | `POST /urgent-care/workflow/visits/{visit_id}/notify` | Backend-only workflow parity. |
| `POST /patient/{id}/start` | `POST /urgent-care/workflow/visits/{visit_id}/start` | Backend-only workflow parity. |
| `POST /patient/{id}/complete` | `POST /urgent-care/workflow/visits/{visit_id}/complete` | Backend-only workflow parity. |
| `POST /feedback` | Internal service or `POST /urgent-care/workflow/feedback` if needed | Backend-only workflow parity. |

## Flutter

| CareFlow Patient App Source | DTI6302 Target | Notes |
| --- | --- | --- |
| `PatientStatus` model | `src/app/lib/features/urgent_care/models/urgent_care_models.dart` | Add Dart models for status, check-in, feedback, health. |
| `PatientApi` | `src/app/lib/features/urgent_care/data/urgent_care_repository.dart` | Use existing `ApiClient` and `ApiConfig.backendBaseUrl`. |
| Splash/welcome standalone app | Existing Smart Health route/screen entry | Do not create a second app shell. |
| Check-in form | `features/urgent_care/screens/urgent_care_check_in_screen.dart` | Default active patient id from current session; collect symptoms and medical history. |
| Review screen | Same check-in flow or confirmation view | Preserve review-before-submit behavior if practical. |
| Status tab | `features/urgent_care/screens/urgent_care_status_screen.dart` | Show queue/status details and refresh/poll. |
| My info tab | Status/details section | Show submitted information for the current visit only. |
| Feedback tab | `features/urgent_care/screens/urgent_care_feedback_screen.dart` or section | Support condition updates and app feedback. |
| Secure standalone session keys | DTI6302 app session plus urgent-care active visit storage | Reuse existing patient context; store active urgent-care visit id/status locally if needed. |
| Voice input | Optional follow-up unless dependency already exists | Preserve workflow without adding unnecessary dependency churn unless needed. |

## Excluded Source Behaviors

- Do not copy `flutter_frontend` staff dashboard UI into DTI6302.
- Do not copy either standalone Flutter project shell into `src/app`.
- Do not keep direct DeepSeek HTTP calls.
- Do not require CareFlow backend on port `8001`.
- Do not expose staff dashboard routes in the patient mobile app.
