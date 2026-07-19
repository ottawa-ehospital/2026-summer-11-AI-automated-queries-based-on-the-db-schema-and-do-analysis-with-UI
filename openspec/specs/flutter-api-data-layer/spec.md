# flutter-api-data-layer Specification

## Purpose
TBD - created by archiving change refactor-flutter-architecture. Update Purpose after archive.
## Requirements
### Requirement: Centralized backend API access
The Flutter app SHALL centralize calls to the Python assistant backend through a dedicated API client or repository layer.

#### Scenario: Health assistant sends a message
- **WHEN** the Health Assistant requests an AI response
- **THEN** the request is sent through the centralized assistant API layer with the current patient identifier

### Requirement: Centralized eHospital API access
The Flutter app SHALL centralize eHospital table reads and wearable vitals uploads through a repository or API client layer.

#### Scenario: Vitals screen loads remote table data
- **WHEN** the Vitals screen needs wearable, ECG, or vitals history data
- **THEN** it obtains the data from the eHospital data layer rather than constructing table URLs inside the screen

### Requirement: API errors use a consistent model
The Flutter API layer SHALL map backend and eHospital failures into consistent app-level errors that UI code can display without parsing HTTP details.

#### Scenario: Backend returns an error
- **WHEN** the assistant backend returns an error response or cannot be reached
- **THEN** the UI receives a consistent error message from the API/data layer

### Requirement: Data models are parsed outside screens
The Flutter app SHALL parse non-trivial backend and eHospital response shapes into typed models or normalized maps outside screen widgets.

#### Scenario: Trend insights are loaded
- **WHEN** trend insight data is returned by the backend
- **THEN** parsing and validation happen in the data layer before the screen renders the result

