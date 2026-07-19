# secure-client-configuration Specification

## Purpose
TBD - created by archiving change refactor-flutter-security-structure. Update Purpose after archive.

## Requirements
### Requirement: Committed Dart source excludes real secrets
The Flutter app SHALL NOT commit real Gemini API keys, Fitbit client secrets, OAuth refresh tokens, or access tokens in Dart source files.

#### Scenario: Config file is inspected
- **WHEN** a developer opens `src/app/lib/config/api_config.dart`
- **THEN** real API keys and OAuth client secrets are absent
- **THEN** the file only contains non-sensitive defaults or environment variable readers

#### Scenario: Repository search for sensitive values
- **WHEN** a developer searches committed Flutter source for known real credentials
- **THEN** no real Gemini API key or Fitbit client secret appears

### Requirement: Sensitive config is supplied outside committed source
The Flutter app SHALL read sensitive client configuration from compile-time environment values or an ignored local configuration mechanism.

#### Scenario: App runs with Gemini provider
- **WHEN** the app is launched with `AI_PROVIDER=gemini` and a `GEMINI_API_KEY`
- **THEN** AI requests use Gemini configuration from the supplied environment values

#### Scenario: App runs with Ollama provider
- **WHEN** the app is launched with `AI_PROVIDER=ollama`
- **THEN** AI requests use local Ollama configuration without requiring a Gemini API key

#### Scenario: Fitbit credentials are required
- **WHEN** a Fitbit OAuth flow needs client credentials
- **THEN** the app reads the client id and client secret from supplied environment values
- **THEN** missing values fail with a clear developer-facing error instead of using committed secrets

### Requirement: Configuration documentation is available
The project SHALL document the required local configuration keys and provide an example that contains no real secrets.

#### Scenario: New developer configures the app
- **WHEN** a developer reads the app README or config example
- **THEN** they can identify the required `--dart-define` keys for Gemini, Ollama, and Fitbit
- **THEN** they are warned not to commit real credentials
