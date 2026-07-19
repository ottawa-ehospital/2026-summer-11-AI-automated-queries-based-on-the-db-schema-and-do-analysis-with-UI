## Why

The app login path is inconsistent with the eHospital system: older demo endpoints authenticate against local JSON users, while the mobile app expects a remote patient session. Login must use the remote eHospital React/Node backend as the source of truth so patient identity, `patient_id`, and downstream health workflows match the records visible in eHospital pages such as `patientpage?patientId=382`.

## What Changes

- Add a backend-owned remote eHospital authentication contract for `POST /login`.
- Replace local/demo user authentication with remote `POST /api/users/login` on `https://tysnx3mi2s.us-east-1.awsapprunner.com`.
- Preserve the eHospital identity selector behavior by supporting the same `selectedOption` values used by the React/Node UI, even when non-patient roles do not unlock patient-scoped health workflows yet.
- Normalize remote login responses into the mobile session fields already used by the app, especially mapping remote patient `id` to local `patient_id`.
- Strip sensitive fields such as `password`, `Password`, `password_hash`, `hash`, and `token` from backend responses before returning data to Flutter.
- Remove local JSON demo login and runtime authentication dependencies on local test data.

## Capabilities

### New Capabilities
- `remote-ehospital-authentication`: Remote eHospital login, role selection, response normalization, sensitive-field hygiene, and Flutter session persistence.

### Modified Capabilities
- `flutter-api-layer`: Flutter login calls SHALL use the Python backend login boundary instead of direct remote table scans.
- `backend-api-observability`: Backend startup and error reporting SHALL include the remote eHospital authentication base URL/configuration boundary.

## Impact

- Affected backend files: FastAPI login router/schema, eHospital auth client, backend configuration, startup logging, local demo auth cleanup, tests, and API documentation.
- Affected Flutter files: auth repository/service, login screen/form, eHospital user model, localization, and Flutter tests.
- Remote systems: React/Node eHospital backend `POST /api/users/login`, including role values `Admin`, `Patient`, `Doctor`, `Clinic`, `PharmaAdmin`, `Pharma`, and `ClinicalReasoning`.
- Configuration: `EHOSPITAL_AUTH_BASE_URL` defaults to `https://tysnx3mi2s.us-east-1.awsapprunner.com` and remains overrideable for local Node backend testing.
