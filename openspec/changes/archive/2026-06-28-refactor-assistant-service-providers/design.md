## Context

The backend assistant currently exposes a stable FastAPI contract, but the implementation boundary is too broad: `assistant_service.py` owns endpoint orchestration, direct model invocation, LangGraph chart routing, result validation, and fallback text composition. This made sense for the MVP, but it does not scale when other contributors want to add Gemini, local model, or custom LangGraph implementations.

The desired architecture is a small shared assistant API shell plus provider implementations selected through a factory. The user's LangGraph wearable chart design should remain the default product provider, but it should live in its own module so other experiments do not change its graph, prompts, or data-query logic.

## Goals / Non-Goals

**Goals:**

- Keep `/assistant/chat` and `AssistantChatResponse` stable for Flutter and external callers.
- Define a clear `AssistantProvider` interface for every assistant implementation.
- Add an `AssistantProviderFactory` that selects providers by configuration or explicit key.
- Move the wearable LangGraph chart workflow into a dedicated provider module.
- Provide direct text-only examples for Gemini-style and local-model-style calls.
- Keep shared result composition and validation reusable across providers.

**Non-Goals:**

- Change Flutter request or response shape.
- Add complex multi-table analytical graph behavior.
- Make Gemini or local provider the default assistant behavior.
- Introduce provider-specific response fields into `AssistantChatResponse`.

## Decisions

### Provider Interface

Create a backend assistant interface, for example `AssistantProvider`, with one async method:

```python
async def chat(
    self,
    patient_id: int | str,
    message: str,
    history: list[AssistantConversationMessage] | None = None,
) -> AssistantChatResponse
```

Rationale: the public endpoint should only know that a provider can answer a chat request with the shared response model. Provider internals can use LangGraph, direct model calls, or mocks.

Alternative considered: keep one service class with methods for each model. That keeps files fewer but preserves the current coupling and makes future provider additions edit shared code.

### Factory Selection

Introduce an `AssistantProviderFactory` or `get_assistant_provider()` function that maps provider keys to provider classes. The default provider remains the wearable LangGraph provider. Example keys:

- `wearable_langgraph`
- `direct_gemini`
- `direct_local`

Rationale: contributors can add a provider by registering it in one controlled place while tests can instantiate providers directly.

Alternative considered: choose providers inside FastAPI route handlers. That makes endpoint code aware of implementation details and weakens the service boundary.

### Provider Module Layout

Use a package-style layout under backend assistant services, for example:

```text
src/backend/services/assistant/
  __init__.py
  base.py
  factory.py
  result_helpers.py
  providers/
    wearable_langgraph.py
    direct_gemini.py
    direct_local.py
```

`assistant_service.py` can remain as a compatibility facade that imports the factory and exposes existing functions used by routes/tests.

Rationale: this keeps implementation ownership visible. The user's LangGraph design is isolated in `wearable_langgraph.py`; other providers are examples, not modifications to that graph.

Alternative considered: split into many top-level service files. That works but makes assistant-specific concepts less discoverable.

### Shared Result Helpers

Move reusable helpers such as `compose_text_response()` and `validate_assistant_result_payload()` out of provider implementations and into shared result helpers.

Rationale: providers should not duplicate response-model glue, and all providers must return validated structured results.

### Direct Provider Examples

Add minimal examples:

- Direct Gemini-style provider: builds patient context, invokes the configured model client with a provider-specific system prompt, and returns text-only structured response.
- Direct local-model-style provider: same contract, using local model settings or the existing model client abstraction.

These examples demonstrate extension without becoming the default path.

## Risks / Trade-offs

- Provider registry drift -> Keep a small factory test that verifies each registered provider implements the interface and returns `AssistantChatResponse`.
- Over-abstracting before many providers exist -> Keep the interface narrow and avoid provider lifecycle frameworks.
- Accidental behavior change in current chart flow -> Preserve current LangGraph chart tests and add parity tests for the new provider module.
- Configuration confusion -> Use explicit provider names and make the default value documented.

## Migration Plan

1. Add the assistant provider package and shared provider interface.
2. Move current LangGraph chart code into the wearable LangGraph provider.
3. Keep existing route imports stable through a compatibility facade.
4. Add direct Gemini/local text providers as non-default examples.
5. Add factory and provider tests.
6. Run backend tests and Flutter tests to verify API compatibility.
