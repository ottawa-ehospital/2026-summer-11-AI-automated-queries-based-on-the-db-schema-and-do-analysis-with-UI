from __future__ import annotations

from src.backend.core.config import settings
from src.backend.schemas.nutrition_monitor import NutritionModelCapabilities


_IMAGE_MODEL_HINTS = (
    "gpt-4o",
    "gpt-4.1",
    "gpt-5",
    "vision",
    "llava",
    "bakllava",
    "minicpm-v",
    "qwen-vl",
    "qwen2.5-vl",
    "gemini",
    "gemma3",
)


def get_model_capabilities() -> NutritionModelCapabilities:
    provider = settings.ai_model_provider.strip().lower()
    model = settings.ai_model_name.strip()
    key = f"{provider}:{model}".lower()
    supports = any(hint in key for hint in _IMAGE_MODEL_HINTS)
    reason = None if supports else "Configured model is not recognized as image-capable."
    return NutritionModelCapabilities(
        supportsImageInput=supports,
        provider=settings.ai_model_provider,
        model=settings.ai_model_name,
        reason=reason,
    )
