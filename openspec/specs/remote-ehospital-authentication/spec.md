# remote-ehospital-authentication Specification

## Purpose
TBD - created by archiving change complete-remote-ehospital-login. Update Purpose after archive.
## Requirements
### Requirement: Backend proxies remote eHospital login
The Python backend SHALL provide a `POST /login` contract that authenticates eHospital users through the configured remote React/Node backend using `email`, `password`, and `selectedOption`.

#### Scenario: Patient credentials are accepted remotely
- **WHEN** a login request supplies a patient email, password, and `selectedOption` of `Patient`
- **THEN** the backend sends those credentials to `EHOSPITAL_AUTH_BASE_URL/api/users/login`
- **AND** the backend returns a successful normalized login response

#### Scenario: Remote credentials are rejected
- **WHEN** the remote eHospital login endpoint rejects the credentials
- **THEN** the backend returns an authentication failure without creating a local patient session

#### Scenario: Remote login service is unavailable
- **WHEN** the remote eHospital login endpoint cannot be reached or returns an unexpected server failure
- **THEN** the backend returns a gateway-style error with a clear message
- **AND** the backend does not fall back to local JSON users for the same mobile login request

### Requirement: Login preserves eHospital identity selection
The login contract SHALL support the eHospital identity values used by the React/Node login flow: `Admin`, `Patient`, `Doctor`, `Clinic`, `PharmaAdmin`, `Pharma`, and `ClinicalReasoning`.

#### Scenario: Patient identity is selected
- **WHEN** the user logs in with `selectedOption` set to `Patient`
- **THEN** the backend proxies the request with `selectedOption` unchanged
- **AND** the normalized response is eligible to populate patient-scoped session fields when a remote patient id is returned

#### Scenario: Non-patient identity is selected
- **WHEN** the user logs in with a non-patient supported identity
- **THEN** the backend proxies the request with `selectedOption` unchanged
- **AND** the response preserves role metadata without fabricating a patient id

#### Scenario: Unsupported identity is submitted
- **WHEN** a login request supplies a `selectedOption` outside the supported eHospital identity set
- **THEN** the backend rejects the request before proxying it to the remote Node backend

### Requirement: Backend normalizes remote login payloads
The backend SHALL normalize remote role-specific login payloads into stable fields used by the Flutter session layer.

#### Scenario: Patient payload contains remote id and EmailId
- **WHEN** the remote patient payload includes `id` and `EmailId`
- **THEN** the backend response includes `patient_id`, `user_id`, `email`, and `username`
- **AND** `patient_id` and `user_id` match the remote `id`

#### Scenario: Payload contains name parts
- **WHEN** the remote payload includes `FName`, `MName`, or `LName`
- **THEN** the backend derives a readable `username` from the available name parts

#### Scenario: Payload already contains normalized fields
- **WHEN** the remote payload already contains normalized `patient_id`, `user_id`, `email`, or `username` fields
- **THEN** the backend preserves those fields unless they are empty

### Requirement: Login responses do not leak sensitive fields
The backend SHALL remove sensitive authentication fields from remote login payloads before returning them to Flutter.

#### Scenario: Remote patient payload contains password
- **WHEN** the remote eHospital login response includes `password` or `Password`
- **THEN** the backend response sent to Flutter does not include those fields

#### Scenario: Remote payload contains token-like secrets
- **WHEN** the remote eHospital login response includes `password_hash`, `hash`, or `token`
- **THEN** the backend response sent to Flutter does not include those fields

#### Scenario: Login request is logged
- **WHEN** the backend handles a login request
- **THEN** application logs do not include the submitted password or raw remote response body

### Requirement: Flutter stores normalized remote session context
The Flutter app SHALL authenticate through the Python backend login endpoint and persist normalized session context from the backend response.

#### Scenario: Patient login succeeds
- **WHEN** Flutter receives a successful patient login response containing `patient_id`, `email`, and `username`
- **THEN** it stores `patient_id`, `patient_email`, and `patient_username` in the existing local session storage
- **AND** patient-scoped features continue to read the active patient id from that storage

#### Scenario: Login response lacks patient id
- **WHEN** Flutter receives a successful non-patient login response without a patient id
- **THEN** it stores identity metadata separately from `patient_id`
- **AND** patient-scoped screens show a patient-context-required or unsupported-role state instead of using stale patient data

### Requirement: Local JSON login is removed
Local JSON `username/password` login SHALL be removed from supported runtime authentication behavior.

#### Scenario: Mobile login submits email credentials
- **WHEN** Flutter submits email, password, and selected identity
- **THEN** the backend uses the remote eHospital authentication path
- **AND** the backend does not authenticate against `src/local_db/users.json`

#### Scenario: Legacy username credentials are submitted
- **WHEN** a request submits the legacy local `username/password` shape without remote email credentials
- **THEN** the backend rejects the request or routes it to a clearly separate non-runtime test harness
- **AND** the runtime `/login` endpoint does not read `src/local_db/users.json`

#### Scenario: Login tests need deterministic users
- **WHEN** automated tests need deterministic authentication responses
- **THEN** they mock the remote eHospital auth client or use test-local fixtures
- **AND** they do not require runtime local JSON user files

