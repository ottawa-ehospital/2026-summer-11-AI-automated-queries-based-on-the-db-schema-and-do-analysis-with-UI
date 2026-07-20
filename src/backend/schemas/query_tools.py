from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


FilterOperator = Literal["eq", "neq", "gt", "gte", "lt", "lte", "contains", "startswith", "endswith", "in"]
SortDirection = Literal["asc", "desc"]


class QueryFilter(BaseModel):
    field: str
    operator: FilterOperator = "eq"
    value: Any


class DateRangeFilter(BaseModel):
    field: str
    start: str | None = None
    end: str | None = None


class QueryOrder(BaseModel):
    field: str
    direction: SortDirection = "desc"


class SigmaValidationRequest(BaseModel):
    sigma: dict[str, Any]


class ValidationResponse(BaseModel):
    valid: bool
    errors: list[str] = Field(default_factory=list)
    normalized: dict[str, Any] | None = None


class SqlValidationRequest(BaseModel):
    sql: str


class SchemaInventoryResponse(BaseModel):
    count: int
    tables: list[dict[str, Any]]
    generated_at: str | None = None


class TableQueryRequest(BaseModel):
    table: str
    fields: list[str] = Field(default_factory=lambda: ["*"])
    filters: list[QueryFilter] = Field(default_factory=list)
    date_filter: DateRangeFilter | None = None
    order_by: list[QueryOrder] = Field(default_factory=list)
    limit: int = 500
    offset: int = 0


class TableQueryResponse(BaseModel):
    sql: str
    replacements: dict[str, Any]
    count: int
    data: list[dict[str, Any]]


class MultiQueryPlanEntry(BaseModel):
    query_id: str
    purpose: str
    required: bool = False
    domain: str | None = None
    sigma: dict[str, Any]


class MultiQueryPlanRequest(BaseModel):
    queries: list[MultiQueryPlanEntry]
