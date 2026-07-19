## MODIFIED Requirements

### Requirement: Health assistant uses backend orchestration
The Health Assistant screen SHALL obtain AI replies and structured assistant results through the Python backend service instead of building patient context and invoking the model directly in Flutter. The backend orchestration SHALL be able to use a LangGraph-compatible flow for simple single-table chart queries without changing the Flutter response contract, and SHALL accept optional runtime model invocation settings without requiring deployment-time provider changes.

#### Scenario: User sends assistant message
- **WHEN** a logged-in user sends a message in the Health Assistant screen
- **THEN** Flutter sends the patient id, message, and any active model invocation settings to the backend assistant chat endpoint
- **THEN** the backend returns the assistant reply and ordered structured result items shown in the chat UI

#### Scenario: User asks for recent heart rate
- **WHEN** a logged-in user asks for their recent heart-rate pattern
- **THEN** Flutter sends the same assistant chat request shape to the backend
- **THEN** the backend may use its LangGraph-compatible single-table chart flow to return a text reply and chart result

#### Scenario: User is not logged in
- **WHEN** no patient id is available
- **THEN** the screen does not call the backend and shows a clear not-logged-in state or error

## ADDED Requirements

### Requirement: Backend routes assistant calls by request invocation settings
The backend assistant endpoints SHALL route model calls using valid request-level model invocation settings when those settings are provided.

#### Scenario: Request specifies a supported assistant provider
- **WHEN** an assistant request includes a model invocation profile with a supported assistant provider key
- **THEN** the backend uses that provider for the request
- **THEN** the backend keeps the existing assistant response shape

#### Scenario: Request omits invocation settings
- **WHEN** an assistant request omits model invocation settings
- **THEN** the backend uses its deployment default assistant provider and model configuration

### Requirement: Backend validates runtime invocation settings
The backend SHALL validate runtime model invocation settings before invoking a model.

#### Scenario: Unsupported provider is requested
- **WHEN** an assistant request includes an unsupported assistant provider key
- **THEN** the backend returns a validation error that identifies the unsupported provider
- **THEN** the backend does not invoke a model

#### Scenario: Required model details are missing
- **WHEN** an assistant request includes a provider mode that requires a model name or endpoint/base URL and those values are missing
- **THEN** the backend returns a validation error before invoking a model

### Requirement: Backend applies invocation settings consistently across assistant workflows
The backend SHALL apply runtime model invocation settings consistently for chat, vitals summary, and trend insight assistant endpoints.

#### Scenario: Vitals summary request includes invocation settings
- **WHEN** Flutter requests a vitals summary with active model invocation settings
- **THEN** the backend invokes the configured model behavior for that request
- **THEN** the backend returns the existing vitals summary response shape

#### Scenario: Trend insight request includes invocation settings
- **WHEN** Flutter requests trend insights with active model invocation settings
- **THEN** the backend invokes the configured model behavior for that request
- **THEN** the backend returns the existing trend insights response shape
