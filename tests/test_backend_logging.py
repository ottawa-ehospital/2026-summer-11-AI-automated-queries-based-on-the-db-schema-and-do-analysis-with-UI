import logging

import pytest
from fastapi.testclient import TestClient

from src.backend.core.logging import LOGGER_NAME
from src.backend.main import create_app


def test_backend_startup_logs_readiness(caplog):
    app = create_app()

    with caplog.at_level(logging.INFO, logger=LOGGER_NAME):
        with TestClient(app):
            pass

    startup_logs = [
        record.message
        for record in caplog.records
        if "Smart Health backend ready" in record.message
    ]
    assert startup_logs
    assert "host=" in startup_logs[0]
    assert "port=" in startup_logs[0]
    assert "ehospital_base_url=" in startup_logs[0]
    assert "ehospital_auth_base_url=" in startup_logs[0]
    assert "assistant_provider=" in startup_logs[0]
    assert "model_provider=" in startup_logs[0]
    assert "model_name=" in startup_logs[0]


def test_backend_logs_successful_api_request(caplog):
    app = create_app()

    with caplog.at_level(logging.INFO, logger=LOGGER_NAME):
        with TestClient(app) as client:
            response = client.get("/openapi.json")

    assert response.status_code == 200
    assert any(
        "api_request method=GET path=/openapi.json status=200" in record.message
        for record in caplog.records
    )


def test_backend_logs_failed_api_request_without_swallowing_exception(caplog):
    app = create_app()

    @app.get("/logging-test/boom")
    def boom():
        raise RuntimeError("test failure")

    with caplog.at_level(logging.INFO, logger=LOGGER_NAME):
        with TestClient(app) as client:
            with pytest.raises(RuntimeError, match="test failure"):
                client.get("/logging-test/boom")

    assert any(
        "api_request method=GET path=/logging-test/boom status=ERROR" in record.message
        for record in caplog.records
    )
