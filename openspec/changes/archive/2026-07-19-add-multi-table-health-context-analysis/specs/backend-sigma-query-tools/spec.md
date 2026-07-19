## ADDED Requirements

### Requirement: Multi-query plan validation
The backend SHALL provide workflow-facing validation for bounded multi-query plans composed of Sigma-style query payloads.

#### Scenario: Valid multi-query plan
- **WHEN** the workflow submits a multi-query plan with known query ids, known tables, valid fields, supported filters, valid limits, and allowed required/optional markers
- **THEN** the backend validates every query entry independently
- **THEN** the backend returns normalized query entries suitable for conversion to table query requests

#### Scenario: Invalid query entry
- **WHEN** one query entry in a multi-query plan references an unknown table, unknown field, unsupported operator, unsafe limit, or unscoped table
- **THEN** the backend reports validation errors for that query entry without executing it
- **THEN** validation errors preserve the query id or table name for workflow trace metadata

### Requirement: Multi-query execution preserves patient scoping
The backend SHALL convert and execute each normalized multi-query plan entry through the same patient-scoped table query path used for single Sigma payloads.

#### Scenario: Multi-query entry is converted
- **WHEN** a normalized multi-query entry targets a table with a known patient scope field
- **THEN** the backend converts it into a `TableQueryRequest` with the current patient id enforced
- **THEN** model-generated patient filters cannot override the current authenticated/request patient id

#### Scenario: Multi-query entry cannot be scoped
- **WHEN** a normalized multi-query entry targets a table that cannot be safely scoped to the current patient
- **THEN** the backend rejects that entry before execution
- **THEN** the backend does not execute an unscoped patient-data query

### Requirement: Multi-query results preserve source metadata
The backend SHALL return enough metadata for the workflow to aggregate multi-table query results with source provenance.

#### Scenario: Query entry executes successfully
- **WHEN** a multi-query entry executes successfully
- **THEN** the result includes query id, table name, row count, selected fields, SQL metadata, replacements metadata, and returned rows

#### Scenario: Query entry returns no rows
- **WHEN** a multi-query entry validates and executes but returns no rows
- **THEN** the result includes query id, table name, row count of zero, and source metadata
- **THEN** the workflow can distinguish no data from validation or execution failure
