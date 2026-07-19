## Source Inventory

Source repository: `/Users/yuyang/Documents/Code/2025-fall-calorieTrack-EHR-integrated-nutritional-monitoring`

### Behaviors Migrated

- `DataModels.kt`: food analysis response shape, nutrient fields, patient profile fields, daily summary, meal log fields, vitals, blood tests, allergies.
- `FoodScanActivity.kt`: camera/gallery meal image input and optional user hint.
- `FoodAnalysisActivity.kt`: EHR-aware prompt behavior, non-food sentinel handling, nutrient display, risk/warning/positive sections, final verdict scoring, meal log payload.
- `SessionManager.kt`: patient-scoped reads from `patients_registration`, `vitals_history`, `bloodtests`, `allergy_records`, `ai_diagnostics`, and `app_nutrition_log`.
- `HomeActivity.kt`: daily calorie/macro summary and goal editing behavior.
- `GoalManager.kt`: local goal defaults and local persistence behavior.
- `MealLogActivity.kt`, `MealLogAdapter.kt`, `MealDetailActivity.kt`: meal history and detail review behavior.
- `README.md`: product intent and OpenAI image-analysis requirement.

### Excluded Artifacts

- Native Android runtime shell: `AppCompatActivity` classes are source references, not runtime code.
- Android XML layouts, menu XML, drawables, launcher assets, and app-specific branding.
- Gradle project files, `.gradle`, `.idea`, wrapper files, generated build output, and AndroidManifest/FileProvider declarations.
- Direct OpenAI API key handling from `gradle.properties` / `BuildConfig`.
- Direct mobile calls to `https://aetab8pjmb.us-east-1.awsapprunner.com/table/*`.

## Android-to-Flutter Component Mapping

| Android / CalorieTrack | DTI6302 Flutter replacement |
| --- | --- |
| `BottomNavigationView` | Existing Smart Health shell and AI module picker; no nested nutrition bottom nav |
| `AppCompatActivity` + XML screen flow | `features/nutrition_monitor` screen/widgets |
| `ConstraintLayout` / `LinearLayout` XML | Responsive `Column`, `Row`, `Wrap`, `CustomScrollView`, `ListView` |
| `ActivityResultContracts` camera/gallery | Flutter `image_picker` / `file_selector` abstraction |
| `FileProvider` temp image URI | Flutter picked file result with path or bytes uploaded by repository |
| `ImageButton` capture/upload controls | Themed icon buttons and `FilledButton.icon` / `OutlinedButton.icon` |
| `MaterialCardView` result sections | Existing app-style Card/AppCard-like widgets with current spacing/radius |
| `MaterialAlertDialogBuilder` goal editor | Flutter dialog or bottom sheet matching app forms |
| Android `Toast` | `SnackBar` or inline status/error feedback |
| `RecyclerView` meal history | `ListView` / `SliverList` with feature-local item widgets |
| Material circular/linear progress indicators | Flutter progress indicators styled with current theme |
| Android `SharedPreferences` goals | Patient-scoped Flutter `SharedPreferences` fallback, or backend API if a remote goal table exists |

## Baseline Checks

- `python3 -m py_compile src/backend/main.py src/backend/clients/ehospital_client.py src/backend/clients/model_client.py src/backend/api/report_interpreter.py` passed.
- `cd src/app && flutter analyze` passed.
- `python3 -m pytest --version` failed because the local Python environment does not have `pytest` installed.
