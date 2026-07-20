# Legacy Function Reliability

## Purpose

Reliability constraints for cleaning up migrated helper functions while preserving existing app routes and API contracts.

## Requirements

### Requirement: Legacy helper functions remain behaviorally valid after migration
Migrated legacy helper functions SHALL be updated when they rely on stale paths, stale service assumptions, unused branch state, or parsing logic made obsolete by the previous repository refactor.

#### Scenario: Stale helper is repaired
- **WHEN** a migrated helper still performs work that now belongs to a repository/service layer or references a moved file boundary incorrectly
- **THEN** the helper is updated to use the accepted feature/core/data/service structure

#### Scenario: Unused legacy locals are removed
- **WHEN** analyzer reports an unused local variable in touched legacy code
- **THEN** the variable is removed or the function is adjusted so the value is intentionally used

### Requirement: Feature behavior remains stable
Legacy function cleanup MUST NOT change existing route names, page entry points, backend endpoint contracts, or remote eHospital table contracts.

#### Scenario: Existing routes still compile
- **WHEN** the Flutter app is analyzed after cleanup
- **THEN** all existing route widgets referenced by `main.dart` resolve through the feature structure

#### Scenario: Existing backend contracts are unchanged
- **WHEN** Flutter repositories and backend endpoints are inspected after cleanup
- **THEN** no cleanup-only change requires a new API path, request shape, or response shape

#### Scenario: API comments do not redefine contracts
- **WHEN** comments are added around API-facing code
- **THEN** the comments describe existing behavior and MUST NOT imply a new request or response contract

### Requirement: Cleanup is verified with focused checks
The implementation MUST verify the cleanup with the existing Flutter checks and any added text hygiene check.

#### Scenario: Flutter checks pass without new errors
- **WHEN** `flutter analyze` and `flutter test` are run after cleanup
- **THEN** they complete without new compile or test failures

#### Scenario: Web build still succeeds
- **WHEN** the Flutter web build is run with backend provider defines
- **THEN** the app builds successfully
