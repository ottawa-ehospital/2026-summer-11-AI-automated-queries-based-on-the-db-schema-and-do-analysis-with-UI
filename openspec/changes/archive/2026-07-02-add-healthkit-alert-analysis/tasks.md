## 1. Native iOS HealthKit Event Intake

- [x] 1.1 Add HealthKit read permissions and native sample-type configuration for supported alert inputs, starting with blood pressure and including heart-rate, sleep, activity, and workout context where available.
- [x] 1.2 Implement native observer and anchored-query handling for supported HealthKit sample updates.
- [x] 1.3 Add anchor persistence and launch/foreground reconciliation so delayed HealthKit delivery is not missed.
- [x] 1.4 Map native HealthKit samples into normalized event payloads with sample id, type, values, units, timestamps, source metadata, and anchor metadata.
- [x] 1.5 Emit native event payloads to Flutter through the chosen MethodChannel or EventChannel bridge.

## 2. Flutter Event Intake and Notification Coordination

- [x] 2.1 Add Flutter models for health event payloads, alert-analysis requests, alert decisions, and notification dispatch results.
- [x] 2.2 Add validation and source labeling for real HealthKit events versus injected test events.
- [x] 2.3 Route accepted events through existing wearable ingestion where applicable before or alongside alert analysis.
- [x] 2.4 Add local notification permission handling and dispatch helpers for production alert decisions.
- [x] 2.5 Add notification gating so production notifications are sent only for validated backend decisions with `notify=true`.
- [x] 2.6 Add clear failure/result handling for denied notification permission, invalid analysis output, unsupported events, and backend analysis failures.
- [x] 2.7 Add patient-scoped local storage for alert decision records using the existing symptom-log style of app-local persistence.
- [x] 2.8 Store notification-worthy, suppressed, test-source, invalid-output, and notification-dispatch-failure records with evidence and trace metadata.

## 3. Test Notification and Test Data Injection

- [x] 3.1 Add a debug/test configuration flag for valid-data test notifications from real HealthKit bridge events.
- [x] 3.2 Send a clearly labeled test notification when test notification mode is enabled and a valid supported HealthKit event is received.
- [x] 3.3 Add a developer-facing test-data injection path that creates synthetic supported health events without writing fake data to Apple Health.
- [x] 3.4 Ensure injected test events use the same alert-analysis API and notification decision path as real HealthKit events.
- [x] 3.5 Clearly label test-source notifications and analysis metadata so they cannot be mistaken for production health alerts.

## 4. Backend Event Analysis API

- [x] 4.1 Add backend request/response schemas for health event analysis and structured alert decisions.
- [x] 4.2 Add an event-analysis endpoint or service entry point that accepts normalized app health events.
- [x] 4.3 Validate supported event types, patient id, timestamps, units, source ids, and value ranges before analysis.
- [x] 4.4 Return deterministic unsupported-event, invalid-event, no-notification, and notification-worthy response shapes.
- [x] 4.5 Return enough alert decision and analysis trace metadata for the app to store local debug/history records.

## 5. LangGraph Alert Analysis Workflow

- [x] 5.1 Register an event-triggered alert-analysis workflow separately from user chat routing.
- [x] 5.2 Query patient history from `medical_history` and `diagnosis`, active medication context from `prescription_form` and `prescription`, patient-reported context from `patient_feedback`, risk context from `heart_disease_analysis`, `stroke_prediction`, and `ai_diagnostics`, recent measurements from `vitals_history` and `wearable_vitals`, and workout history from `wearable_workouts` when available.
- [x] 5.3 Implement blood-pressure analysis input assembly for a 3-hour window, including minimum evidence, user baseline, recent measurements, normal/reference-range context, medication/history context, resting heart rate, sleep, activity, and workout context.
- [x] 5.4 Invoke the shared model client for demo blood-pressure judgment after the 3-hour context package is assembled.
- [x] 5.5 Constrain LLM output to a validated alert decision schema with notification flag, severity, title, body, evidence, reason, freshness, and trace metadata.
- [x] 5.6 Suppress notification output on missing medication evidence, insufficient trend evidence, malformed model output, or safety validation failure.

## 6. Blood Pressure Reminder Behavior

- [x] 6.1 Configure the first demo blood-pressure rule to use a 3-hour analysis window with user-baseline comparison, normal adult reference-range context, and supporting heart-rate, sleep, activity, and workout context.
- [x] 6.2 Detect patients with relevant history from `medical_history`/`diagnosis` and active antihypertensive medication from `prescription_form`/`prescription`, using `medicines` only as optional reference metadata.
- [x] 6.3 Generate medication-adherence reminder decisions only when sustained elevation and medication/history context are both present.
- [x] 6.4 Avoid missed-medication wording when active antihypertensive medication evidence is unavailable.
- [x] 6.5 Use supportive notification language that avoids diagnosis, emergency claims, or overconfident causal statements.
- [x] 6.6 Add cached authoritative blood-pressure reference ranges for demo prompts, with an option to refresh or supplement them through LLM web search during demos.

## 7. Tests and Verification

- [x] 7.1 Add native bridge tests or fakes for valid, malformed, unsupported, and reconciled HealthKit events.
- [x] 7.2 Add Flutter tests for event validation, test-data injection, notification gating, test notification mode, local alert-decision storage, and permission-denied behavior.
- [x] 7.3 Add backend tests for event-analysis schema validation and unsupported/invalid event responses.
- [x] 7.4 Add workflow tests for sustained blood-pressure elevation with medication context producing a reminder decision.
- [x] 7.5 Add workflow tests proving isolated elevated readings, missing medication context, and malformed LLM output suppress notifications.
- [x] 7.6 Add integration-style tests proving injected test events travel through the same analysis and notification decision path as real events.
- [x] 7.7 Add a real-device smoke checklist for HealthKit permission grant, valid-data test notification, injected alert analysis, production notification gating, and launch/foreground reconciliation.
- [x] 7.8 Add Flutter widget tests for the Settings alert decision history page, including empty state, populated records, and clear-history action.

## 8. Settings Debug UI

- [x] 8.1 Add an alert decision history route and page under Settings.
- [x] 8.2 Add a Settings tile that opens the alert decision history debug page.
- [x] 8.3 Display patient-scoped local records with timestamp, event type/source, notify status, severity, title/body or suppression reason, test/production label, evidence summary, and notification dispatch status.
- [x] 8.4 Add a clear-history action that deletes local alert decision records for the current patient.
- [x] 8.5 Ensure local alert decision records are cleared on logout with other local patient data.

## 9. Documentation and Rollout

- [x] 9.1 Document supported Apple Health event types, test notification mode, test-data injection workflow, and Settings alert-decision debug page.
- [x] 9.2 Document that iOS delivery is real-time or near-real-time but not guaranteed when the OS delays background execution.
- [x] 9.3 Document safety boundaries: no diagnosis, no emergency detection, no clinician alerting in this change.
- [x] 9.4 Add rollback notes for disabling event-analysis triggers and notification dispatch while preserving ingestion and local decision history.
