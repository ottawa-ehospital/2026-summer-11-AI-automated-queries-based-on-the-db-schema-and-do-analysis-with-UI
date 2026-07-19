## Context

The existing `src/query_builder` package demonstrates a Sigma-style query generation flow, but it is outside the backend boundary and should remain a reference. The backend already has an eHospital client for table reads and assistant services that need patient/context data. The new query tooling must live under `src/backend` and expose deterministic validation functions that an AI agent can call before and after generating SQL.

## Goals / Non-Goals

**Goals:**

- Provide backend-owned function-call-friendly tools for Sigma payload validation and generated SQL reference validation.
- Export a JSON schema inventory from the live eHospital metadata so later query validation can use stable table/field metadata.
- Execute full-table reads through a structured interface with optional filter support, including date range filters.
- Keep SQL execution read-only and route arbitrary user values through replacements.

**Non-Goals:**

- Replace the remote eHospital generic API.
- Add authentication or authorization to the remote service.
- Directly import or move code from `src/query_builder`.
- Build a complete natural-language-to-SQL agent in this change.

## Decisions

1. Add backend query tooling under `src/backend/services/query_tools.py`, `src/backend/schemas/query_tools.py`, and `src/backend/api/query_tools.py`.
   - Rationale: keeps implementation inside the backend while matching existing router/schema/service structure.
   - Alternative considered: reuse `src/query_builder`. Rejected because the user explicitly scoped it as demo reference only.

2. Model Sigma as a narrow, backend-supported query intent rather than accepting arbitrary Sigma variants.
   - Rationale: AI function calls need a deterministic contract. The supported shape will include title, table, fields, filters, date filter, order, and limit.
   - Alternative considered: accept any dictionary and validate loosely. Rejected because it would make downstream SQL validation less reliable.

3. Generate the eHospital schema inventory from `GET /tables` and persist it as backend JSON.
   - Rationale: downstream validation should not need to call the remote metadata endpoint every time.
   - Alternative considered: hardcode schema metadata. Rejected because table fields can drift.

4. Validate generated SQL by parsing table names and selected/filtered/order fields against the inventory.
   - Rationale: catches hallucinated tables/columns before execution.
   - Trade-off: this remains a conservative validator for common SELECT queries, not a full SQL compiler.

5. Full-table query execution uses structured request fields instead of accepting frontend SQL.
   - Rationale: filters and date ranges can be safely converted to parameterized SQL.
   - Alternative considered: expose `/sql/select` directly from the backend. Rejected because it bypasses schema and filter validation.

## Risks / Trade-offs

- SQL parsing can miss complex SQL syntax -> Mitigate by supporting the generated query patterns the AI is expected to produce and failing closed for unsupported shapes.
- Schema inventory can become stale -> Mitigate with a refresh endpoint/function and checked-in/generated JSON output.
- Full-table reads can become expensive -> Mitigate by enforcing maximum limits even when the logical mode is "full query".
- Date columns vary by table -> Mitigate by making `date_field` explicit and validating it against the table schema.
