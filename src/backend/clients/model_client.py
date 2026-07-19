from __future__ import annotations

import json
import re
from typing import Any

from fastapi import HTTPException
from langchain.chat_models import init_chat_model
from langchain.messages import HumanMessage, SystemMessage
from langchain_openai import ChatOpenAI

from src.backend.core.config import settings
from src.backend.schemas.assistant import ModelInvocationSettings


def invoke_model(
    prompt: str,
    system_prompt: str | None = None,
    model_invocation: ModelInvocationSettings | None = None,
) -> str:
    # Keep LangChain/Ollama/Gemini invocation behind one function so service
    # code can later swap to LangGraph without changing router contracts.
    model_provider = _setting_value(
        model_invocation.model_provider if model_invocation else None,
        settings.ai_model_provider,
    )
    model_name = _setting_value(
        model_invocation.model_name if model_invocation else None,
        settings.ai_model_name,
    )
    base_url = _setting_value(
        model_invocation.base_url if model_invocation else None,
        settings.ollama_base_url,
    )
    try:
        messages = []
        if system_prompt:
            messages.append(SystemMessage(content=system_prompt))
        messages.append(HumanMessage(content=prompt))
        response = _build_chat_model(model_provider, model_name, base_url).invoke(messages)
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=(
                "AI model failed via "
                f"{model_provider}/{model_name}: {exc}"
            ),
        ) from exc

    text = str(getattr(response, "content", "")).strip()
    if not text:
        raise HTTPException(status_code=502, detail="AI model returned an empty response")
    return text


def invoke_model_json(
    prompt: str,
    system_prompt: str | None = None,
    model_invocation: ModelInvocationSettings | None = None,
) -> dict[str, Any]:
    text = invoke_model(prompt, system_prompt, model_invocation)
    return parse_model_json(text)


def parse_model_json(text: str) -> dict[str, Any]:
    cleaned = text.strip()
    fenced = re.search(r"```(?:json)?\s*(.*?)```", cleaned, flags=re.DOTALL | re.IGNORECASE)
    if fenced:
        cleaned = fenced.group(1).strip()
    try:
        value = json.loads(cleaned)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=502, detail="AI model returned invalid JSON") from exc
    if not isinstance(value, dict):
        raise HTTPException(status_code=502, detail="AI model returned invalid JSON")
    return value


def _build_chat_model(model_provider: str, model_name: str, base_url: str):
    provider = model_provider.strip().lower()
    if provider in {"ollama", "local"}:
        return ChatOpenAI(
            model=model_name,
            base_url=f"{base_url.rstrip('/')}/v1",
            api_key="ollama",
        )
    return init_chat_model(model_name, model_provider=provider)


def _setting_value(candidate: str | None, fallback: str) -> str:
    value = (candidate or "").strip()
    return value if value else fallback
