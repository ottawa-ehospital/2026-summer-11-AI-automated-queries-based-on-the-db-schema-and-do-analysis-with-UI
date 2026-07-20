from __future__ import annotations

from collections.abc import Callable

from src.backend.core.config import settings
from src.backend.schemas.assistant import ModelInvocationSettings
from src.backend.services.assistant.base import AssistantProvider
from src.backend.services.assistant.providers.direct_gemini import DirectGeminiAssistantProvider
from src.backend.services.assistant.providers.direct_local import DirectLocalAssistantProvider
from src.backend.services.assistant.providers.wearable_langgraph import (
    WearableLangGraphAssistantProvider,
)


ASSISTANT_PROVIDER_WEARABLE_LANGGRAPH = "wearable_langgraph"
ASSISTANT_PROVIDER_DIRECT_GEMINI = "direct_gemini"
ASSISTANT_PROVIDER_DIRECT_LOCAL = "direct_local"


class AssistantProviderFactory:
    """Creates assistant providers from explicit provider keys."""

    def __init__(self) -> None:
        self._registry: dict[str, Callable[[ModelInvocationSettings | None], AssistantProvider]] = {
            ASSISTANT_PROVIDER_WEARABLE_LANGGRAPH: WearableLangGraphAssistantProvider,
            ASSISTANT_PROVIDER_DIRECT_GEMINI: DirectGeminiAssistantProvider,
            ASSISTANT_PROVIDER_DIRECT_LOCAL: DirectLocalAssistantProvider,
        }

    def create(
        self,
        provider_key: str | None = None,
        model_invocation: ModelInvocationSettings | None = None,
    ) -> AssistantProvider:
        key = (provider_key or settings.assistant_provider).strip().lower()
        factory = self._registry.get(key)
        if factory is None:
            supported = ", ".join(sorted(self._registry))
            raise ValueError(
                f"Unsupported ASSISTANT_PROVIDER '{key}'. Supported providers: {supported}."
            )
        return factory(model_invocation)

    @property
    def supported_provider_keys(self) -> tuple[str, ...]:
        return tuple(sorted(self._registry))


def get_assistant_provider(
    provider_key: str | None = None,
    model_invocation: ModelInvocationSettings | None = None,
) -> AssistantProvider:
    return AssistantProviderFactory().create(provider_key, model_invocation)
