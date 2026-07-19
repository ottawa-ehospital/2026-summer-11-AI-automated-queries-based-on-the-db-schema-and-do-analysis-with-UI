## Context

The teammate-provided `/Users/yuyang/Documents/Code/app` directory is an older project fork. It adds sleep analysis, stress scoring, stress annotation, and some assistant prompt-history behavior, but it lacks current DTI-6302 features such as report interpretation, nutrition monitoring, health alerts, wearable workout ingestion, assistant module picker, chat session persistence, runtime model invocation settings, and backend API observability.

The teammate implementation stores detailed sleep nights and symptom logs in a local SQLite file through `src/backend/services/local_store.py`. The DTI-6302 merge must instead use remote eHospital persistence. Current remote `wearable_vitals` supports `vital_id`, `patient_id`, `heart_rate`, `steps`, `calories`, `sleep`, `timestamp`, and `recorded_on`. The teammate version expects `hrv_sdnn`, `resting_heart_rate`, `respiratory_rate`, `stress_score`, and `annotation` on the same table. A new remote `sleep_nights` table is required to hold detailed sleep-stage data.

## Goals / Non-Goals

**Goals:**

- Merge teammate sleep and stress features into the current DTI-6302 architecture.
- Store sleep nights and stress-related wearable fields in remote eHospital tables.
- Preserve current assistant, module picker, model settings, health alert, nutrition monitor, report interpreter, wearable ingestion, and logging behavior.
- Provide a clear implementation path with backend APIs, Flutter repository/UI changes, SQL migration, and tests.
- Keep stress score derivation server-side so the Flutter client sends raw signals, not trusted scores.

**Non-Goals:**

- Do not replace current `src/app` or `src/backend` with the teammate fork.
- Do not keep teammate-local SQLite as the source of truth for sleep or symptoms.
- Do not introduce a full clinical-grade stress diagnosis model; stress score remains an explainable wellness heuristic.
- Do not merge symptom logging unless explicitly selected during implementation.
- Do not redesign the entire assistant module picker or vitals UI beyond sleep/stress integration.

## Decisions

### Decision 1: Cherry-pick feature modules instead of directory replacement

The merge will copy or adapt only the teammate files and code blocks required for sleep, stress, and assistant context improvements. Current DTI-6302 files with later functionality, especially `main.py`, assistant schemas/providers, health assistant UI, and assistant repositories, must be edited in place rather than overwritten.

Alternative considered: replace DTI-6302 `src/app` and `src/backend` with the teammate fork. Rejected because it would remove active project capabilities and regress the current architecture.

### Decision 2: Remote eHospital persistence replaces `local_store.py`

Sleep nights will be stored in a new remote `sleep_nights` table. Stress signals, stress score, and annotation will be stored on remote `wearable_vitals`. The backend sleep service should read/write through eHospital client functions or a dedicated remote-backed repository.

Alternative considered: keep local SQLite for detailed sleep stages while forwarding only aggregate sleep hours remotely. Rejected because the requirement is to store these records remotely and because local backend files are not reliable across machines or deployments.

### Decision 3: Use additive SQL migration

Remote migration should add the minimum required stress columns to existing `wearable_vitals` and create `sleep_nights`. The implementation should tolerate remote deployments where `respiratory_rate` is already present by using the appropriate ALTER statement.

Required SQL shape:

```sql
ALTER TABLE wearable_vitals
  ADD COLUMN hrv_sdnn DOUBLE NULL AFTER recorded_on,
  ADD COLUMN resting_heart_rate DOUBLE NULL AFTER hrv_sdnn,
  ADD COLUMN respiratory_rate DOUBLE NULL AFTER resting_heart_rate,
  ADD COLUMN stress_score DOUBLE NULL AFTER respiratory_rate,
  ADD COLUMN annotation TEXT NULL AFTER stress_score;

CREATE TABLE IF NOT EXISTS sleep_nights (
  patient_id VARCHAR(64) NOT NULL,
  night DATE NOT NULL,
  deep_minutes DOUBLE NOT NULL DEFAULT 0,
  rem_minutes DOUBLE NOT NULL DEFAULT 0,
  core_minutes DOUBLE NOT NULL DEFAULT 0,
  light_minutes DOUBLE NOT NULL DEFAULT 0,
  awake_minutes DOUBLE NOT NULL DEFAULT 0,
  asleep_minutes DOUBLE NOT NULL DEFAULT 0,
  in_bed_minutes DOUBLE NOT NULL DEFAULT 0,
  spo2_avg DOUBLE NULL,
  spo2_min DOUBLE NULL,
  hr_avg DOUBLE NULL,
  hr_min DOUBLE NULL,
  source VARCHAR(64) NULL DEFAULT 'apple_health',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (patient_id, night),
  INDEX idx_sleep_nights_patient_night (patient_id, night)
);
```

If `wearable_vitals.respiratory_rate` already exists, the migration should omit that column from the ALTER statement.

### Decision 4: Keep stress scoring server-side

Flutter will upload `hrv_sdnn`, `resting_heart_rate`, `respiratory_rate`, optional `heart_rate`, and `timestamp`. The backend will compute `stress_score` using the teammate heuristic and persist the score. Client requests must not accept or trust a client-provided `stress_score`.

Alternative considered: compute stress score in Flutter. Rejected because server-side derivation keeps scoring consistent and auditable.

### Decision 5: Preserve current assistant contracts

The merge will keep `ModelInvocationSettings`, `AssistantReportResult`, health alert analysis, LangGraph-compatible flows, saved chat sessions, and module picker behavior. Assistant prompt history improvements should use the current `AssistantConversationMessage` model and bounded history, not the teammate fork's downgraded dictionary-only contract.

### Decision 6: Sleep-specific assistant behavior can be separate from general chat

Sleep feedback and sleep chat can live under `/sleep/feedback` and `/sleep/chat` because they use detailed sleep-stage context. General health chat should remain under `/assistant/chat`; stress analysis can live under `/assistant/stress-analysis` because it combines wearable stress signals with broader patient context.

## Risks / Trade-offs

- Remote schema is not migrated before app deployment -> Sleep/stress requests fail. Mitigation: apply SQL before enabling Flutter calls and add backend tests that mock missing fields.
- The teammate fork contains older versions of shared files -> Regressions if copied wholesale. Mitigation: only cherry-pick isolated code and review diffs for every shared file.
- Sleep nightly aggregation may duplicate or overwrite rows unexpectedly. Mitigation: use `(patient_id, night)` as the remote primary key and implement idempotent upsert semantics.
- HealthKit stress signals may be sparse. Mitigation: backend stress score must allow missing components and return `null` when all inputs are missing.
- Existing generic `/table` API may not support upsert or partial update cleanly. Mitigation: add dedicated backend helper functions or endpoint-specific SQL path as needed.
- Long-running AI sleep/stress calls can be slow. Mitigation: keep prompts concise, reuse existing model invocation configuration, and maintain UI loading/error states.

## Migration Plan

1. Apply the remote MySQL migration for `wearable_vitals` and `sleep_nights`.
2. Update backend schema inventory or query assumptions to include new fields.
3. Implement backend sleep/stress APIs against remote eHospital data and test them with mocked remote clients.
4. Implement Flutter repositories and UI integration behind existing vitals and assistant surfaces.
5. Run backend and Flutter tests.
6. Smoke-test remote writes: sleep sync, stress snapshot upload, stress annotation, sleep feedback, and stress analysis.

Rollback strategy: leave the additive SQL columns/table in place, disable or revert new API routes and Flutter calls if needed. Existing app behavior should continue because old fields and routes remain intact.

## Open Questions

- Should symptom logging be included in this change or deferred? The current plan defers it unless explicitly requested.
- Should `sleep_nights` use `patient_id` as `VARCHAR(64)` or match the exact remote patient id column type if the database enforces integer ids?
- Does the remote generic table API support upsert for composite primary keys, or do we need a dedicated backend route that performs direct MySQL upserts?
