## Context

The current app already has pieces of wearable handling: the Vitals screen can manually upload values, Apple Health data can be read from the `health` package in a screen-local method, the Device screen can simulate wearable uploads, and Fitbit has a service that can fetch values but is not part of a unified sync path. These writes currently go directly from Flutter to the remote eHospital table endpoint, so the Python backend cannot validate, normalize, deduplicate, observe, or trigger downstream risk reasoning when new wearable records arrive.

The desired architecture is a data pipeline rather than a page feature. Flutter should collect data from platform sources and submit a normalized payload. The backend should own ingestion, table writes, and the future handoff to alert reasoning.

## Goals / Non-Goals

**Goals:**
- Introduce a Flutter `WearableSyncService` as the single entry point for wearable sync and upload behavior.
- Define `WearableSyncService` as an orchestrator that delegates platform data collection to `AppleHealthSyncService` and `GoogleHealthSyncService`.
- Keep Apple Health and Google Health / Android Health Connect collection logic separate behind concrete sync services.
- Preserve manual and simulated upload behavior by routing them through the same normalized service contract.
- Add a backend `POST /wearables/ingest` endpoint that validates payloads, writes to `wearable_vitals`, and returns a structured result.
- Make the ingestion endpoint the future trigger point for movement-state inference and clinician alerting.

**Non-Goals:**
- Build full doctor alert delivery in this change.
- Guarantee continuous real-time background monitoring on iOS or Android; both platforms impose background execution limits.
- Replace the eHospital database or redesign the `wearable_vitals` schema.
- Implement Fitbit ingestion unless it can reuse the same source-adapter contract without expanding scope.

## Decisions

### Decision 1: Backend-centered ingestion

Flutter wearable writes will call the Python backend at `/wearables/ingest` instead of posting directly to `EHOSPITAL_BASE_URL/table/wearable_vitals`.

Rationale: the backend is the right boundary for validation, unit normalization, deduplication, observability, and future alert triggering. Direct eHospital writes from screens make it impossible to run consistent ingestion-side reasoning.

Alternative considered: keep direct Flutter eHospital writes and add alert checks in Flutter. Rejected because alerts would only run when UI code executes, and doctor-facing workflows should not depend on a patient screen being open.

### Decision 2: One normalized payload, two concrete health sync services

Flutter will define one wearable sample payload with fields compatible with `wearable_vitals`: patient id, heart rate, steps, calories, sleep, timestamp, optional recorded-on time, and source metadata. Platform-specific adapters will produce this payload:

- `AppleHealthSyncService`: reads Apple Health through the existing `health` package on iOS and returns normalized wearable samples.
- `GoogleHealthSyncService`: reads Google Health / Android Health Connect data through the existing `health` package on Android and returns normalized wearable samples.
- Manual/demo upload methods remain on `WearableSyncService` and wrap entered or simulated values with explicit source metadata.

Rationale: Apple Health and Google Health / Android Health Connect have different permission, availability, and background-sync behavior, but downstream ingestion should not branch on platform-specific APIs. Naming the two concrete services makes the implementation boundary clear and testable.

Alternative considered: one large cross-platform sync method inside a screen. Rejected because permission handling, data availability, and test doubles become hard to isolate.

Alternative considered: a generic `AndroidHealthSyncService` name. Rejected because the user-facing integration goal is Google Health / Health Connect, and the class name should make the intended Android health provider explicit.

### Decision 3: First version uses foreground/manual sync plus service-ready hooks

The first implementation will centralize sync operations and make platform collection explicit, but it will not promise continuous background monitoring. Android `WorkManager`, iOS HealthKit observer queries, and background delivery can be added as follow-up scheduling mechanisms around the same service.

Rationale: the current request is to complete the sync service and ingestion endpoint first. A clean service boundary makes background scheduling safer later.

Alternative considered: implement background scheduling immediately. Rejected because it adds platform entitlements, mobile-device testing, and OS-specific reliability concerns before the ingestion contract is stable.

### Decision 4: eHospital write support stays behind backend client code

The backend will extend its eHospital client with a POST/write helper for table rows. The ingestion service will not construct raw HTTP calls inline in the router.

Rationale: the existing backend already centralizes eHospital reads and SELECT queries in `src/backend/clients/ehospital_client.py`. Keeping writes there preserves the same boundary.

Alternative considered: route-level `httpx.post` directly inside `/wearables/ingest`. Rejected because it duplicates transport behavior and makes tests more brittle.

### Decision 5: API boundary changes require contract tests

The backend `/wearables/ingest` endpoint, Flutter backend ingestion repository, and migrated upload callers will each receive tests for the request/response contract. Platform health readers will be tested through fake services or dependency injection rather than requiring real Apple Health or Google Health permissions.

Rationale: this refactor changes the upload path from direct eHospital writes to backend-mediated ingestion. Tests must protect the API contract so screens do not silently keep calling the old path or send malformed payloads.

Alternative considered: rely on manual smoke testing because platform health permissions are hard to automate. Rejected because the API boundary can be tested with mocks even when real device health APIs cannot.

## Risks / Trade-offs

- Platform health APIs may return different units or sparse values -> Normalize the payload in Flutter and validate numeric fields in the backend before write.
- Google Health / Health Connect availability varies by Android version/device -> Surface a clear unsupported or permission-denied sync result rather than treating it as a backend failure.
- Backend writes may succeed while response parsing differs across eHospital deployments -> Normalize the eHospital write response into a stable ingestion result.
- Existing screens may still call legacy direct upload methods -> Keep compatibility facades temporarily, but have them delegate to `WearableSyncService`.
- Background sync expectations may be overstated -> Document this as near-real-time foreground/service-ready ingestion, not guaranteed continuous monitoring.
- API request shapes may drift between Flutter and backend -> Add backend endpoint tests plus Flutter repository/service tests that assert payload fields, source labels, error mapping, and migrated caller routing.

## Migration Plan

1. Add backend schemas, eHospital write helper, ingestion service, and `/wearables/ingest` router.
2. Add backend tests with mocked eHospital write behavior for valid payloads, invalid payloads, unknown/missing patient ids, and response shape.
3. Add Flutter wearable payload/result models, `WearableSyncService`, `AppleHealthSyncService`, and `GoogleHealthSyncService`.
4. Add Flutter tests for backend ingestion repository payload mapping, sync result parsing, service routing, and platform-source failure handling with fakes.
5. Move Vitals manual upload, Vitals health sync, and Device simulation uploads to the new service boundary.
6. Keep existing `EHospitalService.sendWearableVitals` as a compatibility wrapper only if needed, delegating through the new backend sync path.
7. Run backend tests and Flutter analyzer/tests.

Rollback is straightforward because the existing direct eHospital upload path can remain temporarily available until screen migration is complete.

## Open Questions

- Which Google Health / Health Connect test device should be prioritized for demo, or should Android validation start with a manual/demo source that uses the same ingestion endpoint?
- Should the first ingestion result include a placeholder `alerts` array for future alerting, or keep alert output out until the alert pipeline exists?
- Should `source` metadata be persisted in `wearable_vitals` if the remote schema does not expose a source column, or returned/logged only by the backend for now?
