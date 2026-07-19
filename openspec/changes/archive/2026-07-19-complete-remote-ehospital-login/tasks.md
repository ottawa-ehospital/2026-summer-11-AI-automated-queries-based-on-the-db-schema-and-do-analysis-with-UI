## 1. Backend Authentication Boundary

- [x] 1.1 Add or update backend login request schemas to accept `email`, `password`, and `selectedOption` for remote eHospital login, and remove the legacy local `username/password` runtime login shape.
- [x] 1.2 Add validation for supported eHospital identity values: `Admin`, `Patient`, `Doctor`, `Clinic`, `PharmaAdmin`, `Pharma`, and `ClinicalReasoning`.
- [x] 1.3 Implement a backend eHospital auth client that posts to `${EHOSPITAL_AUTH_BASE_URL}/api/users/login` and maps remote 400/401/403 failures to authentication errors.
- [x] 1.4 Normalize remote login payloads into stable fields, including `id` or equivalent remote ids to `patient_id` and `user_id`, email variants to `email`, and name parts to `username`.
- [x] 1.5 Strip sensitive fields including `password`, `Password`, `password_hash`, `hash`, and `token` before returning login responses.
- [x] 1.6 Remove runtime `/login` reads from `src/local_db/users.json` and delete or quarantine local JSON auth fixtures so they are not used by app login.

## 2. Runtime Configuration And Observability

- [x] 2.1 Add `EHOSPITAL_AUTH_BASE_URL` to backend settings with default `https://tysnx3mi2s.us-east-1.awsapprunner.com`.
- [x] 2.2 Wire `EHOSPITAL_AUTH_BASE_URL` through Makefile and PowerShell startup flows without regressing existing Ollama/model environment settings.
- [x] 2.3 Include the eHospital auth base URL in backend readiness logs without logging credentials or response bodies.
- [x] 2.4 Document how to override `EHOSPITAL_AUTH_BASE_URL` for a local React/Node backend running on a different port.

## 3. Flutter Login Experience

- [x] 3.1 Update the login form to collect email, password, and selected eHospital identity.
- [x] 3.2 Add identity selector UI options matching the React/Node backend and default selection to `Patient`.
- [x] 3.3 Update Flutter auth repository/service code to call the Python backend `/login` endpoint with `email`, `password`, and `selectedOption`.
- [x] 3.4 Remove direct `/table/users` scanning from the normal Flutter login path.
- [x] 3.5 Persist successful patient login responses into existing `patient_id`, `patient_email`, and `patient_username` session keys.
- [x] 3.6 Persist non-patient identity metadata without writing a fabricated or stale `patient_id`.
- [x] 3.7 Show invalid-credentials and remote-auth-unavailable errors through the existing API error handling path.

## 4. Patient-Scoped Workflow Guardrails

- [x] 4.1 Audit screens and repositories that read `patient_id` to ensure they handle missing patient context after non-patient login.
- [x] 4.2 Add or preserve patient-context-required UI states for patient-scoped modules when the active login has no patient id.
- [x] 4.3 Verify patient id `382` style remote ids can flow through existing assistant, wearable, report, and health-goal request payloads as strings or ints according to existing contracts.

## 5. Tests And Documentation

- [x] 5.1 Add backend tests for successful remote patient login with mocked Node response normalization.
- [x] 5.2 Add backend tests for rejected credentials, unsupported `selectedOption`, remote service failure, and sensitive-field stripping.
- [x] 5.3 Add Flutter auth repository tests proving `/login` request shape and patient session persistence.
- [x] 5.4 Add Flutter login UI tests for password entry, identity selector options, invalid credentials, and non-patient response handling.
- [x] 5.5 Update API documentation to describe the remote eHospital login contract and note that local JSON login is no longer supported.
- [x] 5.6 Run targeted backend and Flutter tests, then run broader checks appropriate for touched files.
