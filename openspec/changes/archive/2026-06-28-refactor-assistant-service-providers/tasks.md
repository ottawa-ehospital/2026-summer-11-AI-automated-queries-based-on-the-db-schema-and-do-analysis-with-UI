## 1. Provider Package Structure

- [x] 1.1 Create backend assistant provider package files for base interface, factory, shared result helpers, and providers.
- [x] 1.2 Move `AssistantProvider` interface into the provider base module with the shared `chat()` contract.
- [x] 1.3 Move text response composition and assistant result payload validation into provider-neutral helper code.
- [x] 1.4 Keep `assistant_service.py` as a compatibility facade for FastAPI routes and existing callers.

## 2. Provider Implementations

- [x] 2.1 Move the current wearable LangGraph single-table chart workflow into a dedicated wearable LangGraph provider.
- [x] 2.2 Ensure the wearable LangGraph provider remains the default provider and preserves current heart-rate chart behavior.
- [x] 2.3 Add a direct Gemini-style text provider example that uses the shared provider interface and text response helper.
- [x] 2.4 Add a direct local-model-style text provider example that uses the shared provider interface and text response helper.

## 3. Factory And Configuration

- [x] 3.1 Implement an assistant provider factory that maps explicit provider keys to provider implementations.
- [x] 3.2 Add or reuse backend configuration for selecting the default assistant provider.
- [x] 3.3 Reject unknown provider keys with a clear configuration error and no implicit fallback.
- [x] 3.4 Update assistant chat routing to resolve providers through the factory instead of directly constructing provider-specific orchestration.

## 4. Tests And Verification

- [x] 4.1 Add factory tests for default provider selection, named provider selection, and unknown provider rejection.
- [x] 4.2 Add provider interface tests for wearable LangGraph, direct Gemini-style, and direct local-model-style providers.
- [x] 4.3 Preserve chart behavior tests for patient-scoped heart-rate chart results.
- [x] 4.4 Run backend compile and pytest checks for assistant and query tooling.
- [x] 4.5 Run Flutter analyze and tests to confirm the assistant API response contract remains compatible.
