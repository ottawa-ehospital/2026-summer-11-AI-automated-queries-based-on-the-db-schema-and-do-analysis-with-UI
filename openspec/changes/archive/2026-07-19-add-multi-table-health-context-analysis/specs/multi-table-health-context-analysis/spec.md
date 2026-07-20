## ADDED Requirements

### Requirement: Health assistant plans multi-table context
The health assistant SHALL build a bounded multi-table context plan for personalized health questions that require evidence from more than one patient data domain.

#### Scenario: Training readiness uses mandatory context set
- **WHEN** a user asks a `health_plan`, `training readiness`, `tomorrow`, or `intensive training` question
- **THEN** the context plan includes patient-scoped queries for `wearable_vitals`, `vitals_history`, `diagnosis`, `medical_history`, `prescription_form`, and `wearable_workouts`
- **THEN** the workflow does not answer from a single selected table only

#### Scenario: Exercise advice needs vitals and workout context
- **WHEN** a user asks for personalized exercise, running, recovery, or training advice
- **THEN** the context plan includes relevant patient-scoped wearable vitals and workout history queries when those tables are available
- **THEN** the context plan MAY include additional history, diagnosis, medication, feedback, or risk-analysis queries when the request requires that context

#### Scenario: Medication-sensitive question needs medication and measurement context
- **WHEN** a user asks about a health pattern where medication or diagnosis context can affect interpretation
- **THEN** the context plan includes relevant patient-scoped medication, diagnosis, history, and measurement queries
- **THEN** the assistant does not infer medication use from wearable metrics alone

#### Scenario: Simple metric chart request remains narrow
- **WHEN** a user asks only for a simple chart or recent value for one supported metric
- **THEN** the context plan may contain a single query for the relevant metric table
- **THEN** the workflow still represents that lookup as a one-entry context plan

### Requirement: Context retrieval is patient scoped and bounded
The health assistant SHALL retrieve multi-table context only through validated patient-scoped queries with bounded table count, row limits, and allowed fields.

#### Scenario: Multi-table plan is executed
- **WHEN** the workflow executes a context plan with multiple query entries
- **THEN** each query entry is validated independently against schema inventory before execution
- **THEN** each query entry is converted to a patient-scoped table query for the current patient

#### Scenario: Optional table has no data
- **WHEN** an optional context query returns no rows or its optional table is unavailable
- **THEN** the workflow records missing context for that table
- **THEN** the workflow continues analyzing other successful context sources

#### Scenario: Mandatory training context table has no rows
- **WHEN** a mandatory training-readiness context table validates and executes but returns no rows
- **THEN** the workflow records that table as empty context
- **THEN** the workflow continues analyzing other mandatory and optional sources

#### Scenario: Required context cannot be safely scoped
- **WHEN** a required context query cannot be validated or cannot be scoped to the current patient
- **THEN** the workflow does not execute the unsafe query
- **THEN** the workflow revises the plan or falls back according to retry policy

### Requirement: Analysis uses a combined health context package
The health assistant SHALL analyze successful context sources as one combined health context package with source provenance and missing-context limitations.

#### Scenario: Multiple sources return evidence
- **WHEN** vitals, workout, history, medication, feedback, or risk-analysis queries return usable rows
- **THEN** the workflow provides the analysis step with a context package grouped by table or domain
- **THEN** the analysis includes evidence references that identify the contributing source tables

#### Scenario: Some relevant context is missing
- **WHEN** one or more relevant context sources are empty, unavailable, or optional failures
- **THEN** the final text or report explains the missing context as a limitation
- **THEN** the assistant avoids recommendations that depend on unavailable medication, diagnosis, or history evidence

#### Scenario: Training readiness prompt includes time windows
- **WHEN** the assistant analyzes a training-readiness, tomorrow-training, or intensive-training request
- **THEN** the analysis prompt includes the current backend time, recent 3-hour context, recent one-day context, medical history, medication context, symptom or feedback context, vitals, and workout history
- **THEN** the analysis judges training readiness from the combined context rather than one source table

#### Scenario: Deterministic safety hints constrain training advice
- **WHEN** the context package shows sleep under 4 hours, high blood pressure, or symptom evidence
- **THEN** the workflow includes deterministic safety hints in the analysis input
- **THEN** the final training recommendation is conservative and explains the evidence behind that caution

#### Scenario: No usable context is retrieved
- **WHEN** every required and optional context source returns no usable evidence
- **THEN** the workflow returns a validated text or report response explaining that no matching patient data is available
- **THEN** the workflow does not invent patient-specific conclusions

### Requirement: Multi-table analysis is traceable
The health assistant SHALL record trace metadata for multi-table planning, validation, execution, and missing-context behavior.

#### Scenario: Context plan succeeds partially
- **WHEN** a context plan has both successful and missing sources
- **THEN** trace metadata includes selected tables, per-table row counts, missing-context reasons, validation attempt counts, and execution status

#### Scenario: Context plan falls back
- **WHEN** the workflow falls back because required context cannot be validated or retrieved
- **THEN** trace metadata includes the failed stage, failed query ids or tables, and fallback reason
