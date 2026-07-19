# healthkit-alert-analysis Specification

## Purpose
Defines native HealthKit event intake, event-triggered alert analysis, validated notification decisions, local decision history, and test notification behavior.
## Requirements
### Requirement: App receives native Apple Health update events
The Flutter app SHALL receive normalized Apple Health update events from native iOS HealthKit observer and anchored-query delivery for supported sample types.

#### Scenario: Valid HealthKit event is received
- **WHEN** native iOS receives a supported Apple Health update such as blood pressure with sample time, value, unit, source id, and anchor metadata
- **THEN** the native bridge emits a normalized health event to Flutter
- **THEN** Flutter validates the event shape before sending it to ingestion or analysis

#### Scenario: Unsupported HealthKit event is received
- **WHEN** native iOS receives a HealthKit update for an unsupported sample type
- **THEN** the app ignores the event for alert analysis
- **THEN** the app does not send a user notification for that event

#### Scenario: HealthKit delivery is reconciled after delay
- **WHEN** the app launches or returns to foreground after iOS delayed background delivery
- **THEN** the native bridge performs anchored reconciliation for supported sample types
- **THEN** newly discovered events are emitted through the same normalized event path

### Requirement: Health events are not blindly notified
The app SHALL NOT notify the user solely because Apple Health delivered a data update, except when explicit test notification mode is enabled.

#### Scenario: Valid event has no alert decision
- **WHEN** a valid Apple Health event is received and analysis does not return a notification-worthy decision
- **THEN** the app does not send a production health notification
- **THEN** the event may still be ingested or logged for future analysis

#### Scenario: Analysis is unavailable
- **WHEN** a valid Apple Health event is received but the alert-analysis request fails or returns an invalid result
- **THEN** the app suppresses production health notifications
- **THEN** the app records a failure result for debugging or observability

### Requirement: Alert analysis evaluates health changes against patient context
The backend SHALL analyze supported Apple Health events against patient history, active medications, recent measurements, and supporting wearable context before returning a notification decision.

#### Scenario: Sustained blood pressure rise with medication context is detected
- **WHEN** a patient with relevant history or an active antihypertensive medication has blood pressure values that remain elevated across the 3-hour analysis window
- **THEN** the alert-analysis workflow evaluates the trend against the user's baseline, recent measurements, medication context, and authoritative normal/reference ranges
- **THEN** the workflow may return a medication-adherence reminder decision with evidence and user-safe notification copy

#### Scenario: Isolated elevated reading is received
- **WHEN** a single elevated blood pressure reading is received without enough supporting evidence in the 3-hour window
- **THEN** the workflow does not return a medication-adherence reminder solely from that isolated reading
- **THEN** the workflow returns a reason indicating that more evidence or context is needed

#### Scenario: Demo LLM judges blood pressure trend
- **WHEN** the demo workflow receives enough blood-pressure evidence in the 3-hour window
- **THEN** the workflow provides the LLM with the user's baseline, recent readings, medication/history context, resting heart rate or heart-rate trend when available, sleep signals when available, activity or step signals when available, workout history when available, and normal adult reference ranges
- **THEN** the LLM returns a constrained alert decision rather than free-form medical advice

#### Scenario: Supporting wearable context changes interpretation
- **WHEN** blood pressure is elevated and supporting wearable context shows unusual sleep, activity, heart-rate, or workout patterns
- **THEN** the workflow includes that context in the alert decision evidence
- **THEN** the workflow does not frame the alert only as a medication-adherence reminder unless medication/history evidence supports that framing

#### Scenario: Medication context is missing
- **WHEN** blood pressure is elevated but the workflow cannot find active antihypertensive medication evidence
- **THEN** the workflow does not mention missed medication in the notification decision
- **THEN** the workflow may return a lower-severity monitoring recommendation if configured thresholds are met

### Requirement: Alert notifications are delivered from validated decisions
The app SHALL deliver local notifications only from validated alert decisions returned by the backend alert-analysis workflow.

#### Scenario: Notification-worthy decision is returned
- **WHEN** the backend returns a valid alert decision with `notify=true`, severity, title, body, evidence summary, and freshness metadata
- **THEN** the app schedules or displays a local notification using the returned title and body
- **THEN** the app records that the notification was triggered for the event source id

#### Scenario: Decision suppresses notification
- **WHEN** the backend returns a valid alert decision with `notify=false`
- **THEN** the app does not schedule a local notification
- **THEN** the app may show no user-facing output unless a test mode is active

#### Scenario: Notification permission is denied
- **WHEN** the backend returns a notification-worthy decision but local notification permission is denied
- **THEN** the app does not attempt to display the notification
- **THEN** the app records the denied-permission result

### Requirement: App stores alert decisions locally
The app SHALL store alert-analysis decisions locally as patient-scoped records, similar to symptom logs.

#### Scenario: Notification-worthy decision is stored
- **WHEN** the backend returns a valid alert decision with `notify=true`
- **THEN** the app stores a local alert decision record for the current patient
- **THEN** the record includes the event source id, event type, decision timestamp, severity, notification title/body, evidence summary, and notification dispatch result

#### Scenario: Suppressed decision is stored
- **WHEN** the backend returns a valid alert decision with `notify=false`
- **THEN** the app stores a local alert decision record for the current patient
- **THEN** the record includes the event source id, event type, decision timestamp, suppression reason, evidence summary when available, and workflow trace metadata

#### Scenario: Local notification failure is stored
- **WHEN** notification permission is denied or local notification dispatch fails
- **THEN** the app stores the failure result with the related alert decision record
- **THEN** the app does not mark the notification as dispatched

#### Scenario: Patient logs out
- **WHEN** the current patient logs out and local patient data is cleared
- **THEN** local alert decision records for that patient are cleared with other patient-scoped local records

### Requirement: Settings exposes alert decision debug history
The app SHALL provide a Settings debug page that displays local alert and notification decision records.

#### Scenario: User opens alert decision history
- **WHEN** the user opens the alert decision history page from Settings
- **THEN** the app displays local alert decision records for the current patient
- **THEN** each record shows timestamp, event type/source, notify status, severity, title/body or suppression reason, test/production label, and notification dispatch status

#### Scenario: No alert decisions exist
- **WHEN** the current patient has no local alert decision records
- **THEN** the debug page shows an empty state

#### Scenario: User clears alert decision history
- **WHEN** the user clears local alert decision history from the debug page
- **THEN** the app deletes local alert decision records for the current patient
- **THEN** the debug page updates to the empty state

### Requirement: Test notification proves valid HealthKit data delivery
The app SHALL support a test notification mode that sends a clearly labeled notification when valid Apple Health push data is received.

#### Scenario: Test notification mode receives valid data
- **WHEN** test notification mode is enabled and a valid supported Apple Health event arrives through the native bridge
- **THEN** the app sends a clearly labeled test notification proving the data path is working
- **THEN** the test notification is distinguishable from production health alerts

#### Scenario: Test notification mode receives invalid data
- **WHEN** test notification mode is enabled and an invalid or unsupported Apple Health event arrives
- **THEN** the app does not send the test notification
- **THEN** the app records why the event was not accepted

### Requirement: Test data can validate analysis behavior
The app SHALL support injected test health events that exercise the same analysis and notification decision path as real Apple Health events.

#### Scenario: Test event is injected
- **WHEN** a developer injects a supported test event such as elevated blood pressure for a test patient
- **THEN** the app marks the event source as test data
- **THEN** the app sends the event through the same alert-analysis API used by real HealthKit events

#### Scenario: Test event triggers analysis notification
- **WHEN** injected test data satisfies alert-analysis conditions
- **THEN** the backend returns the same decision schema used for real data
- **THEN** the app can deliver a clearly labeled test or development notification according to the active test configuration

### Requirement: Alert behavior has contract tests
The system SHALL include tests for HealthKit event mapping, test data injection, alert-analysis decisions, notification gating, and test notifications.

#### Scenario: Native bridge mapping is tested
- **WHEN** tests provide fake native HealthKit event payloads
- **THEN** the tests verify Flutter accepts valid events and rejects malformed events

#### Scenario: Notification gating is tested
- **WHEN** tests provide backend decisions with `notify=true`, `notify=false`, invalid schema, and permission-denied conditions
- **THEN** the tests verify local notifications are sent only for allowed validated decisions

#### Scenario: Local decision history is tested
- **WHEN** tests provide notification-worthy, suppressed, test-source, and failed-dispatch decisions
- **THEN** the tests verify the app stores patient-scoped local alert decision records
- **THEN** the tests verify the Settings debug page can display and clear those records

#### Scenario: Blood pressure reminder analysis is tested
- **WHEN** backend tests provide elevated blood-pressure trends with matching history and medication context
- **THEN** the tests verify the workflow returns a medication-adherence reminder decision with evidence

#### Scenario: Test notification path is tested
- **WHEN** tests enable valid-data test notification mode and provide valid HealthKit events
- **THEN** the tests verify a clearly labeled test notification is dispatched

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

