from __future__ import annotations

from abc import ABC, abstractmethod

from src.backend.schemas.assistant import (
    AssistantChatResponse,
    AssistantConversationMessage,
)


class AssistantProvider(ABC):
    """Common contract for backend assistant implementations.

    Providers can use LangGraph, direct Gemini-style calls, local models, or
    test doubles, but they must return the shared structured response model.
    """

    @abstractmethod
    async def chat(
        self,
        patient_id: int | str,
        message: str,
        history: list[AssistantConversationMessage] | None = None,
    ) -> AssistantChatResponse:
        raise NotImplementedError
