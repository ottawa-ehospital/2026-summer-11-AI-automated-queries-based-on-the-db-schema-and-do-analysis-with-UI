from __future__ import annotations

from fastapi import HTTPException

from src.backend.schemas.assistant import (
    AssistantChatResponse,
    AssistantConversationMessage,
    ModelInvocationSettings,
)
from src.backend.services.assistant.base import AssistantProvider
from src.backend.services.assistant.providers.direct_local import DirectLocalAssistantProvider
from src.backend.services.assistant.workflow_router import WorkflowRouter
from src.backend.services.assistant.workflows.base import AssistantWorkflowState
from src.backend.services.assistant.workflows.general_chat import GeneralChatWorkflow
from src.backend.services.assistant.workflows.health_data_query import (
    HealthDataQueryWorkflow,
)
from src.backend.services.assistant.workflows.registry import WorkflowRegistry


class LangGraphAssistantOrchestrator(AssistantProvider):
    """Workflow-capable assistant orchestrator.

    The class keeps the historical AssistantProvider interface while making
    LangGraph a workflow/orchestration layer above the shared model client.
    """

    def __init__(
        self,
        model_invocation: ModelInvocationSettings | None = None,
        fallback_provider: AssistantProvider | None = None,
        router: WorkflowRouter | None = None,
    ) -> None:
        self._model_invocation = model_invocation
        fallback = fallback_provider or DirectLocalAssistantProvider(model_invocation)
        self._router = router or WorkflowRouter(
            registry=WorkflowRegistry(
                [
                    HealthDataQueryWorkflow(),
                ]
            ),
            fallback_workflow=GeneralChatWorkflow(fallback),
        )

    async def chat(
        self,
        patient_id: int | str,
        message: str,
        history: list[AssistantConversationMessage] | None = None,
    ) -> AssistantChatResponse:
        if not message.strip():
            raise HTTPException(status_code=400, detail="Message must not be empty")

        return await self._router.route(
            AssistantWorkflowState(
                patient_id=patient_id,
                message=message,
                history=history or [],
                model_invocation=self._model_invocation,
            )
        )
