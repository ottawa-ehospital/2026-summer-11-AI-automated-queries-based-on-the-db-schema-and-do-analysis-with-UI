## Why

The external `/Users/yuyang/Documents/Code/app` folder contains teammate-built sleep monitoring, stress scoring, stress annotation, and assistant follow-up features that should be merged into the current DTI-6302 application. That folder is an older fork, so the merge must extract the useful feature work without overwriting current nutrition monitoring, report interpretation, health alerts, wearable ingestion, model invocation settings, chat sessions, or module picker behavior.

## What Changes

- Add remote-backed sleep night storage for Apple Health sleep stages, overnight SpO2, overnight heart-rate summaries, AI sleep feedback, and sleep-specific follow-up chat.
- Extend remote `wearable_vitals` support for stress signals: HRV SDNN, resting heart rate, respiratory rate, backend-derived stress score, and user annotations.
- Add stress snapshot ingestion and stress annotation APIs that write to remote eHospital data instead of local SQLite.
- Add a stress analysis assistant endpoint that uses wearable stress signals, user annotations, and patient clinical context while preserving the existing health-alert assistant endpoint.
- Integrate sleep and stress into the Flutter vitals experience without removing existing steps, calories, heart-rate, sleep, wearable sync, health goals, nutrition monitor, report interpreter, module picker, or chat session features.
- Preserve existing assistant model invocation settings and current structured assistant result types while adopting the teammate version's useful multi-turn prompt context behavior where needed.
- Replace teammate-local `local_store.py` persistence with remote eHospital tables and document the required SQL migration.

## Capabilities

### New Capabilities

- `backend-sleep-monitoring-api`: Remote-backed sleep night sync, listing, feedback, and sleep chat API behavior.
- `backend-stress-monitoring-api`: Stress snapshot ingestion, backend stress-score derivation, annotation update, and stress analysis API behavior.
- `flutter-sleep-monitoring-feature`: Flutter sleep data collection, sleep stage visualization, sync, feedback, and sleep chat behavior.
- `flutter-stress-monitoring-feature`: Flutter stress metric visualization, stress snapshot upload, annotation, trend, and assistant analysis behavior.

### Modified Capabilities

- `backend-wearable-ingestion`: Expand wearable vitals ingestion and remote schema expectations to include stress-related wearable fields.
- `health-assistant-chat-sessions`: Preserve current saved chat sessions while ensuring assistant requests carry bounded conversation history for contextual replies.
- `ai-chat-module-host`: Add sleep/stress assistant surfaces without regressing existing chat, report interpreter, and nutrition monitor modules.
- `runtime-model-invocation-settings`: Ensure new sleep/stress assistant calls either use existing backend model settings or do not remove the current model invocation contract.

## Impact

- Backend API files: `src/backend/main.py`, `src/backend/api/assistant.py`, new sleep/stress routers, schemas, and services.
- Backend data access: remote eHospital table writes/updates for `sleep_nights` and `wearable_vitals`; avoid teammate-local SQLite persistence.
- Remote SQL: add stress columns to `wearable_vitals`; create `sleep_nights`; optionally create `symptom_logs` only if symptom logging is included.
- Flutter features: add sleep feature files, extend vitals screen/widgets, add sleep repository calls, extend eHospital/assistant service facades.
- Tests: add backend sleep/stress tests, extend assistant tests, add Flutter repository/widget tests for new sleep/stress paths.
- Migration risk: teammate code is an older fork and must be cherry-picked; direct replacement would remove current project features.
