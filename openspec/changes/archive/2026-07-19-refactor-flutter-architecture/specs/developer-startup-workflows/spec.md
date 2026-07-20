## ADDED Requirements

### Requirement: Startup scripts expose backend workflows
The project SHALL provide `tasks.ps1` and Makefile commands for starting the Python backend with and without reload.

#### Scenario: Developer starts backend locally
- **WHEN** a developer runs the documented backend dev command
- **THEN** the command starts uvicorn against the canonical `src/backend` app entry point

### Requirement: Startup scripts expose Flutter backend-provider workflows
The project SHALL provide `tasks.ps1` and Makefile commands for launching Flutter with `AI_PROVIDER=backend` and configurable `BACKEND_BASE_URL`.

#### Scenario: Developer starts Flutter against local backend
- **WHEN** a developer runs the documented Flutter backend command
- **THEN** Flutter starts with backend-provider Dart defines without manually repeating every define

### Requirement: Startup scripts document local model workflows
The project SHALL provide or document commands for local Ollama/model checks used by the backend AI workflow.

#### Scenario: Developer checks local model availability
- **WHEN** a developer follows the documented local model test command
- **THEN** they can confirm whether the expected local model is available before starting AI-backed flows

### Requirement: PowerShell and Makefile names remain aligned
The project SHALL keep equivalent PowerShell and Makefile workflow names aligned where both are provided.

#### Scenario: Developer switches between Windows tasks and Makefile
- **WHEN** the developer compares task names
- **THEN** backend, Flutter backend, web CORS/dev, and verification workflows are recognizable across both script systems

### Requirement: Documentation explains environment-specific backend URLs
The project documentation SHALL explain backend URL differences for local desktop/web, Android emulator, physical phone, and deployed backend use.

#### Scenario: Developer runs Flutter on Android emulator
- **WHEN** the developer reads the startup documentation
- **THEN** they can identify when to use `10.0.2.2` instead of `127.0.0.1`
