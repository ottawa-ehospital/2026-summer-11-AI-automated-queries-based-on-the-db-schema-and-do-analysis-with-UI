## ADDED Requirements

### Requirement: Workflow analyzes event-triggered health changes
The LangGraph health-data workflow SHALL support event-triggered alert analysis that evaluates new health measurements against patient context and recent trends.

#### Scenario: Event analysis gathers patient context
- **WHEN** the workflow receives a supported health event such as blood pressure
- **THEN** it gathers relevant patient history from `medical_history` and `diagnosis`, active medication context from `prescription_form` and `prescription`, patient-reported context from `patient_feedback`, risk context from `heart_disease_analysis`, `stroke_prediction`, and `ai_diagnostics`, recent measurements from `vitals_history` and `wearable_vitals`, and workout history from `wearable_workouts` when available through validated patient-scoped queries
- **THEN** it uses that context before returning an alert decision

#### Scenario: Event analysis uses configured model provider
- **WHEN** the 3-hour blood-pressure window has enough evidence for demo LLM reasoning
- **THEN** the workflow invokes the shared model client using the configured model provider
- **THEN** the workflow provides user baseline, recent readings, medication/history context, resting heart rate, sleep, activity, workout history, and normal adult reference ranges while constraining the model to produce the alert decision schema

#### Scenario: Event analysis lacks sufficient context
- **WHEN** the workflow cannot retrieve enough patient history, medication context, or recent measurement evidence
- **THEN** it returns a no-notification decision with missing-context reasons
- **THEN** it does not produce medication-specific reminder text

#### Scenario: Event analysis uses reference-range context
- **WHEN** the workflow evaluates a blood-pressure event for demo notification analysis
- **THEN** it uses cached authoritative blood-pressure reference ranges or live LLM web-search results with source/provenance metadata
- **THEN** it treats those references as context for wellness reminder analysis rather than as standalone diagnosis logic

### Requirement: Workflow returns structured alert decisions
The LangGraph health-data workflow SHALL return event-analysis results as structured alert decisions rather than free-form chat replies.

#### Scenario: Reminder decision is generated
- **WHEN** the workflow determines that a user reminder is warranted
- **THEN** it returns `notify=true` with severity, notification title, notification body, evidence summary, recommendation category, freshness metadata, and model/provider trace metadata
- **THEN** the notification body uses supportive language and avoids diagnosis or emergency claims

#### Scenario: No notification is warranted
- **WHEN** deterministic gates or model analysis determine that the event does not warrant user interruption
- **THEN** the workflow returns `notify=false`
- **THEN** the result includes the reason notification was suppressed

#### Scenario: Model output cannot be validated
- **WHEN** model-generated alert output is malformed, unsafe, or missing required fields after bounded retries
- **THEN** the workflow returns a no-notification fallback decision
- **THEN** the workflow records the validation failure stage in trace metadata
