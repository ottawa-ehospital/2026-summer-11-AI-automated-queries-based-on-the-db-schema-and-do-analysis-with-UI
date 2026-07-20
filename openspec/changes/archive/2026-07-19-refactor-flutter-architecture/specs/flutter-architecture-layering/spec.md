## ADDED Requirements

### Requirement: Flutter code uses layered ownership boundaries
The Flutter app SHALL separate runtime configuration, shared infrastructure, data access, reusable UI, and feature-specific presentation into distinct directories with clear ownership boundaries.

#### Scenario: Project structure is reviewed
- **WHEN** a developer inspects `src/app/lib`
- **THEN** shared configuration, network helpers, repositories/models, reusable widgets, and feature folders are identifiable without reading screen implementation details

### Requirement: Feature screens do not own cross-cutting infrastructure
Feature screen widgets SHALL NOT construct remote API URLs, parse raw HTTP responses, or contain backend prompt orchestration logic.

#### Scenario: Screen handles a backend-backed action
- **WHEN** a screen needs assistant, vitals, trend, auth, or eHospital data
- **THEN** it calls a controller, repository, or API layer method rather than using raw HTTP directly

### Requirement: Imports follow dependency direction
Flutter imports SHALL flow from features to data/core/config layers, and shared core/data layers SHALL NOT import feature screens.

#### Scenario: Shared network client is inspected
- **WHEN** a developer opens a shared network or repository file
- **THEN** it does not import screen widgets or feature presentation files

### Requirement: Existing user flows remain stable
The refactor SHALL preserve existing visible route behavior for login, dashboard navigation, health assistant, vitals, trend comparison, settings, and profile entry points.

#### Scenario: App is smoke tested after refactor
- **WHEN** a user logs in and navigates through the existing dashboard entry points
- **THEN** the same screens remain reachable with equivalent visible behavior
