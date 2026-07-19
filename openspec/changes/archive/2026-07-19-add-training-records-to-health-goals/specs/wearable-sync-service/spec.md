## ADDED Requirements

### Requirement: Flutter can retrieve wearable workout history
The Flutter wearable layer SHALL expose a reusable way to retrieve patient-scoped workout history for features that need to display synced training records.

#### Scenario: Workout history is retrieved for a patient
- **WHEN** a feature requests training records for the signed-in patient
- **THEN** the Flutter wearable data layer retrieves rows from the configured remote workout-history source
- **THEN** the returned records use a typed model rather than raw dynamic maps in the feature widget tree

#### Scenario: Workout history retrieval fails
- **WHEN** the remote workout-history source returns an error or an unexpected response
- **THEN** the Flutter wearable data layer exposes a consistent failure that Health Goals can display
- **THEN** it does not report stale or partial data as freshly loaded records

### Requirement: Workout sync and workout history reload are coordinated
`WearableSyncService` SHALL remain responsible for platform workout upload, and callers that trigger sync before viewing records SHALL reload workout history only after the sync operation completes.

#### Scenario: Sync then reload succeeds
- **WHEN** Health Goals triggers platform workout sync and the sync result succeeds
- **THEN** the caller reloads remote workout history after upload completion
- **THEN** the displayed Training Records data reflects server-side state rather than local HealthKit-only records

#### Scenario: Sync fails before reload
- **WHEN** platform workout sync fails due to permission, unsupported platform, or no available workouts
- **THEN** the caller displays the sync result message
- **THEN** the user can still perform a remote-only history refresh
