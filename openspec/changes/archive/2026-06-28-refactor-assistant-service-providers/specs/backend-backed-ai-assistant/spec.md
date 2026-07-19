## ADDED Requirements

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
