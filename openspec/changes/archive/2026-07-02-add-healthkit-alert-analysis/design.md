## Context

The existing wearable direction centralizes Apple Health and Google Health uploads through backend ingestion so measurements can be normalized and queried later. The new requirement is different: receiving Apple Health data is only the trigger. The app must evaluate whether the new data represents a meaningful change for this patient, using medical history, medication context, and recent measurements, and then notify the user only when the analysis finds a useful reminder or warning.

The motivating case is blood pressure. If a patient has relevant history and an active antihypertensive prescription, sustained blood-pressure elevation over a recent window can justify a medication-adherence reminder. The system also needs a test notification path because real HealthKit background delivery is difficult to prove during development, and it needs test-data injection so analysis behavior can be verified without creating real Apple Health records.

## Goals / Non-Goals

**Goals:**

- Receive native Apple Health updates in real time or near real time where iOS allows it.
- Normalize HealthKit updates into app events without blindly sending every update as a user notification.
- Persist or forward accepted measurements through the existing backend ingestion/query path so analysis has evidence.
- Trigger an LLM-assisted alert-analysis workflow that can query patient history, medication context, blood pressure, resting heart rate, sleep, activity, workouts, and recent wearable measurements.
- Deliver local notifications only for validated alert decisions, plus a clearly labeled test notification when valid Apple Health push data is received in test mode.
- Store alert decisions locally in the app as patient-scoped records, similar to symptom logs, so notification history and suppressed decisions can be reviewed during debugging.
- Add a Settings debug page for alert/notification decision records.
- Support injected test events inside the app so developers can verify analysis, routing, and notification behavior without depending on HealthKit background delivery.

**Non-Goals:**

- Provide emergency detection, diagnosis, or guaranteed clinical triage.
- Guarantee exact real-time delivery when iOS delays or suppresses HealthKit background execution.
- Notify clinicians or write clinician tasks in this change.
- Replace existing chat-based assistant workflows.
- Store route coordinates, raw HealthKit private metadata beyond what is needed for audit/debug, or unsupported Apple Health types.

## Decisions

### Decision 1: Treat HealthKit delivery as an event trigger, not as the alert itself

Native iOS code will receive HealthKit updates and send normalized health events to Flutter. Flutter will route valid events through ingestion and alert analysis. A notification is sent only after the analysis workflow returns a notification-worthy decision, except for an explicit test-notification mode that proves valid Apple Health data arrived.

Rationale: raw measurements are noisy and context-dependent. Blood pressure, heart rate, sleep, and activity changes should be interpreted against recent trend windows and patient context before interrupting the user.

Alternative considered: send a notification for every Apple Health push. Rejected because it would create alert fatigue and would not satisfy the requirement to analyze changes.

### Decision 2: Keep HealthKit observation native, but keep analysis backend-owned

iOS will use native HealthKit observer and anchored queries for supported sample types. The app will pass normalized event payloads to the backend for patient-context lookup and LLM-assisted analysis. The backend workflow can use existing query/report infrastructure and model-provider configuration rather than embedding clinical prompt logic in Swift or Flutter.

Rationale: HealthKit background delivery requires native code, while patient history, medications, validated data queries, model routing, and auditability are already backend concerns.

Alternative considered: run LLM analysis inside Flutter after receiving the HealthKit event. Rejected because Flutter does not own the full patient-context query path and would duplicate backend model orchestration.

### Decision 3: Add a separate event-triggered alert workflow

The alert workflow will be registered alongside assistant workflows but invoked by a health event, not by a user chat message. It will accept a structured event, gather context, produce a validated alert decision, and return notification copy plus evidence and confidence metadata.

Rationale: event-triggered analysis has different inputs and outputs from chat. It must decide whether to notify, not answer a user question. Keeping it as a distinct workflow avoids bending the chat contract while still reusing LangGraph and shared model invocation.

Alternative considered: synthesize a hidden chat prompt such as "Should I notify this user?" and send it through the chat endpoint. Rejected because it makes routing, validation, testing, and notification gating harder to reason about.

### Decision 4: Start with a 3-hour LLM-assisted blood-pressure demo rule

The first alert analysis will use a 3-hour analysis window for blood-pressure events. The workflow will gather the new HealthKit reading, recent blood-pressure measurements in the prior 3 hours, the user's own baseline from historical vitals, and comparable normal/reference ranges. For the demo version, the LLM can judge whether the 3-hour pattern is meaningfully elevated compared with the user's baseline and normal adult reference data, then return a constrained alert decision. Medication-adherence reminders require active antihypertensive evidence or relevant hypertension/cardiovascular history.

Rationale: a 3-hour window is short enough to feel responsive after Apple Health push delivery but long enough to avoid firing on one isolated measurement. LLM judgment is acceptable for the demo because it can combine patient-specific baseline, recent trend shape, medication context, and normal-user references without hard-coding one brittle threshold.

Alternative considered: ask the LLM to inspect every new data point. Rejected because it is expensive, less predictable, and more likely to generate alerts from isolated noise.

Alternative considered: use only a fixed threshold such as 130/80 or 140/90. Rejected for the demo because the user's baseline and medication context should influence whether a reminder is useful.

### Decision 5: Testing uses two explicit modes

The app will support a "valid data received" test notification mode for native HealthKit push verification. Separately, it will support injected test events that travel through the same analysis API as real events, with source metadata marking them as test data.

Rationale: HealthKit push delivery and alert analysis are different things to prove. A test notification proves the native data path; injected events prove analysis and notification decisioning.

Alternative considered: rely only on unit tests. Rejected because real device HealthKit delivery, app wake behavior, notification permissions, and Flutter bridge behavior need smoke-test coverage.

### Decision 6: Store alert decisions locally like symptom logs

Flutter will persist each alert-analysis decision locally using patient-scoped app storage, following the existing symptom-log pattern. A record will be written for both `notify=true` and `notify=false` backend decisions, plus local failures that affect notification delivery such as denied permission or invalid decision schema. Each record should include a local id, patient id, event source id, event type, source mode, decision timestamp, notify flag, severity, notification title/body when present, suppression reason when present, evidence summary, model/workflow trace metadata, and whether a local notification was actually dispatched.

Rationale: the user wants alert decisions retained in the app as records, and local storage is enough for the demo/debug workflow. This avoids creating a backend audit table before the alert behavior stabilizes, while still making notification decisions inspectable on device.

Alternative considered: store alert decisions only in backend logs or a new remote audit table. Rejected for this change because the immediate need is app-side verification and debug history similar to symptom logs.

### Decision 7: Use existing eHospital tables as alert context sources

The first alert-analysis workflow will use existing eHospital tables rather than creating a new clinical context store. Active antihypertensive evidence will come primarily from `prescription_form` and secondarily from `prescription`; `medicines` is a reference/catalog table only. Diagnosis and condition evidence will come from `medical_history` first and `diagnosis` second. Recent blood-pressure evidence will come from the incoming HealthKit event plus `vitals_history`; supporting wearable context can come from `wearable_vitals`. Symptom or patient-reported context will use `patient_feedback` because no dedicated `symptom_log` table exists in the current schema inventory. Risk context can include `heart_disease_analysis`, `stroke_prediction`, and `ai_diagnostics`, but those tables are supporting evidence rather than authoritative medication or diagnosis sources.

Rationale: these tables already exist in the eHospital schema inventory and are already used by patient-context or insights code. This keeps the first version implementable without a schema migration while still giving the LLM enough context to distinguish medication reminders, symptom-aware caution, and general monitoring.

Alternative considered: use risk-analysis tables as the main source for hypertension context. Rejected because risk predictions are derived signals and do not prove active diagnoses or medications.

### Decision 8: Use authoritative reference ranges as LLM context, not as diagnosis logic

For the demo, the alert-analysis prompt may include normal adult blood-pressure references obtained through LLM web search or cached reference text from authoritative sources. The current reference baseline is: normal adult blood pressure is below 120/80 mm Hg; elevated is 120-129 systolic and below 80 diastolic; stage 1 hypertension is 130-139 systolic or 80-89 diastolic; stage 2 hypertension is at least 140 systolic or 90 diastolic; severe values around 180 systolic or 120 diastolic require special caution. These references are used to help the LLM interpret trend severity, while the app still presents reminders as informational wellness prompts rather than diagnoses.

Rationale: AHA, CDC, and NHLBI references are consistent on common adult blood-pressure categories. Supplying those references to the LLM makes the demo judgment less arbitrary, while preserving the requirement that final output must be validated and conservative.

Alternative considered: live web search on every event. Rejected for the first implementation because notification analysis should be fast and reliable; live search can be used in demos or refreshed periodically into cached references.

### Decision 9: Add a Settings debug page for alert decision records

The Settings screen will include a debug-oriented entry that opens a local alert decision history page. The page will read the same patient-scoped local records used by the notification coordinator and display notification-worthy, suppressed, test, and failure records. It should show enough information to verify the pipeline: time, event type/source, notify status, severity, title/body or suppression reason, evidence summary, and test/production label. The page may support clearing local records for the current patient.

Rationale: HealthKit delivery and notification gating are hard to validate from logs alone. A visible Settings page lets developers and demo users verify what the app received, what the backend decided, and whether a notification was actually sent.

Alternative considered: expose the debug log only through console output. Rejected because device demos need an in-app view.

### Decision 10: Include broader wearable context in the first version

The first version will not limit analysis context to blood pressure alone. Blood pressure remains the primary trigger and the clearest first notification scenario, but the alert-analysis context package will also include resting heart rate or heart-rate trend where available, sleep duration/quality signals, activity or step count, and workout history. These supporting signals help the LLM distinguish possible medication-adherence reminders from patterns that may be better explained by poor sleep, unusual activity, recent workouts, stress, or missing data.

Rationale: doing this more completely upfront makes the demo more convincing and better matches the requirement to analyze changes rather than react to a single metric. The existing data sources already expose `wearable_vitals` and the workout ingestion change adds `wearable_workouts`, so the workflow can gather richer context without changing the notification contract.

Alternative considered: analyze only blood pressure in the first version. Rejected because it would make the LLM decision too narrow and could over-notify when a blood-pressure reading is better interpreted with sleep, heart-rate, or activity context.

## Risks / Trade-offs

- iOS may delay HealthKit background delivery -> Use anchored reconciliation on launch/foreground and describe alerts as near-real-time.
- Blood pressure data may be sparse or manually entered -> Require enough recent evidence before analysis can produce a user-facing reminder.
- LLM output may be unsafe or malformed -> Validate alert decisions against a strict schema and suppress notifications on validation failure.
- LLM web search may return variable references -> Prefer cached authoritative reference snippets for normal demo operation and include source/provenance metadata when live search is used.
- Local alert logs may contain sensitive health context -> Scope records by patient id, keep them on device, avoid storing raw HealthKit payloads beyond useful evidence summaries, and clear them on logout with other local patient data.
- Notifications may cause anxiety or overreach -> Use supportive reminder language, include uncertainty, and avoid diagnosis or emergency claims.
- Test notifications could be confused with real alerts -> Label test notifications clearly and keep them behind debug/test configuration.
- Backend context may be incomplete -> Include missing-context reasons in the workflow result and avoid medication-specific reminders without medication evidence.
- Medication names may not be normalized across `prescription_form`, `prescription`, and `medicines` -> Use a conservative antihypertensive keyword/class matcher and treat uncertain matches as supporting evidence only.
- Supporting wearable data may be sparse or inconsistent -> Treat resting heart rate, sleep, activity, and workout history as context signals, not required inputs for every alert decision.

## Migration Plan

1. Add HealthKit event models and native-to-Flutter bridge contract for supported Apple Health event types.
2. Add local notification permission and dispatch helpers with separate production-alert and test-notification paths.
3. Add a backend event-analysis API and workflow input/output schemas.
4. Register an event-triggered alert workflow that can query patient context, medications, recent vitals, sleep, activity, and workout history.
5. Add the first blood-pressure sustained-rise analysis path with a 3-hour window, user-baseline comparison, normal/reference-range context, supporting wearable context, and constrained LLM decision output.
6. Add local alert-decision storage and a Settings debug page for alert/notification history.
7. Add app test-data injection for synthetic HealthKit events and test notification controls.
8. Add backend, Flutter, and native bridge tests; add a real-device smoke checklist for HealthKit push and notification behavior.

Rollback can disable the event-analysis trigger and notification dispatch while keeping raw ingestion, local decision records, and chat workflows intact. Local decision records can be cleared from Settings or on logout.

## Open Questions

None currently.
