## ADDED Requirements

### Requirement: Backend accepts wearable workout ingestion requests
The Python backend SHALL expose workout ingestion endpoints for normalized workout records submitted by Flutter or native iOS mobile adapters.

#### Scenario: Valid workout is ingested
- **WHEN** a caller sends a valid workout payload with patient id, source provider, source workout id, workout type, start time, end time, and duration
- **THEN** the backend validates the request
- **THEN** the backend writes a normalized row to `wearable_workouts`
- **THEN** the backend returns a structured success response containing patient id, source provider, source workout id, workout type, and ingestion status

#### Scenario: Batch workout upload is ingested
- **WHEN** a caller sends multiple valid workout payloads in one batch request
- **THEN** the backend validates each workout record
- **THEN** the backend writes the accepted workouts to `wearable_workouts`
- **THEN** the backend returns a structured result that reports the number of accepted records

### Requirement: Backend validates workout payload shape
The Python backend SHALL reject malformed workout ingestion payloads before writing to the database.

#### Scenario: Required identity is missing
- **WHEN** a workout payload is missing patient id, source provider, source workout id, or workout type
- **THEN** the backend rejects the request with a client-visible validation error
- **THEN** the backend does not write a workout row

#### Scenario: Invalid workout time window is submitted
- **WHEN** a workout payload has an end time before the start time or a negative duration
- **THEN** the backend rejects the request with a client-visible validation error
- **THEN** the backend does not write a workout row

#### Scenario: Invalid workout metric is submitted
- **WHEN** a workout payload includes a negative distance, energy, steps, speed, cadence, elevation, or heart-rate metric
- **THEN** the backend rejects the request with a client-visible validation error
- **THEN** the backend does not write a workout row

### Requirement: Backend normalizes workout writes
The Python backend SHALL transform accepted workout ingestion requests into the `wearable_workouts` table shape without requiring the caller to know database implementation details.

#### Scenario: Apple-style workout fields are provided
- **WHEN** a workout payload includes Apple HealthKit-style fields such as activity type, bundle id, device metadata, duration, distance, active energy, and heart-rate summary
- **THEN** the backend maps those fields to the corresponding `wearable_workouts` columns
- **THEN** provider-specific details that do not have normalized columns are preserved in `source_metadata` or `raw_payload`

#### Scenario: Fitbit-compatible fields are provided
- **WHEN** a workout payload includes Fitbit-compatible fields such as activity id, activity name, duration, distance, calories, and source record id
- **THEN** the backend maps common fields to normalized workout columns
- **THEN** Fitbit-specific details remain available in provider metadata without changing the common API contract

### Requirement: Workout ingestion is idempotent by source identity
The backend SHALL avoid duplicate workout rows when the same provider workout is uploaded more than once.

#### Scenario: Same source workout is uploaded twice
- **WHEN** a caller uploads a workout with a `source_provider` and `source_workout_id` that already exist
- **THEN** the backend updates or safely preserves the existing database record
- **THEN** the response reports success without creating a duplicate workout row

### Requirement: Backend workout ingestion errors are consistent
The backend SHALL return consistent errors for validation failures and database write failures.

#### Scenario: Database write fails
- **WHEN** the database or eHospital table write fails during workout ingestion
- **THEN** the backend returns a gateway-style ingestion error
- **THEN** the response does not report the workout as newly ingested

#### Scenario: Ingestion succeeds
- **WHEN** the workout write succeeds
- **THEN** the backend response includes the stored workout identity, source label, workout type, and ingestion status

### Requirement: Backend workout ingestion has contract tests
The backend SHALL include tests for workout ingestion validation, row normalization, idempotency behavior, and error handling.

#### Scenario: Successful workout ingestion is tested
- **WHEN** backend tests call the workout ingestion endpoint with a valid payload and mocked table write behavior
- **THEN** the tests verify the response shape
- **THEN** the tests verify the normalized row sent to `wearable_workouts`

#### Scenario: Rejected workout ingestion is tested
- **WHEN** backend tests call the workout ingestion endpoint with missing identity, invalid time window, or invalid metric values
- **THEN** the tests verify client-visible errors
- **THEN** the tests verify the table write helper is not called

#### Scenario: Duplicate workout ingestion is tested
- **WHEN** backend tests upload the same source workout identity more than once
- **THEN** the tests verify ingestion remains idempotent
- **THEN** the tests verify duplicate rows are not reported as separate workouts
