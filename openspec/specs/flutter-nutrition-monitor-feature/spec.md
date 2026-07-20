# flutter-nutrition-monitor-feature Specification

## Purpose
TBD - created by archiving change integrate-calorie-track-nutrition-monitor. Update Purpose after archive.
## Requirements
### Requirement: Flutter provides Nutrition Monitor AI module
The Flutter app SHALL provide a `nutrition_monitor` feature module for EHR-aware food image analysis, meal logging, goal progress, and meal history.

#### Scenario: User opens Nutrition Monitor module
- **WHEN** a logged-in user selects Nutrition Monitor from the AI assistant module picker
- **THEN** Flutter displays the Nutrition Monitor screen inside the Smart Health app shell
- **AND** the screen follows the current app theme rather than CalorieTrack's standalone Android navigation

#### Scenario: Patient context is required
- **WHEN** no active patient id is available
- **THEN** Flutter shows a clear login-required or patient-context-required state
- **AND** Flutter does not submit analysis, logging, summary, or history requests with patient id `0` or a hard-coded demo id

### Requirement: Food image input and analysis flow
The Nutrition Monitor feature SHALL let the user provide a meal image and optional hint, submit it for backend analysis, and render the normalized analysis response.

#### Scenario: User submits meal image
- **WHEN** the user selects or captures a meal image and optionally enters a hint
- **THEN** Flutter uploads the image and hint through the Nutrition Monitor repository
- **AND** Flutter shows a loading state while analysis is pending
- **AND** Flutter renders the returned dish, portion, ingredients, nutrient breakdown, risks, warnings, positives, and final verdict

#### Scenario: Image analysis model is unavailable
- **WHEN** the backend reports that the configured model cannot process image input
- **THEN** Flutter disables the analyze action
- **AND** Flutter shows a clear message explaining that the current model does not support food image analysis

#### Scenario: Backend rejects unsupported image analysis
- **WHEN** Flutter receives a `nutrition_image_model_unsupported` error from the analysis endpoint
- **THEN** Flutter keeps the selected image available for later retry after settings change
- **AND** Flutter shows the unsupported-model message instead of a generic network failure

#### Scenario: Analysis fails
- **WHEN** the backend returns an analysis error
- **THEN** Flutter shows a recoverable error state
- **AND** the user can choose another image or retry without leaving the module

#### Scenario: Non-food result
- **WHEN** the backend reports that the image is not food
- **THEN** Flutter shows a non-food message
- **AND** Flutter disables or hides the log-meal action for that result

### Requirement: Meal logging from analysis
The Nutrition Monitor feature SHALL let users log a successful analysis as a meal record.

#### Scenario: User logs meal
- **WHEN** an analysis result is valid food and the user activates the log action
- **THEN** Flutter sends the normalized analysis result through the Nutrition Monitor repository
- **AND** Flutter shows success feedback after the backend accepts the meal
- **AND** daily summary and history state refresh or become stale for refresh

#### Scenario: Log action unavailable before analysis
- **WHEN** no successful food analysis is present
- **THEN** Flutter does not allow a meal log submission

### Requirement: Nutrition goals and progress
The Nutrition Monitor feature SHALL display daily nutrition progress against configurable goals.

#### Scenario: User views daily progress
- **WHEN** the Nutrition Monitor screen loads for a patient
- **THEN** Flutter displays daily totals for calories, protein, carbs, fat, sodium, and sugar where available
- **AND** Flutter compares calories and macros against configured or default goals

#### Scenario: User edits goals
- **WHEN** the user saves new calorie and macro goals
- **THEN** Flutter validates the values
- **AND** Flutter persists them through the repository when a supported remote goal table exists
- **AND** Flutter otherwise stores them through patient-scoped local storage, matching the source app's local goal behavior
- **AND** the progress view updates to use the new goals

### Requirement: Meal history
The Nutrition Monitor feature SHALL provide a patient-scoped meal history view with enough detail to review past logged meals.

#### Scenario: User opens meal history
- **WHEN** the user opens Nutrition Monitor history
- **THEN** Flutter displays logged meals for the active patient
- **AND** each meal includes date/time, dish, portion, calories, nutrients, and safety insight summary when available

#### Scenario: History is empty
- **WHEN** no meals exist for the active patient
- **THEN** Flutter shows an empty state that invites the user to analyze a meal

### Requirement: Source integration hygiene
The Flutter integration SHALL migrate only feature behavior and source concepts from CalorieTrack and SHALL NOT add generated native Android app artifacts to the host Flutter app.

#### Scenario: Standalone Android artifacts are excluded
- **WHEN** the Nutrition Monitor feature is implemented
- **THEN** Kotlin Activity files, Android XML layouts, duplicate Gradle project files, generated build outputs, and standalone app navigation are not copied as runtime code into `src/app`
- **AND** equivalent Flutter widgets, models, and repositories are created under the host app structure

### Requirement: Android source components map to Flutter-native replacements
The Nutrition Monitor feature SHALL replace Android-only CalorieTrack UI and platform components with Flutter-native components that match the current DTI6302 app style.

#### Scenario: Android navigation is replaced
- **WHEN** the CalorieTrack bottom navigation and Activity-based screen flow are migrated
- **THEN** Nutrition Monitor uses the existing Smart Health app shell and AI module picker
- **AND** Flutter does not add a nested Android-style bottom navigation bar inside the module

#### Scenario: Android image pickers are replaced
- **WHEN** camera, gallery, or file image input is implemented
- **THEN** Flutter uses approved Flutter image/file picker abstractions
- **AND** the implementation does not depend on Android `ActivityResultContracts` or `FileProvider` code

#### Scenario: Android visual components are replaced
- **WHEN** CalorieTrack cards, dialogs, buttons, progress indicators, history lists, and toast messages are migrated
- **THEN** Flutter uses current app-style widgets such as themed buttons, app cards, dialogs or sheets, progress indicators, lists, snackbars, and inline errors
- **AND** typography, spacing, colors, and rounded corners remain consistent with existing DTI6302 Flutter screens

#### Scenario: Android preferences are replaced
- **WHEN** CalorieTrack nutrition goals are migrated
- **THEN** Flutter stores goals through the Nutrition Monitor repository or a patient-scoped local storage fallback
- **AND** the implementation does not reuse Android `SharedPreferences` code or global unscoped preference keys

### Requirement: Migrated feature is verified against CalorieTrack source behavior
The Nutrition Monitor implementation SHALL include final verification that compares migrated Flutter behavior against the CalorieTrack source workflows while preserving DTI6302 styling.

#### Scenario: Source behavior checklist is complete
- **WHEN** implementation is ready for review
- **THEN** verification covers image input, optional hint, EHR-aware analysis, non-food handling, result rendering, verdicts, meal logging, daily progress, goal editing, meal history, and patient-scoped isolation
- **AND** any intentionally deferred CalorieTrack behavior is documented

#### Scenario: UI style check is complete
- **WHEN** implementation is ready for review
- **THEN** verification confirms the Nutrition Monitor screen follows current Flutter app styling
- **AND** it does not visually clone CalorieTrack's native Android app chrome, bottom navigation, or XML layout styling

