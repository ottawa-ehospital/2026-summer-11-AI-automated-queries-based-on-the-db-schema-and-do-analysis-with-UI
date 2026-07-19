## Why

Apple Health ingestion should not be a blind remote-storage path. Some health changes only matter when interpreted against patient history, medication context, and recent trends, so the app needs an event-driven analysis and notification path that can warn users when new HealthKit data suggests a clinically relevant behavior change.

## What Changes

- Add native iOS HealthKit real-time or near-real-time update handling for supported Apple Health samples, starting with blood pressure and including related wearable signals needed for alert analysis.
- Add an app-side health event intake path that receives HealthKit updates, validates and normalizes the data, and wakes the analysis flow without requiring the user to open a chat screen.
- Add an LLM-assisted alert analysis workflow, likely implemented as a separate LangGraph route, that evaluates new health measurements against patient history, medications, blood pressure, resting heart rate, sleep, activity, workouts, and recent trends before deciding whether a notification is warranted.
- Add local notification delivery for generated health reminders, including medication-adherence style prompts such as sustained blood-pressure increase while prescribed antihypertensive medication exists.
- Store alert decisions locally in the app, similar to symptom logs, so notification decisions and suppressed decisions remain available as patient-scoped debug/history records.
- Add a Settings debug page that displays local alert/notification decision records for verification and troubleshooting.
- Add a test notification mode that sends a clearly labeled notification when an Apple Health push delivers valid data, so device testing can prove the real-time data path is working even when no clinical alert is produced.
- Add test-data injection into the app so developers can simulate HealthKit events and verify analysis, LLM routing, and notification behavior without depending on hard-to-reproduce Apple Health background delivery.
- Preserve backend ingestion as evidence storage and query context, but do not treat every Apple Health update as a reason to notify the user.

## Capabilities

### New Capabilities

- `healthkit-alert-analysis`: Native HealthKit event intake, test event injection, event-triggered analysis, notification decisioning, and app notification delivery for Apple Health changes.

### Modified Capabilities

- `assistant-workflow-routing`: Register event-triggered alert analysis as a workflow path that can invoke LLM/LangGraph logic without going through a user chat message.
- `langgraph-query-report-flow`: Extend health-data reasoning so alert workflows can gather patient history, medication context, and recent measurements for event-triggered analysis.

## Impact

- iOS native code under `src/app/ios`, including HealthKit observer/anchored-query handling, MethodChannel or EventChannel delivery, and local notification permission/dispatch.
- Flutter code under `src/app/lib`, including HealthKit event intake models, notification coordination, local alert-decision storage, Settings debug UI, test-data injection controls, and service orchestration.
- Python backend assistant/workflow code under `src/backend/services/assistant/workflows`, including an event-triggered alert workflow and LLM prompt/result validation.
- Backend APIs for event analysis requests, patient-context lookup, and alert-decision metadata returned to the app for local history/debug storage.
- Tests for native bridge mapping, Flutter event injection, backend alert analysis, notification gating, and test-notification behavior.
