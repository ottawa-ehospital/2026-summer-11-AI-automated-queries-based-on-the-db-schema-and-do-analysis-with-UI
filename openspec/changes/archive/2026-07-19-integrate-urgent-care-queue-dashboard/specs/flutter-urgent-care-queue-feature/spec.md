## ADDED Requirements

### Requirement: Flutter urgent-care patient check-in
The Flutter app SHALL provide a patient-facing urgent-care check-in flow inside the existing Smart Health app shell.

#### Scenario: Logged-in patient opens check-in
- **WHEN** a logged-in patient opens the urgent-care check-in screen
- **THEN** Flutter preloads the active patient id where available
- **AND** the screen collects symptoms and optional medical history
- **AND** the screen does not require manually typing the patient id when logged-in patient context exists

#### Scenario: Patient submits check-in
- **WHEN** the patient submits valid urgent-care check-in information
- **THEN** Flutter sends the request through an urgent-care repository using the configured backend base URL
- **AND** Flutter shows loading while CTAS analysis and queue assignment are pending
- **AND** Flutter navigates or updates to the patient's queue status after success

#### Scenario: Check-in fails validation
- **WHEN** required check-in fields are missing
- **THEN** Flutter shows inline validation or clear error feedback
- **AND** no backend request is submitted for invalid local input

### Requirement: CareFlow patient app functional parity
The Flutter urgent-care patient module SHALL preserve the original CareFlow patient app workflows while presenting them in the DTI6302 mobile app style.

#### Scenario: Patient workflow parity is present
- **WHEN** the urgent-care patient module is complete
- **THEN** a patient can perform the original app's core workflow: check in, review submitted information, view active queue status, refresh or poll status, receive called/completed state changes, and submit feedback or condition updates
- **AND** the UI uses DTI6302 navigation, cards, forms, typography, spacing, and feedback patterns rather than the standalone CareFlow app shell

### Requirement: Flutter patient queue status
The Flutter app SHALL provide a patient-facing status view for urgent-care queue progress.

#### Scenario: Patient views active status
- **WHEN** a checked-in patient opens the status view
- **THEN** Flutter displays status, queue number, patients ahead, estimated wait range, notification state, submitted symptoms, CTAS level, risk score, queue name, and recommended staff action when returned by the backend

#### Scenario: Status refreshes
- **WHEN** the patient remains on the active status view
- **THEN** Flutter supports manual refresh or periodic polling
- **AND** Flutter handles backend errors without losing the last known status

#### Scenario: Visit is completed
- **WHEN** backend status reports the urgent-care visit is completed
- **THEN** Flutter displays a completed state
- **AND** active polling stops or becomes less frequent

### Requirement: Flutter patient feedback
The Flutter app SHALL allow patients to submit queue feedback and condition updates for an urgent-care visit.

#### Scenario: Patient submits condition update
- **WHEN** a checked-in patient submits a condition update
- **THEN** Flutter posts feedback through the urgent-care repository
- **AND** Flutter displays the backend patient-facing acknowledgement

#### Scenario: Feedback triggers alert
- **WHEN** the backend response indicates staff alert was required
- **THEN** Flutter communicates that staff review has been flagged without presenting a diagnosis or treatment order

### Requirement: Staff web dashboard is not migrated
The Flutter urgent-care integration SHALL NOT migrate the CareFlow staff-facing web dashboard into the DTI6302 mobile app.

#### Scenario: Staff dashboard source remains out of scope
- **WHEN** the urgent-care Flutter module is implemented
- **THEN** it does not add staff queue dashboard screens, staff action controls, completed staff history screens, or staff alert review screens to the DTI6302 mobile app
- **AND** `flutter_frontend/lib/main.dart` is not used as a UI source file for this module

#### Scenario: Backend workflow may still expose staff actions
- **WHEN** the backend exposes notify, start consultation, complete visit, queue, or alert endpoints for CareFlow workflow compatibility
- **THEN** the DTI6302 mobile urgent-care module is not required to surface those endpoints as staff UI

#### Scenario: Customer-only scope
- **WHEN** this change is implemented
- **THEN** the Flutter urgent-care feature exposes only customer/patient mobile screens
- **AND** it does not introduce web, staff, or admin UI surfaces

### Requirement: Urgent-care API repository boundary
Flutter urgent-care screens SHALL call a dedicated repository or API client and SHALL NOT embed raw HTTP request construction in widgets.

#### Scenario: Screen needs urgent-care data
- **WHEN** a patient urgent-care screen needs backend data
- **THEN** it calls the urgent-care repository
- **AND** endpoint path construction and response normalization remain outside widget classes

#### Scenario: Backend returns error
- **WHEN** an urgent-care backend call fails
- **THEN** the repository maps the error into a clear screen-consumable message

### Requirement: Urgent-care entry points
The Flutter app SHALL expose urgent-care screens through existing app navigation without disrupting current routes.

#### Scenario: Dashboard entry opens patient check-in
- **WHEN** a logged-in user activates the urgent-care entry point from the dashboard or emergency area
- **THEN** Flutter opens the urgent-care patient check-in or active status view
- **AND** existing dashboard, emergency SOS, assistant, vitals, goals, and settings routes still open as before

#### Scenario: Staff route is absent
- **WHEN** urgent-care routes are registered for this change
- **THEN** Flutter does not add a staff-dashboard mobile route
- **AND** urgent-care entry points open patient-facing check-in or status screens only

### Requirement: Urgent-care clinical safety wording
Flutter urgent-care screens SHALL present CTAS, risk, summary, recommendations, and feedback alerts as decision support only.

#### Scenario: Patient sees analysis result
- **WHEN** Flutter displays urgent-care queue assignment or recommended action
- **THEN** visible copy avoids final diagnosis, prescription, or treatment-order language
- **AND** the screen indicates that clinical staff review is required for care decisions

### Requirement: Source UI behavior is migrated, not cloned
The urgent-care Flutter implementation SHALL migrate CareFlow patient app workflows into DTI6302 visual and structural conventions.

#### Scenario: Patient app source is integrated
- **WHEN** the CareFlow patient app workflow is implemented
- **THEN** check-in, status, feedback, and polling behavior are represented with DTI6302 feature widgets and routes
- **AND** `patient_app/lib/main.dart` is not used as the host app entry point

#### Scenario: Staff dashboard source is excluded
- **WHEN** the CareFlow staff dashboard source is considered during implementation
- **THEN** it may inform backend workflow semantics only
- **AND** staff dashboard UI files, layouts, and route structure are not rebuilt under the DTI6302 mobile feature module
