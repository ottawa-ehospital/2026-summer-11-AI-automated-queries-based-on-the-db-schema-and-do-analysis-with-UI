## 1. Backend Query Tool Contracts

- [x] 1.1 Add Pydantic request/response schemas for Sigma validation, SQL validation, schema inventory refresh, and filtered table queries.
- [x] 1.2 Add an eHospital metadata client function for `GET /tables`.

## 2. Core Query Tool Implementation

- [x] 2.1 Implement schema inventory refresh/read helpers that write backend JSON metadata.
- [x] 2.2 Implement Sigma payload validation against known tables, fields, operators, order fields, limits, and date filters.
- [x] 2.3 Implement generated SQL reference validation against known tables and fields.
- [x] 2.4 Implement filtered full-table query execution using parameterized SQL and validated filters.

## 3. Backend API Surface

- [x] 3.1 Add a FastAPI router exposing query tool endpoints for AI/backend callers.
- [x] 3.2 Register the router in the backend app.

## 4. Verification

- [x] 4.1 Add backend tests for valid/invalid Sigma payloads.
- [x] 4.2 Add backend tests for schema inventory generation and SQL reference validation.
- [x] 4.3 Add backend tests for filtered date query construction/execution.
- [x] 4.4 Run Python tests/checks relevant to backend query tools.
