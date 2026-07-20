## 1. Picker Structure

- [x] 1.1 Review the existing `/assistant` entry screen module definitions and preserve the Health Chat and Report Analyze builders.
- [x] 1.2 Shape the module definition data so each module has stable identity, localized label/description, icon, and launch builder or callback.
- [x] 1.3 Add or update feature-local Health Assistant picker widget(s) to render a vertical scrollable selector from an arbitrary module list with a stable selected index.
- [x] 1.4 Move picker-specific visual values into Health Assistant presentation resources, composing existing app colors, spacing, typography, radii, and shadows.

## 2. Entry Screen Integration

- [x] 2.1 Replace the static AI module card list in `HealthAssistantScreen` with the vertical picker selector.
- [x] 2.2 Wire vertical scrolling and focused-item taps so the selected module updates predictably.
- [x] 2.3 Wire the launch action so Health Chat and Report Analyze open through the existing module builders without changing their workflows.
- [x] 2.4 Ensure small mobile layouts keep picker text, icons, focused state, and launch controls readable and reachable for two or more modules.

## 3. Localization and Accessibility

- [x] 3.1 Move picker heading, helper text, module labels, descriptions, and action text into l10n-compatible resources or the existing l10n facade.
- [x] 3.2 Add meaningful semantics for module items, selected state, and activation targets.

## 4. Verification

- [x] 4.1 Add or update Flutter widget tests for default selected module, vertical selection changes, and launching both modules.
- [x] 4.2 Add a widget test or test fixture that provides at least three module definitions and verifies the picker still renders and selects modules through the same path.
- [x] 4.3 Run targeted Flutter tests for the Health Assistant UI.
- [x] 4.4 Run `flutter analyze` for the app and fix any new analyzer issues.
