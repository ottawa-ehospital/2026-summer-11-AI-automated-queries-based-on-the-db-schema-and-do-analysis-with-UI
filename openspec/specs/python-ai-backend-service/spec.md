# python-ai-backend-service Specification

## Purpose
TBD - created by archiving change add-python-ai-backend-service. Update Purpose after archive.

## Requirements
### Requirement: Backend service exposes assistant APIs
The Python backend SHALL expose HTTP endpoints that Flutter can call for AI assistant chat, vitals summaries, and trend insights.

#### Scenario: Assistant chat request
- **WHEN** Flutter sends a valid patient id and user message to the backend assistant chat endpoint
- **THEN** the backend returns a JSON response containing an assistant reply
- **THEN** the reply is generated using backend-side patient context rather than Flutter-built context

#### Scenario: Vitals summary request
- **WHEN** Flutter requests an AI summary for a vitals metric and patient id
- **THEN** the backend returns a concise summary for that metric

#### Scenario: Trend insight request
- **WHEN** Flutter requests week-over-week trend insights for a patient id
- **THEN** the backend returns structured insights for steps, calories, heart rate, and sleep

### Requirement: Backend aggregates patient health context
The Python backend SHALL fetch and normalize patient context from the remote eHospital API for AI workflows.

#### Scenario: Context includes current tables
- **WHEN** the backend builds context for a patient id
- **THEN** it includes relevant wearable vitals, vitals history, ECG, diabetes analysis, heart disease analysis, and other required clinical tables where available

#### Scenario: Unknown patient id
- **WHEN** a request uses an unknown or invalid patient id
- **THEN** the backend returns a client-visible error without calling the AI model

### Requirement: Backend is LangGraph-ready
The Python backend SHALL structure assistant orchestration so future LangGraph nodes and tools can be added without changing Flutter request contracts.

#### Scenario: Future tool is added
- **WHEN** a new workout readiness or recommendation tool is added to the backend graph
- **THEN** Flutter continues calling the same assistant endpoint contract

#### Scenario: Local model provider is used
- **WHEN** the backend is configured for Ollama during local development
- **THEN** assistant endpoints generate responses using the local model provider
