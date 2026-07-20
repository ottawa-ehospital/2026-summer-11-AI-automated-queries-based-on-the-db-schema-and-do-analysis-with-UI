## Context

The previous refactor moved most Flutter code into `features`, introduced shared network/repository boundaries, and moved backend ownership under `src/backend`. During that work, several legacy Dart files were migrated from older source with corrupted comment text such as mojibake box-drawing sequences and replacement characters. Some legacy helper functions also survived the move with unused variables, stale assumptions, or fragile parsing patterns.

This change is a cleanup pass after the architectural refactor has been manually accepted. It should make the migrated source easier to maintain without changing product behavior.

## Goals / Non-Goals

**Goals:**

- Remove corrupted comments and obvious mojibake from migrated Flutter source.
- Add concise explanatory comments for API-facing code where the data flow or boundary is not obvious.
- Keep affected Dart files encoded as UTF-8.
- Add or update a lightweight text hygiene validation command if useful.
- Repair legacy helper functions that analyzer warnings or code review show are stale after migration.
- Keep current UI, routes, backend API contracts, repository interfaces, and local/remote data flows stable.
- Preserve existing app copy unless it is corrupted or demonstrably misleading.

**Non-Goals:**

- Full visual redesign.
- Full lint cleanup across all `withOpacity` or broad style-only warnings.
- Introducing Riverpod/Bloc/Provider or another state management framework.
- Changing backend endpoint contracts or remote eHospital table schemas.
- Rewriting large feature screens from scratch.

## Decisions

### Decision 1: Treat text hygiene as source health, not translation

Corrupted comments should be replaced with short readable English comments or removed if they add no value. The implementation should not translate all UI copy or rewrite ordinary comments just for tone.

Alternative considered: delete all comments in affected files. That is simple, but a few comments explain demo data simulation and clinical chart logic, so readable replacement is better.

### Decision 1.1: Comment API boundaries, not obvious assignments

API-related comments should explain why a repository/client/router boundary exists, what external contract is being protected, or what response shape is being normalized. They should not narrate simple assignments or duplicate function names.

Alternative considered: add broad comments to every public method. That creates noise quickly; the better target is code where a future maintainer might otherwise accidentally bypass the backend/repository boundary.

### Decision 2: Prefer targeted legacy function fixes

Legacy helper fixes should be driven by analyzer warnings, broken assumptions from the feature migration, or obviously dead/unreachable code. The implementation should not perform speculative algorithm rewrites.

Alternative considered: aggressively refactor the large migrated screens. That would likely improve structure, but it would blur this cleanup change with a larger feature decomposition.

### Decision 3: Keep validation lightweight

Use `rg`-based scans and existing Flutter checks first. If a helper script is added, it should be small, deterministic, and runnable from `tasks.ps1`/Makefile without extra dependencies.

Alternative considered: add a full encoding/lint toolchain. That would be stronger, but unnecessary for the current project size and cleanup target.

### Decision 4: Preserve accepted architecture

The cleanup should happen inside the feature/core/data/backend structure produced by the previous refactor. Compatibility shims and startup commands should only change if they directly reference legacy paths or need validation hooks.

Alternative considered: reopen the previous architecture change. A fresh cleanup change keeps the scope auditable and avoids mixing accepted refactor work with follow-up fixes.

## Risks / Trade-offs

- Corrupted comments may contain lost meaning -> Replace only with comments that can be inferred from nearby code, otherwise remove them.
- Text replacement can accidentally alter UI strings -> Search and review visible strings separately from comments before editing.
- Encoding fixes can create large diffs -> Limit file rewrites to affected legacy files and verify analyzer/build afterward.
- Legacy function cleanup may expose old behavior differences -> Keep changes small and verify with `flutter analyze`, `flutter test`, and web build.
- Added comments can become stale -> Keep comments focused on boundaries and invariants rather than implementation minutiae.
- Some analyzer info may remain -> Treat remaining broad style warnings as acceptable unless they point to touched broken legacy logic.

## Migration Plan

1. Inventory migrated legacy Flutter files for mojibake patterns and replacement characters.
2. Classify matches as comments, visible UI strings, or data literals.
3. Replace corrupted comments with concise readable comments or remove decorative noise comments.
4. Add concise comments to API/repository/backend boundary code where cleanup or refactor context is important.
5. Repair visible text only when it is clearly corrupted.
6. Scan for legacy helper warnings such as unused locals, unused private methods, stale branch variables, fragile parsing, or now-unnecessary wrappers.
7. Apply targeted function fixes in affected feature screens/services.
8. Add a text hygiene check to scripts if the scan can be made stable and low-noise.
9. Run Flutter analyze/test/build and relevant OpenSpec status checks.

Rollback strategy: this change is source-only and should not alter external contracts, so rollback is a normal source revert of the cleanup files if behavior changes unexpectedly.

## Open Questions

- Should remaining broad deprecated `withOpacity` warnings be handled in a later lint-focused change?
- Should the text hygiene scan run by default in `py-check`/`flutter-check`, or remain an explicit command?
