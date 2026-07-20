## ADDED Requirements

### Requirement: Schema inventory includes wearable workout tables
The backend SHALL include `wearable_workouts` and required workout fields in schema inventory and query validation metadata used by Sigma planning and execution.

#### Scenario: Workout schema appears in planning context
- **WHEN** the workflow builds schema planning context for patient-scoped health assistant queries
- **THEN** the context includes the `wearable_workouts` table
- **THEN** the context includes fields needed for workout history analysis, including patient id, source provider, workout type, start time, end time, duration, distance, energy, heart-rate summaries, and sync metadata

#### Scenario: Workout query references known fields
- **WHEN** a Sigma payload references known `wearable_workouts` fields
- **THEN** Sigma validation accepts the table and fields subject to existing filter, order, and limit rules
- **THEN** the query can be converted into a backend table query request

#### Scenario: Workout query references unknown fields
- **WHEN** a Sigma payload references a missing workout table field
- **THEN** Sigma validation rejects the payload before execution
- **THEN** the backend does not run an unvalidated workout query

### Requirement: Workout queries enforce patient scoping
The backend SHALL enforce current-patient scoping for workout table queries generated from Sigma payloads.

#### Scenario: Workout query is scoped to current patient
- **WHEN** a workflow query targets `wearable_workouts`
- **THEN** the backend adds or verifies a filter for the current patient id
- **THEN** model-generated patient filters cannot override the current patient id

#### Scenario: Workout query cannot be safely scoped
- **WHEN** a workout query cannot be tied to the current patient
- **THEN** the backend rejects the query or routes the workflow to fallback
- **THEN** the backend does not execute an unscoped workout-history query

### Requirement: Workout schema support has validation tests
The backend SHALL include tests that prove workout table schema metadata participates in planning and validation.

#### Scenario: Workout planning context test passes
- **WHEN** backend tests build schema planning context
- **THEN** the tests verify `wearable_workouts` and required workout fields are present

#### Scenario: Workout Sigma validation test passes
- **WHEN** backend tests validate a Sigma payload for recent workouts
- **THEN** the payload is accepted only when it references known workout fields and remains patient-scopeable
