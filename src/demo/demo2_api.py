"""Compatibility shim for the canonical backend app.

Use `src.backend.main:app` for new uvicorn commands.
"""

from src.backend.main import app, create_app

__all__ = ["app", "create_app"]
