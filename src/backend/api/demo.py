from __future__ import annotations

from fastapi import APIRouter, HTTPException

from src.backend.clients.ehospital_auth_client import authenticate_ehospital_user
from src.backend.schemas.demo import ChatRequest, LoginRequest, MockCurrentDataRequest
from src.demo.demo2 import (
    generate_mock_current_data,
    get_dashboard_for_user,
    get_profile_by_user_id,
    list_public_users,
    run_chat_for_user,
)


router = APIRouter(tags=["demo"])


@router.get("/users")
def users() -> list[dict]:
    # Demo endpoints preserve the original local_db contract used by the first
    # Flutter prototype; production eHospital data goes through /assistant.
    return list_public_users()


@router.post("/login")
async def login(request: LoginRequest) -> dict:
    return await authenticate_ehospital_user(
        request.email,
        request.password,
        request.selectedOption,
    )


@router.post("/chat")
def chat(request: ChatRequest) -> dict:
    if get_profile_by_user_id(request.user_id) is None:
        raise HTTPException(status_code=404, detail="Unknown user_id")
    if not request.message.strip():
        raise HTTPException(status_code=400, detail="Message must not be empty")
    return {"reply": run_chat_for_user(request.user_id, request.message)}


@router.get("/dashboard/{user_id}")
def dashboard(user_id: str) -> dict:
    data = get_dashboard_for_user(user_id)
    if data is None:
        raise HTTPException(status_code=404, detail="Unknown user_id")
    return data


@router.post("/mock/current-data")
def mock_current_data(request: MockCurrentDataRequest) -> dict:
    # Mock current data intentionally stays backend-side so future readiness or
    # recommendation flows can share the same generated vitals/check-in shape.
    ranges = {
        key: value.model_dump(exclude_none=True) for key, value in request.ranges.items()
    }
    data = generate_mock_current_data(
        request.user_id,
        request.date,
        ranges=ranges,
        seed=request.seed,
    )
    if data is None:
        raise HTTPException(status_code=404, detail="Unknown user_id")
    return data
