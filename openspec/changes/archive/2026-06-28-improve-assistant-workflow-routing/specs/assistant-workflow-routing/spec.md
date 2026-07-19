## ADDED Requirements

### Requirement: Assistant workflows are registered behind a router
The backend assistant orchestration layer SHALL route chat messages through a workflow registry above the bottom-level AI provider layer.

#### Scenario: Registered workflow handles a message
- **WHEN** an assistant chat message matches a registered workflow with sufficient confidence
- **THEN** the router dispatches the request to that workflow
- **THEN** the workflow returns an `AssistantChatResponse` through the existing chat endpoint

#### Scenario: Workflow needs model output
- **WHEN** a workflow needs LLM-generated output
- **THEN** the workflow invokes the shared model client using the configured model provider
- **THEN** the workflow does not bypass the model provider abstraction

#### Scenario: New workflow is added
- **WHEN** a developer adds a workflow implementation and registers it with the router
- **THEN** the workflow can handle eligible assistant chat messages without changing the Flutter chat request shape

### Requirement: Workflow routing has deterministic fallback behavior
The workflow router SHALL provide deterministic fallback behavior when no specialized workflow confidently handles a message.

#### Scenario: No workflow matches
- **WHEN** no registered specialized workflow meets the routing confidence threshold
- **THEN** the router dispatches the request to the general chat workflow

#### Scenario: Ambiguous workflow match
- **WHEN** multiple workflows can handle a message but none has sufficient confidence
- **THEN** the router returns a clarification response or dispatches to the general chat workflow according to the configured fallback policy

### Requirement: Workflows share a stable response contract
Each assistant workflow SHALL return the shared `AssistantChatResponse` model and SHALL validate structured result payloads before returning them to the API layer.

#### Scenario: Workflow returns structured result
- **WHEN** a workflow produces a chart or other structured assistant result
- **THEN** the result is validated against the backend schema before the response is returned

#### Scenario: Workflow returns text only
- **WHEN** a workflow produces a text-only answer
- **THEN** the response contains a reply and a text result compatible with existing Flutter rendering

### Requirement: Query report workflow validates queries and outputs
The health-data query/report workflow SHALL validate generated queries before execution and validate generated reports before returning them. The workflow SHALL handle both health metric analysis requests and supported personalized health planning/advice requests where an answer depends on patient context.

#### Scenario: Query validates successfully
- **WHEN** the query/report workflow builds a valid query for the user's request
- **THEN** the workflow executes the query and continues to result analysis

#### Scenario: Query validation fails with retries remaining
- **WHEN** query validation fails and the workflow has remaining query validation attempts
- **THEN** the workflow revises the query and validates it again

#### Scenario: Query validation exceeds retry limit
- **WHEN** query validation fails after the configured maximum attempts
- **THEN** the workflow stops retrying and returns a fallback response instead of looping indefinitely

#### Scenario: Output validation fails with retries remaining
- **WHEN** report output validation fails and the workflow has remaining output validation attempts
- **THEN** the workflow revises the report and validates it again

#### Scenario: Output validation exceeds retry limit
- **WHEN** report output validation fails after the configured maximum attempts
- **THEN** the workflow stops retrying and returns a fallback response instead of looping indefinitely

#### Scenario: Report validates successfully
- **WHEN** report output validation succeeds
- **THEN** the workflow returns a structured report result with Markdown content and freshness metadata

#### Scenario: Personalized planning request is routed through the query report workflow
- **WHEN** a user asks for a running plan, workout recommendation, sleep-improvement plan, recovery guidance, or similar personalized health advice
- **THEN** the router selects the health-data query/report workflow with sufficient confidence
- **THEN** the workflow gathers relevant patient context and analyzes available health data before returning a structured Markdown report
- **THEN** the request is not handled as plain general chat solely because the user did not ask for a "report"

### Requirement: Query report workflow uses named routing decisions
The health-data query/report workflow SHALL use named routing decisions that describe the condition being evaluated.

#### Scenario: Context gathering branch is selected
- **WHEN** question analysis determines that patient profile context is required
- **THEN** the workflow routes through a context-gathering decision named for that need

#### Scenario: Validation branch is selected
- **WHEN** query or output validation fails
- **THEN** the workflow routes through a failure branch named for the failed validation outcome

### Requirement: Query report workflow assigns report expiration
The health-data query/report workflow SHALL assign each generated report an expiration timestamp based on the expected freshness of the report's underlying inference.

#### Scenario: Short-term report is generated
- **WHEN** a report depends on short-term signals such as recent sleep, readiness, acute symptoms, or recent activity
- **THEN** the workflow assigns a short expiration window appropriate for data that may change within hours or after the next relevant data update
- **THEN** the report includes a freshness reason explaining why it may expire quickly

#### Scenario: Longer-term report is generated
- **WHEN** a report depends on longer-term baseline or historical trends
- **THEN** the workflow may assign a longer expiration window
- **THEN** the report still includes an explicit expiration timestamp

#### Scenario: Expiration cannot be determined confidently
- **WHEN** the workflow cannot determine the correct freshness category for a report
- **THEN** the workflow uses a conservative expiration window
- **THEN** the report includes a freshness reason that describes the uncertainty

### Requirement: AI providers remain model invocation adapters
AI providers SHALL represent bottom-level model invocation adapters and SHALL NOT be used as the primary extension point for business workflows.

#### Scenario: Model provider is selected
- **WHEN** request or runtime settings select Gemini, local/Ollama, or OpenAI-compatible invocation
- **THEN** that selection controls only the underlying model call behavior
- **THEN** workflow selection remains controlled by the assistant orchestration router

#### Scenario: New business workflow is added
- **WHEN** a developer adds a new assistant business capability such as query reporting or appointments
- **THEN** the capability is added as a workflow or orchestrator behavior
- **THEN** it is not added as a new bottom-level AI provider solely because it uses LangGraph
