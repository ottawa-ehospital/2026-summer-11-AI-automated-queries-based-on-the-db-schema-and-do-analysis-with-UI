## ADDED Requirements

### Requirement: Urgent-care backend namespace
The backend SHALL expose urgent-care workflow endpoints under a dedicated `/urgent-care` namespace and SHALL register them through the existing DTI6302 FastAPI app.

#### Scenario: Health endpoint reports urgent-care readiness
- **WHEN** a client requests `GET /urgent-care/health`
- **THEN** the backend returns a successful JSON health response
- **AND** the response includes whether required eHospital persistence targets are available
- **AND** existing assistant, report interpreter, nutrition monitor, and wearable routes remain registered

#### Scenario: Standalone CareFlow backend is not required
- **WHEN** Flutter uses urgent-care features
- **THEN** all urgent-care requests go to the configured DTI6302 `BACKEND_BASE_URL`
- **AND** Flutter does not require a separate CareFlow FastAPI backend on port `8001`

### Requirement: CareFlow backend behavior parity
The backend SHALL faithfully port CareFlow's urgent-care business logic while allowing API path and integration-boundary changes required by DTI6302.

#### Scenario: Source backend workflow is preserved
- **WHEN** a developer compares the integrated backend with CareFlow `backend.py`
- **THEN** CTAS labels, queue names, status names, fallback risk scores, queue sorting, estimated wait calculation, patient status payload meaning, feedback alert precedence, and active/completed visit semantics match the source behavior
- **AND** differences are limited to endpoint prefixes, DTI6302 FastAPI registration, async/client boundaries, configuration, and tests

#### Scenario: API paths are adapted
- **WHEN** CareFlow source endpoint behavior is exposed through DTI6302
- **THEN** equivalent behavior is available under `/urgent-care` paths
- **AND** endpoint renaming does not remove source app workflows such as check-in, status polling, feedback, queues, alerts, patients, notify, start, complete, and history

### Requirement: Shared backend AI service integration
The urgent-care backend SHALL invoke AI models through DTI6302's shared backend AI/model service instead of direct DeepSeek-specific HTTP calls.

#### Scenario: Risk analysis invokes shared model client
- **WHEN** urgent-care CTAS/risk analysis needs model output
- **THEN** the urgent-care service calls the shared backend model client or shared AI service abstraction
- **AND** the urgent-care service does not open direct HTTP connections to `api.deepseek.com`
- **AND** the urgent-care service uses the generic runtime model configuration rather than urgent-care-specific provider overrides
- **AND** the model prompt and expected JSON fields remain compatible with CareFlow's Risk Analysis Agent behavior

#### Scenario: Feedback alert invokes shared model client
- **WHEN** urgent-care feedback alert analysis needs model output
- **THEN** the urgent-care service calls the shared backend model client or shared AI service abstraction
- **AND** deterministic keyword safety fallback remains available when the shared model call fails

#### Scenario: Shared model layer is extended
- **WHEN** JSON helper behavior or broader provider/base URL support is needed for urgent care
- **THEN** the extension is implemented as generic shared model-client infrastructure
- **AND** existing users of the model layer continue to work without request contract changes
- **AND** no urgent-care-specific model provider, model name, base URL, or API key setting is introduced

#### Scenario: Existing AI features are protected
- **WHEN** the shared model layer is changed for urgent care
- **THEN** regression tests cover existing assistant, health alert, report interpreter, and nutrition model paths
- **AND** those existing features retain their previous API contracts and expected error behavior

### Requirement: Patient check-in intake
The backend SHALL accept patient-scoped urgent-care check-in requests containing symptoms and optional medical history, then create or update the required eHospital records for the visit.

#### Scenario: Logged-in patient checks in
- **WHEN** a request includes a valid patient id, patient demographics, symptoms, and optional medical history
- **THEN** the backend validates the intake fields
- **AND** the backend uses the supplied patient id as the eHospital patient identity
- **AND** the backend creates a visit record with status `Waiting`
- **AND** the response includes the created local visit id or record id

#### Scenario: Intake is missing symptoms
- **WHEN** a check-in request has no symptom description
- **THEN** the backend rejects the request with a client-visible validation error
- **AND** no urgent-care visit record is written

#### Scenario: Patient registration is missing
- **WHEN** the intake references a patient id that is not present in `patients_registration`
- **THEN** the backend attempts to create or repair the minimum patient registration row when enough demographics are available
- **AND** the response includes registration persistence status

### Requirement: CTAS risk analysis
The backend SHALL assign each check-in a CTAS urgency level, risk score, queue name, clinical summary, reasoning, and recommended staff action using model-assisted analysis with deterministic safety fallback.

#### Scenario: Model analysis succeeds
- **WHEN** the configured urgent-care model returns valid structured CTAS analysis
- **THEN** the backend normalizes CTAS level to one of levels 1 through 5
- **AND** the backend clamps risk score to the supported range
- **AND** the backend maps CTAS levels 1-2 to Emergency Queue, level 3 to Normal Queue, and levels 4-5 to Non-Urgent Queue

#### Scenario: CareFlow prompt contract is preserved
- **WHEN** model-assisted risk analysis is invoked
- **THEN** the backend uses a prompt contract equivalent to CareFlow's Risk Analysis Agent
- **AND** the backend expects and validates the same core JSON fields: `ctas_level`, `urgency_label`, `risk_score`, `clinical_summary`, `reasoning`, and `recommended_action`

#### Scenario: Model analysis is unavailable
- **WHEN** model invocation is unavailable, unconfigured, or returns invalid JSON
- **THEN** the backend uses deterministic CTAS/risk fallback rules based on red-flag symptoms
- **AND** the response includes trace or metadata showing fallback was used
- **AND** high-risk red-flag symptoms are not downgraded solely because model analysis failed

#### Scenario: Previous urgent-care context exists
- **WHEN** the patient has previous healthcare records or feedback
- **THEN** the backend includes recent patient history in model-assisted analysis
- **AND** deterministic fallback remains safe even when history cannot be loaded

### Requirement: Queue prioritization
The backend SHALL provide active urgent-care queues sorted by clinical priority and check-in time.

#### Scenario: Staff loads queues
- **WHEN** a client requests `GET /urgent-care/queues`
- **THEN** the backend returns Emergency Queue, Normal Queue, and Non-Urgent Queue lists
- **AND** each queue contains active patients only
- **AND** each queue is sorted by CTAS level, descending risk score, then earliest check-in time

#### Scenario: Queue summary is returned
- **WHEN** a client requests queue data
- **THEN** the response includes counts for waiting, in-consultation, completed, total patients, and CTAS levels

### Requirement: Patient queue status
The backend SHALL provide patient-facing queue status for an active or completed urgent-care visit.

#### Scenario: Patient checks status
- **WHEN** a client requests status for a valid urgent-care visit id
- **THEN** the backend returns patient id, visit status, global queue position, patients ahead, estimated wait range, notification state, check-in time, and submitted intake summary

#### Scenario: Patient status response remains CareFlow-compatible
- **WHEN** the integrated patient UI requests visit status
- **THEN** the response preserves the source patient app's status concepts including `local_patient_id`, `patient_id`, `queue_number`, `status`, `patients_ahead`, `estimated_wait_range`, `notified`, `checked_in_at`, `server_time`, and `submitted_information`

#### Scenario: Completed patient checks status
- **WHEN** a client requests status for a completed visit
- **THEN** the backend returns completed status
- **AND** the backend does not assign an active queue number

#### Scenario: Unknown visit id
- **WHEN** a client requests status for an unknown urgent-care visit id
- **THEN** the backend returns a not-found error

### Requirement: Staff consultation actions
The backend SHALL expose staff actions for notifying a patient, starting consultation, and completing an urgent-care visit.

#### Scenario: Staff notifies patient
- **WHEN** staff posts a notify action for a valid waiting visit
- **THEN** the backend records a notification timestamp
- **AND** subsequent patient status indicates the patient has been notified

#### Scenario: Staff starts consultation
- **WHEN** staff posts a start-consultation action for a valid active visit
- **THEN** the backend sets status to `In Consultation`
- **AND** the backend records a consultation start timestamp

#### Scenario: Staff completes visit
- **WHEN** staff posts a complete action for a valid active visit
- **THEN** the backend sets status to `Completed`
- **AND** the backend records a completed timestamp
- **AND** the visit no longer appears in active queue lists

### Requirement: Patient feedback and alerting
The backend SHALL accept patient feedback and condition updates for urgent-care visits, persist them, and generate staff alert decisions.

#### Scenario: Patient submits non-urgent feedback
- **WHEN** patient feedback contains no red-flag condition update
- **THEN** the backend persists the feedback
- **AND** the alert decision indicates no immediate staff alert is required

#### Scenario: Patient submits worsening condition update
- **WHEN** feedback or condition update contains red-flag language such as chest pain, breathing difficulty, fainting, confusion, seizure, severe bleeding, severe pain, or explicit urgent help request
- **THEN** the backend marks staff alert required
- **AND** the alert includes severity, alert reason, recommended staff action, and patient-facing acknowledgement

#### Scenario: Model alert disagrees with safety fallback
- **WHEN** model-assisted feedback alerting says no alert but deterministic fallback finds red-flag language
- **THEN** the backend follows the safer fallback alert path

### Requirement: Staff feedback alerts
The backend SHALL expose feedback alerts for staff review without duplicating the same alert event.

#### Scenario: Staff loads alerts
- **WHEN** a client requests `GET /urgent-care/alerts`
- **THEN** the backend returns alert-required feedback events
- **AND** each alert includes patient id or visit id, severity, reason, feedback text, condition update, recommended staff action, and created time

#### Scenario: Duplicate alert sources exist
- **WHEN** an alert appears in both local fallback data and eHospital feedback rows
- **THEN** the backend de-duplicates equivalent alert events in the response

### Requirement: eHospital persistence boundary
The backend SHALL read and write urgent-care data through DTI6302 eHospital client helpers and SHALL NOT embed raw eHospital URL construction outside the client boundary.

#### Scenario: Urgent-care service writes records
- **WHEN** urgent-care service code creates feedback, visit, registration, or medical history records
- **THEN** it calls shared backend eHospital client helpers
- **AND** it does not use direct `requests` calls to the eHospital API from service modules

#### Scenario: Required persistence fields are unavailable
- **WHEN** the active eHospital metadata lacks required urgent-care persistence fields
- **THEN** the backend health or intake response reports the missing fields clearly
- **AND** the backend does not silently write malformed urgent-care records
