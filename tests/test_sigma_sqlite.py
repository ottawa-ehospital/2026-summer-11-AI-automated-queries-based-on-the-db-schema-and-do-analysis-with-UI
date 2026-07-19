import sys
import types

import pytest

from src.query_builder import (
    LogicalTableMapping,
    SigmaValidationError,
    convert_sigma_yaml_to_sqlite_sql,
    load_sigma_yaml,
    validate_sigma_rule,
)


VALID_YAML = """
title: "orders in january 2026"
id: "3f0d5a5e-8c9a-4c0a-9f72-5d2f7b05f601"
status: "experimental"
description: "Query orders within January 2026."

logsource:
  category: "business"
  product: "analytics"
  service: "orders"

detection:
  selection:
    EventTime|gte: 1767225600
    EventTime|lte: 1769903999
  condition: selection

fields:
  - "*"
"""


def test_valid_example_yaml_passes_schema():
    rule = load_sigma_yaml(VALID_YAML)

    validate_sigma_rule(rule)


def test_missing_logsource_service_fails_schema():
    rule = load_sigma_yaml(
        """
title: "missing service"
logsource:
  product: "analytics"
detection:
  selection:
    EventTime|gte: "2026-01-01"
  condition: selection
"""
    )

    with pytest.raises(SigmaValidationError, match="service"):
        validate_sigma_rule(rule)


def test_custom_time_range_field_is_rejected():
    rule = load_sigma_yaml(
        """
title: "custom time range"
logsource:
  service: "orders"
detection:
  selection:
    EventTime|gte: "2026-01-01"
  time_range:
    type: "absolute"
    start: "2026-01-01"
    end: "2026-01-31"
  condition: selection
"""
    )

    with pytest.raises(SigmaValidationError, match="time_range"):
        validate_sigma_rule(rule)


def test_gte_lte_values_must_be_numeric():
    rule = load_sigma_yaml(
        """
title: "string dates"
logsource:
  service: "orders"
detection:
  selection:
    EventTime|gte: "2026-01-01"
    EventTime|lte: "2026-01-31"
  condition: selection
"""
    )

    with pytest.raises(SigmaValidationError, match="Unix epoch seconds"):
        validate_sigma_rule(rule)


def test_multiple_selections_are_rejected_for_v1():
    rule = load_sigma_yaml(
        """
title: "too many selections"
logsource:
  service: "orders"
detection:
  selection:
    EventTime|gte: "2026-01-01"
  selection_other:
    Status: "paid"
  condition: selection
"""
    )

    with pytest.raises(SigmaValidationError, match="selection_other"):
        validate_sigma_rule(rule)


def test_converter_uses_logical_table_mapping_and_backend(monkeypatch):
    captured = {}

    class FakeCollection:
        @classmethod
        def from_yaml(cls, yaml_text):
            captured["yaml"] = yaml_text
            return "collection"

    class FakeSqliteBackend:
        table = None

        def convert(self, collection):
            assert collection == "collection"
            captured["table"] = self.table
            return [
                "SELECT * FROM orders_table WHERE EventTime >= 1767225600 "
                "AND EventTime <= 1769903999"
            ]

    sigma_module = types.ModuleType("sigma")
    sigma_backends_module = types.ModuleType("sigma.backends")
    sigma_sqlite_module = types.ModuleType("sigma.backends.sqlite")
    sigma_collection_module = types.ModuleType("sigma.collection")
    sigma_sqlite_module.sqliteBackend = FakeSqliteBackend
    sigma_collection_module.SigmaCollection = FakeCollection

    monkeypatch.setitem(sys.modules, "sigma", sigma_module)
    monkeypatch.setitem(sys.modules, "sigma.backends", sigma_backends_module)
    monkeypatch.setitem(sys.modules, "sigma.backends.sqlite", sigma_sqlite_module)
    monkeypatch.setitem(sys.modules, "sigma.collection", sigma_collection_module)

    sql = convert_sigma_yaml_to_sqlite_sql(
        VALID_YAML,
        {"orders": LogicalTableMapping(physical_table="orders_table")},
    )

    assert "orders_table" in sql
    assert "EventTime >=" in sql
    assert "EventTime <=" in sql
    assert captured["table"] == "orders_table"


def test_converter_rewrites_canonical_time_field(monkeypatch):
    captured = {}

    class FakeCollection:
        @classmethod
        def from_yaml(cls, yaml_text):
            captured["yaml"] = yaml_text
            return "collection"

    class FakeSqliteBackend:
        table = None

        def convert(self, collection):
            return ["SELECT * FROM orders_table WHERE created_at >= '2026-01-01'"]

    sigma_module = types.ModuleType("sigma")
    sigma_backends_module = types.ModuleType("sigma.backends")
    sigma_sqlite_module = types.ModuleType("sigma.backends.sqlite")
    sigma_collection_module = types.ModuleType("sigma.collection")
    sigma_sqlite_module.sqliteBackend = FakeSqliteBackend
    sigma_collection_module.SigmaCollection = FakeCollection

    monkeypatch.setitem(sys.modules, "sigma", sigma_module)
    monkeypatch.setitem(sys.modules, "sigma.backends", sigma_backends_module)
    monkeypatch.setitem(sys.modules, "sigma.backends.sqlite", sigma_sqlite_module)
    monkeypatch.setitem(sys.modules, "sigma.collection", sigma_collection_module)

    convert_sigma_yaml_to_sqlite_sql(
        VALID_YAML,
        {"orders": LogicalTableMapping(physical_table="orders_table", time_field="created_at")},
    )

    assert "created_at|gte" in captured["yaml"]
    assert "created_at|lte" in captured["yaml"]
    assert "EventTime|gte" not in captured["yaml"]
