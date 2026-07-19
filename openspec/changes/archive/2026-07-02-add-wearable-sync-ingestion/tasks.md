## 1. Backend Ingestion API

- [x] 1.1 Add backend wearable ingestion request/response schemas with patient id, metrics, timestamp, recorded-on time, and source metadata.
- [x] 1.2 Add an eHospital table write helper in the backend client layer for POSTing normalized rows.
- [x] 1.3 Implement a wearable ingestion service that validates at least one metric, rejects malformed values, normalizes `timestamp` and `recorded_on`, and prepares the `wearable_vitals` row.
- [x] 1.4 Add `POST /wearables/ingest` router and register it in the FastAPI app.
- [x] 1.5 Return a stable ingestion response containing patient id, accepted metric names, source label, stored timestamp, and ingestion status.

## 2. Backend Tests

- [x] 2.1 Add API contract tests for successful `POST /wearables/ingest` with mocked eHospital write behavior.
- [x] 2.2 Verify successful ingestion tests assert response shape, accepted metric names, source label, stored timestamp, and normalized row sent to eHospital.
- [x] 2.3 Add API contract tests for missing patient id, no metric values, negative metric values, and malformed timestamps.
- [x] 2.4 Verify invalid payload tests assert the eHospital write helper is not called.
- [x] 2.5 Add tests that eHospital write failures return a gateway-style ingestion error without reporting success.
- [x] 2.6 Run the backend test subset covering assistant/query regressions and new wearable ingestion behavior.

## 3. Flutter Wearable Sync Service

- [x] 3.1 Add Flutter wearable sample and sync result models for normalized ingestion payloads and user-visible sync outcomes.
- [x] 3.2 Add a backend wearable ingestion repository/client method using `BACKEND_BASE_URL`.
- [x] 3.3 Implement `WearableSyncService` as the shared orchestrator for manual uploads, simulation uploads, `AppleHealthSyncService`, and `GoogleHealthSyncService`.
- [x] 3.4 Keep any legacy wearable upload facade as a temporary compatibility wrapper that delegates to `WearableSyncService`.
- [x] 3.5 Add Flutter tests for backend ingestion repository request path, JSON body mapping, response parsing, and API error mapping.
- [x] 3.6 Add Flutter tests for `WearableSyncService` routing with fake `AppleHealthSyncService`, fake `GoogleHealthSyncService`, and fake ingestion repository.

## 4. Platform Source Adapters

- [x] 4.1 Extract Apple Health reading from Vitals screen code into `AppleHealthSyncService`.
- [x] 4.2 Add `GoogleHealthSyncService` that checks Google Health / Health Connect availability and permission before reading Android health data through the existing health plugin.
- [x] 4.3 Ensure unavailable or permission-denied Apple/Google health sources return explicit sync failure results rather than attempting direct table writes.
- [x] 4.4 Normalize units consistently before upload, including sleep duration and active calories.

## 5. Screen Migration

- [x] 5.1 Update the Vitals manual log sheet to upload through `WearableSyncService`.
- [x] 5.2 Update the Vitals health sync action to choose `AppleHealthSyncService` or `GoogleHealthSyncService` through `WearableSyncService`.
- [x] 5.3 Update the Device simulation flow to upload generated samples through `WearableSyncService`.
- [x] 5.4 Confirm screen messaging displays structured success and failure results from the sync service.
- [x] 5.5 Add or update tests that verify manual and simulation upload callers route through `WearableSyncService` rather than constructing direct eHospital wearable POST requests.

## 6. Verification

- [x] 6.1 Run Flutter analyzer and relevant Flutter tests.
- [x] 6.2 Run backend tests in the `langgraph` conda environment.
- [x] 6.3 Manually smoke test manual wearable upload against a local backend and confirm `wearable_vitals` refreshes in the UI.
- [x] 6.4 Document the limitation that this change provides foreground/service-ready near-real-time ingestion, while continuous background scheduling remains a follow-up.
