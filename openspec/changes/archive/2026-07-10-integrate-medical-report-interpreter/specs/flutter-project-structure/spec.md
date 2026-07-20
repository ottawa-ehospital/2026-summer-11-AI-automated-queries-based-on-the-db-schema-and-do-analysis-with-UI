## ADDED Requirements

### Requirement: Report interpreter follows feature-first structure
The integrated report interpreter UI SHALL live under the host app's feature-first Flutter structure instead of retaining the extracted standalone app entry point.

#### Scenario: Feature directory exists
- **WHEN** a developer inspects `src/app/lib/features`
- **THEN** report interpreter source is organized under `features/report_interpreter`
- **THEN** report interpreter screens, models, data access, widgets, and presentation helpers have clear feature ownership

#### Scenario: Standalone main is not imported as app shell
- **WHEN** the report interpreter is integrated
- **THEN** the host app does not replace `src/app/lib/main.dart` with the extracted project's `main.dart`
- **THEN** the extracted standalone app shell is not used as the Smart Health app shell

### Requirement: Existing route behavior remains stable
The integration SHALL preserve existing Smart Health routes while adding the report interpreter as an AI module or optional route.

#### Scenario: Existing assistant route opens
- **WHEN** a user navigates to `/assistant`
- **THEN** the AI assistant area opens successfully
- **THEN** the existing Health Chat experience remains available
