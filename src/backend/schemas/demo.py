from __future__ import annotations

from pydantic import BaseModel, Field

from src.backend.clients.ehospital_auth_client import DEFAULT_EHOSPITAL_IDENTITY


class LoginRequest(BaseModel):
    email: str
    password: str
    selectedOption: str = DEFAULT_EHOSPITAL_IDENTITY


class ChatRequest(BaseModel):
    user_id: str
    message: str


class NumberRange(BaseModel):
    min: int | None = None
    max: int | None = None


class MockCurrentDataRequest(BaseModel):
    user_id: str
    date: str
    seed: int | None = None
    ranges: dict[str, NumberRange] = Field(default_factory=dict)
