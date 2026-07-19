## MODIFIED Requirements

### Requirement: Backend emits startup readiness logs
The Python FastAPI backend SHALL emit a concise application-level log after startup completes, including the backend name and relevant runtime settings needed to confirm the service is ready.

#### Scenario: Backend startup completes
- **WHEN** the FastAPI startup lifecycle completes
- **THEN** the backend logs that the Smart Health backend is ready
- **AND** the log includes host, port, eHospital base URL, eHospital auth base URL, assistant provider, model provider, and model name
