## ADDED Requirements

### Requirement: Workflow uses workout history for exercise-related advice
The LangGraph health-data query/report workflow SHALL consider workout history when a user asks for personalized exercise, running, cycling, recovery, or activity-history advice.

#### Scenario: User asks to start running after inactivity
- **WHEN** a user asks whether they should start running and the request implies personal exercise planning
- **THEN** the workflow identifies workout history as relevant patient context
- **THEN** the workflow attempts a patient-scoped query against `wearable_workouts` before generating personalized guidance

#### Scenario: User asks about long-distance cycling
- **WHEN** a user asks about long-distance cycling, endurance exercise, or an unusually large planned workout
- **THEN** the workflow considers recent workouts, duration, distance, and heart-rate summaries as relevant context
- **THEN** the workflow combines workout history with other available patient context before generating a report or text guidance

#### Scenario: User asks about exercise with medical risk context
- **WHEN** a user asks for exercise advice and patient context includes possible cardiac or other high-risk conditions
- **THEN** the workflow treats workout history as supporting evidence rather than sufficient clearance
- **THEN** the final response includes evidence-grounded limitations and appropriate care-seeking guidance

### Requirement: Workflow plans workout-history Sigma queries
The workflow SHALL map workout, exercise, activity, run, cycling, and inactivity intents to query plans that can retrieve relevant workout records.

#### Scenario: Deterministic workout mapping applies
- **WHEN** the intent clearly asks for recent workout history or activity trend
- **THEN** the workflow builds or selects a Sigma payload targeting `wearable_workouts`
- **THEN** the payload selects fields needed for analysis such as workout type, start time, duration, distance, energy, and heart-rate summaries

#### Scenario: Model-backed workout planning applies
- **WHEN** deterministic mapping is insufficient for a supported workout-related advice request
- **THEN** the workflow prompts the configured model using schema context that includes `wearable_workouts`
- **THEN** the generated Sigma payload is validated before execution

### Requirement: Workflow validates end-to-end workout reasoning
The workflow SHALL include tests or fixtures proving that uploaded workout records can affect AI query/report behavior.

#### Scenario: Uploaded workout appears in assistant analysis
- **WHEN** a test patient has workout records available in `wearable_workouts`
- **THEN** an exercise-history or exercise-advice assistant request retrieves those records through the validated query path
- **THEN** the generated analysis references retrieved workout evidence instead of relying only on general knowledge

#### Scenario: No workout history is handled safely
- **WHEN** a user asks for exercise advice and the workout-history query returns no rows
- **THEN** the workflow explains that no matching workout history is available
- **THEN** the workflow does not fabricate workout evidence

#### Scenario: Workout query validation fails
- **WHEN** the workflow cannot validate a patient-scoped workout query
- **THEN** the workflow returns a fallback or clarification response
- **THEN** the workflow does not execute an unsafe workout query
