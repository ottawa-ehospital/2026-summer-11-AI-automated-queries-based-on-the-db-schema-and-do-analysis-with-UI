# llm-health-demo-seed-tool Specification

## Purpose
Defines the developer/demo seed tool for creating fixed LLM health-analysis demo patients and current scenario data.

## Requirements
### Requirement: Demo seed tool creates fixed demo patients
The system SHALL provide a developer-run seed tool that creates or reuses fixed-email demo patients for LLM health-analysis validation.

#### Scenario: Demo users are missing
- **WHEN** the seed tool runs and a fixed demo email is not present in `users`
- **THEN** it creates a `users` row with a stable numeric user id
- **THEN** it creates a matching `patients_registration` row whose `patient_id` matches that user id

#### Scenario: Demo users already exist
- **WHEN** the seed tool runs and a fixed demo email already exists in `users`
- **THEN** it reuses the existing numeric id as the demo patient id
- **THEN** it prints the final email-to-patient-id mapping

### Requirement: Demo seed tool inserts three current health scenarios
The system SHALL seed three independent patient scenarios for LLM analysis testing: normal indicators, hypertension with medication context and symptom notes, and sleep deprivation under four hours.

#### Scenario: Normal indicators are seeded
- **WHEN** recent scenario data is missing for the normal demo patient
- **THEN** the tool inserts recent `wearable_vitals` rows with normal heart rate, activity, calories, and sleep
- **THEN** it inserts recent `vitals_history` rows with normal blood pressure

#### Scenario: Hypertension context is seeded
- **WHEN** recent scenario data is missing for the hypertension demo patient
- **THEN** the tool inserts elevated recent blood-pressure rows into `vitals_history`
- **THEN** it ensures hypertension diagnosis/history context and an active antihypertensive prescription
- **THEN** it stores headache and dizziness symptom context in `vitals_history.notes`

#### Scenario: Sleep deprivation context is seeded
- **WHEN** recent scenario data is missing for the sleep-deprivation demo patient
- **THEN** the tool inserts `wearable_vitals.sleep` values below four hours
- **THEN** it stores fatigue and poor-concentration symptom context in `vitals_history.notes`

### Requirement: Demo seed tool is idempotent by default
The system SHALL avoid inserting duplicate current-window scenario measurements when recent data already exists for a demo patient.

#### Scenario: Recent data already exists
- **WHEN** the seed tool finds `wearable_vitals` or `vitals_history` rows for a demo patient inside the configured recent window
- **THEN** it skips inserting new recent scenario measurements for that patient
- **THEN** it still ensures reusable context rows such as diagnosis, medical history, and prescription

#### Scenario: Refresh mode is requested
- **WHEN** the seed tool is run with explicit refresh mode
- **THEN** it inserts a fresh set of recent scenario measurements even if current-window rows already exist
- **THEN** the response identifies that refresh mode was used

### Requirement: Demo seed tool reports deterministic output
The seed tool SHALL print a structured JSON summary of the seeding run.

#### Scenario: Seed run completes
- **WHEN** the seed tool finishes
- **THEN** it prints the eHospital base URL, analysis window start and end, refresh setting, scenario name, fixed email, final patient id, and actions taken for each demo patient
