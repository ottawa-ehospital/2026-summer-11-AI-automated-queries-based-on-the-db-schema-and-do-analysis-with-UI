from __future__ import annotations

from fastapi import APIRouter

from src.backend.clients.ehospital_auth_client import authenticate_ehospital_user
from src.backend.schemas.auth import LoginRequest


router = APIRouter(tags=["auth"])


@router.post("/login")
async def login(request: LoginRequest) -> dict:
    return await authenticate_ehospital_user(
        request.email,
        request.password,
        request.selectedOption,
    )
