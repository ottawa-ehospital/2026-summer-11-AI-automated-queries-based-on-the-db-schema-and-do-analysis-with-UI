## ADDED Requirements

### Requirement: Remote sleep night persistence
The backend SHALL persist detailed sleep night records to a remote eHospital `sleep_nights` table keyed by patient and night, not to a local SQLite store.

#### Scenario: Sync sleep nights
- **WHEN** the backend receives a sleep-night sync request with one or more nights for a patient
- **THEN** it stores each night remotely with sleep stage minutes, asleep minutes, in-bed minutes, optional SpO2 values, optional heart-rate values, source, and update timestamp

#### Scenario: Idempotent sleep update
- **WHEN** the backend receives a sleep-night sync request for a patient and night that already exists
- **THEN** it updates the existing remote row instead of creating a duplicate row

### Requirement: Sleep night listing
The backend SHALL expose a patient-scoped API for listing recent remote sleep nights.

#### Scenario: List recent sleep nights
- **WHEN** the app requests sleep nights for a patient with a day limit
- **THEN** the backend returns at most that many nights ordered chronologically for display and analysis

### Requirement: Sleep feedback generation
The backend SHALL generate AI sleep feedback from the patient's remote sleep-night records.

#### Scenario: Feedback with sleep data
- **WHEN** sleep feedback is requested for a patient with recent sleep-night records
- **THEN** the backend grounds the response in the patient's total sleep, sleep stages, SpO2, and heart-rate values

#### Scenario: Feedback with no sleep data
- **WHEN** sleep feedback is requested for a patient with no remote sleep-night records
- **THEN** the backend returns a clear no-data response without invoking an unsafe diagnosis or medication recommendation

### Requirement: Sleep-specific chat
The backend SHALL support sleep-specific follow-up chat grounded in recent remote sleep-night records and bounded conversation history.

#### Scenario: Sleep chat uses recent nights
- **WHEN** the app sends a sleep chat message with prior turns
- **THEN** the backend includes recent remote sleep-night context and bounded conversation history in the model prompt

#### Scenario: Sleep chat excludes unrelated persistence
- **WHEN** the backend handles sleep chat
- **THEN** it does not read from or write to teammate-local SQLite storage
