"""Compatibility exports for older imports.

New backend code should import from `src.backend.api`, `src.backend.clients`, or
`src.backend.services` directly.
"""

from src.backend.api.assistant import router
from src.backend.clients.ehospital_client import fetch_ehospital_table
from src.backend.clients.model_client import invoke_model as _invoke_model
from src.backend.services.assistant_service import build_system_prompt as _system_prompt
from src.backend.services.patient_context_service import build_patient_context

__all__ = [
    "router",
    "fetch_ehospital_table",
    "build_patient_context",
    "_invoke_model",
    "_system_prompt",
]

