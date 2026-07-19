# Source Inventory

Source project: `/Users/yuyang/Downloads/urgent-care-queue-dashboard-main`

This inventory captures CareFlow behavior that must be preserved while moving it into DTI6302's single backend and existing mobile app shell.

## Source Layout

| Source | Role | Integration Use |
| --- | --- | --- |
| `backend.py` | Single-file FastAPI backend for intake, CTAS/risk analysis, queues, feedback, alerts, and eHospital persistence. | Port business logic faithfully into DTI6302 backend modules. |
| `patient_app/lib/main.dart` | Standalone customer/patient Flutter app. | Rebuild patient workflows inside DTI6302 mobile app style. |
| `flutter_frontend/lib/main.dart` | Staff-facing Flutter web dashboard. | Use only to confirm backend workflow semantics; do not migrate UI. |
| `api.md` | eHospital generic table API reference. | Confirms `/tables`, `/table/:name`, `/table/:name/:id`, and `/sql/select` behavior. |

## Backend Source Inventory

### Constants and Tables

CareFlow defaults:

- `DATABASE_API_URL`: `https://aetab8pjmb.us-east-1.awsapprunner.com`
- `HEALTHCARE_RECORDS_TABLE`: `healthcare_records`
- `FEEDBACK_TABLE`: `patient_feedback`
- `PATIENTS_REGISTRATION_TABLE`: `patients_registration`
- `MEDICAL_HISTORY_TABLE`: `medical_history`
- local fallback files under `Feedback_Data`: `patients.json`, `completed_patients.json`, `feedback_log.json`, `feedback_alerts.json`

DTI6302 integration must use existing backend config/client boundaries and live eHospital metadata. Urgent-care code must not depend on `src/backend/ehospital_schema_inventory.json`.

### Statuses, Queues, and CTAS

Statuses:

- `Waiting`
- `In Consultation`
- `Completed`
- legacy completed source status `Completed / Discharged` normalizes to `Completed`

Queues:

- `Emergency Queue`: CTAS 1-2
- `Normal Queue`: CTAS 3
- `Non-Urgent Queue`: CTAS 4-5

CTAS labels:

- 1: `Level 1: Resuscitation / Critical`
- 2: `Level 2: Emergent`
- 3: `Level 3: Urgent`
- 4: `Level 4: Less Urgent`
- 5: `Level 5: Non-Urgent`

Fallback risk scores:

- CTAS 1 -> 10
- CTAS 2 -> 8
- CTAS 3 -> 6
- CTAS 4 -> 3
- CTAS 5 -> 1

### Backend Models

`Patient` contains:

- `id`, `patient_id`, `name`, `age`
- `symptoms`, `medical_history`
- `ctas_level`, `risk_score`, `queue_name`
- `clinical_summary`, `reasoning`, `recommended_action`
- `status`
- `checked_in_at`, `consultation_started_at`, `completed_at`, `notified_at`

`IntakeRequest` contains:

- optional `patient_id`
- required `name`, `age`, `symptoms`
- `gender` default `Other`
- `medical_history` default empty string

`FeedbackRequest` contains:

- `patient_id`
- `rating`
- `message`
- `condition_update`
- optional `ctas_level`, `risk_score`

`FeedbackAlert` contains:

- `alert_required`
- `severity`
- `alert_reason`
- `recommended_staff_action`
- `patient_message`
- `feedback_type`
- `agent_source`

### Source Endpoints

| Source Endpoint | Behavior |
| --- | --- |
| `GET /health` | Backend health/config response. |
| `GET /ctas-levels` | Return CTAS metadata. |
| `GET /patient/{patient_id}/history` | Return previous healthcare records and linked feedback. |
| `POST /patient/check-in` | Patient wrapper around `/intake`; requires database save success and returns patient status payload. |
| `GET /patient/{local_patient_id}/status` | Return patient-facing queue status payload. |
| `POST /patient/{local_patient_id}/feedback` | Patient app feedback wrapper; parses `[CONDITION_UPDATE]` and `[APP_FEEDBACK]` message prefixes. |
| `POST /intake` | Core intake, registration ensure, history load, model CTAS/risk analysis, visit record create, medical history save, queue summary. |
| `GET /queues` | Active queues plus summary. |
| `GET /patients` | Active and completed patients. |
| `GET /feedback` | Database feedback rows or local fallback feedback. |
| `GET /alerts` | Alert-required feedback events with local/database de-duplication. |
| `POST /patient/{local_patient_id}/notify` | Set notification timestamp. |
| `POST /patient/{local_patient_id}/start` | Set `In Consultation` and persist `consultation_started_at`. |
| `POST /patient/{local_patient_id}/complete` | Set `Completed`, persist `completed_at`, remove from active queues. |
| `POST /feedback` | Save feedback, run alert analysis, persist feedback, save local alert if required. |

### Persistence Mapping

`Patient` to `healthcare_records`:

- `patient_id`
- `symptoms`
- `ctas_urgency_level`
- `risk_score`
- `queue_name`
- `status`
- `clinical_summary`: source packs summary plus reasoning with `\n\nReasoning:\n`
- `recommended_action`
- `check_in_time`
- `consultation_started_at`
- `completed_at`

Patient registration ensure:

- If `patients_registration.patient_id` exists, reuse it.
- Otherwise create minimum row with `patient_id`, `name`, approximate `dob` from age, normalized `gender`, `contact_info`.

Medical history save:

- If intake medical history is non-empty, create a `medical_history` row with patient self-report fields and `notes`.

Feedback persistence:

- `record_id`
- `rating`
- `feedback_message`
- `condition_update`
- `alert_required` string value
- `alert_reason`
- `created_time`

### History and Prompt Context

CareFlow loads recent healthcare records by patient id with `/sql/select`, then fetches feedback by each `record_id`. If `/sql/select` fails, it falls back to table scans. Prompt history includes previous visit symptoms, CTAS, risk score, summary, recommended action, status, and feedback alert details.

### Model Prompts

Risk Analysis Agent prompt requires JSON fields:

- `ctas_level`
- `urgency_label`
- `risk_score`
- `clinical_summary`
- `reasoning`
- `recommended_action`

Feedback Alert Agent prompt requires JSON fields:

- `alert_required`
- `severity`
- `alert_reason`
- `recommended_staff_action`
- `patient_message`
- `feedback_type`
- `agent_source`

CareFlow calls DeepSeek directly. DTI6302 must preserve prompt contracts but call the shared model client instead.

### Feedback Safety Fallback

High-risk terms include:

- worsening language: `worse`, `worsening`
- breathing/speech issues: `shortness of breath`, `can't breathe`, `cannot breathe`, `can't speak`, `cannot speak`, `unable to speak`, `trouble speaking`, `difficulty speaking`
- urgent/help language: `need help`, `need assistance`
- red flags: `chest pain`, `faint`, `fainted`, `passed out`, `seizure`, `bleeding`, `severe pain`, `stroke`, `weakness`, `numbness`, `confused`, `suicidal`, `oxygen`

Mismatch terms:

- `too low`, `undertriaged`, `not urgent enough`, `waited too long`
- rating values `Too low` and `Unsure`

If deterministic fallback requires alert but model says no alert, safer fallback wins.

## Patient App Source Inventory

The standalone patient app:

- Uses `PATIENT_API_BASE`, default `http://10.0.2.2:8001`.
- Stores session in `FlutterSecureStorage` using `patient.localPatientId`, `patient.accessToken`, and `patient.lastStatus`.
- Has views: splash, welcome, check-in, review, active, invalid.
- Active tabs: check-in, status, my info, feedback.
- Restores saved sessions on startup and refreshes status.
- Polls status every 8 seconds while active, foregrounded, on status tab, and not finished.
- Stops polling when status is completed/cancelled.
- Vibrates and announces through semantics when the patient is newly called.
- Validates optional patient id, required name, age 0-125, and required symptoms locally.
- Sends check-in payload with `patient_id` if supplied, plus `name`, `age`, `gender`, `symptoms`, and `medical_history`.
- Shows review screen before final submission.
- Displays status, queue reference/number, patients ahead, estimated wait, last update, refresh errors, and safety notice.
- Shows submitted name, age, symptoms, medical history, and check-in time.
- Lets patient submit condition update with `[CONDITION_UPDATE]` prefix.
- Lets patient submit app feedback with `[APP_FEEDBACK]` prefix and star rating.
- Includes voice input for symptoms, history, and condition details through `speech_to_text`.

DTI6302 should preserve these workflows but use the existing app shell, `SharedPreferences` patient context, `ApiClient`, and DTI6302 mobile styling.

## Staff Dashboard Source Inventory

The staff dashboard:

- Calls `/queues`, `/patients`, `/alerts`, `/intake`, `/feedback`, and `/patient/{id}/{start|complete}`.
- Shows operational queue summary, priority queues, active patients, completed/discharged history, feedback alerts, and CTAS distribution.
- Supports staff actions for start consultation and complete visit.
- Supports staff-style feedback dialog for queue/urgency feedback and condition updates.

This UI is explicitly out of scope. It only confirms backend workflow semantics that DTI6302 should preserve in backend-only workflow endpoints.
