## Why

The Health Assistant entry screen currently asks users to choose between two AI tools using ordinary cards, which feels visually disconnected from the mobile app and makes the choice page feel like a menu rather than a focused assistant launcher. A vertically scrollable picker, inspired by Apple Watch workout selection, will make the AI chat entry feel more tactile, mobile-native, and easier to extend as more AI tools are added.

## What Changes

- Replace the current static two-card AI tool chooser at `/assistant` with a vertically scrollable picker-style selector that can support additional AI tools without redesigning the entry screen.
- Keep the existing AI destinations: health chat and report analysis.
- Represent AI tools through a reusable module definition shape so future modules can be added by appending definitions rather than duplicating picker UI.
- Highlight the centered/selected AI tool with stronger scale, opacity, and detail treatment while non-selected tools remain visible above and below.
- Let users enter the selected AI tool with an obvious primary action or by tapping the focused item.
- Preserve existing Health Chat and Report Interpreter routes, state, repository contracts, and backend request behavior.
- Ensure the picker layout works on mobile-sized screens without text clipping, overlap, or unreachable actions.

## Capabilities

### New Capabilities
- `ai-assistant-module-picker`: Defines the Health Assistant entry selection experience for vertically browsing and launching AI assistant modules.

### Modified Capabilities
- `flutter-presentation-system`: The AI assistant picker must use presentation-layer styling, l10n-ready copy, and feature-local UI extraction consistent with the existing Flutter presentation conventions.

## Impact

- Affected Flutter UI under `src/app/lib/features/health_assistant/`, especially the `/assistant` selection screen inside `health_assistant_screen.dart` and any new feature-local picker widgets or styles.
- Affected localization resources for picker title, module labels, descriptions, and primary action text.
- No backend API or data model changes are expected.
- Tests should cover module selection behavior, verify that both existing AI module destinations remain reachable, and exercise the picker with more than two module definitions.
