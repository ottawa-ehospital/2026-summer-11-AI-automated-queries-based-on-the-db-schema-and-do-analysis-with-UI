## ADDED Requirements

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
