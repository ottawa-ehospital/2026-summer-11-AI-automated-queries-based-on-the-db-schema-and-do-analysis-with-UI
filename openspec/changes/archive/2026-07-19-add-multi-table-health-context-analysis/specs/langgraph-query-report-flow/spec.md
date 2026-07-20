## ADDED Requirements

### Requirement: Workflow builds multi-query context plans
The LangGraph health-data query/report workflow SHALL build a bounded multi-query context plan for health-data requests that need patient context from multiple tables.

#### Scenario: Training readiness intent is forced to multi-table flow
- **WHEN** intent analysis classifies a request as `health_plan`, `training readiness`, `tomorrow`, or `intensive training`
- **THEN** the workflow routes the request through the multi-query context-plan path
- **THEN** the workflow includes `wearable_vitals`, `vitals_history`, `diagnosis`, `medical_history`, `prescription_form`, and `wearable_workouts` in the planned tables

#### Scenario: Intent identifies multiple candidate tables
- **WHEN** intent analysis identifies multiple relevant candidate tables for a personalized health question
- **THEN** the workflow builds a context plan containing one validated query entry per selected table or domain
- **THEN** the plan marks each query entry as required or optional with a purpose used by analysis

#### Scenario: Model-backed planning proposes context queries
- **WHEN** deterministic planning is not sufficient for a supported multi-table health-data request
- **THEN** the workflow asks the configured model provider to propose a constrained context plan
- **THEN** the prompt constrains the model to known schema inventory tables, known fields, patient-scoped tables, and the maximum query count

#### Scenario: Single-table request is planned
- **WHEN** a request only needs one table such as a simple recent wearable metric chart
- **THEN** the workflow builds a one-entry context plan
- **THEN** downstream validation, execution, analysis, and trace behavior use the same context-plan path

### Requirement: Workflow executes multi-query context plans
The LangGraph health-data query/report workflow SHALL validate, convert, and execute each context-plan query independently before analysis.

#### Scenario: All planned queries validate
- **WHEN** every context-plan query references known tables, known fields, supported operators, valid limits, and patient-scopeable tables
- **THEN** the workflow converts every query into a backend table query request for the current patient
- **THEN** the workflow executes the converted queries and stores successful rows by query id and table

#### Scenario: Optional query fails validation or execution
- **WHEN** an optional context-plan query fails validation, references an unavailable optional table, or returns no usable rows
- **THEN** the workflow records the issue as missing context for that query
- **THEN** the workflow continues with other validated successful queries

#### Scenario: Forced training table is empty
- **WHEN** a forced training-readiness table query validates and executes but returns no rows
- **THEN** the workflow records an empty-source missing-context reason for that table
- **THEN** the workflow continues with the remaining forced and optional context queries

#### Scenario: Required query fails after retries
- **WHEN** a required context-plan query cannot be validated or safely executed after configured retries
- **THEN** the workflow stops executing unsafe query entries
- **THEN** the workflow returns a fallback or no-data response with the failed stage recorded

### Requirement: Workflow analyses combined context
The LangGraph health-data query/report workflow SHALL analyze a combined context package rather than a single query result when multi-table context is available.

#### Scenario: Combined context is available
- **WHEN** at least one context-plan query returns usable patient rows
- **THEN** the workflow invokes the shared model client using the configured model provider to analyze all successful context sources together
- **THEN** the analysis includes source-specific evidence references, limitations, freshness category, recommendation candidates, and chart candidates when chartable data exists

#### Scenario: Training readiness analysis receives explicit context framing
- **WHEN** the workflow analyzes a training-readiness, tomorrow-training, or intensive-training request
- **THEN** the analysis prompt includes current backend time, recent 3-hour data, recent one-day data, medical history, medication context, symptom or feedback context, vitals, and workout history
- **THEN** the prompt instructs the model to synthesize those sources before recommending training intensity

#### Scenario: Training safety hints are present
- **WHEN** deterministic preprocessing detects sleep under 4 hours, high blood pressure, or symptom evidence
- **THEN** the workflow adds safety hints to the context package and analysis prompt
- **THEN** the generated advice must be conservative about intensive training

#### Scenario: Context is partial
- **WHEN** some relevant context sources are missing but at least one source returns usable rows
- **THEN** the workflow includes missing-context details in the analysis input
- **THEN** the final response explains the limitation without treating the entire request as failed

#### Scenario: Context is empty
- **WHEN** no context-plan query returns usable rows
- **THEN** the workflow returns a validated text or report result explaining that no matching data is available
- **THEN** the workflow does not return an empty chart result

### Requirement: Workflow records multi-table trace metadata
The LangGraph health-data query/report workflow SHALL record trace metadata for multi-table context planning and execution.

#### Scenario: Multi-table workflow completes
- **WHEN** the workflow returns a successful assistant response from a multi-table context plan
- **THEN** trace metadata includes selected workflow, intent kind, selected tables, query ids, per-table row counts, missing-context reasons, selected result types, model provider, and validation attempt counts

#### Scenario: Multi-table workflow falls back
- **WHEN** the workflow returns a fallback response from a multi-table context plan
- **THEN** trace metadata includes fallback reason, failed stage, and the failed query ids or tables when available
