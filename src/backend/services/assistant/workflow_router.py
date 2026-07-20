from __future__ import annotations

from src.backend.core.logging import get_backend_logger
from src.backend.schemas.assistant import AssistantChatResponse
from src.backend.services.assistant.workflows.base import (
    AssistantWorkflow,
    AssistantWorkflowState,
    WorkflowMatch,
)
from src.backend.services.assistant.workflows.registry import WorkflowRegistry


class WorkflowRouter:
    def __init__(
        self,
        registry: WorkflowRegistry,
        fallback_workflow: AssistantWorkflow,
        confidence_threshold: float = 0.6,
    ) -> None:
        self._registry = registry
        self._fallback_workflow = fallback_workflow
        self._confidence_threshold = confidence_threshold
        self._logger = get_backend_logger()

    async def route(self, state: AssistantWorkflowState) -> AssistantChatResponse:
        matches = [await workflow.can_handle(state) for workflow in self._registry.workflows]
        selected = self._select_match(matches)
        if selected is None:
            state.trace.selected_workflow = self._fallback_workflow.key
            state.trace.fallback_reason = "no workflow met confidence threshold"
            self._log_route(state)
            return await self._fallback_workflow.run(state)

        workflow = self._workflow_by_key(selected.workflow_key)
        state.trace.selected_workflow = selected.workflow_key
        state.trace.confidence = selected.confidence
        state.trace.reason = selected.reason
        self._log_route(state)
        return await workflow.run(state)

    def _select_match(self, matches: list[WorkflowMatch]) -> WorkflowMatch | None:
        eligible = [
            match for match in matches if match.confidence >= self._confidence_threshold
        ]
        if not eligible:
            return None
        return max(eligible, key=lambda match: match.confidence)

    def _workflow_by_key(self, key: str) -> AssistantWorkflow:
        for workflow in self._registry.workflows:
            if workflow.key == key:
                return workflow
        raise ValueError(f"Assistant workflow '{key}' is not registered.")

    def _log_route(self, state: AssistantWorkflowState) -> None:
        model_provider = (
            state.model_invocation.model_provider if state.model_invocation is not None else None
        )
        state.trace.model_provider = model_provider
        self._logger.info(
            "assistant workflow route selected=%s confidence=%.2f fallback=%s model_provider=%s",
            state.trace.selected_workflow,
            state.trace.confidence,
            state.trace.fallback_reason,
            model_provider or "default",
        )
