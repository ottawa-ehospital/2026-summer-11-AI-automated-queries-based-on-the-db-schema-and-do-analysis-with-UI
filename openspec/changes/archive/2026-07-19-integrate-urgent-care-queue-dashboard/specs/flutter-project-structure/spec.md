## ADDED Requirements

### Requirement: Urgent-care feature follows host Flutter structure
The urgent-care integration SHALL live under the host app's feature-first Flutter structure instead of retaining CareFlow's separate patient Flutter app entry point or migrating CareFlow's staff web dashboard.

#### Scenario: Feature directory owns urgent-care code
- **WHEN** a developer inspects `src/app/lib/features`
- **THEN** urgent-care source is organized under `features/urgent_care`
- **AND** urgent-care screens, models, data access, widgets, and presentation helpers have clear feature ownership

#### Scenario: Standalone CareFlow app shells are not imported
- **WHEN** urgent-care screens are integrated
- **THEN** the host app does not replace `src/app/lib/main.dart` with CareFlow's `patient_app/lib/main.dart`
- **AND** the host app does not replace `src/app/lib/main.dart` with CareFlow's `flutter_frontend/lib/main.dart`
- **AND** the downloaded standalone Flutter projects are not copied into `src/app` as runnable nested apps

#### Scenario: Staff dashboard UI is not added
- **WHEN** urgent-care is integrated into the Flutter app
- **THEN** staff web dashboard screens from CareFlow are not recreated as mobile routes
- **AND** the feature contains patient-facing screens only

#### Scenario: Existing route behavior remains stable
- **WHEN** urgent-care routes are added
- **THEN** existing routes such as `/dashboard`, `/emergency`, `/assistant`, `/vitals`, `/goals`, and `/settings` continue to open successfully
