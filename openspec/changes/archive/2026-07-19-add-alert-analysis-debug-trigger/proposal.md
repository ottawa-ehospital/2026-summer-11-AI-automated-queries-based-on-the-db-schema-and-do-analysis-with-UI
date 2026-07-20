## Why

Apple Health alert analysis already has ingestion, decision history, and notification behavior, but developers need a deterministic way to exercise the end-to-end flow without waiting for real HealthKit delivery on a device. Adding debug triggers to Alert Decision History makes it easy to verify both the valid-data notification path and the abnormal blood-pressure analysis path during local testing and demos.

## What Changes

- Add a debug-only "Test Alert Analyse" action to the Alert Decision History screen.
- Provide two debug scenarios:
  - a normal Apple Health sync simulation that proves valid HealthKit data was received and dispatches a clearly labeled debug notification.
  - an abnormal declining blood-pressure scenario that simulates repeated HealthKit sync events, includes antihypertensive medication context, routes through alert analysis, and can produce a medication-adherence reminder notification.
- Ensure injected debug events use the same alert-analysis and notification decision path as native HealthKit events, while remaining clearly labeled as test/debug data in notifications and decision history.
- Add tests covering the debug trigger UI, scenario injection, decision-history records, and notification behavior.

## Capabilities

### New Capabilities

- None.

### Modified Capabilities

- `healthkit-alert-analysis`: Adds developer-facing debug triggers from Alert Decision History for normal HealthKit sync notification testing and abnormal blood-pressure analysis notification testing.

## Impact

- Flutter Settings debug UI under `src/app/lib/features/settings/screens/alert_decision_history_screen.dart`.
- Flutter alert services under `src/app/lib/services/health_alert_service.dart` and related coordinator or repository boundaries.
- Local notification dispatch and alert decision history storage.
- Existing Flutter widget/unit tests for alert decision history and health alert service.
- Potential backend alert-analysis fixtures or request options if the abnormal scenario needs deterministic medication-context analysis in development.
