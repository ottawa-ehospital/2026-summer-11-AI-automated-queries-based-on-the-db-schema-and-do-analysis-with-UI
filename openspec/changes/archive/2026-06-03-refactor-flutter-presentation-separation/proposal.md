## Why

Flutter screens currently mix feature logic, widget layout, visible text, spacing, colors, gradients, and repeated style constants in the same files. This makes the app hard to review, hard to restyle consistently, and risky to extend because small UI text or layout changes require editing large stateful screens.

## What Changes

- Separate presentation concerns in `src/app/lib` into dedicated layers for layout primitives, design tokens, and localizable user-facing strings.
- Move repeated spacing, radius, typography, color, gradient, shadow, and component styling values out of feature screens and into shared UI/theme files.
- Move feature-specific page layout, section composition, and CSS-like style definitions out of `screens/*.dart` into feature-local presentation files such as `features/<feature>/widgets`, `features/<feature>/layout`, or `features/<feature>/presentation`.
- Move hardcoded visible text labels, titles, empty/error messages, button labels, and health disclaimer copy into Flutter l10n-compatible resources, preferably ARB files managed by Flutter `gen-l10n`.
- Where constants are used as a transitional compatibility layer, keep them key-based and generated/delegated from the l10n source rather than becoming a second long-term text system.
- Introduce reusable layout and section widgets for common app structures such as page scaffolds, action rows, metric grids, hero/header panels, form sections, and data cards.
- Refactor existing feature screens incrementally to consume both shared presentation primitives and feature-local presentation widgets/styles while preserving routes, repositories, services, API contracts, and current UI behavior.
- Keep business logic and data access in feature/repository/service layers; presentation resources must not call APIs or own domain state.
- No breaking changes to backend APIs, Flutter route names, authentication flow, eHospital integration, Fitbit integration, or AI provider configuration.

## Capabilities

### New Capabilities

- `flutter-presentation-system`: Defines how Flutter UI layout primitives, feature-local page presentation, localizable text resources, and style tokens are separated from feature logic and reused across screens.

### Modified Capabilities

- None.

## Impact

- Affected Flutter code: `src/app/lib/ui`, `src/app/lib/core/widgets`, `src/app/lib/features/**/screens`, `src/app/lib/features/**/widgets`, feature-local layout/style folders, `src/app/lib/l10n` or the project-selected l10n resource folder, and feature barrel exports where reusable widgets are introduced.
- Affected tooling: analyzer/test/build commands should continue to work; existing `tasks.ps1` and `Makefile` targets should not need behavior changes beyond optional checks.
- Not affected: Python backend API contracts, repository method signatures, remote eHospital table contracts, local mock data schemas, route names, and authentication behavior.
