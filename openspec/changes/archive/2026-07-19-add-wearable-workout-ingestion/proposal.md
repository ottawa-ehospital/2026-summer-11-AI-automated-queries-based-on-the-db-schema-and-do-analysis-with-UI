## Why

The app can ingest aggregate wearable vitals, but it cannot yet upload structured workout records into the new `wearable_workouts` schema. Without workout history in the backend query path, the AI assistant cannot reliably identify exercise-context risks such as long inactivity before running, sleep-deprived endurance plans, or cardiac-history exercise requests.

## What Changes

- Add backend workout ingestion endpoints for single and batch workout uploads from Flutter and native iOS sync adapters.
- Validate and normalize workout records into the `wearable_workouts` table using the Apple HealthKit workout shape as the primary model while preserving Fitbit-compatible provider metadata.
- Add Flutter workout models and repository methods that upload normalized workout payloads through the backend instead of writing database rows directly from screens.
- Extend the existing wearable sync boundary so the app can upload workout records from app-driven sync, manual/demo payloads, fixture data, and native iOS HealthKit observer/anchored-query delivery.
- Make `wearable_workouts` available to the LangGraph/Sigma query planning path so AI responses can query workout history alongside patient context and vitals.
- Add tests and a smoke-test path that verify the full chain: Flutter payload construction, backend validation/write behavior, schema-aware AI planning, and query/report analysis against workout data.
- Implement the iOS native HealthKit source-adapter path so Swift `HKWorkout` observer/anchored-query delivery can push workout updates through the same backend APIs without changing the shared payload contract.

## Capabilities

### New Capabilities

- `backend-workout-ingestion`: Backend API and service contract for accepting normalized workout records, validating them, writing `wearable_workouts`, and returning stable ingestion results.
- `wearable-workout-sync`: Flutter-side workout upload/sync models, repository calls, service orchestration, demo/test upload support, and native iOS HealthKit real-time/near-real-time workout sync through a MethodChannel boundary.

### Modified Capabilities

- `langgraph-query-report-flow`: The health-data query/report workflow will treat workout history as supported patient context for exercise advice, risk-oriented planning, and activity-history analysis.
- `backend-sigma-query-tools`: Schema planning and query validation will include the new `wearable_workouts` table and patient-scoped fields so model-generated queries can be validated before execution.

## Impact

- Backend code under `src/backend`, including wearable schemas, ingestion service logic, API routes, eHospital/database write helpers, and tests.
- Flutter code under `src/app/lib`, including wearable models, ingestion repository methods, sync service extensions, MethodChannel integration, and tests.
- iOS native code under `src/app/ios`, including HealthKit permissions, observer/anchored workout queries, background delivery registration, anchor persistence, and bridge tests or smoke verification.
- AI workflow code under `src/backend/services/assistant/workflows`, schema inventory context, and query-planning tests.
- Existing MySQL schema now includes `wearable_workouts`; implementation should use the existing table rather than creating another workout table.
- No breaking changes to current vitals ingestion; workout ingestion is additive, but the iOS Apple Health integration now requires native HealthKit code for real-time/near-real-time workout push.
