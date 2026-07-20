## Why

LLM health analysis and alert workflows need repeatable, current patient data to test whether reasoning changes with normal vitals, sustained hypertension, medication context, symptoms, and sleep deprivation. Manually creating users and recent rows is slow and error-prone, especially when demo patient ids must remain stable for app login and backend queries.

## What Changes

- Add a dedicated dataset seed utility that creates or reuses three fixed-email demo patients.
- Ensure each demo patient's `users.user_id` is usable as the app/backend `patient_id`.
- Insert idempotent recent data for a 3-hour analysis window across `wearable_vitals`, `vitals_history`, and supporting clinical context tables.
- Model three scenarios: normal indicators, hypertension with active medication and symptom notes, and sleep deprivation under four hours.
- Store symptom context in `vitals_history.notes` so the LLM can retrieve symptoms together with the relevant clinical reading.
- Provide a refresh mode for demos that need a fresh "current time minus 3 hours" window without waiting for older rows to age out.
- Add tests for idempotency, fixed patient identity, medication context, and symptom-note placement.

## Capabilities

### New Capabilities

- `llm-health-demo-seed-tool`: Developer/demo tooling for creating fixed test patients and current health-analysis scenarios for LLM workflow validation.

### Modified Capabilities

- None.

## Impact

- New script under `src/datasets` for seeding eHospital demo data.
- New tests under `tests`.
- No production API contract changes.
- Writes only to existing eHospital tables: `users`, `patients_registration`, `wearable_vitals`, `vitals_history`, `diagnosis`, `medical_history`, and `prescription_form`.
