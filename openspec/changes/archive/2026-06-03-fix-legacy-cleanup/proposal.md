## Why

The previous architecture refactor made the Flutter and backend structure much cleaner, but it intentionally left a few legacy cleanup problems behind. Some migrated Flutter files still contain mojibake comments and legacy helper functions that are hard to trust, making future work slower and noisier than it needs to be.

## What Changes

- Clean corrupted source comments and visible developer-facing text in migrated legacy Flutter files.
- Add concise code comments where legacy cleanup would otherwise remove useful context, especially around API clients, repositories, backend routers, and request/response boundaries.
- Normalize affected Dart source files to UTF-8 and add a lightweight check so mojibake does not quietly return.
- Repair legacy helper functions that still carry unused variables, unreachable branches, stale assumptions, or fragile parsing after the architecture move.
- Keep UI behavior, route names, backend contracts, and repository/service boundaries stable.
- Reduce analyzer warnings in touched legacy files where the warning points to a real stale function or broken cleanup, without attempting a full style-only lint pass.

## Capabilities

### New Capabilities

- `source-text-hygiene`: Ensures legacy source comments and developer-facing text remain readable, UTF-8 encoded, and free from known mojibake patterns.
- `legacy-function-reliability`: Ensures migrated legacy Flutter helper functions remain valid after the feature/repository refactor and are covered by focused analyzer/build checks.

### Modified Capabilities

None.

## Impact

- Affected code:
  - `src/app/lib/features/**`
  - `src/app/lib/core/**`
  - `src/app/lib/data/**`
  - `src/app/lib/services/**`
  - `src/backend/api/**`
  - `src/backend/clients/**`
  - `src/backend/services/**`
  - scripts or tasks used for validation if a text hygiene check is added
- Affected workflows:
  - Flutter analyze/test/build verification
  - OpenSpec cleanup task tracking
- No expected API, route, backend endpoint, or data schema changes.
