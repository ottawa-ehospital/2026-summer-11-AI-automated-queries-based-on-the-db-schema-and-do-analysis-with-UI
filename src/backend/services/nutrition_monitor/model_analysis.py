from __future__ import annotations

import base64
import json
import mimetypes
import re
from typing import Any

import httpx
from fastapi import HTTPException
from langchain.chat_models import init_chat_model
from langchain.messages import HumanMessage
from langchain_openai import ChatOpenAI

from src.backend.core.config import settings


def invoke_food_image_model(
    *,
    image_bytes: bytes,
    mime_type: str,
    prompt: str,
    file_name: str | None = None,
) -> dict[str, Any]:
    provider = settings.ai_model_provider.strip().lower()
    if provider in {"ollama", "local"}:
        text = _invoke_ollama_image_model(image_bytes=image_bytes, prompt=prompt)
    else:
        text = _invoke_langchain_image_model(
            image_bytes=image_bytes,
            mime_type=_image_mime_type(mime_type, file_name),
            prompt=prompt,
        )
    if not text:
        raise HTTPException(status_code=502, detail="AI model returned an empty response")
    return parse_model_json(text)


def _invoke_langchain_image_model(*, image_bytes: bytes, mime_type: str, prompt: str) -> str:
    data_url = f"data:{mime_type};base64,{base64.b64encode(image_bytes).decode('ascii')}"
    model = _build_chat_model()
    try:
        response = model.invoke(
            [
                HumanMessage(
                    content=[
                        {"type": "text", "text": prompt},
                        {"type": "image_url", "image_url": {"url": data_url}},
                    ]
                )
            ]
        )
    except Exception as exc:
        raise HTTPException(status_code=502, detail=f"AI image model failed: {exc}") from exc
    return str(getattr(response, "content", "")).strip()


def _invoke_ollama_image_model(*, image_bytes: bytes, prompt: str) -> str:
    payload = {
        "model": settings.ai_model_name,
        "stream": False,
        "format": "json",
        "messages": [
            {
                "role": "user",
                "content": prompt,
                "images": [base64.b64encode(image_bytes).decode("ascii")],
            }
        ],
    }
    try:
        response = httpx.post(
            f"{settings.ollama_base_url.rstrip('/')}/api/chat",
            json=payload,
            timeout=120,
        )
        response.raise_for_status()
        body = response.json()
    except httpx.HTTPStatusError as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Ollama image model failed ({exc.response.status_code}): {exc.response.text}",
        ) from exc
    except (httpx.HTTPError, ValueError) as exc:
        raise HTTPException(status_code=502, detail=f"Ollama image model failed: {exc}") from exc

    message = body.get("message") if isinstance(body, dict) else None
    if isinstance(message, dict):
        return str(message.get("content") or "").strip()
    return str(body.get("response") or "").strip() if isinstance(body, dict) else ""


def _image_mime_type(mime_type: str, file_name: str | None) -> str:
    normalized = (mime_type or "").split(";", 1)[0].strip().lower()
    if normalized.startswith("image/"):
        return normalized
    guessed, _ = mimetypes.guess_type(file_name or "")
    if guessed and guessed.startswith("image/"):
        return guessed
    return "image/jpeg"


def parse_model_json(text: str) -> dict[str, Any]:
    cleaned = text.strip()
    fenced = re.search(r"```(?:json)?\s*(.*?)```", cleaned, flags=re.DOTALL | re.IGNORECASE)
    if fenced:
        cleaned = fenced.group(1).strip()
    try:
        value = json.loads(cleaned)
    except json.JSONDecodeError as exc:
        raise HTTPException(status_code=502, detail="AI model returned invalid nutrition JSON") from exc
    if not isinstance(value, dict):
        raise HTTPException(status_code=502, detail="AI model returned invalid nutrition JSON")
    return value


def _build_chat_model():
    provider = settings.ai_model_provider.strip().lower()
    if provider in {"ollama", "local"}:
        return ChatOpenAI(
            model=settings.ai_model_name,
            base_url=f"{settings.ollama_base_url.rstrip('/')}/v1",
            api_key="ollama",
        )
    return init_chat_model(settings.ai_model_name, model_provider=provider)
