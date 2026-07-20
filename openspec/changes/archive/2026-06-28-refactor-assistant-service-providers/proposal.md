## Why

The backend assistant service currently mixes the public assistant API, model invocation, LangGraph chart orchestration, and fallback text behavior in one service module. As more contributors add assistant implementations, this makes it easy for one provider's graph or prompt choices to pollute the shared API path.

This change separates assistant provider selection from provider implementations so the shared FastAPI contract remains stable while LangGraph, Gemini, and local model examples live behind explicit factory-selected providers.

## What Changes

- Introduce a backend assistant provider factory that selects a named assistant provider from configuration or explicit construction.
- Move the wearable LangGraph chart workflow into its own provider implementation instead of keeping graph-specific logic in the shared assistant service.
- Keep the FastAPI `/assistant/chat` API and structured `AssistantChatResponse` contract unchanged.
- Add simple example providers for direct Gemini-style and local-model-style calls that compose text-only structured responses.
- Keep provider implementations isolated behind a common interface so contributors can add or test providers without modifying the primary assistant endpoint logic.
- Document the provider contract and the intended extension points in code comments or docs.

## Capabilities

### New Capabilities

None.

### Modified Capabilities

- `backend-backed-ai-assistant`: Adds explicit provider factory and provider isolation requirements for backend assistant implementations.

## Impact

- Affected backend code: `src/backend/services/assistant_service.py` and new provider/factory modules under the backend assistant service area.
- Affected tests: backend assistant tests should cover provider factory selection, provider interface conformance, LangGraph provider chart behavior, and direct text provider examples.
- API impact: no breaking change to `/assistant/chat`; callers still receive `reply` and `results`.
- Configuration impact: may add an assistant-provider setting while keeping current behavior as the default.
