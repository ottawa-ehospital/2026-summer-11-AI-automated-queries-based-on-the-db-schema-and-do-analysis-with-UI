## Why

The imported Flutter app currently mixes naming conventions, broad screen files, direct AI/provider configuration, and hard-coded client secrets in source control. This makes the app harder to maintain and creates avoidable security risk, especially around Gemini and Fitbit credentials.

## What Changes

- Refactor Flutter source layout toward standard Dart conventions:
  - Use lowercase directory names such as `screens/`, `services/`, `config/`, `ui/`.
  - Keep imports consistent after folder renames.
  - Extract shared AI calling logic behind a service boundary instead of calling provider SDKs directly from screens.
- Replace hard-coded sensitive values in `lib/config/api_config.dart` with a safer configuration strategy:
  - Keep non-sensitive defaults in source.
  - Load secrets through compile-time environment values or another non-committed local configuration path.
  - Add a template/example file documenting required keys without real secrets.
- Preserve current behavior:
  - Gemini configuration remains available for production usage.
  - Ollama/Llama remains available for local testing.
  - Fitbit integration continues to use configured client credentials.
- Update documentation so developers know how to run the app with local test config and production-like config.

## Capabilities

### New Capabilities
- `flutter-project-structure`: Defines maintainable Flutter project organization, naming conventions, and service boundaries for AI-related calls.
- `secure-client-configuration`: Defines how sensitive API keys, OAuth client secrets, and provider selection are configured without committing real credentials.

### Modified Capabilities

## Impact

- Affected Flutter code under `src/app/lib`.
- Affected configuration files under `src/app/lib/config`, `src/app/pubspec.yaml`, `src/app/.gitignore`, and `src/app/README.md`.
- May require updating import paths after directory normalization.
- May require developers to pass `--dart-define` values or create local ignored config before running production providers.
