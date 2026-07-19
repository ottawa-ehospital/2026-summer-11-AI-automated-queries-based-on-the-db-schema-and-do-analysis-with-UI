## Context

Health Goals currently loads the signed-in patient id from `SharedPreferences`, fetches `wearable_vitals` through `EHospitalService.fetchTable`, and renders three editable goal cards for steps, sleep, and calories. Workout data is already represented in Flutter as `WearableWorkout`, can be read from HealthKit/Health Connect via `HealthDataType.WORKOUT`, and can be uploaded to backend endpoints under `/wearables/workouts`. The backend writes normalized workout rows to the remote `wearable_workouts` table and treats `source_provider + source_workout_id` as idempotent identity.

The missing product surface is read/display: synced workout records are stored remotely, but Health Goals has no module that retrieves `wearable_workouts` for the current patient. The existing eHospital table facade can read arbitrary tables with a patient filter, while the backend wearable API currently exposes ingestion endpoints only. The implementation can therefore choose either a thin Flutter repository over `/table/wearable_workouts` or a backend-mediated `GET /wearables/workouts` endpoint if stronger response normalization is needed.

## Goals / Non-Goals

**Goals:**

- Add a Health Goals Training Records module that reads patient-scoped workout history from the remote server.
- Represent remote workout rows with a typed Flutter model suitable for display, sorting, filtering, and testing.
- Show recent workouts on a separate Training Records tab with refresh, loading, empty, and error states.
- Reuse existing wearable workout upload/sync infrastructure for optional refresh-before-view behavior.
- Preserve existing goal cards and locally stored goal targets.
- Keep API access behind repositories/services rather than placing transport details in the screen.

**Non-Goals:**

- Finish native iOS HealthKit observer/background-delivery work that remains in `add-wearable-workout-ingestion`.
- Build route maps, split/segment visualizations, or detailed workout analytics.
- Add goal-setting for workout count, minutes, distance, or training load in this change.
- Replace existing `wearable_vitals` goal-progress reads.
- Change workout ingestion payload shape or remote database schema unless a read endpoint requires response DTOs.

## Decisions

### Decision 1: Add a typed Training Records read model

Create a Flutter model for remote training records that can parse rows from `wearable_workouts`, including workout type, start/end time, duration, distance, energy, steps, source provider, and source identity.

Rationale: Health Goals should not repeatedly parse dynamic maps in widget code. A typed model makes sorting, formatting, tests, and future filtering safer.

Alternative considered: render eHospital row maps directly in `HealthGoalsScreen`. Rejected because it would keep transport/schema knowledge in the screen and make empty/malformed-field behavior hard to test.

### Decision 2: Prefer existing remote table reads unless a backend read endpoint is needed

The first implementation should read `wearable_workouts` through a repository using the existing eHospital table API, because `EHospitalRepository.fetchTable` already supports patient-scoped table reads. If this proves unstable or returns inconsistent row shapes, add `GET /wearables/workouts?patient_id=...` to the backend to normalize and sort records.

Rationale: the remote table is already the source of truth and Health Goals only needs patient-scoped history display. Avoiding an unnecessary endpoint keeps the change small.

Alternative considered: always add a new backend endpoint. Rejected for the initial implementation because ingestion is already backend-mediated and no additional server-side analysis is required for the display module.

### Decision 3: Keep sync and read as separate user actions

Health Goals should load remote training records on entry and expose refresh. If a platform workout sync action is added, it should clearly perform upload first and then reload remote records; plain refresh should only reread the server.

Rationale: users need to distinguish “fetch what is on the server” from “ask Apple Health / Google Health for new workouts and upload them.” This also keeps web/local demos from reporting platform-sync failures when the user only wants to view existing records.

Alternative considered: always trigger platform workout sync before loading records. Rejected because platform sync is unavailable on web/desktop and may require permissions, making a read-only history module feel broken.

### Decision 4: Use top-level tabs inside Health Goals

Add a tab selector near the top of Health Goals with at least two tabs: Goals and Training Records. The Goals tab preserves the existing step, sleep, and calorie cards. The Training Records tab contains workout history, refresh/sync controls, and data states.

Rationale: training history is a related but distinct workflow. A tab keeps the current goal progress page focused and gives training records room to grow without crowding the goal cards.

Alternative considered: append Training Records below the existing goal cards. Rejected because it makes the current page longer and mixes two different jobs: goal progress editing and workout history review.

### Decision 5: Place tab contents in feature-local widgets

Add feature-local widgets for the Goals tab content, Training Records tab content, and record tiles under `features/goals`, while `HealthGoalsScreen` remains the state/composition boundary.

Rationale: the existing Health Goals screen is small, but training history adds multiple display states and repeated formatting. Feature-local widgets follow the repository's presentation guidance without over-generalizing.

Alternative considered: add all rendering directly to `health_goals_screen.dart`. Rejected because it would quickly make the screen harder to maintain.

## Risks / Trade-offs

- Remote table shape differs between deployments -> Parse fields defensively, ignore malformed optional values, and cover representative row shapes in tests.
- Existing workout ingestion change is not fully complete -> Treat remote records as viewable when present, but do not block the module on native iOS push completion.
- Reading through eHospital bypasses backend normalization -> Keep the repository boundary thin so it can switch to `GET /wearables/workouts` without changing UI widgets.
- Long workout histories could be large -> Fetch patient-scoped records, sort by start time, and display a bounded recent list on the Training Records tab.
- Platform sync may fail due to permissions or unsupported platform -> Surface a clear sync message and still allow remote-record refresh.

## Migration Plan

1. Add typed Flutter training record models and a repository method for patient-scoped workout history reads.
2. Add Health Goals tab state plus training records loading, error, refresh, and optional sync result messages.
3. Add feature-local Goals tab, Training Records tab, and record tile widgets plus l10n strings.
4. Wire Health Goals to load records after patient id resolution and after successful workout sync.
5. Add focused tests for model parsing, repository path/query behavior, and Health Goals rendering states.
6. If eHospital table reads prove insufficient, add backend workout-history response schemas, a `GET /wearables/workouts` route, and repository support without changing the UI contract.

Rollback is additive: remove the Training Records tab and repository calls while leaving workout ingestion and existing goal cards untouched.

## Open Questions

- Should the initial module show all recent records or cap to a fixed count such as 10 or 30 in Health Goals?
- Should Health Goals include a platform workout sync button in the first pass, or only a server refresh button?
- Should record detail navigation be part of this module now, or deferred until route/segment data exists?
