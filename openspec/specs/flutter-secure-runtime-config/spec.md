# flutter-secure-runtime-config Specification

## Purpose
TBD - created by archiving change refactor-flutter-architecture. Update Purpose after archive.
## Requirements
### Requirement: Runtime configuration is centralized
The Flutter app SHALL expose backend URL, eHospital URL, AI provider, model settings, and local testing values through centralized configuration helpers.

#### Scenario: Backend URL is changed for local testing
- **WHEN** a developer passes `BACKEND_BASE_URL` through Dart defines
- **THEN** Flutter API clients use that value without code changes in screens

### Requirement: Secret-like values are not committed in Flutter source
The Flutter app SHALL NOT require committed Dart source files to contain API tokens, Gemini keys, backend secrets, or other secret-like production credentials.

#### Scenario: Repository source is inspected
- **WHEN** a developer searches tracked Flutter source files
- **THEN** no production token or required secret is hard-coded in config, service, screen, or widget files

### Requirement: Local configuration examples are safe
Configuration examples SHALL document required keys and local values without exposing real secrets.

#### Scenario: Developer opens example config
- **WHEN** a developer reads `dart_defines.example.json` or README setup instructions
- **THEN** placeholders or local demo values are shown instead of real secret values

### Requirement: Client-side security limitation is documented
The app documentation SHALL state that Flutter client-side values are not secure secret storage and production secret-bearing calls should be mediated by a backend.

#### Scenario: Developer reads AI configuration docs
- **WHEN** the docs describe model provider or API key configuration
- **THEN** they explain that mobile/web client secrets are not considered secure

