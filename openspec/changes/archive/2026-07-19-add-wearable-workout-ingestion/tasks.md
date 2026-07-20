## 1. Backend Workout Ingestion

- [x] 1.1 Add backend workout request/response schemas for single and batch ingestion, covering source identity, workout type, time window, normalized metrics, provider metadata, raw payload, and deletion/sync fields.
- [x] 1.2 Implement validation for required identity fields, time ordering, non-negative duration, and non-negative numeric workout metrics.
- [x] 1.3 Add backend service functions that normalize accepted workout payloads into `wearable_workouts` table rows.
- [x] 1.4 Implement idempotent write behavior using `source_provider` and `source_workout_id` so retrying the same workout does not create duplicate records.
- [x] 1.5 Add `POST /wearables/workouts/ingest` and `POST /wearables/workouts/batch-ingest` routes and register them with the backend wearable API.
- [x] 1.6 Return stable ingestion responses with patient id, source provider, source workout id, workout type, accepted count or status, and clear ingestion failure details.

## 2. Backend Tests

- [x] 2.1 Add backend tests for successful single workout ingestion with mocked table write behavior.
- [x] 2.2 Add backend tests for successful batch workout ingestion and accepted count reporting.
- [x] 2.3 Add backend tests that reject missing identity fields, invalid time windows, and negative workout metrics before any table write.
- [x] 2.4 Add backend tests for duplicate source workout ingestion and idempotent success behavior.
- [x] 2.5 Add backend tests for database/eHospital write failures returning gateway-style ingestion errors.

## 3. Flutter Workout Upload

- [x] 3.1 Add Flutter `WearableWorkout` and workout ingestion result models with JSON mapping aligned to the backend workout ingestion schema.
- [x] 3.2 Add wearable ingestion repository methods for single and batch workout upload through backend endpoints.
- [x] 3.3 Extend `WearableSyncService` with workout upload and batch workout upload methods for manual, fixture, and platform-provided workouts.
- [x] 3.4 Add a platform workout reader boundary that can use foreground Flutter health-plugin reads and native iOS MethodChannel workout events.
- [x] 3.5 Preserve explicit sync failure results for unavailable Apple Health / Google Health workout reads or permission denial.

## 4. Flutter Tests

- [x] 4.1 Add tests for `WearableWorkout` JSON serialization, including Apple-style and Fitbit-compatible payloads.
- [x] 4.2 Add tests for workout repository endpoint paths, request bodies, success responses, and API error mapping.
- [x] 4.3 Add tests for `WearableSyncService` workout routing with fake repository and fixture workouts.
- [x] 4.4 Add tests that platform workout-reader failures do not call backend ingestion and return user-visible sync failure messages.
- [ ] 4.5 Add tests for native MethodChannel workout payload mapping, anchor metadata preservation, and native permission/unavailable failure results.

## 5. AI Query Integration

- [x] 5.1 Ensure schema inventory and planning context expose `wearable_workouts` fields required for workout-history analysis.
- [x] 5.2 Update health-data intent analysis and deterministic candidate-table mapping for workout, run, cycling, endurance, inactivity, and activity-history requests.
- [x] 5.3 Ensure model-backed Sigma planning prompts mention `wearable_workouts` as a known patient-scoped health table when relevant.
- [x] 5.4 Add or update Sigma validation tests proving `wearable_workouts` queries accept known fields and reject unknown fields.
- [x] 5.5 Add or update assistant workflow tests proving workout-history requests retrieve uploaded workout rows through the validated query path.

## 6. End-to-End Verification

- [x] 6.1 Add a fixture or demo helper that uploads representative workout records for a test patient without requiring live Apple Health data.
- [x] 6.2 Smoke test the route from Flutter-style workout payload to backend ingestion to database row/query result.
- [x] 6.3 Smoke test an assistant prompt about recent exercise or running readiness and verify workout evidence is available to the generated analysis.
- [ ] 6.4 Document that iOS HealthKit observer/background delivery is enabled for real-time or near-real-time push, with anchored-query reconciliation because iOS controls wake timing.
- [x] 6.5 Run the relevant backend and Flutter test subsets and record any tests that cannot be run locally.

## 7. Native iOS HealthKit Push Sync

- [ ] 7.1 Add iOS HealthKit entitlements, `Info.plist` usage descriptions, and permission request flow for workout read access.
- [ ] 7.2 Implement Swift HealthKit workout observer registration with background delivery where available.
- [ ] 7.3 Implement anchored `HKWorkout` queries that fetch new, updated, and deleted workouts from the last persisted anchor.
- [ ] 7.4 Persist HealthKit anchors locally and advance them only after workout payloads are accepted by the upload path.
- [ ] 7.5 Emit native workout payloads, sync metadata, permission status, and platform failures to Flutter through the MethodChannel boundary.
- [ ] 7.6 Reconcile missed workout updates on app launch and foreground resume using the same anchored-query path.
- [ ] 7.7 Add native/bridge smoke verification for a real iOS device: permission grant, observer registration, workout creation/update, backend ingestion, and duplicate-safe retry behavior.
