## Context

The Flutter app already has a Settings screen and backend-mediated assistant repositories. The Python backend already exposes assistant endpoints and has a provider factory with `wearable_langgraph`, `direct_gemini`, and `direct_local` provider keys, but current model/provider choices are controlled by launch or deployment configuration. That makes switching invocation behavior a rebuild/restart concern instead of an app-level setting.

This change introduces runtime model invocation settings that Flutter can persist locally and send with assistant-related requests. The backend remains the authority for executing model calls, validating supported provider keys, and falling back to deployment defaults when no runtime settings are supplied.

## Goals / Non-Goals

**Goals:**
- Add a Settings entry and detail page where users can select the active model invocation mode.
- Store non-secret invocation settings locally in Flutter and reuse them for assistant chat, vitals summary, and trend insight requests.
- Extend backend assistant requests with optional invocation configuration.
- Let backend assistant routing use request-specific provider/model settings when valid, with existing environment defaults as fallback.
- Keep existing assistant response contracts stable for Flutter UI rendering.

**Non-Goals:**
- Building a full credential vault or account-level cloud settings service.
- Adding new third-party model SDKs beyond providers already represented in the backend.
- Allowing arbitrary backend module/class selection from user input.
- Changing eHospital data access contracts or assistant result rendering schemas.

## Decisions

1. Runtime settings use a typed invocation profile.

   Flutter will model settings as a small `ModelInvocationSettings` value with fields such as `providerKey`, `modelProvider`, `modelName`, `baseUrl`, and `useGraphFlow`. Backend schemas will mirror this as an optional nested object. A typed object is preferable to loose maps because tests can verify serialization and backend validation can reject unsupported values clearly.

   Alternative considered: add individual top-level fields to every request. This would duplicate request shape and make future additions harder to reason about.

2. Flutter persists settings locally and sends them per assistant request.

   The Settings detail page will save the selected profile through `SharedPreferences` or an equivalent local store already used by the Settings feature. Repositories will load the active profile and include it in `/assistant/chat`, `/assistant/vitals-summary`, and `/assistant/trend-insights` payloads.

   Alternative considered: store the active setting only in memory. That would satisfy a single session but would make the setting disappear after restart, which is not useful for developer/testing workflows.

3. Backend validates request overrides and falls back to environment defaults.

   The backend will continue to support deployment defaults from `BackendSettings`. If a request includes an invocation profile, the service layer will validate the provider key against `AssistantProviderFactory.supported_provider_keys` and validate model-specific fields before creating the provider/model client. Invalid runtime settings should return a 400-level error with supported options rather than silently falling back.

   Alternative considered: trust Flutter to send valid settings. Backend validation is still needed because API callers are not limited to the Flutter app.

4. Provider selection and model transport stay separate.

   `providerKey` selects the assistant orchestration style, such as graph-backed or direct. `modelProvider`, `modelName`, and `baseUrl` select the model transport/config used by direct model calls. This keeps "how the assistant reasons" separate from "which model endpoint is invoked".

   Alternative considered: collapse everything into one provider string. That would be simpler initially but brittle once a graph flow needs to run against different model transports.

5. Sensitive credentials remain backend-owned for this change.

   Runtime settings can select providers, model names, and endpoints, but API keys should remain in backend environment variables unless a later change introduces secure client-side secret storage and explicit risk handling.

   Alternative considered: add API-key fields to the Settings page immediately. That would increase security complexity and is not required to solve runtime model selection.

## Risks / Trade-offs

- Runtime overrides could make assistant behavior inconsistent across sessions -> Persist and display the active invocation summary in Settings.
- User-selected provider might not be supported by the backend -> Backend returns a clear validation error listing supported providers.
- Base URL/model-name settings could point to an unavailable model -> Surface backend errors in existing assistant error states and keep the saved profile editable.
- Direct and graph providers may support different result richness -> Preserve response normalization so Flutter continues to render text and chart result items through the same contract.
- Local persistence is device-scoped -> Accept for this developer/tester workflow; account-wide sync is out of scope.

## Migration Plan

1. Add the runtime settings model and local store with defaults derived from current `ApiConfig` and backend defaults.
2. Add the Settings tile and detail page without removing existing settings behavior.
3. Extend Flutter assistant repository payloads to include the saved invocation profile when present.
4. Extend backend schemas and services to consume optional invocation settings while preserving old request compatibility.
5. Add tests for default behavior, runtime override routing, invalid provider validation, and Flutter serialization.
6. Rollback by ignoring/removing the optional `model_invocation` request field; existing backend defaults continue to work.

## Open Questions

- Should the Settings page expose only backend provider keys, or also lower-level model transport fields on the first implementation?
- Should local endpoint/base URL settings be validated with a test-call button in the same change or handled later?
- Should separate profiles be supported later for chat, summaries, and trend insights, or should all assistant workflows share one active profile?
