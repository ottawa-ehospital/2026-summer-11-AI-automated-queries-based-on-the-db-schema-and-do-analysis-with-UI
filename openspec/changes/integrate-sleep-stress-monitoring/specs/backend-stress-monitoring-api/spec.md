## ADDED Requirements

### Requirement: Stress snapshot ingestion
The backend SHALL accept wearable stress snapshots and persist them to remote `wearable_vitals`.

#### Scenario: Persist stress snapshot
- **WHEN** the app uploads a stress snapshot with patient id, timestamp, HRV SDNN, resting heart rate, respiratory rate, and optional heart rate
- **THEN** the backend computes a stress score and stores the raw signals, computed score, timestamp, and patient id remotely

#### Scenario: Reject client-provided stress score
- **WHEN** the app sends a stress snapshot request
- **THEN** the backend derives `stress_score` server-side and does not accept a trusted client-provided score

### Requirement: Missing stress components
The backend SHALL calculate stress scores from available components and return no score only when every stress component is missing.

#### Scenario: Partial stress signals
- **WHEN** a stress snapshot includes only one or two of HRV SDNN, resting heart rate, and respiratory rate
- **THEN** the backend computes a weighted score from the available components

#### Scenario: No stress signals
- **WHEN** a stress snapshot includes none of HRV SDNN, resting heart rate, or respiratory rate
- **THEN** the backend stores no derived stress score for that snapshot

### Requirement: Stress annotation update
The backend SHALL support updating a remote wearable vital row with a user stress annotation.

#### Scenario: Annotate stress point
- **WHEN** the app submits an annotation for a wearable vital id
- **THEN** the backend updates the remote `wearable_vitals.annotation` field for that row

### Requirement: Stress assistant analysis
The backend SHALL expose stress analysis that uses remote stress signals, user annotations, and patient context.

#### Scenario: Analyze stress trend
- **WHEN** the app requests stress analysis for a patient
- **THEN** the backend generates a concise wellness analysis referencing stress score trend, raw stress signals, annotations, and relevant patient context

#### Scenario: Preserve health alert endpoint
- **WHEN** stress analysis is added
- **THEN** the existing `/assistant/health-alert/analyze` behavior remains available
