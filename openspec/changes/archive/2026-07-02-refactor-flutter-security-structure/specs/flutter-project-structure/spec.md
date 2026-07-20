## ADDED Requirements

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
