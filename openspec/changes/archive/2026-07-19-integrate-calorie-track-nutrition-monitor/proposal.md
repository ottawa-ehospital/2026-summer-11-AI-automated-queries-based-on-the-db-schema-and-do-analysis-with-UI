## Why

The existing AI assistant area now supports multiple modules, and the CalorieTrack Android repository already contains a focused EHR-aware nutrition monitoring workflow that fits naturally as the next AI module. Integrating it into DTI6302 lets patients analyze meal photos, receive personalized nutrition safety guidance, and log meal history without leaving the Smart Health app.

## What Changes

- Add a new Nutrition Monitor option under the AI chatbot/module picker, alongside Health Chat and Report Analyze.
- Migrate the CalorieTrack repository as source material, not as a dropped-in Android subtree, converting its food image analysis, EHR-aware safety checks, nutrition breakdown, meal logging, goal tracking, and history concepts into DTI6302's Flutter + FastAPI architecture.
- Add backend nutrition analysis APIs that use the active patient context, existing eHospital client helpers, current model configuration, and the `app_nutrition_log` table.
- Add a Flutter nutrition monitor feature module that supports camera/gallery or file image input, optional user hint text, analysis result display, final verdict, meal logging, daily goal progress, and meal history.
- Preserve existing Health Chat and Report Analyze behavior while making the AI module picker handle a third module through the same extensible module definition path.
- Remove unsafe standalone assumptions from the source project during migration, including direct OpenAI keys in Android Gradle config, direct client writes to eHospital tables, and separate native Android app navigation.

## Capabilities

### New Capabilities

- `backend-nutrition-monitor-api`: Backend API contract for EHR-aware food image analysis, meal logging, goal persistence, daily summary, and meal history.
- `flutter-nutrition-monitor-feature`: Flutter feature module for the Nutrition Monitor AI option, including image selection, analysis display, logging, goals, summary, and history views.
- `ehr-integrated-nutrition-analysis`: Shared behavioral contract for EHR-aware nutrition interpretation, safety verdicts, non-food handling, and patient-scoped context.

### Modified Capabilities

- `ai-chat-module-host`: The AI assistant host must expose Nutrition Monitor as a separate AI module without merging its state into Health Chat or Report Analyze.
- `ai-assistant-module-picker`: The vertical module picker must render and launch the new Nutrition Monitor module through the existing extensible module definition model.

## Impact

- Source reference: `/Users/yuyang/Documents/Code/2025-fall-calorieTrack-EHR-integrated-nutritional-monitoring`.
- Flutter app: `src/app/lib/features/health_assistant`, new `src/app/lib/features/nutrition_monitor`, shared API/data helpers, localization, tests, and dependencies for image/file selection if needed.
- Backend: new router, schemas, and services under `src/backend` for nutrition monitor APIs; reuse existing eHospital and model invocation configuration.
- Database/API: read patient registration, vitals, blood tests, allergies, diagnostics, and meal logs; write patient-scoped rows to `app_nutrition_log`; optionally persist local daily goal preferences if a backend table is not available.
- Tests and docs: backend API tests, Flutter widget/repository tests, module picker tests, and README/update notes for the integrated workflow.
