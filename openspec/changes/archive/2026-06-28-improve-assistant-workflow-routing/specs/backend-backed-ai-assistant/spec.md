## MODIFIED Requirements

### Requirement: Health assistant uses backend orchestration
The Health Assistant screen SHALL obtain AI replies and structured assistant results through the Python backend service instead of building patient context and invoking the model directly in Flutter. The backend orchestration SHALL be able to use a LangGraph-compatible workflow router above the configured AI provider to dispatch assistant chat messages to the health-data query/report workflow or fallback chat without changing the Flutter request contract.

#### Scenario: User sends assistant message
- **WHEN** a logged-in user sends a message in the Health Assistant screen
- **THEN** Flutter sends the patient id and message to the backend assistant chat endpoint
- **THEN** the backend routes the message to an appropriate assistant workflow or fallback workflow
- **THEN** any workflow LLM calls use the configured AI provider through the shared model client
- **THEN** the backend returns the assistant reply and ordered structured result items shown in the chat UI

#### Scenario: User asks for health data analysis
- **WHEN** a logged-in user asks a question that requires querying and analyzing patient health data
- **THEN** Flutter sends the same assistant chat request shape to the backend
- **THEN** the backend may use its LangGraph-compatible query/report workflow to validate the query, execute it, analyze results, and return a validated response
- **THEN** the response may include a structured Markdown report result with generation and expiration metadata

#### Scenario: User asks for recent health metric
- **WHEN** a logged-in user asks about recent heart rate, sleep, steps, calories, blood pressure, or another supported health metric
- **THEN** Flutter sends the same assistant chat request shape to the backend
- **THEN** the backend routes the request to the health-data query/report workflow instead of returning a plain general-chat answer
- **THEN** the response may include a structured Markdown report result with freshness metadata

#### Scenario: User asks for personalized health plan or advice
- **WHEN** a logged-in user asks for a running plan, exercise recommendation, recovery guidance, sleep-improvement advice, or another supported personalized health action
- **THEN** Flutter sends the same assistant chat request shape to the backend
- **THEN** the backend routes the request to the health-data query/report workflow
- **THEN** the workflow gathers relevant patient context, validates the data query, analyzes the result, and returns a structured Markdown report rather than a plain fallback answer

#### Scenario: User request does not match a specialized workflow
- **WHEN** a logged-in user sends a supported assistant message that does not match a specialized workflow
- **THEN** the backend routes the request to a general chat fallback workflow
- **THEN** Flutter receives the same response model as specialized workflows

#### Scenario: User is not logged in
- **WHEN** no patient id is available
- **THEN** the screen does not call the backend and shows a clear not-logged-in state or error
