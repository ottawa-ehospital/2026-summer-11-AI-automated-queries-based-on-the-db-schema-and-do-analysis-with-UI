## Why

AI model invocation is currently determined by deployment-time configuration, which makes it awkward to switch between local and remote models while using the app. Adding user-editable model invocation settings gives developers and testers a direct way to choose how assistant calls are routed without rebuilding or redeploying.

## What Changes

- Add a Flutter Settings extension for configuring model invocation preferences, including provider mode, model name, endpoint/base URL where applicable, and whether the backend should use a graph-backed or direct provider flow.
- Persist the selected model invocation settings locally in Flutter so assistant, vitals summary, and trend insight requests can include the active preferences.
- Extend backend assistant request schemas to accept optional invocation parameters.
- Update backend assistant provider selection so request parameters can choose among supported model invocation modes while preserving deployment defaults as fallbacks.
- Add validation and clear errors for unsupported providers or incomplete runtime settings.

## Capabilities

### New Capabilities
- `runtime-model-invocation-settings`: User-facing and API-facing configuration for choosing model invocation behavior at runtime.

### Modified Capabilities
- `backend-backed-ai-assistant`: Assistant endpoints accept optional runtime model invocation parameters and route calls through the requested backend provider when valid.

## Impact

- Flutter settings feature under `src/app/lib/features/settings/`.
- Flutter persisted configuration and request wiring under `src/app/lib/config/`, `src/app/lib/data/models/`, and `src/app/lib/data/repositories/`.
- Python backend assistant schemas, routes, services, and provider factory under `src/backend/`.
- Tests for Flutter configuration persistence/request payloads and Python backend provider selection/validation.
