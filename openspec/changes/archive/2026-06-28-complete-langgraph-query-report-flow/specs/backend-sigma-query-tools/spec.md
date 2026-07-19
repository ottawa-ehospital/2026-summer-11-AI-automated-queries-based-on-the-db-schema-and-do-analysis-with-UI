## ADDED Requirements

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
