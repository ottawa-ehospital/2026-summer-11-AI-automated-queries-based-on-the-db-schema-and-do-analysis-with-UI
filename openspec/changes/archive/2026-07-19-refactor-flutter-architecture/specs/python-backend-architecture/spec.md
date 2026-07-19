## ADDED Requirements

### Requirement: Backend code is organized under src/backend
The Python backend SHALL place its primary FastAPI app, routers, schemas, clients, services, and core configuration under the `src/backend` package.

#### Scenario: Backend package is inspected
- **WHEN** a developer opens `src/backend`
- **THEN** API routing, service orchestration, remote clients, request/response schemas, and configuration are separated into identifiable modules

### Requirement: FastAPI routers do not own orchestration logic
FastAPI router modules SHALL validate requests and delegate assistant, patient context, vitals, and trend workflows to backend service modules.

#### Scenario: Assistant chat endpoint is inspected
- **WHEN** a developer opens the assistant router
- **THEN** the router delegates context aggregation and model invocation to service/client layers rather than implementing the full workflow inline

### Requirement: Remote eHospital access is isolated in a backend client
The Python backend SHALL isolate remote eHospital table reads and patient-scoped filtering in a dedicated client or service boundary.

#### Scenario: Patient context is built
- **WHEN** the backend aggregates wearable, ECG, vitals history, lab, diagnosis, and risk-analysis data
- **THEN** remote HTTP access is performed through the backend eHospital client boundary

### Requirement: Model provider access is isolated in a backend client
The Python backend SHALL isolate model invocation behind a model client or assistant service boundary that can support local Ollama testing and future production-like providers.

#### Scenario: LangGraph is added later
- **WHEN** a LangGraph graph replaces or extends assistant orchestration
- **THEN** the public FastAPI request and response contracts can remain unchanged

### Requirement: Old backend entry points remain compatible during migration
Existing backend entry points SHALL either delegate to the new `src/backend` package or be updated through scripts/tests without breaking documented startup commands.

#### Scenario: Existing uvicorn command is used during migration
- **WHEN** a developer runs a previously documented backend command
- **THEN** it either still starts the backend app or the documentation and scripts provide the replacement command

### Requirement: Backend tests cover package-level behavior
Backend tests SHALL cover the new backend package app wiring, assistant chat, vitals summary, trend insights, invalid patient id, and remote/model failure handling where practical.

#### Scenario: Backend tests run
- **WHEN** Python backend tests are executed
- **THEN** they validate the new package structure behavior without requiring a live remote eHospital server or real model call
