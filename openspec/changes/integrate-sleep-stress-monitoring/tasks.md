## 1. Worktree and Migration Preparation

- [x] 1.1 Create and use a dedicated git worktree at `.worktrees/integrate-sleep-stress-monitoring` on branch `integrate-sleep-stress-monitoring` before implementation edits.
- [x] 1.2 Review `update.sql` and remote database state to confirm whether `wearable_vitals.respiratory_rate` already exists.
- [x] 1.3 Finalize the remote MySQL migration for `wearable_vitals` stress columns and the new `sleep_nights` table.
- [x] 1.4 Apply the migration remotely or document that it has been applied before enabling app writes.
- [x] 1.5 Refresh or update backend schema inventory assumptions so `sleep_nights` and the new `wearable_vitals` fields are recognized where needed.

## 2. Backend Sleep API

- [x] 2.1 Add `src/backend/schemas/sleep.py` using teammate sleep request/response shapes adapted for remote persistence.
- [x] 2.2 Add remote eHospital helper functions for sleep-night upsert and patient-scoped listing, avoiding `local_store.py`.
- [x] 2.3 Add `src/backend/services/sleep_service.py` that saves, lists, summarizes, and chats over remote `sleep_nights` rows.
- [x] 2.4 Add `src/backend/api/sleep.py` with `/sleep/nights`, `GET /sleep/nights`, `/sleep/feedback`, and `/sleep/chat`.
- [x] 2.5 Register the sleep router in `src/backend/main.py` without removing existing routers or logging middleware.
- [x] 2.6 Handle no-data and partial-data sleep feedback safely, including nullable SpO2 and heart-rate values.

## 3. Backend Stress API

- [x] 3.1 Add `src/backend/schemas/stress.py` for stress snapshot, annotation, and stress analysis request/response models.
- [x] 3.2 Add `src/backend/services/stress_score.py` from the teammate heuristic with tests for complete, partial, and missing inputs.
- [x] 3.3 Add remote eHospital write/update helpers for inserting stress snapshots and updating `wearable_vitals.annotation`.
- [x] 3.4 Add `src/backend/api/stress.py` with `/vitals/stress-snapshot` and `/vitals/{vital_id}/annotation`.
- [x] 3.5 Register the stress router in `src/backend/main.py` without changing existing wearable ingestion routes.
- [x] 3.6 Add `analyze_stress()` to the current assistant service using remote `wearable_vitals`, annotations, and patient context.
- [x] 3.7 Add `/assistant/stress-analysis` to the current assistant router while preserving `/assistant/health-alert/analyze`.

## 4. Assistant Compatibility

- [x] 4.1 Verify current `/assistant/chat` receives and forwards bounded `AssistantConversationMessage` history.
- [x] 4.2 Preserve `ModelInvocationSettings`, `AssistantReportResult`, LangGraph-compatible providers, and health alert analysis while adding stress analysis.
- [x] 4.3 Ensure new sleep/stress AI calls use the current backend model configuration path and do not remove runtime model settings from existing calls.
- [x] 4.4 Update patient context or stress analysis context building to include stress signals and recent annotations only where needed.

## 5. Flutter Sleep Feature

- [x] 5.1 Add sleep model, HealthKit sleep service, sleep repository, sleep analysis screen/widget, sleep stage chart, legend, and style files from the teammate feature.
- [x] 5.2 Adapt sleep repository calls to current `ApiConfig`/`ApiClient` conventions where practical.
- [x] 5.3 Change sleep auto-sync persistence to include patient id in the last-sync key.
- [x] 5.4 Integrate sleep analysis into the existing vitals Sleep tab or a reachable sleep screen without removing current vitals behavior.
- [x] 5.5 Add loading, no-data, and error states for sleep sync, feedback, and sleep chat.

## 6. Flutter Stress Feature

- [x] 6.1 Extend Flutter eHospital repository/service facades with `sendStressSnapshot()` and `updateStressAnnotation()`.
- [x] 6.2 Extend vitals data loading to parse remote `stress_score`, `hrv_sdnn`, `resting_heart_rate`, `respiratory_rate`, and `annotation`.
- [x] 6.3 Add Stress as a fifth vitals metric tab while preserving Steps, Calories, Heart Rate, and Sleep.
- [x] 6.4 Add stress chart tap handling and annotation bottom sheet from teammate behavior, adapted to current widgets/localization.
- [x] 6.5 Add hourly HealthKit stress bucket upload for HRV SDNN, resting heart rate, respiratory rate, and optional heart rate.
- [x] 6.6 Add seven-day stress trend summary UI.
- [x] 6.7 Add stress AI analysis UI and call `BackendApiService.stressAnalysis()`.

## 7. Flutter Assistant Module Host

- [x] 7.1 Preserve the current health assistant module picker, saved chat sessions, report interpreter module, and nutrition monitor module.
- [x] 7.2 Add sleep/stress assistant entry points only where they naturally belong, such as the sleep analysis view and vitals Stress tab.
- [x] 7.3 Verify general assistant chat still sends bounded history and saves full sessions locally.

## 8. Tests and Verification

- [x] 8.1 Add backend tests for sleep sync/list/feedback/chat with mocked remote eHospital clients.
- [x] 8.2 Add backend tests for stress score calculation, stress snapshot persistence, annotation update, and stress analysis routing.
- [x] 8.3 Extend backend assistant tests to confirm `/assistant/health-alert/analyze` remains available after adding `/assistant/stress-analysis`.
- [x] 8.4 Add Flutter repository tests for sleep sync/feedback/chat and stress snapshot/annotation/analysis calls.
- [x] 8.5 Add or update Flutter vitals widget tests for the Stress tab and existing metric tabs.
- [x] 8.6 Run backend test suite relevant to assistant, wearable ingestion, sleep, and stress.
- [x] 8.7 Run Flutter tests relevant to vitals, assistant sessions, repositories, and sleep/stress UI.
- [ ] 8.8 Smoke-test against the migrated remote database: sleep night write/read, stress snapshot write, annotation update, stress analysis, and existing wearable vitals read.

## 9. Cleanup and Documentation

- [x] 9.1 Ensure teammate-local `local_store.py` is not introduced as active persistence for sleep/stress.
- [x] 9.2 Document required remote SQL migration and feature merge notes in the change or backend DB schema docs.
- [x] 9.3 Review diffs to confirm no current DTI-6302 feature was removed by older teammate fork code.
- [x] 9.4 Run `openspec status --change integrate-sleep-stress-monitoring` and confirm the change is apply-ready.
