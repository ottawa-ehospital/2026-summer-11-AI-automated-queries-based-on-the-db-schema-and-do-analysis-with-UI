## ADDED Requirements

### Requirement: Health Goals uses a repository for training records
Health Goals SHALL retrieve training records through a reusable repository or service boundary instead of constructing remote table URLs or parsing transport responses directly in the screen widget.

#### Scenario: Screen loads training records
- **WHEN** Health Goals needs workout history for the current patient
- **THEN** it calls a repository or service method with the patient id
- **THEN** endpoint path construction, response normalization, and row parsing happen outside `HealthGoalsScreen`

#### Scenario: Repository normalizes remote response shapes
- **WHEN** the remote workout-history source returns either a raw list or a wrapped response shape
- **THEN** the repository normalizes the response into typed training records for callers
- **THEN** Health Goals receives a consistent success or error result

### Requirement: Training Records API behavior has tests
The Flutter API layer SHALL include tests for training record retrieval and response parsing.

#### Scenario: Repository request is tested
- **WHEN** tests fetch training records through the repository with a fake API client
- **THEN** they verify the expected remote path or backend endpoint and patient id query are used
- **THEN** they verify records are parsed into typed models

#### Scenario: Repository error is tested
- **WHEN** the remote source returns an error or malformed response in tests
- **THEN** the repository exposes a consistent failure for Health Goals
- **THEN** the screen does not need to inspect HTTP status codes or raw response shapes
