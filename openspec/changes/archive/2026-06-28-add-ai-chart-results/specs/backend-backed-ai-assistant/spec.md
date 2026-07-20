## MODIFIED Requirements

### Requirement: Health assistant uses backend orchestration
The Health Assistant screen SHALL obtain AI replies and structured assistant results through the Python backend service instead of building patient context and invoking the model directly in Flutter. The backend orchestration SHALL be able to use a LangGraph-compatible flow for simple single-table chart queries without changing the Flutter request contract.

#### Scenario: User sends assistant message
- **WHEN** a logged-in user sends a message in the Health Assistant screen
- **THEN** Flutter sends the patient id and message to the backend assistant chat endpoint
- **THEN** the backend returns the assistant reply and ordered structured result items shown in the chat UI

#### Scenario: User asks for recent heart rate
- **WHEN** a logged-in user asks for their recent heart-rate pattern
- **THEN** Flutter sends the same assistant chat request shape to the backend
- **THEN** the backend may use its LangGraph-compatible single-table chart flow to return a text reply and chart result

#### Scenario: User is not logged in
- **WHEN** no patient id is available
- **THEN** the screen does not call the backend and shows a clear not-logged-in state or error
