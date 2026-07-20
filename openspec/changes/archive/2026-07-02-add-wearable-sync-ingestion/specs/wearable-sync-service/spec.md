## ADDED Requirements

### Requirement: Flutter centralizes wearable synchronization
The Flutter app SHALL route wearable data collection and upload through a dedicated `WearableSyncService` instead of having feature screens construct wearable upload requests directly. `WearableSyncService` SHALL act as the shared orchestrator for `AppleHealthSyncService` and `GoogleHealthSyncService`.

#### Scenario: Manual wearable values are uploaded
- **WHEN** a screen submits manually entered heart rate, steps, calories, or sleep values
- **THEN** the screen calls `WearableSyncService`
- **THEN** the service sends a normalized wearable payload to the backend ingestion endpoint

#### Scenario: Demo wearable values are uploaded
- **WHEN** a demo or simulation flow generates wearable values for a patient
- **THEN** the flow calls `WearableSyncService`
- **THEN** each generated sample uses the same normalized backend ingestion contract as real health-source samples

### Requirement: Apple Health collection is platform-specific
The Flutter app SHALL keep Apple Health collection logic in `AppleHealthSyncService`, which SHALL be called by `WearableSyncService`.

#### Scenario: iOS health sync succeeds
- **WHEN** the app runs on iOS and the user grants required Apple Health permissions
- **THEN** `AppleHealthSyncService` reads supported health metrics
- **THEN** `WearableSyncService` uploads the normalized sample through the backend ingestion endpoint

#### Scenario: iOS health sync is unavailable
- **WHEN** the app runs on a platform where Apple Health is unavailable or permission is denied
- **THEN** `AppleHealthSyncService` returns a clear sync failure result
- **THEN** the screen shows the result without attempting a direct eHospital table write

### Requirement: Google Health collection is platform-specific
The Flutter app SHALL keep Google Health / Android Health Connect collection logic in `GoogleHealthSyncService`, which SHALL be called by `WearableSyncService`.

#### Scenario: Google health sync succeeds
- **WHEN** the app runs on Android and Google Health / Health Connect is available with permission
- **THEN** `GoogleHealthSyncService` reads supported health metrics
- **THEN** `WearableSyncService` uploads the normalized sample through the backend ingestion endpoint

#### Scenario: Google health sync is unavailable
- **WHEN** the app runs on Android and Google Health / Health Connect is unavailable or permission is denied
- **THEN** `GoogleHealthSyncService` returns a clear sync failure result
- **THEN** the screen shows the result without treating the failure as a backend ingestion error

### Requirement: Sync results are explicit
`WearableSyncService` SHALL return a structured sync result describing whether sync succeeded, what source was used, how many samples were uploaded, and any user-visible error message.

#### Scenario: Backend ingestion accepts a sample
- **WHEN** the backend ingestion endpoint accepts a wearable sample
- **THEN** `WearableSyncService` returns a success result containing the uploaded count and source label

#### Scenario: Backend ingestion rejects a sample
- **WHEN** the backend ingestion endpoint rejects a wearable sample
- **THEN** `WearableSyncService` returns or throws a consistent API error that screens can display

### Requirement: Flutter wearable API changes have tests
The Flutter app SHALL include tests for the wearable ingestion client, sync service routing, and migrated upload callers.

#### Scenario: Backend ingestion repository maps request and response
- **WHEN** a Flutter test sends a wearable sample through the backend ingestion repository with a fake HTTP client
- **THEN** the test verifies the request path is `/wearables/ingest`
- **THEN** the test verifies patient id, metric values, timestamp, and source label are encoded in the request body
- **THEN** the test verifies the backend response is parsed into the expected sync result model

#### Scenario: WearableSyncService routes platform sync
- **WHEN** a Flutter test runs `WearableSyncService` with fake `AppleHealthSyncService` or `GoogleHealthSyncService`
- **THEN** the test verifies the selected platform service provides samples
- **THEN** the test verifies those samples are uploaded through the backend ingestion repository

#### Scenario: Migrated upload callers use sync service
- **WHEN** tests exercise manual upload or simulation upload paths with fakes
- **THEN** the tests verify those callers route through `WearableSyncService`
- **THEN** the tests verify they do not construct direct eHospital `wearable_vitals` POST requests

#### Scenario: Platform source failure is surfaced
- **WHEN** fake `AppleHealthSyncService` or `GoogleHealthSyncService` returns unavailable or permission-denied
- **THEN** the test verifies `WearableSyncService` returns a clear failure result without calling backend ingestion
