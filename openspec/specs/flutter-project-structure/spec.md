# flutter-project-structure Specification

## Purpose
TBD - created by archiving change refactor-flutter-security-structure. Update Purpose after archive.
## Requirements
### Requirement: Dart source directories follow Flutter conventions
The Flutter app SHALL organize Dart source under lowercase directories for screens, services, configuration, UI, models, and shared widgets.

#### Scenario: Source tree uses lowercase feature folders
- **WHEN** a developer inspects `src/app/lib`
- **THEN** user-facing screens are located under `screens`
- **THEN** service classes are located under `services`
- **THEN** shared configuration remains under `config`

#### Scenario: Imports remain valid after directory normalization
- **WHEN** the Flutter analyzer runs
- **THEN** renamed directory imports resolve without missing-file errors

### Requirement: AI generation is accessed through a service boundary
Flutter screens SHALL request AI-generated text through a shared AI service instead of directly constructing provider-specific SDK clients in widget classes.

#### Scenario: Health assistant sends a prompt
- **WHEN** the health assistant needs an AI response
- **THEN** it calls the shared AI service with the user prompt and optional system prompt
- **THEN** the screen does not directly instantiate a Gemini or Ollama client

#### Scenario: Vitals and trends generate summaries
- **WHEN** vitals or trend screens need AI summaries
- **THEN** they call the same shared AI service used by the assistant
- **THEN** provider selection behavior is consistent across screens

### Requirement: Refactor preserves visible app behavior
The structure refactor SHALL preserve existing navigation routes, screen titles, data loading behavior, and user-visible AI features.

#### Scenario: Existing route opens
- **WHEN** a user navigates to an existing route such as `/assistant`, `/vitals`, or `/trends`
- **THEN** the same screen opens successfully after the refactor

#### Scenario: Existing health data views load
- **WHEN** a logged-in user opens vitals, trend comparison, dashboard, or profile screens
- **THEN** the app continues using the same eHospital data sources as before

### Requirement: Report interpreter follows feature-first structure
The integrated report interpreter UI SHALL live under the host app's feature-first Flutter structure instead of retaining the extracted standalone app entry point.

#### Scenario: Feature directory exists
- **WHEN** a developer inspects `src/app/lib/features`
- **THEN** report interpreter source is organized under `features/report_interpreter`
- **THEN** report interpreter screens, models, data access, widgets, and presentation helpers have clear feature ownership

#### Scenario: Standalone main is not imported as app shell
- **WHEN** the report interpreter is integrated
- **THEN** the host app does not replace `src/app/lib/main.dart` with the extracted project's `main.dart`
- **THEN** the extracted standalone app shell is not used as the Smart Health app shell

### Requirement: Existing route behavior remains stable
The integration SHALL preserve existing Smart Health routes while adding the report interpreter as an AI module or optional route.

#### Scenario: Existing assistant route opens
- **WHEN** a user navigates to `/assistant`
- **THEN** the AI assistant area opens successfully
- **THEN** the existing Health Chat experience remains available

### Requirement: Urgent-care feature follows host Flutter structure
The urgent-care integration SHALL live under the host app's feature-first Flutter structure instead of retaining CareFlow's separate patient Flutter app entry point or migrating CareFlow's staff web dashboard.

#### Scenario: Feature directory owns urgent-care code
- **WHEN** a developer inspects `src/app/lib/features`
- **THEN** urgent-care source is organized under `features/urgent_care`
- **AND** urgent-care screens, models, data access, widgets, and presentation helpers have clear feature ownership

#### Scenario: Standalone CareFlow app shells are not imported
- **WHEN** urgent-care screens are integrated
- **THEN** the host app does not replace `src/app/lib/main.dart` with CareFlow's `patient_app/lib/main.dart`
- **AND** the host app does not replace `src/app/lib/main.dart` with CareFlow's `flutter_frontend/lib/main.dart`
- **AND** the downloaded standalone Flutter projects are not copied into `src/app` as runnable nested apps

#### Scenario: Staff dashboard UI is not added
- **WHEN** urgent-care is integrated into the Flutter app
- **THEN** staff web dashboard screens from CareFlow are not recreated as mobile routes
- **AND** the feature contains patient-facing screens only

#### Scenario: Existing route behavior remains stable
- **WHEN** urgent-care routes are added
- **THEN** existing routes such as `/dashboard`, `/emergency`, `/assistant`, `/vitals`, `/goals`, and `/settings` continue to open successfully

