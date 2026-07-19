# Backend Sigma Query Tools

## Purpose

Backend-owned tools for validating Sigma-style query intents, generating eHospital schema inventory metadata, validating generated SQL references, and executing filtered read queries.
## Requirements
### Requirement: Sigma Payload Validation
The backend SHALL provide an AI-callable function that validates Sigma-style query payloads against the supported backend query intent shape.

#### Scenario: Valid Sigma payload
- **WHEN** the AI submits a Sigma payload with a known table, valid fields, supported filters, and a valid limit
- **THEN** the backend returns a valid result with normalized query intent details

#### Scenario: Invalid Sigma payload
- **WHEN** the AI submits a Sigma payload missing required keys or using unsupported operators
- **THEN** the backend returns validation errors without querying eHospital

### Requirement: Schema Inventory Generation
The backend SHALL generate a JSON file containing eHospital table names, primary keys, attributes, and metadata needed by query validators.

#### Scenario: Refresh schema inventory
- **WHEN** the schema generation function is called
- **THEN** the backend fetches remote table metadata and writes a JSON schema inventory under the backend package

### Requirement: Generated SQL Reference Validation
The backend SHALL provide an AI-callable function that checks whether generated SQL references only existing tables and fields from the schema inventory.

#### Scenario: SQL references existing schema
- **WHEN** generated SQL selects known fields from known tables
- **THEN** the backend returns a valid result

#### Scenario: SQL references unknown schema
- **WHEN** generated SQL references a missing table or field
- **THEN** the backend returns validation errors and does not execute the SQL

### Requirement: Filtered Full Query Interface
The backend SHALL provide a structured full-query interface that reads table rows and supports filters, including date range filtering.

#### Scenario: Query with date filter
- **WHEN** a caller requests a table with a valid date field and start/end date filters
- **THEN** the backend queries rows using parameterized SQL and returns matching records

#### Scenario: Query with invalid filter field
- **WHEN** a caller requests a filter on a field that is not present in the table schema
- **THEN** the backend rejects the request before querying eHospital

### Requirement: Sigma can be converted to table query requests
The backend SHALL provide a workflow-facing conversion path from normalized Sigma payloads into structured table query requests.

#### Scenario: Normalized Sigma is converted
- **WHEN** a normalized Sigma payload contains a table, selected fields, filters, date filter, ordering, and limit
- **THEN** the backend converts it into a `TableQueryRequest` with equivalent query constraints
- **THEN** the conversion does not require Flutter or the model to construct SQL

#### Scenario: Unsupported Sigma modifier is encountered
- **WHEN** Sigma conversion sees a modifier that cannot be represented by the table query interface
- **THEN** the backend rejects the conversion with a validation error
- **THEN** no query is executed

### Requirement: Sigma execution enforces patient scoping
The backend SHALL enforce patient scoping when workflow-generated Sigma is converted and executed for an assistant request.

#### Scenario: Table has patient scope field
- **WHEN** a workflow query targets a table with a known patient identifier field
- **THEN** the backend adds or verifies a filter for the current patient id before execution
- **THEN** model-generated patient filters cannot override the current authenticated/request patient id

#### Scenario: Table cannot be scoped to patient
- **WHEN** a workflow query targets a table that cannot be safely scoped to the current patient
- **THEN** the backend rejects the query or routes the workflow to fallback
- **THEN** the backend does not execute an unscoped patient-data query

### Requirement: Schema inventory supports workflow planning context
The backend SHALL expose schema inventory details needed for model-backed Sigma planning without exposing unrelated execution privileges.

#### Scenario: Workflow builds schema context
- **WHEN** the workflow asks the model to propose Sigma
- **THEN** the backend provides an allowlisted schema context containing table names, fields, primary keys, and patient scope hints relevant to health assistant queries

#### Scenario: Schema inventory is missing
- **WHEN** schema inventory is unavailable during Sigma planning or validation
- **THEN** the backend returns a controlled validation or fallback error
- **THEN** the workflow does not ask the model to guess table fields

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

### Requirement: Schema inventory includes wearable workout tables
The backend SHALL include `wearable_workouts` and required workout fields in schema inventory and query validation metadata used by Sigma planning and execution.

#### Scenario: Workout schema appears in planning context
- **WHEN** the workflow builds schema planning context for patient-scoped health assistant queries
- **THEN** the context includes the `wearable_workouts` table
- **THEN** the context includes fields needed for workout history analysis, including patient id, source provider, workout type, start time, end time, duration, distance, energy, heart-rate summaries, and sync metadata

#### Scenario: Workout query references known fields
- **WHEN** a Sigma payload references known `wearable_workouts` fields
- **THEN** Sigma validation accepts the table and fields subject to existing filter, order, and limit rules
- **THEN** the query can be converted into a backend table query request

#### Scenario: Workout query references unknown fields
- **WHEN** a Sigma payload references a missing workout table field
- **THEN** Sigma validation rejects the payload before execution
- **THEN** the backend does not run an unvalidated workout query

### Requirement: Workout queries enforce patient scoping
The backend SHALL enforce current-patient scoping for workout table queries generated from Sigma payloads.

#### Scenario: Workout query is scoped to current patient
- **WHEN** a workflow query targets `wearable_workouts`
- **THEN** the backend adds or verifies a filter for the current patient id
- **THEN** model-generated patient filters cannot override the current patient id

#### Scenario: Workout query cannot be safely scoped
- **WHEN** a workout query cannot be tied to the current patient
- **THEN** the backend rejects the query or routes the workflow to fallback
- **THEN** the backend does not execute an unscoped workout-history query

### Requirement: Workout schema support has validation tests
The backend SHALL include tests that prove workout table schema metadata participates in planning and validation.

#### Scenario: Workout planning context test passes
- **WHEN** backend tests build schema planning context
- **THEN** the tests verify `wearable_workouts` and required workout fields are present

#### Scenario: Workout Sigma validation test passes
- **WHEN** backend tests validate a Sigma payload for recent workouts
- **THEN** the payload is accepted only when it references known workout fields and remains patient-scopeable

