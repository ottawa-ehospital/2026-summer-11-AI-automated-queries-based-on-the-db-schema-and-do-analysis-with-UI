## ADDED Requirements

### Requirement: Flutter provides report interpreter feature module
The Flutter app SHALL provide a `report_interpreter` feature module for medical report upload, analysis display, saved record loading, and report-specific follow-up chat.

#### Scenario: User opens report interpreter module
- **WHEN** a logged-in user selects the report interpreter AI module
- **THEN** Flutter displays the report interpreter screen inside the Smart Health app shell
- **THEN** the screen follows the current app theme and does not launch a standalone extracted app shell
- **THEN** the screen remains a separate module option rather than merging report workflows into the Health Chat module
- **THEN** the screen preserves the report upload, saved record, analysis, and report follow-up behavior from the extracted app

#### Scenario: User uploads a report
- **WHEN** a user selects or drops a supported report file
- **THEN** Flutter uploads the file through the report interpreter repository
- **THEN** Flutter renders the returned analysis, report context, lab-value visuals, and save status
- **THEN** the upload flow uses report interpreter backend APIs rather than the existing health chat API

#### Scenario: User asks report follow-up question
- **WHEN** a user sends a follow-up question after a report analysis
- **THEN** Flutter sends the question and report context through the report interpreter repository
- **THEN** Flutter appends the report-specific assistant reply to the report session

### Requirement: Report interpreter uses active patient context
The Flutter report interpreter feature SHALL use the logged-in patient id for analysis, saved records, and optional record persistence.

#### Scenario: Patient id is available
- **WHEN** a logged-in patient opens the report interpreter
- **THEN** Flutter includes the active patient id in report analysis and saved record requests

#### Scenario: Patient id is unavailable
- **WHEN** no active patient id is available
- **THEN** Flutter shows a clear login-required or patient-context-required state
- **THEN** Flutter does not default to patient id `20`

### Requirement: Report interpreter source is cleaned before integration
The Flutter integration SHALL migrate only source files needed by the feature and SHALL NOT commit generated or duplicate extracted app artifacts.

#### Scenario: Generated extracted artifacts are excluded
- **WHEN** the extracted report interpreter project is integrated
- **THEN** generated folders such as `.dart_tool*` and `build*` are excluded
- **THEN** duplicate platform folders, `.DS_Store`, Python caches, and standalone app-only metadata are not added to the host Flutter app
