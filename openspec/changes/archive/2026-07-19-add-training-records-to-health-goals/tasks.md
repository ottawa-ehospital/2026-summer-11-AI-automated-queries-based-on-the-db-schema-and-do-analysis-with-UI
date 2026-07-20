## 1. Data Access

- [x] 1.1 Add a typed Flutter training record model for `wearable_workouts` rows, including defensive parsing for timestamps, duration, distance, energy, steps, source provider, and source workout identity.
- [x] 1.2 Add a Health Goals or wearable-history repository method that fetches patient-scoped training records through the existing remote table API.
- [x] 1.3 Sort records by start time descending, cap the Health Goals list to a reasonable recent-record count, and de-duplicate records with the same `source_provider` and `source_workout_id` when present.
- [x] 1.4 If remote table reads are insufficient, add backend response schemas and a `GET /wearables/workouts` endpoint that returns normalized patient-scoped workout history. Existing remote table reads were sufficient, so no backend endpoint was added.
- [x] 1.5 Add or update Flutter API tests for training record parsing, patient id query behavior, wrapped/raw remote response shapes, and error handling.

## 2. Health Goals State

- [x] 2.1 Extend `HealthGoalsScreen` state to load training records after resolving the current patient id without changing existing goal target persistence.
- [x] 2.2 Add a top-level tab selector in `HealthGoalsScreen` with separate Goals and Training Records tabs.
- [x] 2.3 Keep the existing step, sleep, and calorie goal cards on the Goals tab with current edit and persistence behavior unchanged.
- [x] 2.4 Add independent loading, empty, error, and refresh states for the Training Records tab so the Goals tab remains usable.
- [x] 2.5 Add a remote refresh action on the Training Records tab that reloads training records for the current patient.
- [x] 2.6 Optionally add a platform workout sync action on the Training Records tab that calls `WearableSyncService.syncPlatformWorkouts`, shows the sync result, and reloads remote records only after successful upload.

## 3. Presentation

- [x] 3.1 Add feature-local Goals tab, Training Records tab, and record tile widgets under `features/goals`.
- [x] 3.2 Display each record with workout type, date/time, duration, and available metrics such as distance, active energy, steps, and source provider.
- [x] 3.3 Add l10n strings for tab labels, Training Records title, refresh/sync actions, loading, empty, error, and metric labels.
- [x] 3.4 Ensure the tab selector and tab contents fit the existing Health Goals visual style and use existing design tokens/widgets where practical.

## 4. Verification

- [x] 4.1 Add widget tests for Health Goals tab switching plus Training Records populated, loading, empty, error, refresh, and optional sync-failure states.
- [x] 4.2 Add tests proving malformed optional workout fields do not break valid record rendering.
- [x] 4.3 Run Flutter analyze/tests for the touched app packages and fix any new failures.
- [x] 4.4 If a backend read endpoint is added, add backend route/service tests and run the relevant Python test subset. No backend read endpoint was added.
- [x] 4.5 Smoke test with existing or fixture `wearable_workouts` rows for a patient and verify Health Goals displays remote training records.
