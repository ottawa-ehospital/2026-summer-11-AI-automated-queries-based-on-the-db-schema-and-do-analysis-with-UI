## 1. Worktree and Source Inventory

- [x] 1.1 Create and switch to a dedicated Git worktree on branch `integrate-calorie-track-nutrition-monitor` before implementation.
- [x] 1.2 Confirm the source repository path `/Users/yuyang/Documents/Code/2025-fall-calorieTrack-EHR-integrated-nutritional-monitoring` is available.
- [x] 1.3 Inventory CalorieTrack source files and record which behaviors will be migrated from Kotlin activities, data models, resources, and README.
- [x] 1.4 Exclude generated and standalone native app artifacts from migration scope, including Gradle project metadata, Android XML layouts as runtime code, build outputs, and launcher assets.
- [x] 1.5 Create an Android-to-Flutter component mapping note covering bottom navigation, ActivityResult/FileProvider image input, XML layouts, MaterialCardView, Android dialogs, Toast, RecyclerView, progress indicators, and SharedPreferences goals.
- [x] 1.6 Confirm each Android-only component has a Flutter-native replacement that matches current DTI6302 styling before implementation begins.
- [x] 1.7 Confirm current DTI6302 baseline checks before edits where practical: backend compile/tests and Flutter analyze/tests.

## 2. Backend Schemas and API Namespace

- [x] 2.1 Add nutrition monitor request/response schemas for image analysis, nutrients, insights, final verdict, meal log records, daily summaries, goals, and errors.
- [x] 2.2 Add `src/backend/api/nutrition_monitor.py` with router prefix `/nutrition-monitor`.
- [x] 2.3 Register the nutrition monitor router in `src/backend/main.py` without changing existing assistant or report interpreter routes.
- [x] 2.4 Add `GET /nutrition-monitor/health`.
- [x] 2.5 Add endpoint contracts for image analysis, meal logging, meal history, daily summary, goal loading, and goal saving.
- [x] 2.6 Ensure Flutter never needs direct OpenAI URLs or eHospital `/table/*` calls for Nutrition Monitor.
- [x] 2.7 Expose backend capability metadata that tells Flutter whether the configured model/provider supports food image analysis, including provider/model identity and an unavailable reason.

## 3. Backend Nutrition Services

- [x] 3.1 Add `src/backend/services/nutrition_monitor/` package with focused modules for EHR context, prompts, model analysis, validation, scoring, meal logs, summaries, and goals.
- [x] 3.2 Port the CalorieTrack EHR-aware food analysis prompt into backend prompt helpers using the current model configuration.
- [x] 3.3 Fetch patient registration, allergies, diagnosed conditions, recent vitals, recent blood tests, height, and weight through existing eHospital client helpers.
- [x] 3.4 Implement image request handling that accepts uploaded image bytes and optional user hint.
- [x] 3.5 Normalize model output into typed analysis results and reject invalid structured output.
- [x] 3.6 Implement non-food image handling that prevents meal logging.
- [x] 3.7 Implement deterministic exact allergy matching against detected dish/ingredient names.
- [x] 3.8 Implement final verdict scoring compatible with CalorieTrack's high-risk, warning, positive, and neutral behavior.
- [x] 3.9 Implement patient-scoped `app_nutrition_log` writes for confirmed meal logs.
- [x] 3.10 Implement patient-scoped meal history loading with date/filter support needed by Flutter.
- [x] 3.11 Implement daily nutrition summary totals from meal logs.
- [x] 3.12 Implement nutrition goal load/save behavior using backend persistence only if a suitable remote/eHospital goal table exists, with patient-scoped Flutter local storage as the default fallback matching the source app.
- [x] 3.13 Add a server-side image-model capability guard that runs before EHR context loading and before model invocation.
- [x] 3.14 Reject image analysis with a deterministic unsupported-model error such as `nutrition_image_model_unsupported` when the configured runtime model cannot process image input.
- [x] 3.15 Keep uploaded meal images transient and persist only structured nutrition results, leaving `image_storage_path` null unless a future requirement adds secure image storage.

## 4. Backend Tests

- [x] 4.1 Add route tests proving `/nutrition-monitor/health` works and existing assistant/report interpreter routes remain registered.
- [x] 4.2 Add analysis tests using mocked model output and mocked eHospital patient context.
- [x] 4.3 Add tests for missing patient context rejecting requests without demo patient fallback.
- [x] 4.4 Add tests for non-food image results preventing meal logging.
- [x] 4.5 Add tests for exact allergy match behavior and related-but-non-exact allergy behavior.
- [x] 4.6 Add tests for final verdict scoring across high-risk, warning-only, neutral, and recommended results.
- [x] 4.7 Add tests for invalid model JSON returning controlled failures.
- [x] 4.8 Add tests for `app_nutrition_log` write payloads and patient-scoped meal history/summary reads.
- [x] 4.9 Add tests for nutrition goal validation and persistence or fallback behavior.
- [x] 4.10 Add tests for unsupported image-model capability returning unavailable metadata and rejecting analysis requests.
- [x] 4.11 Add tests proving meal log persistence does not store raw image bytes and leaves `image_storage_path` null in the first version.

## 5. Flutter Data Layer

- [x] 5.1 Add required Flutter dependencies for image/file selection if existing dependencies are insufficient.
- [x] 5.2 Create `src/app/lib/features/nutrition_monitor/nutrition_monitor.dart` barrel file.
- [x] 5.3 Add Nutrition Monitor models matching backend response shapes.
- [x] 5.4 Add `NutritionMonitorRepository` using the existing API client/base URL conventions.
- [x] 5.5 Implement multipart or binary image upload with optional hint text.
- [x] 5.6 Implement repository methods for analysis, meal logging, history, daily summary, goals load, and goals save.
- [x] 5.7 Implement repository/model capability loading so the UI can disable analysis when image input is unsupported.
- [x] 5.8 Add repository tests or fakes for endpoint paths, request payloads, patient context behavior, model capability behavior, and error mapping.

## 6. Flutter Nutrition Monitor Feature

- [x] 6.1 Create `NutritionMonitorScreen` under `features/nutrition_monitor/screens`.
- [x] 6.2 Add image input UI for camera/gallery or file selection plus optional user hint using Flutter-native picker/file abstractions rather than Android ActivityResult/FileProvider code.
- [x] 6.3 Add loading, error, retry, and non-food states.
- [x] 6.4 Add analysis result UI for dish, portion, ingredients, nutrient breakdown, risks, warnings, positives, and final verdict.
- [x] 6.5 Add log-meal action that is available only for successful food analysis.
- [x] 6.6 Add daily progress UI for calories and macros against configured/default goals using current Flutter progress/card styles rather than CalorieTrack XML styling.
- [x] 6.7 Add goal editing UI with validation and patient-scoped persistence using a Flutter dialog or sheet matching existing form patterns.
- [x] 6.8 Add meal history UI with empty state, recent entries, nutrient summaries, and safety insight summaries using Flutter list widgets rather than Android RecyclerView concepts.
- [x] 6.9 Add non-diagnostic medical and nutrition safety wording consistent with the existing assistant tone.
- [x] 6.10 Replace Android Toast-style feedback with Flutter SnackBar or inline feedback consistent with existing screens.
- [x] 6.11 Disable or freeze the analyze action and show a clear unsupported-model prompt when backend capability metadata says image analysis is unavailable.
- [x] 6.12 Store nutrition goals in patient-scoped Flutter local storage when no remote goal table is available.
- [x] 6.13 Ensure the feature follows current theme, spacing, typography, localization, and feature-first structure.
- [x] 6.14 Review the implemented Nutrition Monitor UI against existing Flutter screens and revise any component that looks like a direct Android UI clone.

## 7. AI Module Host and Picker Integration

- [x] 7.1 Add Nutrition Monitor to the AI module registry/definition list with id, label, icon, description, and destination builder.
- [x] 7.2 Ensure `/assistant` shows Health Chat, Report Analyze, and Nutrition Monitor in the vertical module picker.
- [x] 7.3 Ensure selecting Nutrition Monitor launches the Nutrition Monitor feature without leaving the AI area.
- [x] 7.4 Preserve Health Chat and Report Analyze behavior when switching between modules.
- [x] 7.5 Update module picker and module host tests to cover at least three module definitions.
- [x] 7.6 Verify small-screen picker layout remains readable and launchable with the third module.

## 8. Documentation and Verification

- [x] 8.1 Update README or app docs with Nutrition Monitor module purpose, source migration notes, backend route prefix, and local run instructions.
- [x] 8.2 Document that the CalorieTrack Android app is source material and is not run as a separate app after integration.
- [x] 8.3 Document image analysis model requirements and what happens if the configured runtime cannot process images.
- [x] 8.4 Run Python compile checks for changed backend modules.
- [x] 8.5 Run backend tests covering nutrition monitor and existing AI routes.
- [x] 8.6 Run `flutter pub get` if dependencies changed.
- [x] 8.7 Run `flutter analyze`.
- [x] 8.8 Run targeted Flutter tests for Nutrition Monitor and AI module picker/host.
- [x] 8.9 Smoke test `/assistant` picker launching Health Chat, Report Analyze, and Nutrition Monitor.
- [ ] 8.10 Smoke test a food image analysis, log meal flow, daily progress refresh, and meal history load with a logged-in patient.
- [x] 8.11 Complete a source-to-target parity checklist against CalorieTrack for image input, optional hint, EHR-aware analysis, non-food handling, result rendering, verdicts, meal logging, goal editing, daily progress, meal history, and patient isolation.
- [x] 8.12 Complete a UI style checklist confirming the final Flutter screen uses DTI6302 visual patterns and does not import CalorieTrack Android chrome, bottom navigation, XML layout styling, drawable branding, or platform-only components.
- [x] 8.13 Document any CalorieTrack behavior intentionally deferred or replaced by a Flutter-native alternative.
- [x] 8.14 Smoke test the unsupported-image-model state by configuring or mocking a text-only model and confirming the analyze action is disabled with a visible prompt.
- [x] 8.15 Verify saved meal records contain structured nutrition data and do not persist raw uploaded meal images in the first version.
