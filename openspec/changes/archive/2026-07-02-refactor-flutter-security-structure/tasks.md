## 1. Secure Configuration

- [x] 1.1 Replace hard-coded Gemini API key, Fitbit client id, and Fitbit client secret in `src/app/lib/config/api_config.dart` with `String.fromEnvironment` readers.
- [x] 1.2 Keep Ollama test defaults configurable through `OLLAMA_BASE_URL` and `OLLAMA_MODEL`, with safe local defaults.
- [x] 1.3 Add developer-facing validation helpers or clear error messages for missing provider credentials.
- [x] 1.4 Add an ignored local defines/config pattern and a committed example file with placeholder values only.
- [x] 1.5 Update `src/app/README.md` with `flutter run --dart-define` examples for Ollama test mode and Gemini/Fitbit configured mode.

## 2. AI Service Boundary

- [x] 2.1 Add a shared AI generation service that selects Gemini or Ollama based on `ApiConfig.aiProvider`.
- [x] 2.2 Move Ollama HTTP generation into the shared AI service or keep it as a provider adapter behind that service.
- [x] 2.3 Restore Gemini support behind the same service without exposing Gemini setup in screen widgets.
- [x] 2.4 Update health assistant, vitals, and trend comparison screens to call the shared AI service.
- [x] 2.5 Ensure provider labels in UI reflect the configured provider without hard-coded Gemini-only text.

## 3. Flutter Structure Normalization

- [x] 3.1 Rename `src/app/lib/Screens` to `src/app/lib/screens`.
- [x] 3.2 Rename `src/app/lib/Services` to `src/app/lib/services`.
- [x] 3.3 Update all Dart imports to use lowercase paths.
- [x] 3.4 Scan for remaining uppercase app-owned import paths and stale folder references.
- [x] 3.5 Keep route names, screen class names, and user-visible navigation behavior unchanged.

## 4. Security Cleanup

- [x] 4.1 Search Flutter source and documentation for real API keys, OAuth secrets, and token values.
- [x] 4.2 Remove any real credentials found in committed files and replace them with placeholders or environment reads.
- [x] 4.3 Document that previously committed keys should be rotated outside this code change.
- [x] 4.4 Confirm runtime Fitbit access/refresh tokens remain stored only in local `SharedPreferences`, not source files.

## 5. Verification

- [x] 5.1 Run `flutter pub get` in `src/app`.
- [x] 5.2 Run `flutter analyze` and confirm there are no new missing-import or provider configuration errors.
- [x] 5.3 Run `flutter build web` to verify the refactored app compiles.
- [x] 5.4 Run a local Ollama test using `AI_PROVIDER=ollama`.
- [x] 5.5 Verify Gemini-configured mode fails clearly when no `GEMINI_API_KEY` is supplied and initializes when one is supplied.
- [x] 5.6 Manually smoke test login, dashboard, assistant, vitals summaries, trend insights, and Fitbit connection entry points.
