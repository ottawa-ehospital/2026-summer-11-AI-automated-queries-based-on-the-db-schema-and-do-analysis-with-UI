# API Module Map

This document groups DTI6302 backend endpoints by module so the integrated app can identify which API surface belongs to which feature.

Local backend base URL:

```text
http://127.0.0.1:8000
```

Physical-device development should use the Mac LAN URL configured through `BACKEND_BASE_URL`.

Remote eHospital base URL:

```text
https://aetab8pjmb.us-east-1.awsapprunner.com
```

## Routing Rules

- Flutter should call the Python backend through `BACKEND_BASE_URL` for app features.
- eHospital table access should stay behind Python backend clients/services unless an existing legacy flow explicitly still uses the eHospital facade.
- Urgent-care customer mobile screens must call only `/urgent-care/customer/*` or equivalent patient-facing urgent-care endpoints.
- Urgent-care staff/web/admin UI is out of scope for this change.
- Urgent-care model calls must use the shared backend model client and generic model settings.

## Module Summary

| Module | Prefix | Status | Primary Consumer | Notes |
| --- | --- | --- | --- | --- |
| Root Auth | `/login` | Existing | Flutter login | Current mobile login boundary; proxies to eHospital auth. |
| Legacy Demo Support | mixed root paths | Existing/compatibility | Early demo/dev flows | Includes `/users`, `/chat`, `/dashboard/{user_id}`, `/mock/current-data`; not intended for new urgent-care work. |
| Assistant | `/assistant` | Existing | Health assistant, vitals/trends, alert coordinator | Uses shared backend model client. |
| Report Interpreter | `/report-interpreter` | Existing | Medical report feature | Handles upload/OCR/report chat/saved records. |
| Nutrition Monitor | `/nutrition-monitor` | Existing | Nutrition feature | Handles food image analysis, meal logs, goals, summaries. |
| Wearables | `/wearables` | Existing | Apple Health/Fitbit ingestion | Handles wearable samples and workout ingestion. |
| Query Tools | `/query-tools` | Existing/dev | Sigma/table-query tooling | Uses local `ehospital_schema_inventory.json`; urgent-care must not depend on it. |
| Urgent Care Customer | `/urgent-care/customer` | Planned | New customer/patient mobile module | Patient check-in, status, feedback. |
| Urgent Care Workflow | `/urgent-care/workflow` | Planned backend-only | Backend tests/future non-mobile surfaces | Queue and state actions preserved for CareFlow workflow; not surfaced as mobile staff UI. |
| eHospital table API | remote `/tables`, `/table/*`, `/sql/select` | External | Python backend clients | Live metadata is source of truth for urgent-care table compatibility. |

## Existing Backend Modules

### Root Auth

This route is still part of the active Flutter login flow.

| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/login` | Authenticate through eHospital auth service and normalize the app session. |

### Legacy Demo Support

These routes currently have no module prefix. They preserve early prototype/demo behavior and should not be used as a pattern for new urgent-care endpoints.

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/users` | List public demo users from local demo data. |
| `POST` | `/chat` | Legacy local demo chat. |
| `GET` | `/dashboard/{user_id}` | Legacy local dashboard payload. |
| `POST` | `/mock/current-data` | Generate mock current health data. |

### Assistant

Prefix: `/assistant`

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/assistant/patients/{patient_id}/context` | Debug/view aggregated eHospital patient context. |
| `POST` | `/assistant/chat` | Backend-backed assistant chat. |
| `POST` | `/assistant/vitals-summary` | Generate vitals summary text. |
| `POST` | `/assistant/trend-insights` | Generate structured trend insight text. |
| `POST` | `/assistant/health-alert/analyze` | Analyze a health alert event and return notification decision. |

### Report Interpreter

Prefix: `/report-interpreter`

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/report-interpreter/health` | Report interpreter and OCR health. |
| `POST` | `/report-interpreter/patients` | Create or register patient for report assignment. |
| `GET` | `/report-interpreter/patients` | List report-interpreter patients. |
| `POST` | `/report-interpreter/reports/assign-patient` | Assign extracted lab values to a patient. |
| `POST` | `/report-interpreter/chat` | Chat over report context. |
| `POST` | `/report-interpreter/suggest-questions` | Suggest follow-up questions. |
| `POST` | `/report-interpreter/analyze-file` | Upload/analyze report file. |
| `GET` | `/report-interpreter/test-types` | List saved test types. |
| `GET` | `/report-interpreter/tests/{test_type}/dates` | List saved record dates for a test type. |
| `GET` | `/report-interpreter/tests/{test_type}/{test_date}` | Load saved record content. |

### Nutrition Monitor

Prefix: `/nutrition-monitor`

| Method | Path | Purpose |
| --- | --- | --- |
| `GET` | `/nutrition-monitor/health` | Nutrition module health and image-analysis capability. |
| `POST` | `/nutrition-monitor/analyze-image` | Analyze food image with optional patient id and hint. |
| `POST` | `/nutrition-monitor/meals` | Log an analyzed meal. |
| `GET` | `/nutrition-monitor/meals?patientId={id}` | Load patient meal history. |
| `GET` | `/nutrition-monitor/summary/daily?patientId={id}` | Load daily nutrition summary. |
| `GET` | `/nutrition-monitor/goals?patientId={id}` | Load nutrition goals/defaults. |
| `PUT` | `/nutrition-monitor/goals` | Validate/save nutrition goals. |

### Wearables

Prefix: `/wearables`

| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/wearables/ingest` | Ingest one wearable sample. |
| `POST` | `/wearables/workouts/ingest` | Ingest one workout. |
| `POST` | `/wearables/workouts/batch-ingest` | Ingest a batch of workouts. |

### Query Tools

Prefix: `/query-tools`

| Method | Path | Purpose |
| --- | --- | --- |
| `POST` | `/query-tools/schema/refresh` | Refresh local schema inventory from remote `/tables`. |
| `GET` | `/query-tools/schema` | Return local schema inventory. |
| `POST` | `/query-tools/sigma/validate` | Validate Sigma-style table query payload. |
| `POST` | `/query-tools/sql/validate` | Validate SQL references against inventory. |
| `POST` | `/query-tools/table/query` | Execute filtered table query through backend service. |

Important: urgent-care must not depend on Query Tools' local schema inventory. Urgent-care schema checks use live eHospital `/tables`.

## Planned Urgent-Care API

The integrated urgent-care backend keeps CareFlow business behavior but changes path naming to make the module easy to recognize. Exact response models are defined during implementation, but route ownership should follow this map.

### Customer/Patient Mobile Endpoints

Prefix: `/urgent-care/customer`

These are the only urgent-care endpoints intended for the DTI6302 mobile UI.

| Method | Path | Purpose | Source CareFlow Behavior |
| --- | --- | --- | --- |
| `GET` | `/urgent-care/customer/health` | Health/capability check for customer urgent-care module. | Derived from backend health and table readiness. |
| `POST` | `/urgent-care/customer/check-in` | Submit patient check-in and create urgent-care visit. | `POST /patient/check-in` wrapping `intake()`. |
| `GET` | `/urgent-care/customer/visits/{visit_id}/status` | Load queue/status payload for a checked-in visit. | `GET /patient/{local_patient_id}/status`. |
| `POST` | `/urgent-care/customer/visits/{visit_id}/feedback` | Submit queue feedback or condition update. | `POST /patient/{local_patient_id}/feedback`. |
| `GET` | `/urgent-care/customer/patients/{patient_id}/history` | Load previous urgent-care records and feedback for context/debugging if needed. | `GET /patient/{patient_id}/history`. |

Customer status response should preserve CareFlow patient app concepts:

- `local_patient_id` or integrated `visit_id`
- `patient_id`
- `queue_number`
- `status`
- `patients_ahead`
- `estimated_wait_range`
- `notified`
- `notified_at`
- `checked_in_at`
- `server_time`
- `submitted_information`

### Backend Workflow Endpoints

Prefix: `/urgent-care/workflow`

These endpoints preserve CareFlow backend workflow semantics and support tests/future non-mobile surfaces. They are not exposed through the customer mobile UI in this change.

| Method | Path | Purpose | Source CareFlow Behavior |
| --- | --- | --- | --- |
| `GET` | `/urgent-care/workflow/health` | Backend workflow health and live table compatibility. | `GET /health`. |
| `POST` | `/urgent-care/workflow/intake` | Full backend intake entrypoint, if kept separate from customer wrapper. | `POST /intake`. |
| `GET` | `/urgent-care/workflow/queues` | Return Emergency/Normal/Non-Urgent queues and summary. | `GET /queues`. |
| `GET` | `/urgent-care/workflow/patients` | Return active and completed urgent-care patients. | `GET /patients`. |
| `GET` | `/urgent-care/workflow/feedback` | Return stored feedback rows/fallback. | `GET /feedback`. |
| `GET` | `/urgent-care/workflow/alerts` | Return alert-required feedback events. | `GET /alerts`. |
| `POST` | `/urgent-care/workflow/visits/{visit_id}/notify` | Mark a visit as patient-notified. | `POST /patient/{local_patient_id}/notify`. |
| `POST` | `/urgent-care/workflow/visits/{visit_id}/start` | Mark consultation started. | `POST /patient/{local_patient_id}/start`. |
| `POST` | `/urgent-care/workflow/visits/{visit_id}/complete` | Mark completed/discharged. | `POST /patient/{local_patient_id}/complete`. |

## Urgent-Care Persistence Tables

Urgent-care uses live eHospital metadata, not the local schema inventory.

| Table | Purpose | Primary Key |
| --- | --- | --- |
| `patients_registration` | Patient identity/demographics | `patient_id` |
| `healthcare_records` | Urgent-care visit/check-in records | `record_id` |
| `patient_feedback` | Feedback and condition updates linked to visit records | `feedback_id` |
| `medical_history` | Optional patient-reported medical history notes | `history_id` |

## Module Identification Checklist

Use this when adding or reviewing endpoints:

- A route used by patient urgent-care UI must start with `/urgent-care/customer`.
- A route used only for preserved queue workflow must start with `/urgent-care/workflow`.
- A route used by general AI assistant must stay under `/assistant`.
- A route used by food image/meal workflow must stay under `/nutrition-monitor`.
- A route used by report upload/OCR/chat must stay under `/report-interpreter`.
- A route used by wearable ingestion must stay under `/wearables`.
- A route used by Sigma/query tooling must stay under `/query-tools`.
- No urgent-care route should directly expose remote eHospital `/table/*` URLs to Flutter.
- No urgent-care route should use urgent-care-specific model settings; use the shared model client.
