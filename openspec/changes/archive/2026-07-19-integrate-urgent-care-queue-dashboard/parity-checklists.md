# Parity Checklists

Use these checklists while implementing the urgent-care integration.

## Backend Behavior Parity

- [x] CTAS labels exactly preserve CareFlow labels for levels 1 through 5.
- [x] Queue names exactly preserve `Emergency Queue`, `Normal Queue`, and `Non-Urgent Queue`.
- [x] CTAS-to-queue mapping preserves levels 1-2 emergency, level 3 normal, levels 4-5 non-urgent.
- [x] Status names preserve `Waiting`, `In Consultation`, and `Completed`.
- [x] Legacy `Completed / Discharged` normalizes to `Completed` when read.
- [x] Fallback risk scores preserve 1->10, 2->8, 3->6, 4->3, 5->1.
- [x] Intake validates required symptoms before writing a visit.
- [x] Patient registration ensure/repair creates a minimum `patients_registration` row when missing and demographics are sufficient.
- [x] Medical history self-report writes to `medical_history` when provided.
- [x] Risk Analysis Agent prompt preserves the CareFlow role, CTAS definitions, current intake, previous history, and decision-support framing.
- [x] Risk Analysis Agent validates `ctas_level`, clamps `risk_score`, maps `queue_name`, and returns `history_used`.
- [x] Model failure or invalid JSON uses deterministic conservative fallback.
- [x] Feedback Alert Agent prompt preserves CareFlow alert fields and safety framing.
- [x] Feedback deterministic high-risk terms trigger staff alert.
- [x] Feedback mismatch terms and `Too low`/`Unsure` ratings trigger medium review alert.
- [x] If model alert says no alert but fallback finds red-flag language, fallback wins.
- [x] Queue sorting uses CTAS level ascending, risk score descending, check-in time ascending.
- [x] Queue summary includes total, total patients, waiting, in consultation, completed, and CTAS counts.
- [x] Patient status payload includes `local_patient_id`, `patient_id`, `queue_number`, `status`, `patients_ahead`, `estimated_wait_range`, `notified`, `notified_at`, `checked_in_at`, `server_time`, `access_token`, and `submitted_information`.
- [x] Completed visit status returns no active queue number.
- [x] Notify action records `notified_at`.
- [x] Start action sets `In Consultation` and `consultation_started_at`.
- [x] Complete action sets `Completed`, `completed_at`, and removes visit from active queues.
- [x] Feedback persists to `patient_feedback` with record linkage where available.
- [x] Alerts de-duplicate local fallback and database feedback rows.
- [x] DTI6302 differences are limited to endpoint paths, FastAPI registration, async/client boundaries, shared model service, and tests.

Remote API note:

- `healthcare_records.notified_at` exists in SQL after the schema update, and DTI6302 writes it through the shared eHospital update helper. The remote eHospital `/tables` and `/table/healthcare_records` responses may require service restart/redeploy before their runtime metadata exposes the new field.

## Flutter Patient Workflow Parity

- [x] Logged-in user can enter urgent-care from DTI6302 app navigation.
- [x] Check-in screen defaults active patient id where available.
- [x] Check-in collects symptoms and optional medical history.
- [x] Local validation catches invalid patient id, missing symptoms, and invalid age/demographics before submit.
- [x] Patient can review submitted check-in information before final submit or receive an equivalent confirmation state.
- [x] Submit shows loading while backend analyzes and assigns queue.
- [x] Success stores or carries active urgent-care visit id.
- [x] Status view shows status, queue number/reference, patients ahead, estimated wait, notification state, submitted symptoms, CTAS/risk, queue name, clinical summary, recommended action, and check-in time when available.
- [x] Status can be manually refreshed.
- [x] Status refresh/polling preserves last known status on transient errors.
- [x] Called/consultation status is visually prominent and patient-facing.
- [x] Completed status stops or reduces active polling.
- [x] Patient can submit condition update linked to active visit.
- [x] Patient can submit app feedback linked to active visit.
- [x] Alert-required feedback response acknowledges staff review without diagnosis or treatment-order wording.
- [x] Submitted information view is scoped to the current patient/visit only.
- [x] No staff queue dashboard, staff action controls, completed staff history, or staff alert review screen appears in mobile UI.
- [x] `patient_app/lib/main.dart` and `flutter_frontend/lib/main.dart` are not copied as host app entry points.
