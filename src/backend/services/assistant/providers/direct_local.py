from __future__ import annotations

from fastapi import HTTPException

from src.backend.clients.model_client import invoke_model
from src.backend.schemas.assistant import (
    AssistantChatResponse,
    AssistantConversationMessage,
    ModelInvocationSettings,
)
from src.backend.services.assistant.base import AssistantProvider
from src.backend.services.assistant.prompt_helpers import (
    build_chat_prompt,
    build_system_prompt,
)
from src.backend.services.assistant.result_helpers import compose_text_response
from src.backend.services.patient_context_service import build_patient_context


class DirectLocalAssistantProvider(AssistantProvider):
    """Example provider for a direct local-model style assistant call.

    This provider intentionally does not run the wearable chart graph. It shows
    contributors how to call a model directly while preserving the shared
    assistant response contract.
    """

    def __init__(self, model_invocation: ModelInvocationSettings | None = None) -> None:
        self._model_invocation = model_invocation

    async def chat(
        self,
        patient_id: int | str,
        message: str,
        history: list[AssistantConversationMessage] | None = None,
    ) -> AssistantChatResponse:
        if not message.strip():
            raise HTTPException(status_code=400, detail="Message must not be empty")

        context = await build_patient_context(patient_id)
        prompt = build_chat_prompt(message, history or [])
        if self._model_invocation is None:
            reply = invoke_model(prompt, build_system_prompt(context))
        else:
            reply = invoke_model(prompt, build_system_prompt(context), self._model_invocation)
        return compose_text_response(reply)
