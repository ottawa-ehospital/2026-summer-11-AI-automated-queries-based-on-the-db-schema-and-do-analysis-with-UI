## Why

The app already has a workout ingestion path for Apple Health / platform workout records, but Health Goals only shows aggregate step, sleep, and calorie progress from `wearable_vitals`. Users need a Health Goals module that can read remote training records from `wearable_workouts` so synced workouts are visible in the goal context instead of being hidden backend data.

## What Changes

- Add a top-level tab selector to Health Goals with separate Goals and Training Records tabs.
- Add a Training Records tab that loads patient-scoped workout history from the remote server.
- Display recent workout records with type, date/time, duration, distance, energy, steps, source, and empty/error/loading states.
- Add a refresh path and optional platform workout sync entry point so users can update Apple Health / Google Health workout uploads before viewing remote records.
- Keep Health Goals goal-progress behavior intact on the Goals tab while placing workout history on the separate Training Records tab.
- Reuse existing workout ingestion/table contracts where possible; add a backend read endpoint only if direct eHospital table reads are insufficient for stable patient-scoped workout retrieval.
- Add tests covering remote workout parsing, repository behavior, Health Goals state handling, and UI rendering for records, empty state, and failures.

## Capabilities

### New Capabilities

- `health-goals-training-records`: Health Goals user experience for viewing remote training records synced from wearable workout sources.

### Modified Capabilities

- `wearable-sync-service`: Expose a read-side Flutter workout-history contract and, where useful, a Health Goals-triggered platform workout sync path alongside existing workout upload support.
- `backend-wearable-ingestion`: Add or document a patient-scoped workout-history retrieval contract for `wearable_workouts` if the existing remote table API is not sufficient for the app module.
- `flutter-api-layer`: Ensure Health Goals retrieves workout history through reusable repository/API abstractions rather than embedding remote table transport logic in the screen.

## Impact

- Flutter Health Goals code under `src/app/lib/features/goals`, including tab state, presentation widgets, l10n strings, and focused widget/unit tests.
- Flutter data/API code under `src/app/lib/data` or a feature-local repository for parsing `wearable_workouts` rows and retrieving patient-scoped training records.
- Existing wearable workout sync code under `src/app/lib/services/wearable_sync_service.dart`, which already supports foreground workout reads and batch upload from Apple Health / Google Health when platform permissions are available.
- Backend wearable API may gain `GET /wearables/workouts` or similar if implementation chooses a backend-mediated read path rather than the existing eHospital `/table/wearable_workouts` read.
- Current workout ingestion support is partly implemented in `add-wearable-workout-ingestion`: Flutter/background upload foundations exist, while native iOS HealthKit observer/background delivery work remains a dependency for true near-real-time Apple Health push.
