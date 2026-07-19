from __future__ import annotations

from pydantic import BaseModel

from src.backend.clients.ehospital_auth_client import DEFAULT_EHOSPITAL_IDENTITY


class LoginRequest(BaseModel):
    email: str
    password: str
    selectedOption: str = DEFAULT_EHOSPITAL_IDENTITY
