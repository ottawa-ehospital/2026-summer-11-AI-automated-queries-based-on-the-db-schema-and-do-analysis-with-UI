import asyncio

import httpx
import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient

from src.backend.api import demo
from src.backend.clients import ehospital_auth_client
from src.backend.clients.ehospital_auth_client import (
    authenticate_ehospital_user,
    normalize_ehospital_login,
)
from src.backend.main import app


client = TestClient(app)


def test_legacy_demo_login_shape_is_rejected():
    response = client.post(
        "/login",
        json={"username": "john", "password": "john123"},
    )

    assert response.status_code == 422


def test_login_proxies_email_password_to_ehospital(monkeypatch):
    captured = {}

    async def fake_authenticate(email, password, selected_option):
        captured["email"] = email
        captured["password"] = password
        captured["selected_option"] = selected_option
        return {
            "id": 20,
            "EmailId": email,
            "FName": "Jane",
            "LName": "Doe",
            "patient_id": 20,
            "email": email,
            "username": "Jane Doe",
        }

    monkeypatch.setattr(demo, "authenticate_ehospital_user", fake_authenticate)

    response = client.post(
        "/login",
        json={
            "email": "jane@example.com",
            "password": "secret",
            "selectedOption": "Patient",
        },
    )

    assert response.status_code == 200
    assert response.json()["patient_id"] == 20
    assert response.json()["email"] == "jane@example.com"
    assert response.json()["username"] == "Jane Doe"
    assert captured == {
        "email": "jane@example.com",
        "password": "secret",
        "selected_option": "Patient",
    }


def test_login_rejects_unsupported_identity_before_proxying():
    response = client.post(
        "/login",
        json={
            "email": "jane@example.com",
            "password": "secret",
            "selectedOption": "HospitalAdmin",
        },
    )

    assert response.status_code == 422
    assert "Unsupported selectedOption" in response.json()["detail"]


def test_login_maps_rejected_remote_credentials(monkeypatch):
    async def fake_authenticate(email, password, selected_option):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    monkeypatch.setattr(demo, "authenticate_ehospital_user", fake_authenticate)

    response = client.post(
        "/login",
        json={
            "email": "jane@example.com",
            "password": "bad",
            "selectedOption": "Patient",
        },
    )

    assert response.status_code == 401
    assert response.json()["detail"] == "Invalid email or password"


def test_node_patient_login_payload_is_normalized_for_flutter_session():
    payload = {
        "id": 42,
        "EmailId": "patient@example.com",
        "FName": "Ava",
        "MName": "M",
        "LName": "Chen",
        "password": "not-returned-by-6302",
    }

    normalized = normalize_ehospital_login(payload)

    assert normalized["patient_id"] == 42
    assert normalized["user_id"] == 42
    assert normalized["email"] == "patient@example.com"
    assert normalized["username"] == "Ava M Chen"
    assert normalized["selectedOption"] == "Patient"
    assert "password" not in normalized


def test_non_patient_payload_does_not_fabricate_patient_id():
    payload = {
        "id": 7,
        "email": "admin@example.com",
        "full_name": "Admin Person",
    }

    normalized = normalize_ehospital_login(payload, selected_option="Admin")

    assert normalized["id"] == 7
    assert "patient_id" not in normalized
    assert "user_id" not in normalized
    assert normalized["email"] == "admin@example.com"
    assert normalized["username"] == "Admin Person"
    assert normalized["selectedOption"] == "Admin"


def test_remote_login_network_failure_returns_gateway_error(monkeypatch):
    class FailingClient:
        def __init__(self, timeout):
            self.timeout = timeout

        async def __aenter__(self):
            return self

        async def __aexit__(self, exc_type, exc, tb):
            return False

        async def post(self, url, json):
            raise httpx.ConnectError("connection refused")

    monkeypatch.setattr(ehospital_auth_client.httpx, "AsyncClient", FailingClient)

    async def run_auth():
        await authenticate_ehospital_user("patient@example.com", "secret", "Patient")

    with pytest.raises(HTTPException) as exc:
        asyncio.run(run_auth())

    assert exc.value.status_code == 502
    assert "Failed to reach eHospital login service" in exc.value.detail
