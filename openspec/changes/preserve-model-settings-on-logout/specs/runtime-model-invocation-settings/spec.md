## ADDED Requirements

### Requirement: Logout preserves model invocation settings
The Flutter app SHALL preserve saved runtime model invocation settings when a user logs out.

#### Scenario: User logs out after saving model invocation settings
- **WHEN** a user has saved runtime model invocation settings and confirms logout from Settings
- **THEN** Flutter clears the active patient session
- **THEN** the saved runtime model invocation settings remain locally available

#### Scenario: User signs in again after logout
- **WHEN** a user logs out after saving runtime model invocation settings and later opens the model invocation settings page
- **THEN** Flutter displays the previously saved provider mode, model name, endpoint/base URL, and graph/direct flow values

#### Scenario: Model invocation settings are explicitly reset
- **WHEN** a user explicitly resets or clears runtime model invocation settings through the model invocation settings flow
- **THEN** Flutter removes the saved runtime model invocation settings
