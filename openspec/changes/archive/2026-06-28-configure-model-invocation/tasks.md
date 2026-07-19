## 1. Backend Invocation Contract

- [x] 1.1 Add a backend `ModelInvocationSettings` schema with provider key, model provider, model name, endpoint/base URL, and graph/direct-flow fields.
- [x] 1.2 Add optional `model_invocation` fields to assistant chat, vitals summary, and trend insight request schemas without changing response models.
- [x] 1.3 Add validation helpers that reject unsupported assistant provider keys and incomplete model invocation settings before model execution.

## 2. Backend Routing

- [x] 2.1 Update assistant service entry points to accept request-level invocation settings for chat, vitals summary, and trend insights.
- [x] 2.2 Update `AssistantProviderFactory` usage so valid request provider keys override deployment defaults for a single request.
- [x] 2.3 Update model client/provider wiring so direct model calls can use request-level model provider, model name, and base URL when supplied.
- [x] 2.4 Preserve existing behavior when `model_invocation` is omitted.

## 3. Flutter Settings Model And Storage

- [x] 3.1 Add a Flutter model for runtime model invocation settings with JSON serialization.
- [x] 3.2 Add a local settings store that loads defaults from current app configuration and persists non-secret overrides.
- [x] 3.3 Ensure API keys or provider secrets are not saved in plain local preferences.

## 4. Flutter Settings UI

- [x] 4.1 Add a Settings tile for model invocation configuration.
- [x] 4.2 Add a model invocation settings page with controls for provider mode, model provider, model name, endpoint/base URL, and graph/direct flow.
- [x] 4.3 Show the saved active configuration when the page opens.
- [x] 4.4 Save edits locally and display success/error feedback through existing Settings UI patterns.

## 5. Flutter Assistant Request Wiring

- [x] 5.1 Update assistant repository chat payloads to include saved invocation settings when available.
- [x] 5.2 Update vitals summary and trend insight payloads to include saved invocation settings when available.
- [x] 5.3 Keep request payloads backward-compatible when no settings are saved.

## 6. Tests And Verification

- [x] 6.1 Add backend tests for omitted settings using deployment defaults.
- [x] 6.2 Add backend tests for supported provider override routing.
- [x] 6.3 Add backend tests for unsupported provider and missing required setting validation.
- [x] 6.4 Add Flutter tests for settings serialization, persistence, and assistant request payload inclusion.
- [x] 6.5 Run backend test suite for assistant behavior.
- [x] 6.6 Run Flutter analyze and targeted Flutter tests.
