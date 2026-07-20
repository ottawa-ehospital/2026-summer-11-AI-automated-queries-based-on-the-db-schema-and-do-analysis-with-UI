# HealthKit Alert Analysis

## Supported Inputs

The first implementation listens for Apple Health updates from native iOS code and forwards normalized events to Flutter:

- Blood pressure: systolic and diastolic values in `mmHg`.
- Heart rate: supporting context in `count/min`.
- Activity: step-count supporting context.
- Sleep: sleep-analysis duration supporting context.
- Workouts: workout duration, activity type, distance, and energy where Apple Health provides them.

HealthKit delivery is real-time or near-real-time. iOS may delay background delivery, so the app also reconciles anchored samples on launch/foreground.

## Test And Debug Flow

Use `HealthAlertService.processEvent(..., validDataTestNotification: true)` during a device demo to send a clearly labeled `[TEST] Apple Health data received` notification when a valid HealthKit event reaches Flutter. This only proves the intake path is alive; it is not a health alert decision.

Use `HealthAlertService.injectTestBloodPressure(...)` to inject synthetic blood-pressure events into the same analysis and notification-decision path without writing fake data to Apple Health.

The Settings page includes `Alert decision history`, which stores patient-scoped local records for notification-worthy, suppressed, invalid, test-source, and dispatch-failure decisions. The page can clear the current patient's local alert history. Logout clears the same records through the app-wide SharedPreferences clear path.

## Decision Boundaries

The demo blood-pressure reminder uses a 3-hour analysis window, cached adult reference ranges, user measurements, active medication context, diagnosis/history context, and supporting heart-rate, sleep, activity, workout, symptom-log, and risk-analysis context.

The backend suppresses notifications when:

- The event is unsupported or invalid.
- The 3-hour window does not show sustained elevation.
- Medication/history evidence is missing.
- The LLM output cannot be parsed and validated.

Notification copy must stay supportive. This change does not diagnose, detect emergencies, contact clinicians, or claim that a user definitely missed medication.

## Rollback Notes

To disable notifications while preserving ingestion and local history, replace the production `HealthAlertNotificationDispatcher` with a dispatcher that records a dispatch failure and returns a non-null failure string.

To disable event-triggered analysis while preserving native intake, stop calling `HealthAlertRepository.analyze` from `HealthAlertService.processEvent` and store local `no_notification` records instead.

To disable native HealthKit alert intake entirely, stop calling `HealthKitAlertBridge.start()` from the app bootstrap or debug wiring. Existing wearable ingestion and local decision history remain unaffected.

## Real-Device Smoke Checklist

- Install on an iPhone with HealthKit available.
- Grant HealthKit read permissions for blood pressure, heart rate, steps, sleep, and workouts.
- Start the HealthKit alert bridge and confirm observer registration does not error.
- Enable valid-data test notification mode, create or receive a supported HealthKit update, and confirm the `[TEST] Apple Health data received` notification appears.
- Inject a test blood-pressure event and confirm it reaches the backend alert-analysis endpoint.
- Confirm production notification gating sends a notification only for a validated backend decision with `notify=true`.
- Background or foreground the app and confirm reconciliation does not duplicate previously anchored samples.
- Open Settings > Alert decision history and confirm records show event type/source, severity, notify status, evidence, trace, and dispatch status.
