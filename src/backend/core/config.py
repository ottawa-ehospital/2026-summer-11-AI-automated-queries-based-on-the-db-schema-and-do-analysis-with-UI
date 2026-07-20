from __future__ import annotations

import os
from dataclasses import dataclass


@dataclass(frozen=True)
class BackendSettings:
    ehospital_base_url: str
    ehospital_auth_base_url: str
    assistant_provider: str
    ai_model_provider: str
    ai_model_name: str
    ollama_base_url: str
    report_interpreter_max_context_chars: int
    report_interpreter_min_pdf_text_chars: int
    cors_allow_origins: tuple[str, ...]
    host: str
    port: int


def _csv_env(name: str, default: str) -> tuple[str, ...]:
    value = os.getenv(name, default)
    return tuple(item.strip() for item in value.split(",") if item.strip())


def get_settings() -> BackendSettings:
    ehospital_base_url = os.getenv(
        "EHOSPITAL_BASE_URL",
        "https://aetab8pjmb.us-east-1.awsapprunner.com",
    ).rstrip("/")
    return BackendSettings(
        ehospital_base_url=ehospital_base_url,
        ehospital_auth_base_url=os.getenv(
            "EHOSPITAL_AUTH_BASE_URL",
            "https://tysnx3mi2s.us-east-1.awsapprunner.com",
        ).rstrip("/"),
        assistant_provider=os.getenv("ASSISTANT_PROVIDER", "wearable_langgraph"),
        ai_model_provider=os.getenv("AI_MODEL_PROVIDER", "ollama"),
        ai_model_name=os.getenv("AI_MODEL_NAME", os.getenv("OLLAMA_MODEL", "llama3.2")),
        ollama_base_url=os.getenv("OLLAMA_BASE_URL", "http://127.0.0.1:11434"),
        report_interpreter_max_context_chars=int(
            os.getenv("REPORT_INTERPRETER_MAX_CONTEXT_CHARS", "12000")
        ),
        report_interpreter_min_pdf_text_chars=int(
            os.getenv("REPORT_INTERPRETER_MIN_PDF_TEXT_CHARS", "200")
        ),
        cors_allow_origins=_csv_env("CORS_ALLOW_ORIGINS", "*"),
        host=os.getenv("BACKEND_HOST", "127.0.0.1"),
        port=int(os.getenv("BACKEND_PORT", "8000")),
    )


settings = get_settings()
