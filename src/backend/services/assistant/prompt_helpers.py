from __future__ import annotations

import json

from src.backend.core.config import settings
from src.backend.schemas.assistant import AssistantConversationMessage


def build_system_prompt(context: dict) -> str:
    # Centralize safety language and runtime metadata so all assistant providers
    # share the same non-diagnostic wellness boundary.
    return """You are a wellness information assistant integrated into a personal health monitoring app. You provide general wellness and health education information only.

IMPORTANT RESTRICTIONS - you must NEVER:
- Provide a medical diagnosis of any condition
- Prescribe or recommend specific treatments, medications, or dosages
- Replace or simulate the advice of a licensed healthcare professional
- Make definitive clinical judgments about the user's health

Use the patient context below for general wellness explanation only.

Patient context:
{context}

Model runtime:
provider={provider}
model={model_name}
ollama_base_url={ollama_base_url}

When responding, be concise, supportive, and refer to relevant data when useful.
Begin health-concern responses with: "For general wellness information only - please consult your healthcare provider for medical advice."
""".format(
        context=json.dumps(context, ensure_ascii=False),
        provider=settings.ai_model_provider,
        model_name=settings.ai_model_name,
        ollama_base_url=settings.ollama_base_url,
    )


def build_chat_prompt(
    message: str,
    history: list[AssistantConversationMessage],
) -> str:
    bounded_history = [
        item
        for item in history[-10:]
        if item.role in {"user", "assistant"} and item.content.strip()
    ]
    if not bounded_history:
        return message

    lines = ["Recent conversation context:"]
    for item in bounded_history:
        lines.append(f"{item.role}: {item.content.strip()}")
    lines.extend(["", "Current user message:", message])
    return "\n".join(lines)
