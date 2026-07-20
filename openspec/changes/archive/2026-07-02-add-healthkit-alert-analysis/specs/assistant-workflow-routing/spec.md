## ADDED Requirements

### Requirement: Assistant router supports event-triggered workflows
The backend assistant orchestration layer SHALL route structured health events to registered event-triggered workflows without requiring a user chat message.

#### Scenario: Health event matches alert workflow
- **WHEN** the backend receives a supported health event analysis request
- **THEN** the router selects the health alert-analysis workflow
- **THEN** the workflow returns a structured alert decision through the event-analysis response contract

#### Scenario: Health event does not match a workflow
- **WHEN** the backend receives an unsupported event-analysis request
- **THEN** the router returns a deterministic unsupported-event result
- **THEN** the router does not dispatch the event to general chat

#### Scenario: Event workflow needs model output
- **WHEN** an event-triggered workflow needs LLM reasoning
- **THEN** the workflow invokes the shared model client using configured model invocation settings
- **THEN** the workflow does not bypass the existing provider abstraction

### Requirement: Event-triggered workflow responses are validated
Event-triggered workflows SHALL validate alert decision payloads before the backend returns them to the app.

#### Scenario: Alert decision validates successfully
- **WHEN** an event-triggered workflow returns a decision with notification flag, severity, reason, evidence, title, body, and freshness metadata
- **THEN** the backend validates the decision schema
- **THEN** the backend returns the decision to the app

#### Scenario: Alert decision validation fails
- **WHEN** an event-triggered workflow returns a malformed or unsafe alert decision
- **THEN** the backend suppresses notification output
- **THEN** the response includes a validation failure reason suitable for logging or debugging
