from __future__ import annotations

from collections.abc import Iterable

from src.backend.services.assistant.workflows.base import AssistantWorkflow


class WorkflowRegistry:
    def __init__(self, workflows: Iterable[AssistantWorkflow] | None = None) -> None:
        self._workflows: list[AssistantWorkflow] = []
        self._keys: set[str] = set()
        for workflow in workflows or []:
            self.register(workflow)

    def register(self, workflow: AssistantWorkflow) -> None:
        if workflow.key in self._keys:
            raise ValueError(f"Duplicate assistant workflow key: {workflow.key}")
        self._workflows.append(workflow)
        self._keys.add(workflow.key)

    @property
    def workflows(self) -> tuple[AssistantWorkflow, ...]:
        return tuple(self._workflows)

    @property
    def keys(self) -> tuple[str, ...]:
        return tuple(workflow.key for workflow in self._workflows)
