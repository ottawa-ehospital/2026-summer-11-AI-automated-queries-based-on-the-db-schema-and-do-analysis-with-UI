# Backend-Backed AI Assistant

## Purpose

Backend-owned AI assistant orchestration for Flutter chat, including structured result items returned through the assistant endpoint.
## Requirements
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

### Requirement: Assistant provider factory selects implementations
The backend assistant service SHALL select assistant implementations through a provider factory instead of constructing provider-specific orchestration directly in the FastAPI route or shared chat facade.

#### Scenario: Default provider is selected
- **WHEN** the assistant chat endpoint handles a request without an explicit test override
- **THEN** the backend obtains the configured default assistant provider from the provider factory
- **THEN** the provider returns an `AssistantChatResponse` with `reply` and `results`

#### Scenario: Named provider is selected in tests
- **WHEN** backend tests request a named assistant provider from the factory
- **THEN** the factory returns an implementation for that provider key
- **THEN** the returned implementation satisfies the common assistant provider interface

#### Scenario: Unknown provider is rejected
- **WHEN** the factory is asked for an unsupported provider key
- **THEN** it raises a clear configuration error instead of falling back to an unrelated provider

### Requirement: LangGraph wearable chart provider is isolated
The backend SHALL keep the wearable metric LangGraph chart workflow in a dedicated assistant provider implementation so other direct model providers cannot modify its graph, query mapping, or chart result construction.

#### Scenario: Wearable chart request uses LangGraph provider
- **WHEN** the configured provider is the wearable LangGraph provider and a user asks for heart rate
- **THEN** the provider runs the wearable single-table chart flow
- **THEN** it returns the validated text and chart results through the shared assistant response contract

#### Scenario: Direct provider does not run chart graph
- **WHEN** the configured provider is a direct text provider
- **THEN** the provider does not execute the wearable chart graph
- **THEN** it returns a text-only structured assistant response unless that provider explicitly implements its own validated chart flow

### Requirement: Direct model provider examples remain text-only and isolated
The backend SHALL include minimal direct model provider examples for Gemini-style and local-model-style assistant calls that demonstrate the shared provider interface without changing the default LangGraph wearable provider.

#### Scenario: Direct Gemini-style provider returns structured text
- **WHEN** the direct Gemini-style provider handles a chat request
- **THEN** it invokes its model path and wraps the reply in a text result
- **THEN** the FastAPI assistant response shape remains unchanged

#### Scenario: Direct local-model-style provider returns structured text
- **WHEN** the direct local-model-style provider handles a chat request
- **THEN** it invokes its local model path and wraps the reply in a text result
- **THEN** the FastAPI assistant response shape remains unchanged

### Requirement: Shared response helpers are provider-neutral
The backend SHALL keep assistant response composition and result validation in provider-neutral helper code used by all assistant providers.

#### Scenario: Provider composes text response
- **WHEN** any provider returns a text-only answer
- **THEN** it uses the shared helper or equivalent shared contract to populate both `reply` and a text item in `results`

#### Scenario: Provider proposes chart response
- **WHEN** any provider proposes a chart result
- **THEN** it validates the result payload through the shared assistant result validator before returning it to Flutter

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

### Requirement: Backend assistant coexists with report interpreter backend
The backend-backed health assistant SHALL continue to operate through its existing assistant routes after the report interpreter backend is added.

#### Scenario: Health assistant route remains available
- **WHEN** the report interpreter router is registered
- **THEN** `POST /assistant/chat` remains available
- **THEN** the response shape for health assistant chat remains compatible with the existing Flutter Health Chat module

### Requirement: AI area can route to specialized modules
The Flutter AI assistant area SHALL route users to separate AI modules, where Chat uses the existing backend-backed assistant API and Report Interpreter uses the isolated report interpreter API.

#### Scenario: User selects Health Chat module
- **WHEN** a user selects Health Chat in the AI module host
- **THEN** Flutter sends health chat messages through the existing assistant backend repository path
- **THEN** Flutter renders the existing chat conversation UI

#### Scenario: User selects Report Interpreter module
- **WHEN** a user selects Report Interpreter in the AI module host
- **THEN** Flutter sends report upload and report follow-up requests through the report interpreter backend namespace
- **THEN** Flutter renders the migrated report interpreter UI instead of the health chat conversation UI
