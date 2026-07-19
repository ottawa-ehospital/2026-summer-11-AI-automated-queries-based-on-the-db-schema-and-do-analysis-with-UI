## 1. Debug Scenario Service

- [x] 1.1 Add a `HealthAlertDebugScenarioRunner` service that accepts a patient id and routes injected events through `HealthAlertService.processEvent()`.
- [x] 1.2 Implement the normal Apple Health sync debug scenario with a valid supported HealthKit-style event and `validDataTestNotification=true`.
- [x] 1.3 Implement the abnormal blood-pressure debug scenario with repeated falling blood-pressure readings, test/simulation source mode, scenario metadata, and antihypertensive medication context.
- [x] 1.4 Ensure scenario results expose enough status for the UI to refresh history and show success or failure feedback.

## 2. Alert Decision History UI

- [x] 2.1 Add a debug-only "Test Alert Analyse" action to `AlertDecisionHistoryScreen`.
- [x] 2.2 Present the normal sync and abnormal blood-pressure scenario choices from that action.
- [x] 2.3 Disable or fail gracefully when no current patient id is available.
- [x] 2.4 Show immediate floating info feedback when a debug scenario is triggered.
- [x] 2.5 Refresh alert decision history after a scenario finishes and show concise floating success, suppression, or failure feedback for the analysis result.

## 3. Analysis and Notification Behavior

- [x] 3.1 Verify the normal debug scenario dispatches a clearly labeled test notification without creating a production alert.
- [x] 3.2 Verify the abnormal scenario sends test blood-pressure data through the backend alert-analysis client rather than hard-coding a local medication reminder.
- [x] 3.3 Preserve test/debug labeling in local notification title/body and decision history records.
- [x] 3.4 Record backend failures, validation failures, and notification dispatch failures in alert decision history.

## 4. Tests

- [x] 4.1 Add unit tests for the debug scenario runner covering normal sync, abnormal blood pressure, missing patient id, and backend failure behavior.
- [x] 4.2 Update `health_alert_service_test.dart` or related tests to assert debug events use the same processing path and test notification gating.
- [x] 4.3 Update `alert_decision_history_screen_test.dart` to cover the "Test Alert Analyse" action, scenario choice flow, trigger feedback, analysis-success feedback, empty-state visibility, refresh behavior, and no-patient handling.
- [x] 4.4 Add or update backend-facing fake client assertions to verify abnormal scenario payloads include medication-context metadata.

## 5. Verification

- [x] 5.1 Run the relevant Flutter unit/widget tests for health alert service and alert decision history.
- [x] 5.2 Run OpenSpec validation for `add-alert-analysis-debug-trigger`.
- [ ] 5.3 Manually smoke test on iOS or simulator where possible: trigger normal debug notification, trigger abnormal scenario, confirm notification/result appears in Alert Decision History.
