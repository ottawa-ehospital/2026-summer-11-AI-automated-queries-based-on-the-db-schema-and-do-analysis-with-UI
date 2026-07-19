from __future__ import annotations

import re
from typing import Any


def truncate_text(text: str, max_chars: int) -> str:
    if len(text) <= max_chars:
        return text
    return f"{text[:max_chars]}\n[Truncated to {max_chars} characters]"


def format_date_value(value: Any) -> str:
    if value is None:
        return ""
    return str(value).split("T", 1)[0]


def normalize_question_key(question: str) -> str:
    return re.sub(r"[^a-z0-9]+", " ", question.lower()).strip()


def unique_suggested_questions(questions: list[Any], limit: int = 5) -> list[str]:
    clean_questions: list[str] = []
    seen = set()
    for raw_question in questions:
        if not isinstance(raw_question, str):
            continue
        question = raw_question.strip()
        if not question:
            continue
        if not question.endswith("?"):
            question = f"{question}?"
        key = normalize_question_key(question)
        if not key or key in seen:
            continue
        seen.add(key)
        clean_questions.append(question)
        if len(clean_questions) >= limit:
            break
    return clean_questions
