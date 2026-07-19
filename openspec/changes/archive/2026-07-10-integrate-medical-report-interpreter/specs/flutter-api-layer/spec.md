## ADDED Requirements

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
