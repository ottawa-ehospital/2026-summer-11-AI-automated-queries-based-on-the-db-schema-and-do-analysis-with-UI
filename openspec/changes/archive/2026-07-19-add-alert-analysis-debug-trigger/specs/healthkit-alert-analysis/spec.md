## ADDED Requirements

### Requirement: Alert decision history exposes debug analysis triggers
The app SHALL provide a debug-only trigger from Alert Decision History that can simulate Apple Health alert-analysis events for the current patient.

#### Scenario: Developer opens debug analysis actions
- **WHEN** a developer opens Alert Decision History in a build where alert-analysis debug tools are enabled
- **THEN** the page exposes a "Test Alert Analyse" action
- **THEN** the action offers a normal Apple Health sync debug scenario and an abnormal blood-pressure analysis debug scenario

#### Scenario: No patient is available
- **WHEN** the debug analysis action is invoked without a current patient id
- **THEN** the app does not inject a test event
- **THEN** the app shows or records that a patient context is required

### Requirement: Debug normal sync scenario proves valid Apple Health data delivery
The app SHALL support a normal debug scenario that simulates receipt of valid Apple Health data and dispatches a clearly labeled test notification.

#### Scenario: Normal debug sync event is triggered
- **WHEN** the developer selects the normal Apple Health sync debug scenario
- **THEN** the app immediately shows a floating info message indicating the debug sync analysis was triggered
- **THEN** the app creates a valid supported Apple Health-style event for the current patient with test or simulation source mode
- **THEN** the app processes the event through the same validation and alert-analysis service path used by native HealthKit events
- **THEN** the app dispatches a clearly labeled test notification indicating Apple Health data was received
- **THEN** the app shows a floating success message when alert analysis returns successfully
- **THEN** Alert Decision History refreshes to show the resulting debug decision record or failure record

#### Scenario: Normal debug event is invalid
- **WHEN** the normal debug scenario builds an invalid or unsupported event
- **THEN** the app shows a floating feedback message indicating the debug event could not be accepted
- **THEN** the app does not dispatch the data-received test notification
- **THEN** Alert Decision History records the validation failure for debugging

### Requirement: Debug abnormal blood-pressure scenario exercises medication-context analysis
The app SHALL support an abnormal debug scenario that simulates repeated Apple Health blood-pressure events with antihypertensive medication context and routes them through backend alert analysis.

#### Scenario: Abnormal blood-pressure debug event is triggered
- **WHEN** the developer selects the abnormal blood-pressure analysis debug scenario
- **THEN** the app injects a test or simulation blood-pressure trend for the current patient that shows blood pressure continuing to fall over the analysis window
- **THEN** the injected event data or metadata includes evidence that the user has a relevant antihypertensive medication record
- **THEN** the app sends the data through the same alert-analysis API used by real HealthKit events
- **THEN** the backend can return a validated test notification decision asking whether the user may have forgotten their blood-pressure medication
- **THEN** Alert Decision History shows the test-source decision, evidence summary, and notification dispatch status

#### Scenario: Abnormal scenario does not meet alert criteria
- **WHEN** the abnormal blood-pressure debug scenario receives a backend decision with `notify=false`
- **THEN** the app does not dispatch a production health notification
- **THEN** Alert Decision History records the suppression reason and scenario metadata

#### Scenario: Abnormal scenario analysis fails
- **WHEN** backend alert analysis fails during the abnormal blood-pressure debug scenario
- **THEN** the app does not fabricate a medication-adherence notification locally
- **THEN** Alert Decision History records the failure for debugging

### Requirement: Debug alert triggers are tested
The system SHALL include automated tests for the Alert Decision History debug trigger scenarios.

#### Scenario: Debug trigger UI is tested
- **WHEN** widget tests enable alert-analysis debug tools and open Alert Decision History
- **THEN** the tests verify the "Test Alert Analyse" action is visible and can invoke both debug scenarios
- **THEN** the tests verify trigger and analysis-success floating feedback is shown for successful debug runs

#### Scenario: Debug notification scenario is tested
- **WHEN** tests run the normal Apple Health sync debug scenario with a valid patient id
- **THEN** the tests verify a test notification is dispatched and a test-source decision record is stored

#### Scenario: Debug abnormal scenario is tested
- **WHEN** tests run the abnormal blood-pressure debug scenario with medication context
- **THEN** the tests verify the alert-analysis client receives test blood-pressure data and medication-context metadata
- **THEN** the tests verify any returned notification-worthy decision is stored and dispatched as a test notification
