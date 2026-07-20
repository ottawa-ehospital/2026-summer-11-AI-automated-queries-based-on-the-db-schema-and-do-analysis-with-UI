## 1. Baseline and Inventory

- [x] 1.1 Run `rg` scans for inline presentation values in `src/app/lib/features`.
- [x] 1.2 Run `flutter analyze` and record existing non-blocking deprecation info separately from refactor issues.
- [x] 1.3 Identify screens with the highest concentration of hardcoded text, colors, spacing, gradients, duplicated layout, and page-specific section composition.
- [x] 1.4 Confirm current route entry points from `main.dart` and feature barrel exports before editing.
- [x] 1.5 Check whether Flutter `gen-l10n` is already configured in `pubspec.yaml`, `l10n.yaml`, or existing generated localization files.
- [x] 1.6 Inventory existing feature folders and decide which need `widgets`, `layout`, or `presentation` subfolders for page-specific extraction.

## 2. Presentation Foundation

- [x] 2.1 Add or expand shared design token files under `src/app/lib/ui` for colors, spacing, radii, typography, shadows, and gradients.
- [x] 2.2 Configure Flutter l10n resources using ARB files and generated accessors, or document a temporary l10n-compatible facade if full generation cannot be completed in the same pass.
- [x] 2.3 Add source-locale ARB entries for repeated app, auth, dashboard, vitals, assistant, settings, profile, device, and disclaimer copy.
- [x] 2.4 Add descriptions and placeholder metadata for dynamic strings such as dates, metrics, upload counts, patient names, and status values.
- [x] 2.5 Keep any constants-based text layer key-based and delegated to l10n so it can be removed later.
- [x] 2.6 Update `app_theme.dart` to consume the shared token files where practical without changing the visual design.
- [x] 2.7 Add concise comments explaining the token/l10n boundaries and how new text should be added.

## 3. Shared Layout Widgets

- [x] 3.1 Create or expand reusable page scaffold, section header, app card, metric tile/grid, action row, and state view widgets in `core/widgets`.
- [x] 3.2 Add reusable form and panel helpers for common screen sections without embedding feature-specific business logic.
- [x] 3.3 Ensure shared widgets receive plain values and callbacks through constructors.
- [x] 3.4 Export shared widgets from a stable barrel file if the project pattern supports it.

## 4. Feature-Local Presentation Structure

- [x] 4.1 Create feature-local `widgets`, `layout`, or `presentation` folders for features whose screens contain page-specific UI structure.
- [x] 4.2 Define a consistent naming pattern for feature-local section widgets, page layout widgets, and style/token helpers.
- [x] 4.3 Move page-specific CSS-like values that are not global tokens into feature-local presentation/style files.
- [x] 4.4 Move page-specific section composition out of `screens/*.dart` and into feature-local widgets/layout helpers.
- [x] 4.5 Confirm feature-local presentation files depend only on UI tokens, shared widgets, l10n accessors passed from context, plain view data, and callbacks.

## 5. Low-Risk Screen Migration

- [x] 5.1 Refactor auth/login screens to use l10n text accessors, tokens, and form/panel widgets.
- [x] 5.2 Refactor settings and profile screens to use l10n text accessors, tokens, and section widgets.
- [x] 5.3 Refactor tools, medications, symptoms, goals, and emergency screens to remove duplicated static copy and inline presentation constants.
- [x] 5.4 Move low-risk page-specific layout/style blocks into feature-local presentation files where shared widgets are not appropriate.
- [x] 5.5 Run focused analyzer checks after the low-risk migration and fix any new compile/import/unused issues.

## 6. Medium-Risk Screen Migration

- [x] 6.1 Refactor dashboard cards, headers, and navigation action blocks to use shared layout widgets and feature-local dashboard sections.
- [x] 6.2 Refactor health assistant chat presentation, disclaimer copy, and message bubbles to use l10n text accessors, shared tokens, and feature-local chat widgets while preserving chat behavior.
- [x] 6.3 Refactor device connection screens to use shared panels, state views, progress text helpers, action rows, and feature-local device sections.
- [x] 6.4 Move medium-risk page-specific layout/style blocks into feature-local presentation files where shared widgets are not appropriate.
- [x] 6.5 Confirm API/service calls remain in repositories, services, or screen state handlers and are not moved into shared or feature-local widgets.

## 7. High-Risk Screen Migration

- [x] 7.1 Extract feature-local widgets from vitals screens before replacing hardcoded presentation values.
- [x] 7.2 Extract feature-local widgets from vitals history and trends screens for charts, metric sections, and filter controls.
- [x] 7.3 Extract feature-local widgets from insights screens for chart panels, correlation cards, and summary sections.
- [x] 7.4 Extract feature-local style/presentation helpers for chart colors, panel decoration, metric formatting, and filter layout where values are page-specific.
- [x] 7.5 Replace repeated static copy and visual constants in high-risk screens with l10n accessors and shared or feature-local resources after extraction.
- [x] 7.6 Verify large-screen migrations preserve data loading, filtering, chart rendering, and navigation behavior.

## 8. Contract and Hygiene Checks

- [x] 8.1 Confirm repository method signatures and backend request/response shapes are unchanged.
- [x] 8.2 Confirm eHospital, Fitbit, and AI provider configuration behavior is unchanged.
- [x] 8.3 Run text hygiene scans to ensure no mojibake or corrupted presentation strings were introduced.
- [x] 8.4 Run targeted `rg` scans to confirm migrated screens no longer contain repeated hardcoded layout/text/style patterns where shared or feature-local resources exist.
- [x] 8.5 Run targeted scans for `Text("...")`, `Text('...')`, `SnackBar(content: Text(...))`, and interpolated visible strings in migrated screens to confirm user-facing copy moved to l10n resources.
- [x] 8.6 Run targeted scans for large `Container`, `Padding`, `Column`, chart panel, and decoration blocks remaining in migrated `screens/*.dart` files and move page-specific layout/style to feature-local presentation files.

## 9. Verification

- [x] 9.1 Run `.\tasks.ps1 text-check`.
- [x] 9.2 Run `flutter analyze` and confirm no new compile, import, URI, unused-code, or presentation-refactor issues remain.
- [x] 9.3 Run `flutter test --dart-define=AI_PROVIDER=backend`.
- [x] 9.4 Build Flutter web with backend provider defines.
- [x] 9.5 Run `openspec validate refactor-flutter-presentation-separation --strict`.
- [x] 9.6 Update this task list as implementation work completes.
