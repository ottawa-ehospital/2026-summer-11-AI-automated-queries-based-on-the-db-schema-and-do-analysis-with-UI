## ADDED Requirements

### Requirement: Backend emits startup readiness logs
The Python FastAPI backend SHALL emit a concise application-level log after startup completes, including the backend name and relevant runtime settings needed to confirm the service is ready.

#### Scenario: Backend startup completes
- **WHEN** the FastAPI startup lifecycle completes
- **THEN** the backend logs that the Smart Health backend is ready
- **AND** the log includes host, port, eHospital base URL, assistant provider, model provider, and model name

### Requirement: Backend logs API request execution
The Python FastAPI backend SHALL log each HTTP API request execution with safe request metadata and timing.

#### Scenario: API request completes successfully
- **WHEN** an HTTP request is handled by the backend
- **THEN** the backend logs the request method, URL path, response status code, and elapsed time
- **AND** the log does not include request bodies, response bodies, credentials, AI prompts, SQL text, or patient context payloads

#### Scenario: API request raises an exception
- **WHEN** an HTTP request raises an exception before a response is produced
- **THEN** the backend logs the request method, URL path, failure status indicator, and elapsed time
- **AND** the original exception handling behavior is preserved
