## Context

The current `/assistant` route renders a simple choice screen with two card rows: Chat and Report Analyze. Selecting either card pushes the corresponding existing module page. The user wants this selection step to feel more like Apple Watch workout selection: vertically scrollable, focused on one centered choice, touch-friendly, and ready for several more AI apps expected later.

The change is limited to the Health Assistant entry UI. Health Chat session persistence, Report Interpreter workflows, repositories, backend endpoints, and route names stay intact. The app already has feature-local presentation files and reusable UI tokens, so the picker should follow that structure instead of embedding all styling in the screen.

## Goals / Non-Goals

**Goals:**
- Replace the static AI module cards with a vertical picker-style module selector.
- Preserve the two existing module destinations and their navigation behavior.
- Keep module rendering data-driven so future AI apps can be added through module definitions rather than new bespoke selector UI.
- Make the selected module visually obvious through center focus, scale, opacity, and supporting detail.
- Keep the selector mobile-safe with stable dimensions, readable text, and reachable actions.
- Extract picker-specific widgets/styles into the Health Assistant feature presentation/widget layer where appropriate.
- Move user-facing picker copy to localization resources or the existing l10n facade pattern.

**Non-Goals:**
- Do not change assistant backend endpoints, prompt construction, or report interpretation behavior.
- Do not implement new AI modules beyond the existing Chat and Report Analyze entries in this change.
- Do not redesign the Health Chat conversation UI or Report Interpreter screen.
- Do not introduce a new navigation framework or external UI dependency unless implementation discovers an existing project dependency that already solves the picker cleanly.

## Decisions

1. Build the selector as a feature-local Flutter widget backed by an extensible module definition list.

   The entry screen should remain responsible for owning module definitions and navigation callbacks, while a dedicated picker widget handles scroll presentation and selection state. Each module definition should include stable identity, localized label/description, icon, and builder or launch callback. This keeps business behavior in the screen, UI mechanics in the feature-local widget layer, and future module additions limited to appending definitions plus their destination wiring.

   Alternative considered: keep all picker code inside `health_assistant_screen.dart`. This would be faster initially but would worsen an already stateful screen and conflict with the existing presentation separation direction.

2. Use a vertical scroll controller/page-style selection instead of two independent cards.

   The picker should maintain a selected index and update it as the user scrolls. A `PageView` with vertical scrolling or a fixed-extent wheel-style list are both acceptable implementation options; the chosen widget must provide predictable item sizing, centered focus, testable selection callbacks, and no hardcoded assumptions about exactly two modules.

   Alternative considered: a plain `ListView` with larger cards. That would improve visuals but would not create the intended Apple Watch-like focused selection interaction.

3. Launch modules through the existing route push behavior.

   Selecting Chat or Report Analyze should still navigate to the current module pages using the same builders. This avoids changes to chat session state, report upload behavior, or backend request contracts.

   Alternative considered: render selected modules inline below the picker. That would make the route lifecycle ambiguous and risk mixing selection state with module workflow state.

4. Localize picker copy and keep styling token-based.

   The picker title, hint text, module labels, descriptions, and primary action text should come from app localization resources or the documented l10n facade. Visual values should compose existing app tokens and Health Assistant presentation styles.

   Alternative considered: hardcode the picker text while prototyping. That is not suitable for an OpenSpec implementation because the existing presentation-system spec requires localizable text.

## Risks / Trade-offs

- [Risk] A wheel-style picker can hide that there are only two options. -> Mitigation: keep both adjacent options partially visible and provide clear selected-state copy plus a primary launch action.
- [Risk] Future modules may have longer labels or descriptions than the initial two modules. -> Mitigation: constrain item text, use localized short labels plus concise descriptions, and test the picker with at least three module definitions.
- [Risk] Scroll physics or scaling can cause text clipping on small phones. -> Mitigation: use fixed item extents, max line counts, responsive constraints, and widget tests or manual viewport checks.
- [Risk] Accessibility users may find focus-based selection unclear. -> Mitigation: ensure each module is tappable, expose semantic labels, and keep the primary action tied to the selected module.
- [Risk] Over-polishing the selector could create a one-off visual system. -> Mitigation: use existing app colors, spacing, radii, typography, and feature-local presentation helpers.

## Migration Plan

1. Add localized picker strings and any feature-local picker styles/widgets.
2. Replace the `/assistant` entry body with the vertical picker while retaining the existing module definitions and builders.
3. Add or update tests that verify scrolling/tapping selection, launching both modules, and rendering a picker with more than two module definitions.
4. Run Flutter analysis and targeted tests.

Rollback is straightforward: restore the previous card chooser body while keeping the unchanged module destinations.

## Open Questions

- Should the primary action text be generic, such as "Open", or module-specific, such as "Start Chat" and "Analyze Report"? Implementation can choose the clearest localized copy while preserving the same behavior.
