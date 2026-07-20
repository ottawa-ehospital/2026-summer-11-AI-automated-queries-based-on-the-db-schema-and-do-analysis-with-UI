## MODIFIED Requirements

### Requirement: Health assistant uses backend orchestration
The Health Assistant screen SHALL obtain AI replies and structured assistant results through the Python backend service instead of building patient context and invoking the model directly in Flutter. The backend orchestration SHALL be able to use a complete LangGraph query/report workflow above the configured AI provider to analyze health-data intent, build and validate Sigma query plans, execute patient-scoped backend queries, analyze results, and return validated text, report, and chart result items without changing the Flutter request contract.

#### Scenario: User sends assistant message
- **WHEN** a logged-in user sends a message in the Health Assistant screen
- **THEN** Flutter sends the patient id and message to the backend assistant chat endpoint
- **THEN** the backend returns the assistant reply and ordered structured result items shown in the chat UI

#### Scenario: User asks for recent heart rate
- **WHEN** a logged-in user asks for their recent heart-rate pattern
- **THEN** Flutter sends the same assistant chat request shape to the backend
- **THEN** the backend may use its LangGraph query/report workflow to build and validate a patient-scoped Sigma query
- **THEN** the backend may return a text reply, Markdown report, and chart result after validating all structured result payloads

#### Scenario: User asks for health data analysis
- **WHEN** a logged-in user asks a question that requires querying and analyzing patient health data
- **THEN** Flutter sends the same assistant chat request shape to the backend
- **THEN** the backend routes the request through the complete LangGraph query/report workflow
- **THEN** workflow LLM calls use the configured AI provider through the shared model client
- **THEN** the backend returns a compatible assistant response with validated structured result items

#### Scenario: User asks for personalized health plan or advice
- **WHEN** a logged-in user asks for a running plan, exercise recommendation, recovery guidance, sleep-improvement advice, or another supported personalized health action
- **THEN** Flutter sends the same assistant chat request shape to the backend
- **THEN** the backend gathers relevant patient context and executes validated patient-scoped queries before generating recommendations
- **THEN** the backend returns a structured response rather than answering solely from general model knowledge

#### Scenario: Workflow cannot safely query data
- **WHEN** the backend cannot validate a patient-scoped query for the user's request
- **THEN** the backend returns a compatible fallback or clarification response
- **THEN** Flutter receives the same response model as successful specialized workflows

#### Scenario: User is not logged in
- **WHEN** no patient id is available
- **THEN** the screen does not call the backend and shows a clear not-logged-in state or error
