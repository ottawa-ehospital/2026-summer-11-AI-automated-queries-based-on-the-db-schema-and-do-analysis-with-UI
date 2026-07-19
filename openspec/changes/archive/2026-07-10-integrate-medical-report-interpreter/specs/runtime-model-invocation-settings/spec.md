## ADDED Requirements

### Requirement: Report interpreter uses backend model configuration
Report interpreter model calls SHALL use the current backend model configuration path rather than a separate extracted-app Ollama configuration.

#### Scenario: Report analysis invokes configured backend model
- **WHEN** the backend analyzes an uploaded report
- **THEN** the model invocation uses backend settings or request-supported invocation behavior consistent with the existing assistant backend
- **THEN** the backend does not require a separate report-interpreter-only `OLLAMA_URL` global

#### Scenario: Report follow-up chat invokes configured backend model
- **WHEN** the backend answers a report follow-up question
- **THEN** the model invocation uses the same configured backend model path as report analysis

### Requirement: Report interpreter avoids client-side model secrets
The Flutter report interpreter SHALL NOT require client-side model credentials to analyze reports.

#### Scenario: User analyzes report from Flutter
- **WHEN** Flutter submits a report for analysis
- **THEN** the request is mediated by the backend report interpreter endpoint
- **THEN** provider credentials remain backend-owned or externally configured
