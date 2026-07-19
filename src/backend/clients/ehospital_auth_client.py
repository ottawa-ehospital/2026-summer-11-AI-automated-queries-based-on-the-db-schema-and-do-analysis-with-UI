from __future__ import annotations

from typing import Any

import httpx
from fastapi import HTTPException

from src.backend.core.config import settings


SUPPORTED_EHOSPITAL_IDENTITIES = {
    "Admin",
    "Patient",
    "Doctor",
    "Clinic",
    "PharmaAdmin",
    "Pharma",
    "ClinicalReasoning",
}
DEFAULT_EHOSPITAL_IDENTITY = "Patient"

SENSITIVE_LOGIN_FIELDS = {
    "password",
    "Password",
    "password_hash",
    "hash",
    "token",
}


async def authenticate_ehospital_user(
    email: str,
    password: str,
    selected_option: str = DEFAULT_EHOSPITAL_IDENTITY,
) -> dict[str, Any]:
    selected_option = validate_ehospital_identity(selected_option)
    if not email.strip() or not password:
        raise HTTPException(status_code=422, detail="email and password are required")

    url = f"{settings.ehospital_auth_base_url}/api/users/login"
    body = {
        "email": email.strip(),
        "password": password,
        "selectedOption": selected_option,
    }
    try:
        async with httpx.AsyncClient(timeout=20) as client:
            response = await client.post(url, json=body)
    except httpx.HTTPError as exc:
        raise HTTPException(
            status_code=502,
            detail=f"Failed to reach eHospital login service: {exc}",
        ) from exc

    if response.status_code in {400, 401, 403}:
        raise HTTPException(status_code=401, detail="Invalid email or password")

    try:
        response.raise_for_status()
    except httpx.HTTPStatusError as exc:
        raise HTTPException(
            status_code=502,
            detail=f"eHospital login service failed: {exc}",
        ) from exc

    try:
        payload = response.json()
    except ValueError as exc:
        raise HTTPException(
            status_code=502,
            detail="eHospital login service returned invalid JSON",
        ) from exc
    if not isinstance(payload, dict):
        raise HTTPException(
            status_code=502,
            detail="eHospital login service returned an invalid user payload",
        )
    return normalize_ehospital_login(payload, selected_option)


def normalize_ehospital_login(
    payload: dict[str, Any],
    selected_option: str = DEFAULT_EHOSPITAL_IDENTITY,
) -> dict[str, Any]:
    selected_option = validate_ehospital_identity(selected_option)
    patient_id = (
        _first_present(payload, "patient_id", "user_id", "id")
        if selected_option == DEFAULT_EHOSPITAL_IDENTITY
        else _first_present(payload, "patient_id")
    )
    email = _first_present(payload, "email", "EmailId", "Email_Id")
    username = _display_name(payload) or str(email or "")

    normalized = {
        key: value
        for key, value in payload.items()
        if key not in SENSITIVE_LOGIN_FIELDS
    }
    if patient_id is not None:
        normalized.setdefault("patient_id", patient_id)
        normalized.setdefault("user_id", patient_id)
    if email is not None:
        normalized.setdefault("email", email)
    if username:
        normalized.setdefault("username", username)
    normalized.setdefault("selectedOption", selected_option)
    return normalized


def validate_ehospital_identity(selected_option: str) -> str:
    if selected_option not in SUPPORTED_EHOSPITAL_IDENTITIES:
        raise HTTPException(
            status_code=422,
            detail=f"Unsupported selectedOption: {selected_option}",
        )
    return selected_option


def _first_present(payload: dict[str, Any], *keys: str) -> Any:
    for key in keys:
        value = payload.get(key)
        if value is not None and value != "":
            return value
    return None


def _display_name(payload: dict[str, Any]) -> str:
    direct = _first_present(payload, "username", "name", "full_name")
    if direct:
        return str(direct)
    parts = [
        str(payload[key]).strip()
        for key in ("FName", "MName", "LName")
        if payload.get(key)
    ]
    return " ".join(part for part in parts if part)
