## Context

The app logs users in by email from the eHospital `users` table, then stores `users.user_id` as the selected patient id. Backend assistant and query flows scope data by `patient_id`. LLM analysis demos therefore need stable users whose ids align with patient-scoped rows in eHospital health tables.

The existing schema has suitable tables for the scenarios:

- `wearable_vitals` for heart rate, steps, calories, and sleep.
- `vitals_history` for blood pressure and symptom notes.
- `diagnosis` and `medical_history` for hypertension context.
- `prescription_form` for active antihypertensive medication context.
- `patients_registration` and `users` for identity and login.

## Goals / Non-Goals

**Goals:**

- Create or reuse exactly three demo patients by fixed email.
- Print the final email-to-patient-id mapping so ids can be documented or hard-coded in demo workflows.
- Insert recent 3-hour scenario data only when recent data is missing by default.
- Support an explicit refresh mode that inserts a fresh current-window dataset.
- Keep symptoms in `vitals_history.notes` instead of introducing or relying on a separate symptom table.
- Keep the script usable against the configured eHospital base URL without requiring a backend server to be running locally.

**Non-Goals:**

- Delete or mutate existing remote demo rows.
- Create new database tables or migrations.
- Replace real Apple Health ingestion, wearable ingestion, or alert-analysis workflows.
- Provide clinical diagnosis or notification decisions directly from the seed script.

## Decisions

### Decision 1: Fixed emails are the identity source

The script uses three fixed emails:

- `llm.demo.normal@example.com`
- `llm.demo.hypertension@example.com`
- `llm.demo.sleep@example.com`

If a user already exists for an email, the script reuses that user's id. If not, it creates the user with a fixed numeric id. This keeps repeated runs stable while still respecting already-seeded environments.

Alternative considered: always hard-code patient ids and fail if they already exist. Rejected because demo environments may already have the users after a previous run.

### Decision 2: `users.user_id` is reused as `patient_id`

The Flutter login path stores `users.user_id` as `patient_id`, so the seed tool aligns `patients_registration.patient_id` and all health rows with that id. This makes the seeded accounts work in both the app and backend assistant query paths.

Alternative considered: create separate patient ids and maintain a mapping. Rejected because the current app does not use a separate mapping during login.

### Decision 3: Scenario rows are idempotent by recent measurement window

By default, the script checks `wearable_vitals` and `vitals_history` for each patient within the last three hours. If recent measurement rows exist, it skips inserting new recent scenario rows. Context rows such as diagnosis, medical history, and prescription are ensured independently.

Alternative considered: deduplicate every row with generated primary keys. Rejected because wearable/vitals rows represent time-series demo measurements and should be refreshable for demos.

### Decision 4: Symptoms live in `vitals_history.notes`

Symptoms for hypertension and sleep deprivation are appended to the latest relevant `vitals_history.notes` row. This keeps the symptom evidence next to the blood-pressure reading the LLM will query and avoids depending on `patient_feedback` for symptom semantics.

Alternative considered: seed `patient_feedback`. Rejected because the user's preferred representation is `vitals_history.notes`, and it better matches the existing LLM evidence path.

## Risks / Trade-offs

- Remote eHospital table constraints may differ from schema inventory -> Use explicit stable ids for context rows and surface insert errors with table names.
- Repeated `--refresh-recent` runs intentionally create more recent rows -> Keep default mode idempotent and make refresh explicit.
- Existing demo users could have unexpected numeric ids -> Reuse the remote id and print it so the final mapping is transparent.
- Timezone confusion during demos -> Generate UTC timestamps and print `window_start`/`window_end` in the JSON result.

## Migration Plan

1. Add the seed script and unit tests.
2. Run the script once to create/reuse demo patients and seed current rows.
3. Document the resulting patient ids in the response or demo instructions.
4. Rollback by removing the script/tests; remote demo rows may remain because they are explicitly marked as demo data and are scoped to fixed demo emails.

## Open Questions

- Should future iterations add a cleanup command for these demo users and rows?
- Should a later workflow expose this through a backend-only admin/debug endpoint, or keep it as a local developer script?
