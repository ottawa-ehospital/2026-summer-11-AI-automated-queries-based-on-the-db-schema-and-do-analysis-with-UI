from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from src.backend.clients.ehospital_client import fetch_ehospital_tables_metadata

from .constants import REQUIRED_TABLE_FIELDS


@dataclass(frozen=True)
class TableCompatibility:
    required_tables: dict[str, list[str]]
    missing_tables: list[str]
    missing_fields: dict[str, list[str]]

    @property
    def ready(self) -> bool:
        return not self.missing_tables and not self.missing_fields


def _metadata_tables_by_name(metadata: dict[str, Any]) -> dict[str, set[str]]:
    tables = metadata.get("tables", [])
    if not isinstance(tables, list):
        return {}

    by_name: dict[str, set[str]] = {}
    for table in tables:
        if not isinstance(table, dict):
            continue
        name = str(table.get("name") or "").strip()
        if not name:
            qualified = str(table.get("qualifiedName") or "").strip()
            name = qualified.split(".")[-1] if qualified else ""
        attributes = table.get("attributes", [])
        if name and isinstance(attributes, list):
            by_name[name] = {str(item) for item in attributes}
    return by_name


async def validate_urgent_care_tables() -> TableCompatibility:
    metadata = await fetch_ehospital_tables_metadata()
    live_tables = _metadata_tables_by_name(metadata)
    missing_tables: list[str] = []
    missing_fields: dict[str, list[str]] = {}

    for table, required_fields in REQUIRED_TABLE_FIELDS.items():
        live_fields = live_tables.get(table)
        if live_fields is None:
            missing_tables.append(table)
            continue
        missing = sorted(required_fields - live_fields)
        if missing:
            missing_fields[table] = missing

    return TableCompatibility(
        required_tables={
            table: sorted(fields) for table, fields in REQUIRED_TABLE_FIELDS.items()
        },
        missing_tables=missing_tables,
        missing_fields=missing_fields,
    )
