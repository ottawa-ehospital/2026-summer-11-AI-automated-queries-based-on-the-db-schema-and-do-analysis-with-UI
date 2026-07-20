## Why

Logging out currently clears all local Flutter preferences, which also removes the saved model invocation profile. Users who switch between local and remote model configurations should not have to re-enter those non-secret settings after every account logout.

## What Changes

- Change Flutter logout behavior so it clears account/session-specific local state without deleting saved model invocation settings.
- Keep the post-logout navigation behavior unchanged: users return to the login route after confirming logout.
- Preserve the existing ability to explicitly reset model invocation settings from the model invocation store or settings flow.
- Add focused Flutter coverage proving logout removes the patient session while retaining the saved model invocation profile.

## Capabilities

### New Capabilities
- `runtime-model-invocation-settings`: User-facing runtime model invocation settings remain locally persisted across account logout unless explicitly cleared.

### Modified Capabilities

## Impact

- Flutter settings logout flow under `src/app/lib/features/settings/`.
- Flutter auth/session persistence under `src/app/lib/data/repositories/` or a small local session clearing helper if needed.
- Existing model invocation persistence under `src/app/lib/data/repositories/model_invocation_settings_store.dart`.
- Flutter tests for SharedPreferences-backed logout/session clearing behavior.
