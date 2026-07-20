from __future__ import annotations

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from fastapi import HTTPException

from src.backend.clients.ehospital_client import (
    execute_ehospital_select,
    fetch_ehospital_tables_metadata,
)
from src.backend.schemas.query_tools import (
    DateRangeFilter,
    MultiQueryPlanEntry,
    MultiQueryPlanRequest,
    QueryFilter,
    QueryOrder,
    TableQueryRequest,
)


SCHEMA_INVENTORY_PATH = Path(__file__).resolve().parents[1] / "ehospital_schema_inventory.json"
SUPPORTED_SIGMA_MODIFIERS = {
    "eq",
    "neq",
    "gt",
    "gte",
    "lt",
    "lte",
    "contains",
    "startswith",
    "endswith",
    "exists",
}
FILTER_SQL_OPERATORS = {
    "eq": "=",
    "neq": "!=",
    "gt": ">",
    "gte": ">=",
    "lt": "<",
    "lte": "<=",
}
MAX_LIMIT = 5000
DEFAULT_LIMIT = 500
MAX_MULTI_QUERY_ENTRIES = 12
PATIENT_SCOPE_FIELDS = ("patient_id", "user_id")


async def refresh_schema_inventory() -> dict[str, Any]:
    metadata = await fetch_ehospital_tables_metadata()
    tables = metadata.get("tables", [])
    clean_tables = []
    for table in tables if isinstance(tables, list) else []:
        if not isinstance(table, dict):
            continue
        clean_tables.append(
            {
                "name": table.get("name"),
                "qualifiedName": table.get("qualifiedName", table.get("name")),
                "modelName": table.get("modelName"),
                "primaryKeys": table.get("primaryKeys", []),
                "attributes": table.get("attributes", []),
            }
        )

    inventory = {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "source": "ehospital:/tables",
        "count": len(clean_tables),
        "tables": clean_tables,
    }
    SCHEMA_INVENTORY_PATH.write_text(
        json.dumps(inventory, indent=2, sort_keys=True),
        encoding="utf-8",
    )
    return inventory


def load_schema_inventory() -> dict[str, Any]:
    if not SCHEMA_INVENTORY_PATH.exists():
        raise HTTPException(
            status_code=503,
            detail="Schema inventory is missing. Refresh it before validating queries.",
        )
    return json.loads(SCHEMA_INVENTORY_PATH.read_text(encoding="utf-8"))


def schema_index(inventory: dict[str, Any] | None = None) -> dict[str, set[str]]:
    inventory = inventory or load_schema_inventory()
    index: dict[str, set[str]] = {}
    for table in inventory.get("tables", []):
        if not isinstance(table, dict) or not isinstance(table.get("name"), str):
            continue
        index[table["name"]] = {
            field for field in table.get("attributes", []) if isinstance(field, str)
        }
    return index


def validate_sigma_payload(sigma: dict[str, Any]) -> tuple[bool, list[str], dict[str, Any] | None]:
    errors: list[str] = []
    title = sigma.get("title")
    logsource = sigma.get("logsource")
    detection = sigma.get("detection")
    fields = sigma.get("fields", ["*"])
    limit = sigma.get("limit", DEFAULT_LIMIT)
    date_filter = sigma.get("date_filter")
    order_by = sigma.get("order_by", [])

    if not isinstance(title, str) or not title.strip():
        errors.append("title must be a non-empty string.")
    if not isinstance(logsource, dict):
        errors.append("logsource must be an object.")
        service = None
    else:
        service = logsource.get("service")
        if not isinstance(service, str) or not service.strip():
            errors.append("logsource.service must be a non-empty table name.")
    if not isinstance(detection, dict):
        errors.append("detection must be an object.")
        selection = None
    else:
        selection = detection.get("selection")
        if detection.get("condition") != "selection":
            errors.append("detection.condition must be 'selection'.")
        if not isinstance(selection, dict) or not selection:
            errors.append("detection.selection must be a non-empty object.")

    if not isinstance(fields, list) or not fields:
        errors.append("fields must be a non-empty list.")
    elif not all(isinstance(field, str) and field for field in fields):
        errors.append("fields entries must be non-empty strings.")

    if not isinstance(limit, int) or isinstance(limit, bool) or limit < 1 or limit > MAX_LIMIT:
        errors.append(f"limit must be an integer between 1 and {MAX_LIMIT}.")
    if date_filter is not None and not isinstance(date_filter, dict):
        errors.append("date_filter must be an object when provided.")
    if not isinstance(order_by, list):
        errors.append("order_by must be a list when provided.")

    if errors:
        return False, errors, None

    assert isinstance(service, str)
    assert isinstance(selection, dict)
    index = schema_index()
    table_fields = index.get(service)
    if table_fields is None:
        errors.append(f"Unknown table: {service}.")
        return False, errors, None

    normalized_filters = []
    for raw_key, value in selection.items():
        if not isinstance(raw_key, str) or not raw_key:
            errors.append("selection keys must be non-empty strings.")
            continue
        field, modifiers = _split_sigma_key(raw_key)
        if field not in table_fields:
            errors.append(f"Unknown field '{field}' on table '{service}'.")
        unknown_modifiers = [item for item in modifiers if item not in SUPPORTED_SIGMA_MODIFIERS]
        if unknown_modifiers:
            errors.append(f"Unsupported modifier(s) for '{raw_key}': {', '.join(unknown_modifiers)}.")
        normalized_filters.append(
            {
                "field": field,
                "modifiers": modifiers or ["eq"],
                "value": value,
            }
        )

    for field in fields:
        if field != "*" and field not in table_fields:
            errors.append(f"Unknown selected field '{field}' on table '{service}'.")

    normalized_date_filter = None
    if isinstance(date_filter, dict):
        date_field = date_filter.get("field")
        if not isinstance(date_field, str) or not date_field:
            errors.append("date_filter.field must be a non-empty string.")
        elif date_field not in table_fields:
            errors.append(f"Unknown date filter field '{date_field}' on table '{service}'.")
        normalized_date_filter = {
            "field": date_field,
            "start": date_filter.get("start"),
            "end": date_filter.get("end"),
        }

    normalized_order_by = []
    if isinstance(order_by, list):
        for index_value, item in enumerate(order_by):
            if not isinstance(item, dict):
                errors.append(f"order_by[{index_value}] must be an object.")
                continue
            order_field = item.get("field")
            direction = item.get("direction", "desc")
            if not isinstance(order_field, str) or not order_field:
                errors.append(f"order_by[{index_value}].field must be a non-empty string.")
            elif order_field not in table_fields:
                errors.append(f"Unknown order field '{order_field}' on table '{service}'.")
            if direction not in {"asc", "desc"}:
                errors.append(f"order_by[{index_value}].direction must be 'asc' or 'desc'.")
            normalized_order_by.append({"field": order_field, "direction": direction})

    if errors:
        return False, errors, None

    return True, [], {
        "title": title.strip(),
        "table": service,
        "fields": fields,
        "filters": normalized_filters,
        "date_filter": normalized_date_filter,
        "order_by": normalized_order_by,
        "limit": limit,
    }


def validate_multi_query_plan(
    plan: dict[str, Any] | MultiQueryPlanRequest,
) -> tuple[bool, list[str], list[dict[str, Any]] | None]:
    raw_entries: Any
    if isinstance(plan, MultiQueryPlanRequest):
        raw_entries = [entry.model_dump() for entry in plan.queries]
    elif isinstance(plan, dict):
        raw_entries = plan.get("queries")
    else:
        return False, ["multi-query plan must be an object."], None

    if not isinstance(raw_entries, list) or not raw_entries:
        return False, ["multi-query plan must include at least one query entry."], None
    if len(raw_entries) > MAX_MULTI_QUERY_ENTRIES:
        return False, [f"multi-query plan cannot exceed {MAX_MULTI_QUERY_ENTRIES} entries."], None

    normalized_entries: list[dict[str, Any]] = []
    errors: list[str] = []
    seen_ids: set[str] = set()
    for index, raw_entry in enumerate(raw_entries):
        if isinstance(raw_entry, MultiQueryPlanEntry):
            entry = raw_entry.model_dump()
        elif isinstance(raw_entry, dict):
            entry = raw_entry
        else:
            errors.append(f"queries[{index}] must be an object.")
            continue

        query_id = entry.get("query_id") or entry.get("id")
        if not isinstance(query_id, str) or not query_id.strip():
            query_id = f"query_{index + 1}"
        if query_id in seen_ids:
            errors.append(f"{query_id}: duplicate query id.")
            continue
        seen_ids.add(query_id)

        purpose = entry.get("purpose")
        if not isinstance(purpose, str) or not purpose.strip():
            errors.append(f"{query_id}: purpose must be a non-empty string.")
        required = entry.get("required", False)
        if not isinstance(required, bool):
            errors.append(f"{query_id}: required must be a boolean.")
            required = False
        sigma = entry.get("sigma")
        if not isinstance(sigma, dict):
            errors.append(f"{query_id}: sigma must be an object.")
            continue

        valid, sigma_errors, normalized = validate_sigma_payload(sigma)
        if not valid or normalized is None:
            errors.extend(f"{query_id}: {error}" for error in sigma_errors)
            continue

        normalized_entries.append(
            {
                "query_id": query_id,
                "purpose": purpose.strip() if isinstance(purpose, str) and purpose.strip() else query_id,
                "required": required,
                "domain": entry.get("domain") if isinstance(entry.get("domain"), str) else None,
                "normalized_sigma": normalized,
            }
        )

    if errors:
        return False, errors, None
    return True, [], normalized_entries


def normalized_multi_query_plan_to_table_queries(
    normalized_entries: list[dict[str, Any]],
    patient_id: int | str,
) -> list[dict[str, Any]]:
    table_queries: list[dict[str, Any]] = []
    for entry in normalized_entries:
        normalized_sigma = entry.get("normalized_sigma")
        if not isinstance(normalized_sigma, dict):
            raise HTTPException(
                status_code=400,
                detail=f"{entry.get('query_id', 'query')}: normalized Sigma is missing.",
            )
        table_request = normalized_sigma_to_table_query(normalized_sigma, patient_id)
        table_queries.append(
            {
                **entry,
                "table_request": table_request,
            }
        )
    return table_queries


def multi_query_result_metadata(
    entry: dict[str, Any],
    request: TableQueryRequest,
    result: dict[str, Any],
) -> dict[str, Any]:
    rows = result.get("data", [])
    clean_rows = [row for row in rows if isinstance(row, dict)] if isinstance(rows, list) else []
    return {
        "queryId": entry.get("query_id"),
        "purpose": entry.get("purpose"),
        "required": bool(entry.get("required")),
        "domain": entry.get("domain"),
        "table": request.table,
        "fields": request.fields,
        "sql": result.get("sql"),
        "replacements": result.get("replacements", {}),
        "count": result.get("count", len(clean_rows)),
        "data": clean_rows,
        "empty": not clean_rows,
    }


def validate_sql_references(sql: str) -> tuple[bool, list[str], dict[str, Any] | None]:
    errors: list[str] = []
    if not _is_single_select(sql):
        return False, ["Only a single SELECT or WITH query is supported."], None

    index = schema_index()
    table_names = _extract_table_names(sql)
    if not table_names:
        errors.append("Could not identify a table after FROM or JOIN.")

    for table in table_names:
        if table not in index:
            errors.append(f"Unknown table: {table}.")

    if errors:
        return False, errors, None

    field_refs = _extract_field_references(sql, table_names, index)
    for table, fields in field_refs.items():
        table_fields = index[table]
        for field in fields:
            if field != "*" and field not in table_fields:
                errors.append(f"Unknown field '{field}' on table '{table}'.")

    if errors:
        return False, errors, None
    return True, [], {"tables": table_names, "fields": {k: sorted(v) for k, v in field_refs.items()}}


def normalized_sigma_to_table_query(
    normalized: dict[str, Any],
    patient_id: int | str,
) -> TableQueryRequest:
    table = normalized.get("table")
    if not isinstance(table, str) or not table.strip():
        raise HTTPException(status_code=400, detail="Normalized Sigma is missing table.")

    index = schema_index()
    table_fields = index.get(table)
    if table_fields is None:
        raise HTTPException(status_code=400, detail=f"Unknown table: {table}.")

    scope_field = _patient_scope_field(table_fields)
    if scope_field is None:
        raise HTTPException(
            status_code=400,
            detail=f"Table '{table}' cannot be safely scoped to a patient.",
        )

    fields = normalized.get("fields", ["*"])
    if not isinstance(fields, list) or not fields:
        fields = ["*"]

    filters = [
        _normalized_sigma_filter_to_query_filter(item)
        for item in normalized.get("filters", [])
        if isinstance(item, dict)
    ]
    filters = [item for item in filters if item.field != scope_field]
    filters.insert(0, QueryFilter(field=scope_field, operator="eq", value=patient_id))

    date_filter = normalized.get("date_filter")
    order_by = normalized.get("order_by", [])
    limit = normalized.get("limit", DEFAULT_LIMIT)

    return TableQueryRequest(
        table=table,
        fields=fields,
        filters=filters,
        date_filter=DateRangeFilter(**date_filter) if isinstance(date_filter, dict) else None,
        order_by=[
            QueryOrder(**item)
            for item in order_by
            if isinstance(item, dict)
        ],
        limit=limit if isinstance(limit, int) and not isinstance(limit, bool) else DEFAULT_LIMIT,
    )


async def query_table(request: TableQueryRequest) -> dict[str, Any]:
    index = schema_index()
    table_fields = index.get(request.table)
    if table_fields is None:
        raise HTTPException(status_code=400, detail=f"Unknown table: {request.table}.")

    errors = _validate_table_query_request(request, table_fields)
    if errors:
        raise HTTPException(status_code=400, detail=errors)

    sql, replacements = build_table_query_sql(request)
    payload = await execute_ehospital_select(sql, replacements)
    rows = payload.get("data", [])
    clean_rows = [row for row in rows if isinstance(row, dict)] if isinstance(rows, list) else []
    return {
        "sql": sql,
        "replacements": replacements,
        "count": payload.get("count", len(clean_rows)),
        "data": clean_rows,
    }


def build_table_query_sql(request: TableQueryRequest) -> tuple[str, dict[str, Any]]:
    selected = _selected_fields_sql(request.fields)
    clauses: list[str] = []
    replacements: dict[str, Any] = {}

    for index, query_filter in enumerate(request.filters):
        clause, value_replacements = _filter_to_sql(query_filter, f"filter_{index}")
        clauses.append(clause)
        replacements.update(value_replacements)

    if request.date_filter is not None:
        date_clauses, date_replacements = _date_filter_to_sql(request.date_filter)
        clauses.extend(date_clauses)
        replacements.update(date_replacements)

    where_sql = f" WHERE {' AND '.join(clauses)}" if clauses else ""
    order_sql = _order_by_sql(request.order_by)
    limit = min(max(request.limit, 1), MAX_LIMIT)
    offset = max(request.offset, 0)
    replacements["limit"] = limit
    replacements["offset"] = offset
    sql = (
        f"SELECT {selected} FROM {_quote_identifier(request.table)}"
        f"{where_sql}{order_sql} LIMIT :limit OFFSET :offset"
    )
    return sql, replacements


def _validate_table_query_request(request: TableQueryRequest, table_fields: set[str]) -> list[str]:
    errors: list[str] = []
    for field in request.fields:
        if field != "*" and field not in table_fields:
            errors.append(f"Unknown selected field: {field}.")
    for query_filter in request.filters:
        if query_filter.field not in table_fields:
            errors.append(f"Unknown filter field: {query_filter.field}.")
        if query_filter.operator == "in" and not isinstance(query_filter.value, list):
            errors.append(f"Filter '{query_filter.field}' uses 'in' and requires a list value.")
    if request.date_filter is not None and request.date_filter.field not in table_fields:
        errors.append(f"Unknown date filter field: {request.date_filter.field}.")
    for order in request.order_by:
        if order.field not in table_fields:
            errors.append(f"Unknown order field: {order.field}.")
    return errors


def _filter_to_sql(query_filter: QueryFilter, prefix: str) -> tuple[str, dict[str, Any]]:
    field_sql = _quote_identifier(query_filter.field)
    if query_filter.operator in FILTER_SQL_OPERATORS:
        key = prefix
        return f"{field_sql} {FILTER_SQL_OPERATORS[query_filter.operator]} :{key}", {key: query_filter.value}
    if query_filter.operator == "contains":
        key = prefix
        return f"{field_sql} LIKE :{key}", {key: f"%{query_filter.value}%"}
    if query_filter.operator == "startswith":
        key = prefix
        return f"{field_sql} LIKE :{key}", {key: f"{query_filter.value}%"}
    if query_filter.operator == "endswith":
        key = prefix
        return f"{field_sql} LIKE :{key}", {key: f"%{query_filter.value}"}
    values = query_filter.value
    keys = [f"{prefix}_{idx}" for idx, _ in enumerate(values)]
    placeholders = ", ".join(f":{key}" for key in keys)
    return f"{field_sql} IN ({placeholders})", dict(zip(keys, values))


def _date_filter_to_sql(date_filter: DateRangeFilter) -> tuple[list[str], dict[str, Any]]:
    clauses: list[str] = []
    replacements: dict[str, Any] = {}
    field_sql = _quote_identifier(date_filter.field)
    if date_filter.start is not None:
        clauses.append(f"{field_sql} >= :date_start")
        replacements["date_start"] = date_filter.start
    if date_filter.end is not None:
        clauses.append(f"{field_sql} <= :date_end")
        replacements["date_end"] = date_filter.end
    return clauses, replacements


def _selected_fields_sql(fields: list[str]) -> str:
    if fields == ["*"] or "*" in fields:
        return "*"
    return ", ".join(_quote_identifier(field) for field in fields)


def _order_by_sql(order_by: list[QueryOrder]) -> str:
    if not order_by:
        return ""
    parts = [
        f"{_quote_identifier(order.field)} {order.direction.upper()}"
        for order in order_by
    ]
    return f" ORDER BY {', '.join(parts)}"


def _split_sigma_key(raw_key: str) -> tuple[str, list[str]]:
    parts = raw_key.split("|")
    return parts[0], parts[1:]


def _patient_scope_field(table_fields: set[str]) -> str | None:
    for field in PATIENT_SCOPE_FIELDS:
        if field in table_fields:
            return field
    return None


def _normalized_sigma_filter_to_query_filter(item: dict[str, Any]) -> QueryFilter:
    field = item.get("field")
    modifiers = item.get("modifiers", ["eq"])
    value = item.get("value")
    if not isinstance(field, str) or not field:
        raise HTTPException(status_code=400, detail="Normalized Sigma filter is missing field.")
    if not isinstance(modifiers, list) or not modifiers:
        modifiers = ["eq"]
    if len(modifiers) > 1:
        raise HTTPException(
            status_code=400,
            detail=f"Filter '{field}' uses multiple Sigma modifiers that cannot be converted.",
        )
    modifier = modifiers[0]
    if modifier == "exists":
        raise HTTPException(
            status_code=400,
            detail=f"Filter '{field}' uses unsupported Sigma modifier 'exists'.",
        )
    if modifier not in {
        "eq",
        "neq",
        "gt",
        "gte",
        "lt",
        "lte",
        "contains",
        "startswith",
        "endswith",
    }:
        raise HTTPException(
            status_code=400,
            detail=f"Filter '{field}' uses unsupported Sigma modifier '{modifier}'.",
        )
    return QueryFilter(field=field, operator=modifier, value=value)


def _quote_identifier(identifier: str) -> str:
    if not re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", identifier):
        raise HTTPException(status_code=400, detail=f"Invalid identifier: {identifier}.")
    return f"`{identifier}`"


def _is_single_select(sql: str) -> bool:
    stripped = sql.strip().rstrip(";")
    if ";" in stripped:
        return False
    return bool(re.match(r"^(select|with)\b", stripped, flags=re.IGNORECASE))


def _extract_table_names(sql: str) -> list[str]:
    names = re.findall(r"\b(?:from|join)\s+`?([A-Za-z_][A-Za-z0-9_]*)`?", sql, flags=re.IGNORECASE)
    return list(dict.fromkeys(names))


def _extract_field_references(
    sql: str,
    table_names: list[str],
    index: dict[str, set[str]],
) -> dict[str, set[str]]:
    if not table_names:
        return {}
    if len(table_names) == 1:
        table = table_names[0]
        fields = _extract_single_table_fields(sql, index[table])
        return {table: fields}

    refs: dict[str, set[str]] = {table: set() for table in table_names}
    for table, field in re.findall(
        r"`?([A-Za-z_][A-Za-z0-9_]*)`?\.`?([A-Za-z_][A-Za-z0-9_]*|\*)`?",
        sql,
    ):
        if table in refs:
            refs[table].add(field)
    return refs


def _extract_single_table_fields(sql: str, known_fields: set[str]) -> set[str]:
    fields: set[str] = set()
    select_match = re.search(r"\bselect\b(?P<select>.*?)\bfrom\b", sql, flags=re.IGNORECASE | re.DOTALL)
    if select_match:
        select_clause = select_match.group("select")
        for part in select_clause.split(","):
            token = part.strip()
            if token == "*":
                fields.add("*")
                continue
            token = re.sub(r"\s+as\s+.*$", "", token, flags=re.IGNORECASE).strip()
            token = token.split(".")[-1].strip("` ")
            if re.fullmatch(r"[A-Za-z_][A-Za-z0-9_]*", token):
                fields.add(token)

    for candidate in re.findall(r"`?([A-Za-z_][A-Za-z0-9_]*)`?", sql):
        if candidate in known_fields:
            fields.add(candidate)
    return fields
