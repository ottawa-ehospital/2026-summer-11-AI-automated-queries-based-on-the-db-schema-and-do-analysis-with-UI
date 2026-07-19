## ADDED Requirements

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
