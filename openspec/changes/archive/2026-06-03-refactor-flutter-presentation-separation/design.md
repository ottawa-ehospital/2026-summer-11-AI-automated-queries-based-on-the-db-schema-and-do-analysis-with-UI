## Context

The Flutter app has already been reorganized into feature folders, repositories, services, and a backend-facing API layer. The remaining pain point is inside the feature screens: many screens still directly define layout structure, copy, spacing, colors, shadows, gradients, and repeated style constants inside large `StatefulWidget` or `StatelessWidget` files.

This change is cross-cutting because it affects most Flutter feature screens and shared UI files. The implementation must preserve existing routes, API calls, data flow, login behavior, and backend contracts while making presentation code easier to maintain.

## Goals / Non-Goals

**Goals:**

- Create a clear presentation system for shared design tokens, l10n-compatible text resources, reusable layout widgets, and feature-local presentation files.
- Reduce hardcoded `Text`, color, gradient, spacing, border radius, and shadow values in feature screens.
- Make feature screens thinner: they should bind state/actions to shared and feature-local presentation widgets instead of owning page layout and repeated styling.
- Keep app behavior visually equivalent unless a small consistency fix is necessary.
- Keep comments concise around non-obvious presentation boundaries.
- Keep analyzer/test/build workflows working during and after migration.

**Non-Goals:**

- Do not redesign the app visually or introduce a new design language.
- Do not translate the app into multiple languages in this change; establish the localization-ready structure and migrate existing source strings into it.
- Do not change backend API contracts, repository signatures, auth behavior, Fitbit behavior, eHospital table contracts, or AI provider selection.
- Do not move business logic into shared UI widgets.
- Do not fix all existing deprecation info such as `withOpacity` unless touched code naturally moves to a token/helper that removes it.

## Decisions

### Decision 1: Use Flutter l10n-Compatible Text Resources

Create centralized text resources using Flutter's standard localization shape, preferably ARB files under `src/app/lib/l10n` with Flutter `gen-l10n` enabled. The default source locale can remain English for now, but the keys, descriptions, placeholders, and generated access pattern should follow Flutter l10n conventions.

If implementation constraints make full `gen-l10n` setup too large for one pass, a temporary `app_text.dart` constants layer may be used only when it mirrors stable l10n-style keys and can be mechanically migrated to ARB. It must not become a second independent source of truth.

Alternative considered: use only Dart constants or JSON loaded at runtime. Constants are simple, but they do not enforce Flutter localization conventions. Runtime JSON adds parsing and fallback behavior that Flutter already solves through ARB/gen-l10n. ARB is the preferred final shape because it is standard for Flutter and supports placeholders, metadata, and future translations.

### Decision 2: Keep Design Tokens in `ui`, Reusable Widgets in `core/widgets`

Use `src/app/lib/ui` for tokens and theme concerns:

- `app_colors.dart`
- `app_spacing.dart`
- `app_radii.dart`
- `app_typography.dart`
- `app_shadows.dart`
- `app_gradients.dart`
- existing `app_theme.dart`

Use `src/app/lib/l10n` for localizable copy and generated lookup access. Keep any `ui/app_text.dart` file, if introduced, as a compatibility facade over l10n keys rather than a parallel text store.

Use `src/app/lib/core/widgets` for shared widgets that are feature-neutral:

- page scaffolds
- section headers
- metric grids
- status/empty/error views
- cards and panels
- form/action rows

Feature-specific composite widgets may live under `src/app/lib/features/<feature>/widgets` when they contain feature vocabulary or state assumptions.

Feature-specific layout and style files should be created when a page has presentation that is not generic enough for `core/widgets` but is too large or repetitive to remain in `screens/*.dart`. Recommended folders:

- `features/<feature>/widgets`: feature-specific UI components and page sections
- `features/<feature>/layout`: page composition helpers or feature-specific scaffold/body layout widgets
- `features/<feature>/presentation`: feature-specific style constants, view data adapters, and small presentation helpers

Feature-local presentation files may depend on `ui` tokens, `core/widgets`, generated l10n accessors passed from context, and simple view data. They must not call repositories, services, backend APIs, or own domain workflow state.

Alternative considered: put everything under `components`. The current code already has `core/widgets` and `ui`, so extending those folders keeps the architecture consistent with previous refactors and avoids introducing a second naming convention.

### Decision 3: Screens Become State and Composition Boundaries

Feature screens should continue to own controllers, selected state, async loading state, navigation callbacks, and repository/service calls where that is the current architecture. They should delegate page sections, style definitions, and repeated layout blocks to shared or feature-local presentation widgets. Shared and feature-local layout widgets must receive data and callbacks through constructor parameters.

Alternative considered: move each screen to a full view-model architecture as part of this change. That is a larger behavior and state-management refactor. It can happen later, but this change should focus on presentation separation.

### Decision 4: Migrate by Feature Risk

Migrate smaller and lower-risk screens first to prove the pattern, then larger screens:

1. Shared tokens/text/widget foundations.
2. Auth, settings, profile, tools, medications, symptoms, emergency.
3. Dashboard, health assistant, devices.
4. Vitals, vitals history, trends, insights.

Large analytical screens should be split into local feature widgets before trying to remove every hardcoded visual value.

### Decision 5: Preserve Public Contracts

No route names, repository method signatures, backend endpoints, or request/response shapes should change. If a widget extraction reveals duplicated API parsing or data mapping, that logic should remain in repositories/services or be moved there only when signatures remain compatible.

## Risks / Trade-offs

- Large diff size -> Migrate in passes and keep each pass behavior-preserving.
- Over-abstracted shared widgets -> Only put patterns used by at least two screens into `core/widgets`; keep page-specific presentation in feature-local files.
- Feature-local folders become inconsistent -> Use a small naming convention and update feature barrel exports where useful.
- Text resources become a dumping ground -> Organize ARB keys by feature/screen prefix with descriptions and placeholders.
- l10n migration becomes too broad -> Migrate hardcoded text by screen group and keep the default locale text unchanged during extraction.
- Layout widgets accidentally own business logic -> Require shared widgets to accept plain values and callbacks only.
- Analyzer still reports existing deprecation info -> Treat deprecations separately unless this refactor naturally touches that line.
- Visual regressions from shared spacing/theme changes -> Prefer replacing repeated values with equivalent tokens first, then tune later in a separate design pass.

## Migration Plan

1. Add presentation tokens and Flutter l10n resources without changing screen behavior.
2. Add reusable layout widgets in `core/widgets`.
3. Add feature-local presentation folders for screens that have page-specific layout/style complexity.
4. Migrate low-risk screens to generated l10n accessors and the new shared/feature-local presentation resources.
5. Migrate large screens by extracting feature-local widgets/layout/style files first, then replacing hardcoded tokens/text with tokens and l10n accessors.
6. Run `flutter analyze`, `flutter test`, and Flutter web build after each major pass.
7. If a pass causes visual or behavior regressions, revert only that pass and keep the foundational presentation layer.

## Open Questions

- Whether existing one-off visual differences are intentional. During implementation, prefer preserving them unless they are clearly accidental duplication.
