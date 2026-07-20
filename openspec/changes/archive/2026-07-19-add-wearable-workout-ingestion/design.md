## Context

The repository already has a backend-centered ingestion path for aggregate wearable vitals and a new MySQL schema for workout records. The current app can read selected Apple Health / Google Health metrics through the Flutter `health` package, aggregate them, and upload one vitals sample through `/wearables/ingest`. It does not yet upload structured workouts such as runs, rides, walks, durations, distances, or workout heart-rate summaries.

The AI assistant workflow can query patient-scoped health data through validated Sigma/table query plans. To support exercise-safety scenarios, workout history must be available through the same backend query path as patient context, disease records, and wearable vitals. The latest requirement also needs real-time or near-real-time Apple Health push, so the iOS path must include native HealthKit observer and anchored-query code rather than relying only on foreground Flutter plugin reads.

## Goals / Non-Goals

**Goals:**

- Add backend workout ingestion for `wearable_workouts` with single and batch endpoints.
- Normalize Apple HealthKit-style workout records into the common schema while preserving provider metadata for Fitbit and future sources.
- Extend Flutter data models and repository methods so workout records can be uploaded through the backend.
- Add a service boundary that can accept workouts from Flutter `health` plugin reads, manual/demo fixtures, and a native iOS HealthKit bridge.
- Implement native iOS `HKObserverQuery`, `HKAnchoredObjectQuery`, background delivery registration, and anchor persistence for Apple Health workout updates.
- Make workout history queryable by the LangGraph/Sigma health-data workflow for AI analysis and personalized exercise guidance.
- Verify the end-to-end path with automated tests and at least one smoke-testable fixture flow.

**Non-Goals:**

- Guarantee delivery when iOS withholds background execution, the user revokes Health permissions, Low Power Mode restricts execution, or Apple Health has no new samples.
- Build route-coordinate storage or route rendering.
- Replace the existing vitals ingestion path.
- Implement full Fitbit OAuth/activity ingestion beyond preserving a compatible common payload shape.

## Decisions

### Decision 1: Add workout ingestion as a sibling of vitals ingestion

The backend will expose workout-specific ingestion endpoints under the existing wearable API namespace, such as `POST /wearables/workouts/ingest` and `POST /wearables/workouts/batch-ingest`.

Rationale: workout records have interval semantics, source identifiers, activity type, distance, energy, heart-rate summaries, and sync metadata that do not fit the aggregate `wearable_vitals` payload. A sibling endpoint keeps the existing vitals API stable and avoids overloading one schema with incompatible meanings.

Alternative considered: expand `/wearables/ingest` to accept both vitals and workouts. Rejected because request validation, accepted metrics, and response details would become ambiguous.

### Decision 2: Use provider source id for idempotency

The backend will treat `source_provider + source_workout_id` as the stable external identity for a workout. Ingestion SHALL be idempotent: resending the same source workout should update or safely preserve the existing row rather than creating duplicate records.

Rationale: Apple HealthKit workouts have stable UUIDs, Fitbit activities have log ids or provider record ids, and app-driven sync may retry. The database schema already has a uniqueness constraint for this pair.

Alternative considered: rely on backend-generated `workout_id` only. Rejected because mobile retry and future background delivery would duplicate workouts.

### Decision 3: Implement native iOS HealthKit push behind the same adapter contract

Flutter will define a normalized `WearableWorkout` model and upload repository. Manual/demo payloads and foreground reads may still use the same service, but iOS Apple Health workout updates SHALL be collected by native Swift code using `HKObserverQuery`, `HKAnchoredObjectQuery`, and HealthKit background delivery where available. The Swift adapter will emit the same JSON payload through a MethodChannel without changing backend APIs.

Rationale: the professor's updated requirement needs real-time or near-real-time push from Apple Health. Flutter plugin foreground reads are still useful for manual sync and tests, but they cannot satisfy background delivery expectations by themselves. Keeping the backend payload stable lets native iOS and Flutter-driven paths share validation, upload, idempotency, and AI query behavior.

Alternative considered: keep native iOS background delivery as a follow-up. Rejected because the latest requirement makes real-time push part of the expected product behavior.

### Decision 4: AI query support is schema allowlisting plus targeted intent coverage

The workflow will include `wearable_workouts` in schema planning context and intent table candidates for workout, exercise, run, ride, inactivity, and activity-history questions. Query validation remains schema-backed and patient-scoped.

Rationale: the model should not guess table or field names, and workout history must be considered when a user asks for exercise advice. Existing Sigma validation and table query execution already provide the correct safety boundary.

Alternative considered: inject workout rows directly into the prompt outside query validation. Rejected because it bypasses table/field validation and scales poorly as more wearable data is added.

### Decision 5: End-to-end validation combines fixtures with native device smoke coverage

Automated tests will verify request mapping, backend row construction, idempotency/error behavior, query planning context, and assistant routing. A fixture/manual upload flow will allow deterministic local smoke testing, and the native iOS path will add simulator-safe bridge tests plus a real-device smoke checklist for HealthKit permissions, observer registration, anchored fetch, anchor persistence, and backend upload.

Rationale: the core AI value can be verified with deterministic records, while real-time HealthKit behavior still needs native-device validation because iOS background delivery cannot be proven fully with backend or Flutter unit tests alone.

Alternative considered: only test with live Apple Health data. Rejected because it is slow, device-dependent, and hard to reproduce.

## Risks / Trade-offs

- Health plugin workout support may expose fewer Apple-specific fields than native HealthKit -> Use the native iOS adapter as the authoritative Apple Health path, preserve `raw_payload` and `source_metadata`, and make missing optional metrics acceptable.
- Local MySQL and remote eHospital write behavior may differ -> Keep table writes behind backend service/helper code and test the normalized row boundary.
- Duplicate workout uploads may occur during retries -> Use `source_provider + source_workout_id` idempotency and test repeated ingestion.
- AI may over-focus on workouts without disease/sleep context -> Keep workout tables as candidate context, not the only context; query planning should combine disease, vitals, sleep, and workouts when relevant.
- iOS background delivery is not a hard real-time guarantee -> Register HealthKit background delivery and observer queries, but document that iOS controls wake timing and the app must reconcile missed updates with anchored queries on launch/foreground.

## Migration Plan

1. Implement backend workout request/response schemas and ingestion service for `wearable_workouts`.
2. Add single and batch workout API routes under `/wearables/workouts`.
3. Add Flutter workout models and repository upload methods.
4. Extend wearable sync service with workout upload methods, MethodChannel bridge handling, and fixture/demo support.
5. Add schema planning context and intent mapping for workout-related AI requests.
6. Implement native iOS HealthKit permission, observer, anchored-query, background-delivery, and anchor-persistence logic for workout updates.
7. Add tests for backend ingestion, Flutter payload mapping, MethodChannel/native adapter mapping, AI query context, and assistant workflow behavior.
8. Smoke test by uploading fixture workout records for a test patient and asking the AI assistant workout-history and exercise-risk questions.
9. Smoke test the iOS native path on a real device with Apple Health permissions and verify new workouts are pushed or reconciled through backend ingestion.

Rollback is additive: routes and models can be disabled without changing existing vitals ingestion. Existing workout rows can remain in the table because they are not used unless the workflow allowlist includes the table.

## Open Questions

- Should batch ingestion response return per-record status for partial success, or fail the whole batch on the first invalid workout?
- Should route availability be uploaded as a boolean only in the base version, or should route metadata fields be added before native iOS bridge work is considered complete?
- Which HealthKit workout and quantity sample types should register background delivery in the first native pass: workouts only, or workouts plus workout-linked heart-rate samples?
