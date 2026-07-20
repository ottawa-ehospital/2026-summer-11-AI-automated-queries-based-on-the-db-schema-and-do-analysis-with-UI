# backend-wearable-ingestion Specification

## Purpose
TBD - created by archiving change add-wearable-sync-ingestion. Update Purpose after archive.
## Requirements
### Requirement: Backend accepts wearable ingestion requests
The Python backend SHALL expose `POST /wearables/ingest` for normalized wearable samples submitted by Flutter.

#### Scenario: Valid wearable sample is ingested
- **WHEN** Flutter sends a valid wearable sample with patient id, timestamp, and at least one supported metric
- **THEN** the backend validates the request
- **THEN** the backend writes the sample to the eHospital `wearable_vitals` table
- **THEN** the backend returns a structured success response

#### Scenario: Wearable sample has no metrics
- **WHEN** Flutter sends a wearable sample without heart rate, steps, calories, or sleep values
- **THEN** the backend rejects the request with a client-visible validation error

### Requirement: Backend validates wearable sample shape
The Python backend SHALL validate wearable ingestion payloads before writing them to eHospital.

#### Scenario: Invalid patient id is submitted
- **WHEN** Flutter sends an ingestion request with an empty or missing patient id
- **THEN** the backend rejects the request without calling the eHospital write endpoint

#### Scenario: Invalid metric value is submitted
- **WHEN** Flutter sends an ingestion request with a negative metric value or malformed timestamp
- **THEN** the backend rejects the request without calling the eHospital write endpoint

### Requirement: Backend normalizes ingestion writes
The Python backend SHALL transform accepted wearable ingestion requests into the eHospital `wearable_vitals` table shape.

#### Scenario: Timestamp is provided
- **WHEN** a valid ingestion request includes a timestamp
- **THEN** the backend writes the timestamp to `wearable_vitals.timestamp`
- **THEN** the backend includes `recorded_on` using the provided recorded time or the sample timestamp

#### Scenario: Optional source metadata is provided
- **WHEN** a valid ingestion request includes source metadata such as `apple_health`, `google_health`, `manual`, or `simulation`
- **THEN** the backend accepts the metadata for observability
- **THEN** the backend does not fail if the remote `wearable_vitals` schema cannot persist that metadata

### Requirement: Backend ingestion errors are consistent
The Python backend SHALL return consistent errors for validation failures and eHospital write failures.

#### Scenario: eHospital write fails
- **WHEN** the eHospital table write returns an error or cannot be reached
- **THEN** the backend returns a gateway-style error describing that wearable ingestion failed
- **THEN** the backend does not report the sample as ingested

#### Scenario: Ingestion succeeds
- **WHEN** the eHospital table write succeeds
- **THEN** the backend response includes the patient id, accepted metric names, source label, and stored timestamp

### Requirement: Backend ingestion API has contract tests
The Python backend SHALL include tests for the `/wearables/ingest` API contract and eHospital write boundary.

#### Scenario: Ingestion endpoint test covers successful request
- **WHEN** the backend test suite exercises `POST /wearables/ingest` with a valid wearable sample and a mocked eHospital write
- **THEN** the test verifies the HTTP status, response fields, accepted metric names, source label, and normalized row sent to eHospital

#### Scenario: Ingestion endpoint test covers rejected request
- **WHEN** the backend test suite exercises `POST /wearables/ingest` with invalid payloads such as missing patient id, no metric values, negative metrics, or malformed timestamp
- **THEN** the tests verify client-visible errors
- **THEN** the tests verify the eHospital write helper is not called

#### Scenario: Ingestion endpoint test covers write failure
- **WHEN** the mocked eHospital write fails during an ingestion endpoint test
- **THEN** the test verifies the backend returns a gateway-style error
- **THEN** the response does not report the sample as ingested

### Requirement: Backend supports patient-scoped wearable workout history retrieval
The backend or configured remote data layer SHALL provide a patient-scoped way to retrieve workout records from `wearable_workouts` for app features that need to display training history.

#### Scenario: Patient workout history is retrieved
- **WHEN** the app requests workout history for a patient id
- **THEN** the remote data layer returns only workout rows belonging to that patient
- **THEN** each returned row includes the fields needed for display, including workout type, start time, end time, duration, distance, energy, steps, source provider, and source workout id when available

#### Scenario: Unknown patient has no records
- **WHEN** the app requests workout history for a patient id with no matching workout rows
- **THEN** the remote data layer returns an empty result rather than rows from another patient

#### Scenario: Remote workout history retrieval fails
- **WHEN** the remote `wearable_workouts` source cannot be reached or returns an invalid response
- **THEN** the app receives a client-visible retrieval error
- **THEN** the failure is distinguishable from a successful empty workout history

### Requirement: Workout history retrieval preserves ingestion identity
Workout history retrieval SHALL expose source identity fields needed to avoid confusing duplicate provider records.

#### Scenario: Source identity is available
- **WHEN** a retrieved workout row has `source_provider` and `source_workout_id`
- **THEN** those fields are available to the Flutter model
- **THEN** the UI can use them as stable record keys when present

#### Scenario: Duplicate-safe rows are displayed once
- **WHEN** the remote source returns multiple rows with the same `source_provider` and `source_workout_id`
- **THEN** the app layer de-duplicates or otherwise avoids rendering visually duplicated training records in the Health Goals module

