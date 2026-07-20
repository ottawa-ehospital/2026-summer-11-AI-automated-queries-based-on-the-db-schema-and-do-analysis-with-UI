## ADDED Requirements

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

## MODIFIED Requirements

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
