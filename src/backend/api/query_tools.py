from __future__ import annotations

from fastapi import APIRouter

from src.backend.schemas.query_tools import (
    SchemaInventoryResponse,
    SigmaValidationRequest,
    SqlValidationRequest,
    TableQueryRequest,
    TableQueryResponse,
    ValidationResponse,
)
from src.backend.services.query_tools import (
    load_schema_inventory,
    query_table,
    refresh_schema_inventory,
    validate_sigma_payload,
    validate_sql_references,
)


router = APIRouter(prefix="/query-tools", tags=["query-tools"])


@router.post("/schema/refresh", response_model=SchemaInventoryResponse)
async def refresh_schema() -> SchemaInventoryResponse:
    inventory = await refresh_schema_inventory()
    return SchemaInventoryResponse(**inventory)


@router.get("/schema", response_model=SchemaInventoryResponse)
def schema_inventory() -> SchemaInventoryResponse:
    inventory = load_schema_inventory()
    return SchemaInventoryResponse(**inventory)


@router.post("/sigma/validate", response_model=ValidationResponse)
def validate_sigma(request: SigmaValidationRequest) -> ValidationResponse:
    valid, errors, normalized = validate_sigma_payload(request.sigma)
    return ValidationResponse(valid=valid, errors=errors, normalized=normalized)


@router.post("/sql/validate", response_model=ValidationResponse)
def validate_sql(request: SqlValidationRequest) -> ValidationResponse:
    valid, errors, normalized = validate_sql_references(request.sql)
    return ValidationResponse(valid=valid, errors=errors, normalized=normalized)


@router.post("/table/query", response_model=TableQueryResponse)
async def filtered_table_query(request: TableQueryRequest) -> TableQueryResponse:
    result = await query_table(request)
    return TableQueryResponse(**result)
