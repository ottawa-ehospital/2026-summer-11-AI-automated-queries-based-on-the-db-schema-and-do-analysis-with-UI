## Context

The app already stores alert decisions locally, displays them in Alert Decision History, dispatches local notifications from validated backend decisions, and supports injected test blood-pressure events. The missing piece is an ergonomic debug trigger that lets a developer exercise the same path from the UI without waiting for real Apple Health background delivery.

Alert Decision History is the right location because it is already a developer/debug surface for HealthKit alert analysis and notification records. The trigger must stay visibly test-only and must not create a separate notification path that bypasses validation.

## Goals / Non-Goals

**Goals:**

- Add a debug UI action in Alert Decision History for test alert analysis.
- Support two deterministic scenarios: normal valid Apple Health sync and abnormal falling blood-pressure trend with antihypertensive medication context.
- Reuse `HealthAlertService.processEvent()` so validation, wearable ingestion, backend analysis, notification dispatch, and decision history behave like native HealthKit delivery.
- Mark all injected events, notifications, and decision records as test/debug data.
- Keep the debug entry easy to disable or hide outside development builds.

**Non-Goals:**

- Do not replace native HealthKit observer or anchored-query behavior.
- Do not create production health alerts without backend alert-analysis decisions.
- Do not add new clinical rules in Flutter; medication-adherence decisions still come from backend analysis.
- Do not create a patient-facing feature or settings preference.

## Decisions

### Decision 1: Add a debug scenario runner behind the existing alert service

Create a small Flutter service, for example `HealthAlertDebugScenarioRunner`, that accepts a patient id and a `HealthAlertService`. The runner builds test `HealthAlertEvent` payloads and calls `processEvent()` for each scenario. The Alert Decision History screen owns only UI state and calls this runner.

Rationale: this keeps the screen simple, makes the scenarios unit-testable, and avoids duplicating event validation, notification, storage, or backend request logic.

Alternative considered: put all scenario construction directly in the screen. That is faster initially but makes widget tests carry too much domain setup and encourages UI-specific behavior.

### Decision 2: Use explicit debug scenarios instead of an unstructured script-only path

Expose a "Test Alert Analyse" action that opens a compact choice between:

- "Debug data received": sends one valid Apple Health-style event with `validDataTestNotification=true`, proving that valid data reached the app and that the debug notification path works.
- "Falling blood pressure": sends a short sequence of blood-pressure events in `sourceMode=test` or `simulation`, including source metadata that identifies recent antihypertensive medication history and the intended scenario.

Rationale: the UI button makes manual device testing quick, while the scenario runner can still be invoked from tests or future scripts.

Alternative considered: a CLI/debug script only. That helps automation but does not let a tester verify notification permission, app foreground state, and local decision history from the actual app surface.

### Decision 3: Preserve backend ownership of abnormal alert decisions

The abnormal scenario should send enough test context for the backend to analyze the trend: repeated blood-pressure readings over the analysis window, medication context such as active antihypertensive use, and clear debug metadata. Flutter should not fabricate a medication-adherence decision unless the backend is unavailable and the product explicitly adds a local fallback later.

Rationale: existing requirements say local notifications come from validated alert decisions. Keeping the analysis server-side prevents the debug tool from proving a path that production does not use.

Alternative considered: hard-code a local abnormal notification. That would be useful for local notification smoke testing, but it would not validate analysis or medication-context handling.

### Decision 4: Label and store debug output clearly

All debug notifications should use a test prefix such as `[TEST]`, and decision history cards should continue to show `test` or `simulation` source labels. The runner should refresh the history after each scenario so the newest record is visible immediately.

Rationale: developers need to distinguish debug notifications from real health alerts, and local decision records are the audit trail for whether the end-to-end flow worked.

### Decision 5: Show immediate and completion floating feedback

When a debug scenario is selected, the screen should show an immediate floating info message, such as a `SnackBar`, confirming that the debug analysis was triggered. When alert analysis returns successfully, the screen should show a second floating success message before or alongside the refreshed history. Validation failures and backend failures should use the same floating feedback surface with failure wording.

Rationale: manual testers need visible confirmation for both phases: the button press was accepted, and the asynchronous analysis path returned. The local notification alone is not enough because notification permissions, app foreground behavior, or OS delivery timing can obscure what happened.

## Risks / Trade-offs

- Backend analysis may be unavailable during local UI testing -> the normal data-received scenario still proves valid HealthKit-style delivery and local notification dispatch, while the abnormal scenario records the backend failure in decision history.
- Abnormal scenario could be mistaken for a real alert -> use test source mode, test notification prefix, and debug-only UI placement.
- iOS notification permissions may be denied -> record the dispatch failure and keep the decision visible in history.
- Floating feedback can disappear before a tester reads it -> keep messages concise and refresh decision history so the durable result remains visible.
- Build-mode gating can hide the button unexpectedly during QA -> document whether the trigger is enabled by `kDebugMode`, a compile-time flag, or an internal debug setting before implementation.

## Migration Plan

No data migration is required. The change is additive to debug UI and alert test paths. Rollback removes the debug runner and button without changing existing alert decision records or production HealthKit behavior.

## Open Questions

- Should the debug button be visible only in `kDebugMode`, or should internal/release QA builds enable it through a compile-time flag?
- Does the backend already accept medication context in `source_metadata`, or should the abnormal scenario also seed/query patient medication data through an existing fixture endpoint before analysis?
