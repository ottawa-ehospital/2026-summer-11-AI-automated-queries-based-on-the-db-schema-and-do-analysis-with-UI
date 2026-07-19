# flutter-api-layer Specification

## Purpose
TBD - created by archiving change add-python-ai-backend-service. Update Purpose after archive.
## Requirements
### Requirement: Flutter pages use API abstractions
Flutter screens SHALL call dedicated API clients or repositories instead of embedding raw HTTP transport logic directly in page widgets.

#### Scenario: Screen needs eHospital table data
- **WHEN** a screen needs eHospital data
- **THEN** it calls a reusable Flutter API service or repository
- **THEN** the screen does not construct the remote table URL itself

#### Scenario: Screen sends wearable vitals
- **WHEN** a screen uploads wearable vitals
- **THEN** it uses a reusable upload service that handles endpoint construction and errors

#### Scenario: Screen needs login
- **WHEN** a screen or login form needs to authenticate a user
- **THEN** it calls the auth repository or equivalent API abstraction
- **AND** the screen does not construct remote eHospital or React/Node login URLs itself

### Requirement: Flutter backend client is configurable
The Flutter app SHALL read the Python backend base URL from configuration and use it for backend AI endpoints.

#### Scenario: Local development backend
- **WHEN** Flutter is launched with `BACKEND_BASE_URL=http://127.0.0.1:8000`
- **THEN** backend AI calls are sent to that URL

#### Scenario: Mobile device backend
- **WHEN** Flutter runs on a phone with a LAN backend URL
- **THEN** backend AI calls use the configured LAN or deployed URL rather than `127.0.0.1`

### Requirement: API errors are surfaced consistently
Flutter API clients SHALL expose consistent errors to screens for failed backend or eHospital calls.

#### Scenario: Backend returns an error
- **WHEN** the Python backend returns a non-success HTTP status
- **THEN** the Flutter API layer converts it into a clear error message for the screen

### Requirement: Flutter report interpreter uses repository API boundary
The Flutter report interpreter feature SHALL call a dedicated repository or API client rather than embedding raw HTTP transport logic in widgets.

#### Scenario: Report upload request
- **WHEN** the report interpreter uploads a report file
- **THEN** the screen calls the report interpreter repository
- **THEN** the screen does not construct multipart endpoint URLs directly

#### Scenario: Saved record request
- **WHEN** the report interpreter loads saved record dates or saved record text
- **THEN** the screen calls the report interpreter repository
- **THEN** endpoint path construction remains outside the screen widget

### Requirement: Flutter report interpreter uses backend base URL
The Flutter report interpreter repository SHALL use the configured `BACKEND_BASE_URL` and `/report-interpreter` paths.

#### Scenario: Local development backend
- **WHEN** Flutter is launched with `BACKEND_BASE_URL=http://127.0.0.1:8000`
- **THEN** report interpreter calls are sent to `http://127.0.0.1:8000/report-interpreter/*`

#### Scenario: Extracted API base URL is not used
- **WHEN** the report interpreter is integrated into the host app
- **THEN** Flutter does not require the extracted app's `API_BASE_URL=http://localhost:3001` configuration

### Requirement: Flutter login uses backend authentication boundary
The Flutter app SHALL submit login requests through the Python backend authentication endpoint rather than scanning remote eHospital tables directly.

#### Scenario: User submits login form
- **WHEN** the user enters credentials and submits the login form
- **THEN** Flutter sends `email`, `password`, and `selectedOption` to the configured Python backend `/login` endpoint
- **AND** Flutter does not call remote eHospital `/table/users` or role tables directly for authentication

#### Scenario: Backend rejects credentials
- **WHEN** the Python backend returns an authentication failure for the submitted credentials
- **THEN** Flutter shows a clear invalid-credentials error without persisting a new patient id

#### Scenario: Backend returns remote-login network error
- **WHEN** the Python backend reports that remote eHospital authentication is unavailable
- **THEN** Flutter surfaces the backend error through its standard API error handling path

### Requirement: Flutter login exposes eHospital identity selector
The Flutter login UI SHALL allow the user to select an eHospital identity compatible with the remote React/Node login contract.

#### Scenario: Login screen opens
- **WHEN** the login screen is displayed
- **THEN** the identity selector includes `Admin`, `Patient`, `Doctor`, `Clinic`, `PharmaAdmin`, `Pharma`, and `ClinicalReasoning`
- **AND** `Patient` is selected by default

#### Scenario: User chooses a non-patient identity
- **WHEN** the user selects a non-patient identity and submits valid credentials
- **THEN** Flutter sends the selected identity to the backend unchanged
- **AND** Flutter does not fabricate a patient session if the response lacks a patient id

### Requirement: Health Goals uses a repository for training records
Health Goals SHALL retrieve training records through a reusable repository or service boundary instead of constructing remote table URLs or parsing transport responses directly in the screen widget.

#### Scenario: Screen loads training records
- **WHEN** Health Goals needs workout history for the current patient
- **THEN** it calls a repository or service method with the patient id
- **THEN** endpoint path construction, response normalization, and row parsing happen outside `HealthGoalsScreen`

#### Scenario: Repository normalizes remote response shapes
- **WHEN** the remote workout-history source returns either a raw list or a wrapped response shape
- **THEN** the repository normalizes the response into typed training records for callers
- **THEN** Health Goals receives a consistent success or error result

### Requirement: Training Records API behavior has tests
The Flutter API layer SHALL include tests for training record retrieval and response parsing.

#### Scenario: Repository request is tested
- **WHEN** tests fetch training records through the repository with a fake API client
- **THEN** they verify the expected remote path or backend endpoint and patient id query are used
- **THEN** they verify records are parsed into typed models

#### Scenario: Repository error is tested
- **WHEN** the remote source returns an error or malformed response in tests
- **THEN** the repository exposes a consistent failure for Health Goals
- **THEN** the screen does not need to inspect HTTP status codes or raw response shapes

