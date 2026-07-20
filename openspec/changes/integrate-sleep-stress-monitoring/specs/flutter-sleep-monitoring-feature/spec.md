## ADDED Requirements

### Requirement: Apple Health sleep collection
The Flutter app SHALL collect supported Apple Health sleep-stage, blood oxygen, and heart-rate samples and aggregate them into nightly sleep records.

#### Scenario: Aggregate nightly sleep
- **WHEN** the user grants sleep-related HealthKit permissions
- **THEN** the app groups sleep samples into per-night records with deep, REM, core/light, awake, asleep, in-bed, SpO2, and heart-rate summaries

### Requirement: Sleep sync to backend
The Flutter app SHALL sync aggregated sleep nights to the backend sleep API for remote persistence.

#### Scenario: Manual or automatic sleep sync
- **WHEN** sleep nights are available for the signed-in patient
- **THEN** the app sends those nights to the backend with the current patient id and handles success or failure visibly

#### Scenario: Patient-scoped daily auto sync
- **WHEN** the app performs once-per-day sleep auto sync
- **THEN** it scopes the last-sync marker by patient id so different users do not block each other's sync

### Requirement: Sleep visualization and feedback
The Flutter app SHALL display sleep analysis UI with sleep stage visualization and AI feedback.

#### Scenario: Display sleep analysis
- **WHEN** remote or freshly collected sleep nights are available
- **THEN** the app shows total sleep, sleep stages, and related sleep-health metrics in the sleep analysis surface

#### Scenario: Request AI sleep feedback
- **WHEN** the user requests sleep feedback
- **THEN** the app calls the backend sleep feedback API and displays the returned response with loading and error states

### Requirement: Sleep chat
The Flutter app SHALL support sleep-specific follow-up chat.

#### Scenario: Ask sleep follow-up
- **WHEN** the user sends a follow-up question from the sleep analysis surface
- **THEN** the app sends the message and bounded prior sleep chat turns to the backend sleep chat API
