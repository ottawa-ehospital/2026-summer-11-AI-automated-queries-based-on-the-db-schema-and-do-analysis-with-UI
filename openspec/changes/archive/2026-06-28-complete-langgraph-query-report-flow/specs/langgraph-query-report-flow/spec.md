## ADDED Requirements

### Requirement: Health data workflow performs structured intent analysis
The LangGraph health-data query/report workflow SHALL analyse each routed assistant message into a structured intent object before building a query.

#### Scenario: Health metric analysis request
- **WHEN** a user asks about a supported health metric such as heart rate, sleep, steps, calories, blood pressure, readiness, or activity
- **THEN** the workflow identifies the request kind, target metric, candidate table or tables, time range intent, required patient context, desired output types, and freshness category

#### Scenario: Personalized advice request
- **WHEN** a user asks for personalized running, exercise, recovery, sleep-improvement, or health-planning advice
- **THEN** the workflow identifies that patient context and health-data queries are required before advice is generated
- **THEN** the workflow does not answer as plain general chat without attempting the query/report path

#### Scenario: Ambiguous health-data request
- **WHEN** the workflow cannot determine the metric, table scope, or user goal with sufficient confidence
- **THEN** the workflow returns a clarification response or routes to fallback according to the configured fallback policy
- **THEN** the workflow does not execute a broad or unscoped query

### Requirement: Workflow builds Sigma query plans
The LangGraph health-data query/report workflow SHALL build Sigma-style query payloads as the intermediate query plan for requests that require patient-data lookup.

#### Scenario: Deterministic metric mapping is available
- **WHEN** the intent matches a supported deterministic metric mapping
- **THEN** the workflow builds a Sigma payload using the mapped table, fields, filters, order, and limit
- **THEN** the Sigma payload remains patient-scopeable before execution

#### Scenario: Model-backed planning is required
- **WHEN** deterministic mapping is not sufficient for a supported health-data request
- **THEN** the workflow asks the configured model provider through the shared model client to propose a Sigma payload
- **THEN** the prompt constrains the model to known schema inventory tables and fields

#### Scenario: No query is needed
- **WHEN** intent analysis determines that the request can be answered without patient-data lookup
- **THEN** the workflow routes to a no-query path or fallback instead of generating Sigma

### Requirement: Workflow validates and revises Sigma before execution
The LangGraph health-data query/report workflow SHALL validate Sigma payloads before converting or executing them and SHALL use bounded revision attempts when validation fails.

#### Scenario: Sigma validates successfully
- **WHEN** the generated Sigma payload references known tables, known fields, supported operators, and valid limits
- **THEN** the workflow stores the normalized Sigma payload and continues to query conversion

#### Scenario: Sigma validation fails with retries remaining
- **WHEN** Sigma validation fails and the workflow has remaining Sigma revision attempts
- **THEN** the workflow revises the Sigma payload using the validation errors
- **THEN** the revised payload is validated again before execution

#### Scenario: Sigma validation exceeds retry limit
- **WHEN** Sigma validation still fails after the configured maximum attempts
- **THEN** the workflow stops retrying and returns a fallback response
- **THEN** no eHospital query is executed for the invalid Sigma

### Requirement: Workflow executes patient-scoped queries from validated Sigma
The LangGraph health-data query/report workflow SHALL convert validated Sigma into backend table query requests and execute only backend-validated patient-scoped queries.

#### Scenario: Patient-scoped table query is built
- **WHEN** normalized Sigma is converted into a table query request
- **THEN** the backend enforces the current patient id on tables that support patient scoping
- **THEN** the query request includes selected fields, filters, date range, ordering, and limit from the normalized Sigma

#### Scenario: Query executes successfully
- **WHEN** the converted table query request passes backend validation
- **THEN** the workflow executes the query through backend query tools
- **THEN** the workflow stores returned rows, row count, SQL metadata, and source summary for analysis

#### Scenario: Query returns no rows
- **WHEN** the executed query returns no usable rows
- **THEN** the workflow returns a validated text or report result explaining that no matching data is available
- **THEN** the workflow does not return an empty chart result

### Requirement: Workflow analyses query results with the configured model provider
The LangGraph health-data query/report workflow SHALL analyse retrieved query rows before generating final assistant outputs.

#### Scenario: Query results are available
- **WHEN** query execution returns rows for the patient
- **THEN** the workflow invokes the shared model client using the configured model provider to produce structured analysis
- **THEN** the analysis includes a concise summary, evidence references, limitations, freshness category, recommendation candidates, and chart candidates when chartable data exists

#### Scenario: Analysis output is malformed
- **WHEN** model-generated analysis cannot be parsed or lacks required analysis fields
- **THEN** the workflow revises or falls back according to the configured analysis/output retry policy

### Requirement: Workflow plans and validates final assistant outputs
The LangGraph health-data query/report workflow SHALL choose final assistant result types from intent and analysis, then validate every structured result before returning it.

#### Scenario: Report output is selected
- **WHEN** the request asks for analysis, advice, planning, or a report
- **THEN** the workflow returns a Markdown report result with generated time, expiration time, freshness reason, source summary, and evidence-grounded content

#### Scenario: Chart output is selected
- **WHEN** analysis finds chartable numeric or time-series data and the user request benefits from visualization
- **THEN** the workflow returns a chart result with a supported display type, axes, series, and numeric points
- **THEN** the chart result is validated before response composition

#### Scenario: Text guidance is selected
- **WHEN** a short answer is sufficient or structured output cannot be safely generated
- **THEN** the workflow returns a text result and a populated top-level reply

#### Scenario: Output validation fails with retries remaining
- **WHEN** generated report or chart payload validation fails and output revision attempts remain
- **THEN** the workflow revises the output using validation errors
- **THEN** the revised output is validated again before being returned

#### Scenario: Output validation exceeds retry limit
- **WHEN** output validation still fails after the configured maximum attempts
- **THEN** the workflow returns a fallback text response instead of returning invalid structured results

### Requirement: Workflow records traceable routing and execution metadata
The LangGraph health-data query/report workflow SHALL record trace metadata useful for tests and backend observability.

#### Scenario: Workflow completes successfully
- **WHEN** the workflow returns a successful assistant response
- **THEN** trace metadata includes selected workflow, intent kind, selected tables, selected result types, model provider, and validation attempt counts

#### Scenario: Workflow falls back
- **WHEN** the workflow returns a fallback response
- **THEN** trace metadata includes fallback reason and the failed stage
