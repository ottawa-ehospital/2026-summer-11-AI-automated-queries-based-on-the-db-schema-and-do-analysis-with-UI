## Context

The Flutter app lives under `src/app` and currently keeps most user-facing code in `lib/Screens` and `lib/Services`. This works at runtime, but the uppercase directory names and broad screen files do not match common Dart package layout. AI provider configuration is also centralized in `lib/config/api_config.dart`, where Gemini and Fitbit credentials are currently stored as source constants.

The app needs to support two AI modes:
- Gemini for production-like behavior.
- Ollama/Llama for local testing.

It also needs to avoid committing real API keys, OAuth client secrets, or long-lived tokens.

## Goals / Non-Goals

**Goals:**
- Normalize Flutter code organization without changing user-visible behavior.
- Keep AI provider selection explicit and easy to switch between Gemini and Ollama.
- Remove real secrets from committed Dart source.
- Provide a repeatable local development path for required config values.
- Preserve existing login, vitals, assistant, Fitbit, and dashboard flows.

**Non-Goals:**
- Rewriting the whole Flutter app architecture.
- Migrating to a state-management framework such as Riverpod, Bloc, or Provider.
- Building a production backend secret broker in this change.
- Changing the eHospital backend API contract.
- Rotating leaked credentials; that must be handled outside this code change.

## Decisions

1. Use lowercase Dart directories and compatibility-preserving imports.

   Dart package conventions favor lowercase paths. The implementation will rename `Screens` to `screens` and `Services` to `services`, then update imports. This is a mechanical refactor and must avoid changing widget behavior.

   Alternative considered: leave directory names as-is and only add linting. This keeps the diff smaller but leaves the project in a non-standard shape.

2. Introduce an AI service boundary.

   Screens will call a local service abstraction for text generation rather than directly constructing provider clients. The service will select Gemini or Ollama based on configuration.

   Alternative considered: keep separate `OllamaService` and direct Gemini calls in screens. That duplicates provider logic and makes testing harder.

3. Use compile-time environment variables for sensitive Flutter client config.

   `ApiConfig` will read values from `String.fromEnvironment`, for example `GEMINI_API_KEY`, `FITBIT_CLIENT_ID`, and `FITBIT_CLIENT_SECRET`. Non-sensitive local defaults, such as Ollama base URL and model, may stay in source.

   Alternative considered: use a checked-in `.env` parser. Flutter web/mobile still bundles values into the client, and adding env-file parsing creates another dependency without solving runtime secrecy.

4. Add an ignored local defines template for developer ergonomics.

   The repository will include an example file documenting required `--dart-define` keys, while real local values stay ignored. README/tasks will show how to run with those values.

   Alternative considered: keep real credentials in `api_config.dart`. This is convenient but unsafe and makes accidental credential exposure likely.

## Risks / Trade-offs

- Renaming folders can break imports on case-insensitive Windows/macOS filesystems → Use a careful two-step rename if needed and verify with `flutter analyze` and `flutter build web`.
- `--dart-define` secrets are still shipped to Flutter clients → Treat this as safer source control hygiene, not complete production secrecy. Production-grade protection requires backend-mediated token exchange.
- Removing hard-coded secrets may break local runs until developers provide defines → Add clear README instructions and safe fallback errors.
- Existing leaked keys may already be compromised → Rotate Gemini/Fitbit credentials outside this refactor.

## Migration Plan

1. Add `AiService` provider abstraction while preserving current behavior.
2. Change `ApiConfig` to read sensitive values from compile-time environment variables.
3. Add local config examples and ignore real local config files.
4. Rename Flutter directories to lowercase and update imports.
5. Run `flutter pub get`, `flutter analyze`, and `flutter build web`.
6. Manually verify login, assistant, vitals summaries, trend insights, and Fitbit connect screens.
