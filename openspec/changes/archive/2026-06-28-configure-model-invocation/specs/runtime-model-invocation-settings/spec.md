## ADDED Requirements

### Requirement: Settings exposes model invocation configuration
The Flutter Settings feature SHALL provide a model invocation configuration page reachable from the Settings screen.

#### Scenario: User opens model invocation settings
- **WHEN** a user taps the model invocation settings entry from the Settings screen
- **THEN** Flutter shows a page for choosing the assistant provider mode and model invocation details

#### Scenario: Current selection is visible
- **WHEN** the model invocation settings page is opened after a saved configuration exists
- **THEN** Flutter displays the saved provider mode, model name, and endpoint/base URL values

### Requirement: Model invocation settings are persisted locally
Flutter SHALL persist the active model invocation settings locally so the selected behavior survives app restarts.

#### Scenario: User saves settings
- **WHEN** a user changes the provider mode or model invocation details and saves
- **THEN** Flutter stores the settings locally
- **THEN** subsequent assistant requests use the saved settings

#### Scenario: No settings have been saved
- **WHEN** no local model invocation settings exist
- **THEN** Flutter uses the configured defaults without requiring the user to visit Settings

### Requirement: Assistant requests include active invocation settings
Flutter assistant repositories SHALL include the active model invocation settings in backend assistant requests when a profile is saved.

#### Scenario: Chat request uses saved invocation settings
- **WHEN** a user sends a Health Assistant chat message after saving model invocation settings
- **THEN** Flutter sends the active invocation settings with the assistant chat request

#### Scenario: Summary requests use saved invocation settings
- **WHEN** Flutter requests vitals summaries or trend insights after saving model invocation settings
- **THEN** Flutter sends the active invocation settings with those backend assistant requests

### Requirement: Settings avoid storing model secrets
The model invocation settings page SHALL NOT persist API keys or provider secrets as plain local preferences.

#### Scenario: User configures remote model invocation
- **WHEN** a user selects a remote model invocation mode
- **THEN** Flutter allows non-secret fields such as provider mode, model name, and endpoint/base URL to be saved
- **THEN** backend-owned credentials remain configured outside the Flutter local settings profile
