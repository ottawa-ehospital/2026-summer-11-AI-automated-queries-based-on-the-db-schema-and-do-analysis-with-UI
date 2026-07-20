## ADDED Requirements

### Requirement: Flutter pages use API abstractions
Flutter screens SHALL call dedicated API clients or repositories instead of embedding raw HTTP transport logic directly in page widgets.

#### Scenario: Screen needs eHospital table data
- **WHEN** a screen needs eHospital data
- **THEN** it calls a reusable Flutter API service or repository
- **THEN** the screen does not construct the remote table URL itself

#### Scenario: Screen sends wearable vitals
- **WHEN** a screen uploads wearable vitals
- **THEN** it uses a reusable upload service that handles endpoint construction and errors

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
