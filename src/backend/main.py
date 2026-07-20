from __future__ import annotations

from time import perf_counter

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from starlette.requests import Request

from src.backend.api.assistant import router as assistant_router
from src.backend.api.auth import router as auth_router
from src.backend.api.query_tools import router as query_tools_router
from src.backend.api.report_interpreter import router as report_interpreter_router
from src.backend.api.nutrition_monitor import router as nutrition_monitor_router
from src.backend.api.sleep import router as sleep_router
from src.backend.api.stress import router as stress_router
from src.backend.api.urgent_care import router as urgent_care_router
from src.backend.api.wearables import router as wearables_router
from src.backend.core.config import settings
from src.backend.core.logging import get_backend_logger


logger = get_backend_logger()


def log_startup_ready() -> None:
    logger.info(
        "Smart Health backend ready host=%s port=%s ehospital_base_url=%s "
        "ehospital_auth_base_url=%s assistant_provider=%s model_provider=%s "
        "model_name=%s cors_origins=%s",
        settings.host,
        settings.port,
        settings.ehospital_base_url,
        settings.ehospital_auth_base_url,
        settings.assistant_provider,
        settings.ai_model_provider,
        settings.ai_model_name,
        ",".join(settings.cors_allow_origins),
    )


def create_app() -> FastAPI:
    app = FastAPI(title="Smart Health Backend API")
    app.add_middleware(
        CORSMiddleware,
        allow_origins=list(settings.cors_allow_origins),
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )

    @app.middleware("http")
    async def log_api_request(request: Request, call_next):
        start = perf_counter()
        try:
            response = await call_next(request)
        except Exception:
            elapsed_ms = (perf_counter() - start) * 1000
            logger.exception(
                "api_request method=%s path=%s status=ERROR duration_ms=%.2f",
                request.method,
                request.url.path,
                elapsed_ms,
            )
            raise

        elapsed_ms = (perf_counter() - start) * 1000
        logger.info(
            "api_request method=%s path=%s status=%s duration_ms=%.2f",
            request.method,
            request.url.path,
            response.status_code,
            elapsed_ms,
        )
        return response

    app.add_event_handler("startup", log_startup_ready)
    app.include_router(auth_router)
    app.include_router(assistant_router)
    app.include_router(query_tools_router)
    app.include_router(report_interpreter_router)
    app.include_router(nutrition_monitor_router)
    app.include_router(stress_router)
    app.include_router(sleep_router)
    app.include_router(urgent_care_router)
    app.include_router(wearables_router)
    return app


app = create_app()
