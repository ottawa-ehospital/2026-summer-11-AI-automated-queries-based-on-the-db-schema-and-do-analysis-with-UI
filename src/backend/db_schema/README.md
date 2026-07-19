# Wearable Workout Schema

`001_create_wearable_workouts.sql` defines the common workout-history format for Apple Health-first sync with Fitbit compatibility.

## Core Mapping

| Common field | Apple HealthKit source | Fitbit source |
| --- | --- | --- |
| `source_provider` | `apple_health` | `fitbit` |
| `source_workout_id` | `HKWorkout.uuid` | activity `logId` or provider record id |
| `workout_type` | normalized `HKWorkoutActivityType` | normalized Fitbit activity name/type |
| `workout_type_raw` | HealthKit activity name/code label | Fitbit activity name |
| `apple_workout_activity_type` | raw `HKWorkoutActivityType` integer | `NULL` |
| `fitbit_activity_id` | `NULL` | Fitbit `activityId` |
| `start_time` / `end_time` | `HKWorkout.startDate` / `endDate` | activity `startTime` + duration |
| `duration_seconds` | `HKWorkout.duration` | activity duration |
| `distance_meters` | `totalDistance` | activity distance normalized to meters |
| `active_energy_kcal` | `totalEnergyBurned` | activity calories |
| `source_bundle_id` | `HKSourceRevision.source.bundleIdentifier` | Fitbit app/client id if available |
| `source_device_*` | `HKDevice` fields | Fitbit device fields if available |
| `source_metadata` | `HKWorkout.metadata` subset | Fitbit activity metadata |
| `raw_payload` | compact serialized source payload | compact serialized source payload |

## Why This Shape

- Apple HealthKit treats workouts as interval records with typed activity, start/end time, duration, distance, energy, metadata, source revision, and optional route data.
- Fitbit activity logs map cleanly into the same interval model, but need provider-specific identity and activity ids.
- AI analysis should query `wearable_workouts` for workout history and use `wearable_vitals` for daily/short-window vitals.
- Route coordinates should not be stored by default. Use `has_route` plus a separate route table later if the user grants explicit location consent.

## Ingestion Contract

- Flutter uploads workout records through backend endpoints under `/wearables/workouts`.
- The backend treats `source_provider` + `source_workout_id` as the provider identity so retrying the same workout is idempotent.
- The base app sync path is foreground/app-driven: manual, simulation, and Flutter health-plugin workout reads can all emit the same normalized payload.
- Native iOS HealthKit background delivery is a follow-up path. A Swift bridge using `HKWorkout`, `HKObserverQuery`, and `HKAnchoredObjectQuery` should map records into this same payload instead of changing backend APIs.
- The backend and AI workflow validate table and field references before querying `wearable_workouts`; the model should not invent workout columns.

## AI Query Examples

Recent workout history:

```sql
SELECT workout_type, start_time, duration_seconds, distance_meters, active_energy_kcal
FROM wearable_workouts
WHERE patient_id = :patient_id
ORDER BY start_time DESC
LIMIT 50;
```

Detect long inactivity after prior running history:

```sql
SELECT
  MAX(start_time) AS last_run_time,
  COUNT(*) AS lifetime_run_count,
  SUM(start_time >= DATE_SUB(NOW(), INTERVAL 90 DAY)) AS runs_last_90_days
FROM wearable_workouts
WHERE patient_id = :patient_id
  AND workout_type IN ('running', 'walking_running');
```
