## Source-to-Target Parity Checklist

Source app: `/Users/yuyang/Documents/Code/2025-fall-calorieTrack-EHR-integrated-nutritional-monitoring`

### Behavior Parity

- [x] Image input: CalorieTrack camera/gallery behavior is represented with Flutter `image_picker` camera/gallery and `file_selector` image-file upload.
- [x] Optional hint: CalorieTrack text hint is represented with an optional Flutter text field and multipart `hint` field.
- [x] EHR-aware analysis: patient registration, vitals, blood tests, allergies, and diagnostics are assembled server-side before model invocation.
- [x] Non-food handling: model output can mark `isFood=false`; backend rejects non-food meal logging and UI hides the log action.
- [x] Result rendering: dish, portion, ingredients, nutrients, risks, warnings, positives, and final verdict render in the Flutter module.
- [x] Verdicts: CalorieTrack-style risk/warning/positive/neutral scoring is deterministic backend logic.
- [x] Meal logging: confirmed food results write patient-scoped structured records to `app_nutrition_log`.
- [x] Daily progress: calories, protein, carbs, and fat render against configured/default goals.
- [x] Goal editing: source local-goal behavior is preserved with patient-scoped Flutter `SharedPreferences`.
- [x] Meal history: recent structured meal records are loaded through backend APIs and rendered with Flutter list/card widgets.
- [x] Patient isolation: analysis, meal logs, summaries, history, and local goals are keyed by active patient id.

### Flutter Style Checklist

- [x] Nutrition Monitor is a feature-first Flutter module under `features/nutrition_monitor`.
- [x] It enters through the existing AI assistant module picker, not a nested CalorieTrack bottom navigation.
- [x] It uses current Flutter cards, buttons, forms, progress indicators, SnackBars, and inline banners.
- [x] Android XML layouts, drawables, launcher assets, AppCompat activity shells, and direct table calls are not imported as runtime code.
- [x] Camera/gallery/file input uses Flutter-native abstractions instead of Android ActivityResult/FileProvider code.
- [x] Unsupported image-model state is visible in the UI and freezes the analyze action.

### Intentional Replacements or Deferrals

- CalorieTrack direct OpenAI calls are replaced by the backend model path so Flutter does not hold API keys or direct model URLs.
- CalorieTrack direct eHospital `/table/*` calls are replaced by backend services and existing eHospital client helpers.
- Meal images are not stored; the backend discards image bytes after analysis and persists only structured nutrition data with `image_storage_path` null.
- A remote nutrition-goals table is not required in the first version; local patient-scoped Flutter storage is used by default.
- Manual food-image end-to-end smoke testing still requires a running backend with an image-capable configured model and a logged-in patient.
