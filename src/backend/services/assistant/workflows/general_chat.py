from __future__ import annotations

from src.backend.schemas.assistant import AssistantChatResponse
from src.backend.services.assistant.base import AssistantProvider
from src.backend.services.assistant.workflows.base import (
    AssistantWorkflowState,
    WorkflowMatch,
)


class GeneralChatWorkflow:
    key = "general_chat"
    description = "Fallback workflow for ordinary assistant conversation."

    def __init__(self, provider: AssistantProvider) -> None:
        self._provider = provider

    async def can_handle(self, state: AssistantWorkflowState) -> WorkflowMatch:
        return WorkflowMatch(self.key, 0.0, "fallback only")

    async def run(self, state: AssistantWorkflowState) -> AssistantChatResponse:
        return await self._provider.chat(state.patient_id, state.message, state.history)
