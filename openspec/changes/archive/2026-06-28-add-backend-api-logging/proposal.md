## Why

Developers currently start the Python backend without a clear application-level confirmation that it initialized successfully. API calls also lack consistent request logs, making it harder to tell whether Flutter or smoke-test traffic is reaching the backend.

## What Changes

- Add backend startup logs that identify the Smart Health backend, host/port settings, CORS configuration, eHospital base URL, assistant provider, and model provider.
- Add one consistent log entry for each API request with method, path, status code, and elapsed time.
- Keep existing FastAPI route contracts unchanged.
- Avoid logging request bodies, response bodies, secrets, or patient data.

## Capabilities

### New Capabilities
- `backend-api-observability`: Defines startup and per-request logging expectations for the Python FastAPI backend.

### Modified Capabilities

## Impact

- Affects `src/backend/main.py` and any small backend logging helper added under `src/backend/core`.
- Adds or updates backend tests for startup and API request logging behavior.
- No API response shape changes and no new runtime dependency expected.
