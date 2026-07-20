## ADDED Requirements

### Requirement: Backend assistant coexists with report interpreter backend
The backend-backed health assistant SHALL continue to operate through its existing assistant routes after the report interpreter backend is added.

#### Scenario: Health assistant route remains available
- **WHEN** the report interpreter router is registered
- **THEN** `POST /assistant/chat` remains available
- **THEN** the response shape for health assistant chat remains compatible with the existing Flutter Health Chat module

### Requirement: AI area can route to specialized modules
The Flutter AI assistant area SHALL route users to separate AI modules, where Chat uses the existing backend-backed assistant API and Report Interpreter uses the isolated report interpreter API.

#### Scenario: User selects Health Chat module
- **WHEN** a user selects Health Chat in the AI module host
- **THEN** Flutter sends health chat messages through the existing assistant backend repository path
- **THEN** Flutter renders the existing chat conversation UI

#### Scenario: User selects Report Interpreter module
- **WHEN** a user selects Report Interpreter in the AI module host
- **THEN** Flutter sends report upload and report follow-up requests through the report interpreter backend namespace
- **THEN** Flutter renders the migrated report interpreter UI instead of the health chat conversation UI
