"""Convert a constrained Sigma rule into SQLite SQL with pySigma.

The agent-facing contract is standard Sigma-shaped YAML. This module keeps the
project-specific parts small: schema validation, logical table mapping, and an
optional canonical time-field rewrite before handing the rule to pySigma.
"""

from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
from typing import Any, Mapping

import yaml


SCHEMA_PATH = Path(__file__).resolve().parents[1] / "sigma_sql_query.schema.json"
DEFAULT_TIME_FIELD = "EventTime"


class SigmaQueryError(RuntimeError):
    """Base error for Sigma query conversion failures."""


class SigmaValidationError(SigmaQueryError):
    """Raised when agent-generated Sigma YAML does not match the local contract."""


@dataclass(frozen=True)
class LogicalTableMapping:
    """Physical database mapping for one logical Sigma logsource service."""

    physical_table: str
    time_field: str = DEFAULT_TIME_FIELD


def load_sigma_yaml(yaml_text: str) -> dict[str, Any]:
    """Parse a YAML string and require a mapping document."""

    loaded = yaml.safe_load(yaml_text)
    if not isinstance(loaded, dict):
        raise SigmaValidationError("Sigma YAML must contain a mapping at the document root.")
    return loaded


def validate_sigma_rule(rule: Mapping[str, Any], schema_path: Path = SCHEMA_PATH) -> None:
    """Validate the constrained standard-Sigma subset used by this project."""

    try:
        from jsonschema import Draft202012Validator
    except ImportError as exc:
        raise SigmaQueryError(
            "Missing dependency 'jsonschema'. Install the environment dependencies first."
        ) from exc

    with schema_path.open("r", encoding="utf-8") as schema_file:
        schema = json.load(schema_file)

    validator = Draft202012Validator(schema)
    errors = sorted(validator.iter_errors(rule), key=lambda error: list(error.path))
    if errors:
        details = "; ".join(_format_validation_error(error) for error in errors)
        raise SigmaValidationError(details)

    _validate_selection_modifier_values(rule)


def convert_sigma_yaml_to_sqlite_sql(
    yaml_text: str,
    table_mappings: Mapping[str, LogicalTableMapping],
    schema_path: Path = SCHEMA_PATH,
) -> str:
    """Validate a Sigma YAML rule and convert it to SQLite SQL.

    Args:
        yaml_text: Agent-generated standard Sigma YAML.
        table_mappings: Logical `logsource.service` to physical SQLite table mappings.
        schema_path: Optional schema override for tests or experimentation.

    Returns:
        The first SQL query produced by the pySigma SQLite backend.
    """

    rule = load_sigma_yaml(yaml_text)
    validate_sigma_rule(rule, schema_path=schema_path)

    service = rule["logsource"]["service"]
    mapping = table_mappings.get(service)
    if mapping is None:
        raise SigmaValidationError(f"No physical table mapping configured for '{service}'.")

    normalized_rule = _normalize_rule_for_physical_schema(rule, mapping)
    normalized_yaml = yaml.safe_dump(normalized_rule, sort_keys=False)

    try:
        from sigma.backends.sqlite import sqliteBackend
        from sigma.collection import SigmaCollection
    except ImportError as exc:
        raise SigmaQueryError(
            "Missing Sigma SQLite dependencies. Install 'pysigma', 'sigma-cli', "
            "and 'pySigma-backend-sqlite'."
        ) from exc

    collection = SigmaCollection.from_yaml(normalized_yaml)
    backend = sqliteBackend()
    backend.table = mapping.physical_table
    queries = backend.convert(collection)
    if not queries:
        raise SigmaQueryError("pySigma SQLite backend returned no SQL queries.")
    return str(queries[0])


def _normalize_rule_for_physical_schema(
    rule: Mapping[str, Any], mapping: LogicalTableMapping
) -> dict[str, Any]:
    """Copy a rule and rewrite the canonical time field if the table needs it."""

    normalized = dict(rule)
    normalized["detection"] = dict(rule["detection"])
    selection = dict(rule["detection"]["selection"])

    if mapping.time_field != DEFAULT_TIME_FIELD:
        selection = {
            _rewrite_field_name(key, DEFAULT_TIME_FIELD, mapping.time_field): value
            for key, value in selection.items()
        }

    normalized["detection"]["selection"] = selection
    return normalized


def _rewrite_field_name(key: str, source_field: str, target_field: str) -> str:
    field_name, separator, modifiers = key.partition("|")
    if field_name != source_field:
        return key
    return f"{target_field}{separator}{modifiers}" if separator else target_field


def _validate_selection_modifier_values(rule: Mapping[str, Any]) -> None:
    selection = rule["detection"]["selection"]
    numeric_modifiers = {"gt", "gte", "lt", "lte"}

    for key, value in selection.items():
        modifiers = key.split("|")[1:]
        if not numeric_modifiers.intersection(modifiers):
            continue

        values = value if isinstance(value, list) else [value]
        if not all(_is_number(item) for item in values):
            raise SigmaValidationError(
                f"{key}: numeric Sigma comparison modifiers require numeric values. "
                "Use Unix epoch seconds for time ranges in v1."
            )


def _is_number(value: Any) -> bool:
    return isinstance(value, (int, float)) and not isinstance(value, bool)


def _format_validation_error(error: Any) -> str:
    path = ".".join(str(part) for part in error.path)
    location = path or "<root>"
    return f"{location}: {error.message}"
