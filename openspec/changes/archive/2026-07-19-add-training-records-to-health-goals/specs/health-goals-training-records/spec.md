## ADDED Requirements

### Requirement: Health Goals exposes tabbed goal and training views
The Health Goals screen SHALL include a top-level tab selector that separates the existing goal progress view from the Training Records view.

#### Scenario: Goals tab preserves existing cards
- **WHEN** the user opens Health Goals
- **THEN** the screen shows a Goals tab containing the existing step, sleep, and calorie goal cards
- **THEN** the existing goal edit and progress behavior remains available without requiring the user to view training records

#### Scenario: Training Records tab is selected
- **WHEN** the user selects the Training Records tab
- **THEN** Health Goals shows the training record list and related refresh or sync actions on that tab
- **THEN** the training record list is not appended below the goal cards on the Goals tab

### Requirement: Health Goals displays remote training records
The Health Goals screen SHALL include a Training Records tab that displays workout records loaded from the remote server for the signed-in patient.

#### Scenario: Recent records are shown
- **WHEN** the signed-in patient has remote rows in `wearable_workouts`
- **THEN** Health Goals displays those rows on the Training Records tab
- **THEN** each visible record includes workout type, start date or time, duration, and available workout metrics such as distance, active energy, steps, or source provider

#### Scenario: Records are sorted by recency
- **WHEN** remote workout records are loaded
- **THEN** Health Goals orders records by workout start time or equivalent timestamp with the most recent workout first
- **THEN** malformed or missing timestamps do not prevent valid records from being displayed

### Requirement: Training Records handles data states
The Training Records tab SHALL provide clear loading, empty, error, and refresh states without disrupting the Goals tab.

#### Scenario: Records are loading
- **WHEN** Health Goals is fetching remote training records
- **THEN** the Training Records tab shows a loading state
- **THEN** existing goal data remains available on the Goals tab when it has already loaded

#### Scenario: No records exist
- **WHEN** the remote server returns no workout records for the signed-in patient
- **THEN** the Training Records tab shows an empty state explaining that no synced training records are available
- **THEN** the screen does not show fabricated records or placeholder workout metrics

#### Scenario: Loading records fails
- **WHEN** remote training record retrieval fails
- **THEN** the Training Records tab shows a user-visible error state
- **THEN** the existing step, sleep, and calorie goal cards remain usable on the Goals tab

#### Scenario: User refreshes records
- **WHEN** the user triggers refresh from the Training Records module
- **THEN** Health Goals reloads remote training records for the current patient
- **THEN** the section updates its loading, data, empty, or error state based on the latest response

### Requirement: Training Records can sync platform workouts before reload
If Health Goals exposes a platform workout sync action, it SHALL upload platform workouts through the existing wearable sync service and then reload remote records.

#### Scenario: Platform workout sync succeeds
- **WHEN** the user triggers platform workout sync from Health Goals on a supported device with granted permissions
- **THEN** Health Goals calls `WearableSyncService.syncPlatformWorkouts`
- **THEN** after successful upload, Health Goals reloads remote training records and shows the latest server state

#### Scenario: Platform workout sync is unavailable
- **WHEN** the user triggers platform workout sync on an unsupported platform or without required permissions
- **THEN** Health Goals shows the sync failure message returned by the wearable sync service
- **THEN** the user can still refresh remote training records that already exist on the server

### Requirement: Training Records presentation is localized and feature-local
Training Records user-facing text SHALL use the app localization resources, and feature-specific tab and record display widgets SHALL live in the Health Goals feature area.

#### Scenario: Training Records text is localized
- **WHEN** the Training Records module renders titles, button labels, empty text, loading text, or error text
- **THEN** the displayed copy comes from Flutter l10n-compatible resources

#### Scenario: Training Records widgets are separated
- **WHEN** the Health Goals implementation is reviewed
- **THEN** repeated tab content, Training Records layout, and tile rendering live in feature-local widgets rather than being embedded as large inline blocks in `health_goals_screen.dart`

### Requirement: Training Records behavior has tests
The Health Goals Training Records module SHALL include focused tests for parsing and visible states.

#### Scenario: Record parsing is tested
- **WHEN** tests parse representative remote `wearable_workouts` rows
- **THEN** they verify type, time, duration, distance, energy, steps, source provider, and malformed optional fields are handled correctly

#### Scenario: UI states are tested
- **WHEN** widget or screen tests render Health Goals with fake training record responses
- **THEN** they verify tab switching plus record, loading, empty, error, and refresh behavior without requiring live Apple Health data
