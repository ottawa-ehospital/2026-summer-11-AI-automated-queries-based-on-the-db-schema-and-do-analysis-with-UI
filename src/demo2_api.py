"""Compatibility shim for the canonical backend app."""

from src.backend.main import app, create_app

__all__ = ["app", "create_app"]

