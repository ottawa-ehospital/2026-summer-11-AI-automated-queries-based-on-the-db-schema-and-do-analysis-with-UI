## ADDED Requirements

### Requirement: Backend supports patient-scoped wearable workout history retrieval
The backend or configured remote data layer SHALL provide a patient-scoped way to retrieve workout records from `wearable_workouts` for app features that need to display training history.

#### Scenario: Patient workout history is retrieved
- **WHEN** the app requests workout history for a patient id
- **THEN** the remote data layer returns only workout rows belonging to that patient
- **THEN** each returned row includes the fields needed for display, including workout type, start time, end time, duration, distance, energy, steps, source provider, and source workout id when available

#### Scenario: Unknown patient has no records
- **WHEN** the app requests workout history for a patient id with no matching workout rows
- **THEN** the remote data layer returns an empty result rather than rows from another patient

#### Scenario: Remote workout history retrieval fails
- **WHEN** the remote `wearable_workouts` source cannot be reached or returns an invalid response
- **THEN** the app receives a client-visible retrieval error
- **THEN** the failure is distinguishable from a successful empty workout history

### Requirement: Workout history retrieval preserves ingestion identity
Workout history retrieval SHALL expose source identity fields needed to avoid confusing duplicate provider records.

#### Scenario: Source identity is available
- **WHEN** a retrieved workout row has `source_provider` and `source_workout_id`
- **THEN** those fields are available to the Flutter model
- **THEN** the UI can use them as stable record keys when present

#### Scenario: Duplicate-safe rows are displayed once
- **WHEN** the remote source returns multiple rows with the same `source_provider` and `source_workout_id`
- **THEN** the app layer de-duplicates or otherwise avoids rendering visually duplicated training records in the Health Goals module
