## Context

DTI-6302 currently has more than one login concept. The legacy FastAPI demo endpoints can authenticate `username/password` against `src/local_db/users.json`, while the Flutter app has historically looked up remote eHospital users directly by email. Those local JSON records are test data and should not remain part of the supported runtime login path. The eHospital web application and React/Node backend use a different contract: `POST /api/users/login` with `email`, `password`, and `selectedOption`.

The remote AppRunner service at `https://tysnx3mi2s.us-east-1.awsapprunner.com` exposes the Node login endpoint and role-specific tables such as `patients_registration`. A verified patient record includes fields such as `id`, `EmailId`, `FName`, `LName`, and `password`; for example `POST /PatientProfileInfo` with `patientId=382` returns a patient whose remote id is `382`. The mobile app, however, already expects local session keys named `patient_id`, `patient_email`, and `patient_username`, so the integration needs an explicit normalization boundary.

## Goals / Non-Goals

**Goals:**
- Make remote eHospital authentication the normal mobile login path.
- Preserve the eHospital role selector behavior by supporting the same `selectedOption` values as the React/Node UI.
- Normalize patient login responses so existing patient-scoped Flutter and backend workflows continue to receive `patient_id`.
- Prevent sensitive remote login fields from being returned to Flutter or logged.
- Keep remote URLs configurable for deployed AppRunner and local Node backend testing.
- Remove local JSON demo login and replace runtime auth tests with mocked remote-auth fixtures.

**Non-Goals:**
- Do not implement full Doctor/Admin/Clinic/Pharma dashboards in the mobile app.
- Do not introduce token-based authorization or persistent server-side sessions beyond the existing remote login response.
- Do not change patient-scoped assistant, wearable, report interpreter, or nutrition APIs beyond consuming the normalized logged-in patient id.

## Decisions

### Use the Python backend as the login boundary

Flutter will call the Python backend `POST /login` endpoint rather than calling the Node backend or remote tables directly. The Python backend will proxy to `EHOSPITAL_AUTH_BASE_URL/api/users/login`.

Rationale: this keeps remote URL shape, error normalization, sensitive-field filtering, and future auth hardening in one backend-owned boundary. It also avoids exposing Node response quirks directly to Flutter screens.

Alternative considered: Flutter calls `POST /api/users/login` directly. This was rejected because the app would need to parse role-specific payloads, strip sensitive fields, handle CORS/network differences, and update multiple clients if the Node response shape changes.

### Treat remote eHospital as the source of truth

The standard login path will use remote eHospital credentials, not `src/local_db/users.json`. Local JSON `username/password` authentication should be removed from supported runtime API behavior. Tests that need predictable login records should mock the remote auth client or use test-local fixtures, not runtime local DB files.

Rationale: current app features operate on eHospital patient ids and remote patient context. Authenticating against local demo users can produce `u_001`-style ids that do not align with remote patient records.

Alternative considered: keep email-only lookup against `/table/users`. This does not work for the target AppRunner service because that table is absent and the eHospital login contract uses `patients_registration` and `password`.

### Preserve role selector values while gating patient workflows

The login request will carry `selectedOption` values matching the React/Node backend: `Admin`, `Patient`, `Doctor`, `Clinic`, `PharmaAdmin`, `Pharma`, and `ClinicalReasoning`. Flutter should present these options in the login UI, with `Patient` as the default.

Patient login SHALL populate `patient_id` when remote `id` is present. Non-patient login can persist identity metadata, but patient-scoped workflows SHALL require a patient id and show an appropriate unsupported or patient-context-required state when absent.

Rationale: preserving the selector keeps the mobile login model aligned with the eHospital UI without pretending all roles are supported by DTI-6302 health features.

### Normalize and sanitize remote responses

The backend auth client will map common remote fields into stable app fields:
- `id`, `patient_id`, or `user_id` -> `patient_id` and `user_id` for patient records
- `EmailId`, `Email_Id`, or `email` -> `email`
- name fields such as `FName`, `MName`, `LName` -> `username`
- `selectedOption` -> selected identity/role metadata

The backend will remove `password`, `Password`, `password_hash`, `hash`, `token`, and equivalent sensitive fields before returning JSON to Flutter.

Rationale: downstream app code already depends on stable session keys and should not need to know each role's database column names. Sensitive data is currently present in remote responses, so filtering is required at the boundary.

### Make auth base URL explicit

`EHOSPITAL_AUTH_BASE_URL` will default to `https://tysnx3mi2s.us-east-1.awsapprunner.com`, with Makefile, PowerShell, and README guidance for overriding it to a local Node backend. This remains separate from `EHOSPITAL_BASE_URL` because table/API services may not always share exactly the same deployed host.

## Risks / Trade-offs

- Remote Node login returns plaintext password fields -> The Python backend strips sensitive fields before returning or logging payloads.
- Non-patient roles return heterogeneous payloads -> Flutter persists role metadata and only enables patient-scoped workflows when a valid patient id is available.
- Remote service downtime blocks login -> The backend maps network/5xx failures to clear gateway errors and does not silently authenticate against stale local data.
- Existing tests may assume local demo login is the only `/login` contract -> Replace them with mocked remote-auth tests and update smoke checks to use the remote contract boundary.
- The Node backend treats unknown `selectedOption` values through a fallback branch -> Flutter and backend validation should restrict values to the known eHospital identity set before proxying.
