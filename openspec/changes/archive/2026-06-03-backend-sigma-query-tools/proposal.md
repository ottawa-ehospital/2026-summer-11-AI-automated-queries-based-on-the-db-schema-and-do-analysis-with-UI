## Why

The app needs an AI-friendly way to turn Sigma-style query intents into verified database queries against the eHospital schema. The current `src/query_builder` package is useful as a demo reference, but backend runtime code needs its own scoped tools for validation, schema export, and filterable full-table reads.

## What Changes

- Add backend-owned Sigma query tool classes and schemas for AI function calls.
- Validate Sigma payload shape before query generation.
- Generate a backend JSON schema inventory from the deployed/current eHospital tables for downstream database validation.
- Validate generated SQL references against known table and field metadata before execution.
- Add backend query execution support for full-table reads with structured filters, including date filtering.
- Keep all implementation edits under `src/backend`; do not directly import or reuse `src/query_builder`.

## Capabilities

### New Capabilities

- `backend-sigma-query-tools`: Backend AI-callable Sigma validation, eHospital schema inventory generation, SQL reference validation, and filtered query execution.

### Modified Capabilities

- None.

## Impact

- Affected backend code: `src/backend/api`, `src/backend/clients`, `src/backend/schemas`, `src/backend/services`, and related backend tests.
- Adds backend API/function-call contracts for Sigma validation, SQL reference validation, schema inventory refresh/read, and filtered table queries.
- Relies on the remote eHospital metadata endpoints already documented in `api.md`.
