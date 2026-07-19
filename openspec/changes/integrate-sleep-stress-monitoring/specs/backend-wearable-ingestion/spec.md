## ADDED Requirements

### Requirement: Stress fields in wearable vitals
The backend wearable data model SHALL support stress-related fields on remote `wearable_vitals`.

#### Scenario: Remote wearable schema includes stress fields
- **WHEN** backend code reads or writes remote `wearable_vitals`
- **THEN** it recognizes `hrv_sdnn`, `resting_heart_rate`, `respiratory_rate`, `stress_score`, and `annotation` as valid optional fields

### Requirement: Existing wearable ingestion remains compatible
The backend SHALL preserve existing wearable ingestion behavior for heart rate, steps, calories, sleep, and workouts.

#### Scenario: Existing wearable sample ingestion
- **WHEN** an existing client submits heart rate, steps, calories, or sleep through current wearable ingestion endpoints
- **THEN** the backend continues to ingest those metrics without requiring stress fields
