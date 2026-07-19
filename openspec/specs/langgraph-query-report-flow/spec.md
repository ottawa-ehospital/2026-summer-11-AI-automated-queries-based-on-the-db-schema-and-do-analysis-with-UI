# langgraph-query-report-flow Specification

## Purpose
TBD - created by archiving change complete-langgraph-query-report-flow. Update Purpose after archive.
## Requirements
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

### Requirement: Workflow analyzes event-triggered health changes
The LangGraph health-data workflow SHALL support event-triggered alert analysis that evaluates new health measurements against patient context and recent trends.

#### Scenario: Event analysis gathers patient context
- **WHEN** the workflow receives a supported health event such as blood pressure
- **THEN** it gathers relevant patient history from `medical_history` and `diagnosis`, active medication context from `prescription_form` and `prescription`, patient-reported context from `patient_feedback`, risk context from `heart_disease_analysis`, `stroke_prediction`, and `ai_diagnostics`, recent measurements from `vitals_history` and `wearable_vitals`, and workout history from `wearable_workouts` when available through validated patient-scoped queries
- **THEN** it uses that context before returning an alert decision

#### Scenario: Event analysis uses configured model provider
- **WHEN** the 3-hour blood-pressure window has enough evidence for demo LLM reasoning
- **THEN** the workflow invokes the shared model client using the configured model provider
- **THEN** the workflow provides user baseline, recent readings, medication/history context, resting heart rate, sleep, activity, workout history, and normal adult reference ranges while constraining the model to produce the alert decision schema

#### Scenario: Event analysis lacks sufficient context
- **WHEN** the workflow cannot retrieve enough patient history, medication context, or recent measurement evidence
- **THEN** it returns a no-notification decision with missing-context reasons
- **THEN** it does not produce medication-specific reminder text

#### Scenario: Event analysis uses reference-range context
- **WHEN** the workflow evaluates a blood-pressure event for demo notification analysis
- **THEN** it uses cached authoritative blood-pressure reference ranges or live LLM web-search results with source/provenance metadata
- **THEN** it treats those references as context for wellness reminder analysis rather than as standalone diagnosis logic

### Requirement: Workflow returns structured alert decisions
The LangGraph health-data workflow SHALL return event-analysis results as structured alert decisions rather than free-form chat replies.

#### Scenario: Reminder decision is generated
- **WHEN** the workflow determines that a user reminder is warranted
- **THEN** it returns `notify=true` with severity, notification title, notification body, evidence summary, recommendation category, freshness metadata, and model/provider trace metadata
- **THEN** the notification body uses supportive language and avoids diagnosis or emergency claims

#### Scenario: No notification is warranted
- **WHEN** deterministic gates or model analysis determine that the event does not warrant user interruption
- **THEN** the workflow returns `notify=false`
- **THEN** the result includes the reason notification was suppressed

#### Scenario: Model output cannot be validated
- **WHEN** model-generated alert output is malformed, unsafe, or missing required fields after bounded retries
- **THEN** the workflow returns a no-notification fallback decision
- **THEN** the workflow records the validation failure stage in trace metadata

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

### Requirement: Workflow uses workout history for exercise-related advice
The LangGraph health-data query/report workflow SHALL consider workout history when a user asks for personalized exercise, running, cycling, recovery, or activity-history advice.

#### Scenario: User asks to start running after inactivity
- **WHEN** a user asks whether they should start running and the request implies personal exercise planning
- **THEN** the workflow identifies workout history as relevant patient context
- **THEN** the workflow attempts a patient-scoped query against `wearable_workouts` before generating personalized guidance

#### Scenario: User asks about long-distance cycling
- **WHEN** a user asks about long-distance cycling, endurance exercise, or an unusually large planned workout
- **THEN** the workflow considers recent workouts, duration, distance, and heart-rate summaries as relevant context
- **THEN** the workflow combines workout history with other available patient context before generating a report or text guidance

#### Scenario: User asks about exercise with medical risk context
- **WHEN** a user asks for exercise advice and patient context includes possible cardiac or other high-risk conditions
- **THEN** the workflow treats workout history as supporting evidence rather than sufficient clearance
- **THEN** the final response includes evidence-grounded limitations and appropriate care-seeking guidance

### Requirement: Workflow plans workout-history Sigma queries
The workflow SHALL map workout, exercise, activity, run, cycling, and inactivity intents to query plans that can retrieve relevant workout records.

#### Scenario: Deterministic workout mapping applies
- **WHEN** the intent clearly asks for recent workout history or activity trend
- **THEN** the workflow builds or selects a Sigma payload targeting `wearable_workouts`
- **THEN** the payload selects fields needed for analysis such as workout type, start time, duration, distance, energy, and heart-rate summaries

#### Scenario: Model-backed workout planning applies
- **WHEN** deterministic mapping is insufficient for a supported workout-related advice request
- **THEN** the workflow prompts the configured model using schema context that includes `wearable_workouts`
- **THEN** the generated Sigma payload is validated before execution

### Requirement: Workflow validates end-to-end workout reasoning
The workflow SHALL include tests or fixtures proving that uploaded workout records can affect AI query/report behavior.

#### Scenario: Uploaded workout appears in assistant analysis
- **WHEN** a test patient has workout records available in `wearable_workouts`
- **THEN** an exercise-history or exercise-advice assistant request retrieves those records through the validated query path
- **THEN** the generated analysis references retrieved workout evidence instead of relying only on general knowledge

#### Scenario: No workout history is handled safely
- **WHEN** a user asks for exercise advice and the workout-history query returns no rows
- **THEN** the workflow explains that no matching workout history is available
- **THEN** the workflow does not fabricate workout evidence

#### Scenario: Workout query validation fails
- **WHEN** the workflow cannot validate a patient-scoped workout query
- **THEN** the workflow returns a fallback or clarification response
- **THEN** the workflow does not execute an unsafe workout query

