# Flutter Presentation System

## Purpose

Presentation-layer structure for reusable Flutter design tokens, localization resources, layout primitives, and feature-local UI extraction.

## Requirements

### Requirement: Centralized Design Tokens
The Flutter app SHALL expose shared presentation tokens for colors, spacing, radii, typography, shadows, gradients, and common component styling outside feature screen files.

#### Scenario: Screen uses shared styling
- **WHEN** a migrated feature screen renders cards, panels, buttons, headers, or metric tiles
- **THEN** repeated visual values such as colors, spacing, radii, gradients, and shadows are read from shared UI/theme resources rather than duplicated inline in the screen

#### Scenario: Token layer remains presentation-only
- **WHEN** a shared token file is inspected
- **THEN** it contains presentation constants or helpers and does not call repositories, services, backend APIs, or feature state

### Requirement: Localizable User-Facing Text
The Flutter app SHALL expose user-facing text through Flutter l10n-compatible resources outside feature screen files for titles, labels, button text, empty states, error text, status messages, and health disclaimers.

#### Scenario: Screen uses l10n resources
- **WHEN** a migrated feature screen displays static or repeated copy
- **THEN** the copy is referenced from generated l10n accessors or a documented l10n facade rather than hardcoded directly in the widget tree

#### Scenario: Text resources follow Flutter localization conventions
- **WHEN** text resources are added for migrated screens
- **THEN** they use Flutter-compatible localization keys, descriptions, and placeholder metadata so they can be generated from ARB or mechanically migrated to ARB

#### Scenario: Dynamic text stays typed
- **WHEN** a migrated feature screen displays dynamic copy that interpolates values
- **THEN** the l10n resource defines typed placeholders or a clearly named l10n helper instead of requiring ad hoc string construction in the widget tree

#### Scenario: Constants are transitional only
- **WHEN** a constants-based text facade is introduced
- **THEN** it delegates to or mirrors l10n keys and is documented as transitional rather than becoming a parallel long-term text source

### Requirement: Reusable Layout Primitives
The Flutter app SHALL provide reusable layout primitives for common app structures such as page scaffolds, section headers, action rows, metric grids, cards, panels, forms, and empty/error/loading states.

#### Scenario: Common layout is reused
- **WHEN** two or more screens need the same structural layout pattern
- **THEN** the shared pattern is represented by a reusable widget or helper instead of being duplicated in each screen

#### Scenario: Layout widgets receive data through parameters
- **WHEN** a reusable layout widget is implemented
- **THEN** it receives values and callbacks through constructor parameters and does not fetch remote data or own domain workflow state

### Requirement: Feature-Local Presentation Separation
The Flutter app SHALL move page-specific layout, section composition, and CSS-like style definitions out of feature `screens/*.dart` files into feature-local presentation files when those concerns are not generic enough for shared `core/widgets`.

#### Scenario: Page-specific layout is extracted
- **WHEN** a migrated screen contains large page-specific layout blocks, repeated section composition, or feature-specific visual structure
- **THEN** those blocks are moved into feature-local widgets, layout files, or presentation helpers under that feature folder

#### Scenario: Page-specific styles are extracted
- **WHEN** a migrated screen uses feature-specific colors, gradients, padding combinations, chart styles, badge styles, or panel decoration values that are not global tokens
- **THEN** those values are defined in a feature-local presentation/style file that composes shared tokens where possible

#### Scenario: Feature-local presentation stays UI-only
- **WHEN** a feature-local widget, layout helper, or style file is inspected
- **THEN** it does not call repositories, services, backend APIs, Fitbit, eHospital, or AI provider code

#### Scenario: Screen remains a composition boundary
- **WHEN** a migrated `screens/*.dart` file is reviewed
- **THEN** it primarily owns state, lifecycle, navigation, repository/service interaction, and composition of presentation widgets rather than detailed layout and CSS-like styling

### Requirement: Feature Screens Remain Thin Presentation Binders
Migrated feature screens SHALL primarily bind feature state, navigation, and callbacks to l10n text accessors, design tokens, and reusable layout widgets.

#### Scenario: Screen owns feature state
- **WHEN** a screen has text controllers, selected filters, loading flags, navigation callbacks, or repository calls in the current architecture
- **THEN** those responsibilities remain in the screen or feature layer unless an existing repository/service boundary already owns them

#### Scenario: Screen avoids presentation duplication
- **WHEN** a migrated screen is reviewed
- **THEN** it does not contain large repeated blocks of inline `TextStyle`, `EdgeInsets`, color literals, gradients, shadows, section layout, or repeated static copy when a shared or feature-local resource exists

### Requirement: Behavior Contracts Remain Stable
The presentation refactor SHALL preserve current app behavior and public integration contracts.

#### Scenario: Flutter routes still resolve
- **WHEN** the app starts through `main.dart` and navigates to existing feature pages
- **THEN** all existing routes and visible feature entry points continue to resolve

#### Scenario: API contracts remain unchanged
- **WHEN** repositories and services call the backend, eHospital, Fitbit, or AI provider integrations
- **THEN** request shapes, response parsing responsibilities, method signatures, and configured provider behavior remain compatible with the pre-refactor app

#### Scenario: Verification passes
- **WHEN** implementation is complete
- **THEN** text hygiene scan, Flutter tests, and Flutter web build pass, and `flutter analyze` has no new compile, import, URI, unused-code, or presentation-refactor errors

### Requirement: Interactive Feature Selectors Use Presentation Resources
Feature-level interactive selectors SHALL use shared presentation tokens, localizable user-facing text, and feature-local widgets or styles when selector behavior is specific to one feature.

#### Scenario: AI assistant picker uses presentation resources
- **WHEN** the AI assistant module picker is implemented
- **THEN** picker labels, descriptions, headings, and action text are sourced from l10n-compatible resources or the documented l10n facade
- **AND** picker spacing, color, typography, radii, and motion-related visual treatment compose existing app tokens or Health Assistant feature-local presentation resources

#### Scenario: Selector implementation remains feature-local
- **WHEN** the AI assistant module picker requires custom layout, selection, or styling code
- **THEN** that code is placed in Health Assistant feature-local widgets or presentation files unless it is generic enough for shared core widgets
- **AND** the feature-local picker UI does not call backend APIs, repositories, AI services, Fitbit, eHospital, or provider SDKs directly
