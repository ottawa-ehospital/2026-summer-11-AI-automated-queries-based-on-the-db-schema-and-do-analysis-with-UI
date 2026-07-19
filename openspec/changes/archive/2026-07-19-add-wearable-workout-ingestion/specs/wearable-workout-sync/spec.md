## ADDED Requirements

### Requirement: Flutter represents normalized wearable workouts
The Flutter app SHALL define a normalized workout model that can represent Apple Health-first workout records while preserving provider metadata for Fitbit and native iOS adapters.

#### Scenario: Workout model serializes Apple-style workout
- **WHEN** Flutter creates a workout model with Apple Health source provider, source workout id, activity type, start time, end time, duration, distance, energy, and heart-rate summary
- **THEN** the model serializes to the backend workout ingestion request shape
- **THEN** optional device and provider metadata are included only when available

#### Scenario: Workout model serializes Fitbit-compatible workout
- **WHEN** Flutter creates a workout model with Fitbit source provider, provider activity id, activity name, source workout id, and common workout metrics
- **THEN** the model serializes common fields using the same backend request shape
- **THEN** Fitbit-specific details are preserved in source metadata fields

### Requirement: Flutter uploads workouts through the backend
The Flutter app SHALL upload workout records through backend workout ingestion endpoints rather than constructing direct database table writes.

#### Scenario: Single workout upload succeeds
- **WHEN** Flutter uploads one normalized workout through the wearable ingestion repository
- **THEN** the repository sends the request to the backend workout ingestion endpoint
- **THEN** the repository parses the structured success response

#### Scenario: Batch workout upload succeeds
- **WHEN** Flutter uploads multiple normalized workouts through the wearable ingestion repository
- **THEN** the repository sends the request to the backend batch workout ingestion endpoint
- **THEN** the repository parses the accepted count and per-source summary needed by the sync result

#### Scenario: Backend rejects workout upload
- **WHEN** the backend returns a validation or ingestion error for workout upload
- **THEN** Flutter maps the response to a consistent API error or sync failure result
- **THEN** screens do not treat the workout as uploaded

### Requirement: Wearable sync service supports workout upload
`WearableSyncService` SHALL provide workout upload operations alongside existing vitals upload operations.

#### Scenario: Manual or fixture workout is uploaded
- **WHEN** a demo, fixture, or manual workflow creates a workout record for a patient
- **THEN** the workflow calls `WearableSyncService`
- **THEN** the service uploads the workout through the backend workout ingestion repository

#### Scenario: Platform foreground workout sync is available
- **WHEN** the app can read workout records from the Flutter health plugin during foreground sync
- **THEN** the platform sync service maps those records into normalized workout models
- **THEN** `WearableSyncService` uploads them through the backend workout ingestion repository

#### Scenario: Platform workout sync is unavailable
- **WHEN** Apple Health or Google Health workout reading is unavailable or permission is denied
- **THEN** the platform sync service returns a clear failure result
- **THEN** `WearableSyncService` does not call backend workout ingestion

### Requirement: Native iOS workout adapter provides HealthKit push sync
The Flutter app SHALL include a native iOS HealthKit bridge that can push Apple Health workout updates through the shared workout ingestion contract without changing backend request shapes.

#### Scenario: Native adapter returns workout payloads
- **WHEN** the native iOS adapter returns workouts collected from `HKWorkout` or anchored HealthKit queries
- **THEN** Flutter can map those payloads into the same normalized workout model used by foreground sync
- **THEN** the backend workout ingestion endpoints require no request-shape change

#### Scenario: Native adapter includes sync metadata
- **WHEN** the native iOS adapter includes opaque anchor, revision, deletion, or source metadata
- **THEN** Flutter preserves that metadata in the normalized workout upload
- **THEN** the backend can store the metadata in the existing sync and provider fields

#### Scenario: HealthKit observer receives a workout update
- **WHEN** iOS wakes the app for a HealthKit workout observer notification
- **THEN** the native adapter runs an anchored workout query from the last persisted anchor
- **THEN** newly returned or updated workouts are emitted to Flutter for backend ingestion
- **THEN** the adapter persists the new anchor only after the upload path accepts the emitted records

#### Scenario: App resumes after missed background delivery
- **WHEN** the app launches or returns to foreground after HealthKit background delivery was delayed or skipped
- **THEN** the native adapter performs an anchored reconciliation query
- **THEN** missed workout updates are emitted through the same normalized upload path without duplicating already-ingested source workout ids

#### Scenario: HealthKit permissions are unavailable
- **WHEN** native iOS HealthKit authorization is denied, restricted, or unavailable
- **THEN** the native adapter returns a clear platform failure result
- **THEN** Flutter does not report real-time workout push as active

### Requirement: Flutter workout upload has tests
The Flutter app SHALL include tests for workout request serialization, repository endpoint calls, sync-service routing, native adapter mapping, and failure handling.

#### Scenario: Repository request mapping is tested
- **WHEN** a Flutter test uploads a normalized workout through a fake API client
- **THEN** the test verifies the backend workout ingestion path
- **THEN** the test verifies patient id, source identity, workout type, time window, metrics, and metadata are encoded correctly

#### Scenario: Sync service routing is tested
- **WHEN** a Flutter test uploads fixture workouts through `WearableSyncService`
- **THEN** the test verifies the workouts are passed to the backend repository
- **THEN** the test verifies the sync result reports success and uploaded count

#### Scenario: Platform failure is tested
- **WHEN** a fake platform workout reader returns unavailable or permission-denied
- **THEN** the test verifies no backend workout upload is attempted
- **THEN** the returned sync result includes a clear user-visible message

#### Scenario: Native adapter mapping is tested
- **WHEN** a fake MethodChannel returns native HealthKit workout payloads and anchor metadata
- **THEN** the test verifies the payloads map to normalized workout uploads
- **THEN** the test verifies anchor and source metadata are preserved
