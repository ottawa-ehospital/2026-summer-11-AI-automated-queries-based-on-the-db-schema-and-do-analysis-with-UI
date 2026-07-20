## Why

Wearable data is currently uploaded from individual Flutter screens, often through manual or simulated flows, so the app does not yet have a reliable data collection layer for near-real-time health monitoring. This change creates a backend-centered ingestion path so newly collected wearable data can be normalized, stored, and later used for timely risk reasoning and clinician alerts.

## What Changes

- Add a Flutter `WearableSyncService` boundary that owns wearable data synchronization instead of leaving Apple Health, Google health data, manual entry, and simulation paths scattered across screens.
- Implement `WearableSyncService` as a shared orchestrator that delegates health-platform collection to two concrete sync services: `AppleHealthSyncService` for Apple Health and `GoogleHealthSyncService` for Google Health / Android Health Connect.
- Add a Python backend `POST /wearables/ingest` endpoint that receives wearable payloads from Flutter, validates them, writes them to the eHospital `wearable_vitals` table, and returns a structured ingestion result.
- Route Flutter wearable uploads through the Python backend rather than posting directly to the eHospital table from UI-facing code.
- Preserve existing manual/demo upload behavior by adapting it to the same sync service and ingestion endpoint.
- Add tests for the affected API boundaries, including backend ingestion request/response behavior, Flutter backend-client payload construction, and migrated upload callers.
- Defer full doctor alert delivery to a later change, but shape ingestion responses and stored records so an alert pipeline can run immediately after ingestion in a follow-up.

## Capabilities

### New Capabilities
- `wearable-sync-service`: Flutter-side wearable synchronization service, including shared payload normalization, `AppleHealthSyncService`, `GoogleHealthSyncService`, manual/demo upload routing, and sync status reporting.
- `backend-wearable-ingestion`: Backend endpoint and service contract for accepting normalized wearable data, validating it, writing `wearable_vitals`, and returning ingestion results.

### Modified Capabilities
None.

## Impact

- Backend code under `src/backend`, likely adding `api/wearables.py`, wearable schemas, ingestion service logic, and eHospital write client support.
- Flutter code under `src/app/lib`, likely adding a wearable sync service/repository plus `AppleHealthSyncService` and `GoogleHealthSyncService`.
- Existing Vitals and Device screens will call the new sync service for manual, simulated, and health-platform sync actions.
- Configuration remains split between `BACKEND_BASE_URL` for ingestion/AI and `EHOSPITAL_BASE_URL` for backend-side table access.
- Tests SHALL cover backend ingestion validation/write behavior, Flutter backend-client request/response mapping, service routing, and migrated upload callers without requiring real Apple Health or Android Health Connect permissions.
