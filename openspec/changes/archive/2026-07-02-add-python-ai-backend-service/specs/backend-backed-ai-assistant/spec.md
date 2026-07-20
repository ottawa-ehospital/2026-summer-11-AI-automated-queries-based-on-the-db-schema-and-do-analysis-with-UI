## ADDED Requirements

### Requirement: Health assistant uses backend orchestration
The Health Assistant screen SHALL obtain AI replies through the Python backend service instead of building patient context and invoking the model directly in Flutter.

#### Scenario: User sends assistant message
- **WHEN** a logged-in user sends a message in the Health Assistant screen
- **THEN** Flutter sends the patient id and message to the backend assistant chat endpoint
- **THEN** the backend returns the assistant reply shown in the chat UI

#### Scenario: User is not logged in
- **WHEN** no patient id is available
- **THEN** the screen does not call the backend and shows a clear not-logged-in state or error

### Requirement: Vitals AI summaries use backend generation
Vitals screen AI summaries SHALL be generated through the Python backend service.

#### Scenario: Vitals page loads AI summary
- **WHEN** vitals data is available for a patient
- **THEN** Flutter requests summaries from the backend rather than calling Gemini or Ollama directly

### Requirement: Trend AI insights use backend generation
Trend comparison AI insights SHALL be generated through the Python backend service.

#### Scenario: Trend page loads AI insight
- **WHEN** week-over-week metrics are available for a patient
- **THEN** Flutter requests structured trend insights from the backend
- **THEN** the UI renders the returned insights in the existing trend cards

### Requirement: Flutter-local AI providers are not primary workflow
Flutter-local Gemini and Ollama calls SHALL be deprecated as the primary assistant workflow once backend-backed AI is available.

#### Scenario: Backend AI provider is configured
- **WHEN** Flutter is launched with the backend AI provider enabled
- **THEN** assistant, vitals summary, and trend insight screens use backend APIs rather than local provider calls
