from __future__ import annotations

from dataclasses import dataclass, field
from typing import Protocol

from src.backend.schemas.assistant import (
    AssistantChatResponse,
    AssistantConversationMessage,
    ModelInvocationSettings,
)


@dataclass(frozen=True)
class WorkflowMatch:
    workflow_key: str
    confidence: float
    reason: str = ""


@dataclass
class WorkflowTrace:
    selected_workflow: str | None = None
    confidence: float = 0.0
    reason: str = ""
    fallback_reason: str | None = None
    model_provider: str | None = None


@dataclass
class AssistantWorkflowState:
    patient_id: int | str
    message: str
    history: list[AssistantConversationMessage] = field(default_factory=list)
    model_invocation: ModelInvocationSettings | None = None
    trace: WorkflowTrace = field(default_factory=WorkflowTrace)


class AssistantWorkflow(Protocol):
    key: str
    description: str

    async def can_handle(self, state: AssistantWorkflowState) -> WorkflowMatch:
        ...

    async def run(self, state: AssistantWorkflowState) -> AssistantChatResponse:
        ...
