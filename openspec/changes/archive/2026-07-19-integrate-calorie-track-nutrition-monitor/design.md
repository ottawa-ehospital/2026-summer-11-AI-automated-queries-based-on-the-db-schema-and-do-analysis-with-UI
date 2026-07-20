## Context

DTI6302 is organized as a Flutter app under `src/app` and a canonical FastAPI backend under `src/backend`. The AI assistant entry already routes through an extensible module picker with Health Chat and Report Analyze modules. Report Analyze established the pattern for migrating an external app into DTI6302 as a feature module plus backend namespace rather than embedding the external app wholesale.

The source repository `/Users/yuyang/Documents/Code/2025-fall-calorieTrack-EHR-integrated-nutritional-monitoring` is a native Android/Kotlin app named `CalorieApp`. It contains valuable product behavior: food image capture/gallery upload, OpenAI vision-based food analysis, EHR-aware allergy/condition/vitals/blood-test prompts, nutrition breakdown, final verdict scoring, meal logging to `app_nutrition_log`, daily goal progress, profile data, and meal history. It also contains assumptions that do not fit DTI6302: direct OpenAI calls from the Android client, API keys in Gradle config, direct eHospital table calls from mobile code, standalone Android navigation, and local `SharedPreferences` goal storage.

The integration should treat CalorieTrack as source material and behavior reference. Final code should match DTI6302's Flutter/FastAPI architecture and the current AI module host.

## Goals / Non-Goals

**Goals:**

- Add Nutrition Monitor as a third AI module under the existing assistant picker.
- Preserve the useful CalorieTrack workflow: image input, optional user hint, EHR-aware analysis, nutrition breakdown, risks/warnings/positives, final verdict, meal logging, goals, summary, and history.
- Move model invocation and eHospital writes to the backend so secrets and persistence do not live in Flutter.
- Reuse current backend settings, model invocation configuration, logging, eHospital client helpers, patient context conventions, and Smart Health app shell.
- Keep Health Chat, Report Analyze, and Nutrition Monitor visually and behaviorally separate.
- Make implementation testable in backend service tests, Flutter repository tests, widget tests, and module picker tests.

**Non-Goals:**

- Embed the native Android project inside `src/app` or run CalorieTrack as a separate app.
- Keep direct OpenAI API calls or eHospital table writes in the mobile client.
- Replace the existing Health Chat or Report Analyze modules.
- Build a full clinical nutrition diagnosis engine. Results must remain explanatory, safety-oriented, and non-diagnostic.
- Guarantee accurate calorie estimates beyond the model's food-image estimation limitations.
- Require a new persistent backend goal table unless one already exists or is approved during implementation.

## Decisions

### Decision 1: Convert CalorieTrack into a DTI6302 AI module

Nutrition Monitor will be registered as an AI assistant module definition with id, label, icon, description, and destination builder. The module picker will render it the same way as Health Chat and Report Analyze.

Rationale: the user asked for the feature under the AI chatbot area, and the existing picker was recently made extensible for future modules.

Alternative considered: add a separate top-level nutrition route only. Rejected as the primary entry because it would bypass the AI module selection flow. A deep link can still route to the same module later.

### Decision 2: Use the native Android source as reference, not imported runtime

The implementation will inspect and port behavior from these source files:

```text
CalorieApp/app/src/main/java/com/example/calorieapp/DataModels.kt
CalorieApp/app/src/main/java/com/example/calorieapp/FoodScanActivity.kt
CalorieApp/app/src/main/java/com/example/calorieapp/FoodAnalysisActivity.kt
CalorieApp/app/src/main/java/com/example/calorieapp/HomeActivity.kt
CalorieApp/app/src/main/java/com/example/calorieapp/MealLogActivity.kt
CalorieApp/app/src/main/java/com/example/calorieapp/MealDetailActivity.kt
CalorieApp/app/src/main/java/com/example/calorieapp/GoalManager.kt
CalorieApp/app/src/main/java/com/example/calorieapp/SessionManager.kt
```

Generated Android/Gradle artifacts, platform folders, Kotlin activity shells, and resource XML should not be copied into the Flutter app.

Rationale: DTI6302 already has a Flutter app and a FastAPI backend; importing a second native app would duplicate navigation, login, styling, networking, and build systems.

Alternative considered: keep CalorieTrack as an Android-only submodule. Rejected because DTI6302 needs one mobile app experience.

### Decision 3: Add an isolated backend API namespace

The backend will expose nutrition monitor APIs under `/nutrition-monitor`, for example:

```text
GET  /nutrition-monitor/health
POST /nutrition-monitor/analyze-image
POST /nutrition-monitor/meals
GET  /nutrition-monitor/meals
GET  /nutrition-monitor/summary/daily
GET  /nutrition-monitor/goals
PUT  /nutrition-monitor/goals
```

The router should delegate to schemas and services rather than containing prompt, model, table, and scoring logic inline.

Rationale: Report Analyze uses a dedicated backend namespace and this keeps module ownership clear.

Alternative considered: call eHospital `/table/app_nutrition_log` directly from Flutter. Rejected because the current app centralizes remote database access through backend clients and keeps credentials/server behavior off the mobile client.

### Decision 4: Backend owns model invocation and EHR context assembly

The backend will receive an image plus optional hint and patient id, fetch patient context through existing eHospital helpers, assemble a prompt equivalent to CalorieTrack's EHR-aware prompt, invoke the configured model path, parse a structured JSON response, compute or verify final verdict, and return normalized response models.

Rationale: the CalorieTrack prompt is valuable, but mobile-side OpenAI calls with API keys in Gradle config are not acceptable in DTI6302.

Alternative considered: use Flutter to assemble EHR context and send it directly to a model API. Rejected because it leaks sensitive patient context and duplicates backend settings.

The backend must only enable image analysis when the configured model/provider supports image input. If the current runtime model is text-only or otherwise cannot process images, the backend should expose that capability state and reject analysis requests with a clear unsupported-model error. This check must be enforced server-side before EHR context loading and before any model invocation, so direct API callers cannot bypass the Flutter disabled state. Flutter should use the capability state to disable or freeze the analyze action and show a user-facing message explaining that the current model does not support food image analysis.

Recommended backend guard shape:

```text
NutritionModelCapabilities
  supports_image_input: bool
  provider: string
  model: string
  reason: string | null

POST /nutrition-monitor/analyze-image
  if !supports_image_input:
    return 409 or 422 with code "nutrition_image_model_unsupported"
```

The unsupported-model response should be deterministic and non-retryable until settings change. It should not log uploaded image contents, should not fetch patient EHR context unnecessarily, and should not attempt text-only fallback analysis for an image.

### Decision 5: Keep nutrition safety deterministic where possible

The model should produce dish name, portion, ingredients, nutrients, and insight text. Deterministic service logic should handle:

- non-food sentinel handling;
- exact allergy matching rules from CalorieTrack;
- verdict scoring from risks, warnings, and positives;
- required default neutral insight when no concerns are present;
- response validation and fallback error states.

Rationale: deterministic checks make allergy and verdict behavior easier to test and reduce reliance on model wording.

Alternative considered: trust the model response completely. Rejected because patient safety and tests need stable boundaries.

### Decision 6: Use patient-scoped persistence

Meal logging will write patient-scoped records to `app_nutrition_log` through the backend. Daily summaries and history will read from the same table filtered by active patient id. CalorieTrack stored daily nutrition goals locally through Android `SharedPreferences`; the first DTI6302 Flutter version should preserve that behavior with patient-scoped Flutter local storage when no remote goal table exists. If implementation discovers an existing remote/eHospital table suitable for nutrition goals, the backend may expose goal load/save APIs and Flutter should use the API path instead.

Rationale: CalorieTrack already uses `app_nutrition_log`, and DTI6302 has existing eHospital client helpers. Goals are user preferences and can ship safely as local patient-scoped state if persistence is unavailable.

Alternative considered: require a new `app_nutrition_goals` table before the feature can ship. Rejected as unnecessary for the first integrated version unless implementation discovers an existing suitable table.

### Decision 6.1: Do not persist meal images in the first version

Uploaded meal images should be treated as transient analysis inputs. The backend may receive image bytes, prepare them for a supported vision model, and discard them after analysis. The persisted `app_nutrition_log` record should store structured results such as dish name, ingredients, portions, nutrients, and insights; `image_storage_path` should remain null unless a future storage requirement explicitly adds secure image persistence.

Rationale: the source app already writes `image_storage_path` as null, and storing patient meal images introduces privacy, storage, retention, and access-control work that is not required for the nutrition monitoring workflow.

Alternative considered: store every uploaded meal image for later review. Rejected for the initial integration because structured nutrition history is enough to preserve the current source behavior.

### Decision 7: Build a feature-first Flutter module

Target structure:

```text
src/app/lib/features/nutrition_monitor/
  nutrition_monitor.dart
  models/
  data/
    nutrition_monitor_repository.dart
  screens/
    nutrition_monitor_screen.dart
  widgets/
  presentation/
```

The feature should use the current app shell, theme, repository/API conventions, localization approach, and test patterns. It should not recreate CalorieTrack's Android bottom navigation.

Rationale: this follows Report Analyze and current feature organization.

Alternative considered: port Android XML layouts one-to-one into Flutter. Rejected because it would preserve platform-specific structure instead of a native Flutter feature.

### Decision 8: Map Android-only UI components to current Flutter patterns

The source app uses native Android components that either do not exist in Flutter or do not fit the current DTI6302 visual system. Implementation should migrate behavior and information architecture, not component styling. The component mapping is:

```text
Android / CalorieTrack source                         Flutter / DTI6302 replacement
---------------------------------------------------   ---------------------------------------------------------
AppCompatActivity + XML layouts                       Feature-first Flutter screen/widgets under nutrition_monitor
ConstraintLayout / LinearLayout XML                   Responsive Column/Row/Wrap/CustomScrollView layouts
BottomNavigationView inside CalorieTrack              Existing Smart Health app shell and AI module picker; no nested Android-style bottom nav
ActivityResultContracts camera/gallery launchers      Flutter image/file picker abstraction; camera support only through an approved Flutter plugin/path
FileProvider temp image URI                           Flutter file picker/image picker result model with bytes/path handled by repository upload
ImageButton camera/upload controls                    IconButton/FilledButton.icon/OutlinedButton.icon using current theme and lucide/Material icons already used by app
MaterialCardView result cards                         AppCard/Card-like widgets using current spacing, radius, typography, and color tokens
MaterialAlertDialogBuilder goal editor                Flutter Dialog/BottomSheet matching app form patterns
Toast success/error feedback                          SnackBar or inline status/error components consistent with current Flutter screens
RecyclerView meal history                             ListView/SliverList with feature-local meal history item widgets
CircularProgressIndicator calorie ring                Existing Flutter CircularProgressIndicator or app-consistent progress summary widget
LinearProgressIndicator macro bars                    Flutter LinearProgressIndicator with current theme colors and stable layout dimensions
SharedPreferences GoalManager                         Patient-scoped Flutter local storage fallback or backend goal API when available
Android drawable icons/images/hospital branding       Existing Smart Health assets/icon system; do not import duplicate Android drawable branding
Android profile/login screens                         Existing DTI6302 auth/profile/session surfaces; Nutrition Monitor consumes active patient context only
```

Rationale: this makes the migration explicit before implementation. It preserves the useful CalorieTrack workflows while avoiding a visually inconsistent Android port inside a Flutter module.

Alternative considered: visually clone CalorieTrack screens in Flutter. Rejected because the user wants the feature moved into DTI6302 and the UI must stay in the current Flutter style.

### Decision 9: Verify against CalorieTrack behavior after implementation

The final implementation should include a source-to-target checklist that compares CalorieTrack behavior against the Flutter module:

- camera/gallery or image-file input and optional hint;
- EHR-aware analysis using allergies, conditions, vitals, blood tests, height, and weight;
- non-food handling;
- dish, portion, ingredients, nutrients, risks, warnings, positives, and verdict rendering;
- log meal behavior and `app_nutrition_log` persistence;
- daily goal progress and goal editing;
- meal history and detail review;
- patient-scoped data isolation;
- current Flutter style, spacing, typography, and module-host integration.

Rationale: a migration can pass unit tests while still dropping an important source workflow. The final checklist makes parity visible and testable.

Alternative considered: rely only on backend and widget tests. Rejected because the migration spans source behavior, UI affordances, and app integration.

## Risks / Trade-offs

- [Risk] Food image nutrition estimates can be approximate and model-dependent. → Mitigation: show non-diagnostic wording, estimated values, and clear confidence/error states.
- [Risk] Allergy matching through model text can be inconsistent. → Mitigation: keep exact allergy matching and final verdict scoring in backend service logic where practical.
- [Risk] Image upload and camera dependencies vary across Flutter targets. → Mitigation: support a minimal image picker/file selector path first and test mobile/web behavior separately.
- [Risk] Source app used direct table calls and may not match current eHospital response shapes. → Mitigation: route all table access through backend client helpers and add mocked tests for table payloads.
- [Risk] Adding a third module can regress picker layout. → Mitigation: add module picker tests with at least three modules and verify Nutrition Monitor launches through module definitions.
- [Risk] Android component parity may be mistaken for pixel-for-pixel UI cloning. → Mitigation: document Android-to-Flutter replacements and verify current Flutter styling instead of CalorieTrack styling.

## Migration Plan

1. Create a dedicated worktree/branch named `integrate-calorie-track-nutrition-monitor` before implementation.
2. Inventory CalorieTrack source files and document which behaviors are ported.
3. Implement backend schemas, services, and router under `/nutrition-monitor`.
4. Add backend tests for analysis parsing, non-food handling, exact allergy matching, verdict scoring, logging payloads, daily summary, and history.
5. Implement Flutter nutrition monitor models, repository, screen, widgets, and local/patient-scoped goal storage.
6. Register Nutrition Monitor in the AI assistant module list and update picker/module host tests for three modules.
7. Complete the Android-to-Flutter component mapping checklist and source behavior parity checklist.
8. Update documentation with source migration notes, local image-analysis setup, and backend route summary.
9. Run backend compile/tests, Flutter `pub get`, `flutter analyze`, targeted Flutter tests, and a manual source-to-target smoke pass.

Rollback is straightforward because the new API namespace and Flutter feature are module-isolated. If needed, remove the Nutrition Monitor module definition from the picker while leaving backend code disabled or unregistered.

## Resolved Questions

- Daily nutrition goals follow the source app's local-preference behavior by default: use patient-scoped Flutter local storage unless a suitable remote/eHospital goal table already exists, in which case use backend APIs to read/write that table.
- Food image analysis requires a configured image-capable model/provider. If the current model does not support image input, the analyze action is disabled and Flutter shows a clear unsupported-model message.
- Meal images are not stored in the first version. The backend processes uploads transiently and persists only structured nutrition results, with `image_storage_path` left null unless a future requirement adds secure image storage.
