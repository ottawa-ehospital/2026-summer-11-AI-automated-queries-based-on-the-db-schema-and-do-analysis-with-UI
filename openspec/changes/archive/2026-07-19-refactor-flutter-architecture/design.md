## Context

The Flutter app under `src/app/lib` currently has a shallow structure: `config`, `screens`, `services`, and `ui`. Several screen files own too much responsibility, including UI layout, HTTP calls, URL construction, JSON parsing, error text, AI invocation, feature state, and reusable card/chart widgets. This was workable for a demo, but it is becoming fragile as the project adds backend-backed AI, wearable upload, remote eHospital tables, and future exercise recommendation workflows.

The recent Python AI backend change introduced backend-facing Flutter API code and a Python service, and the repository now contains `src/backend`. That backend still needs clearer module boundaries so future LangGraph expansion can happen in backend services rather than in Flutter screens or compatibility files. Startup scripts also need to reflect the new architecture so developers can run Flutter, backend, and local model modes without remembering several disconnected commands.

## Goals / Non-Goals

**Goals:**

- Establish a stable Flutter architecture with clear ownership boundaries.
- Establish a stable Python backend architecture under `src/backend` with clear API, service, client, schema, and config boundaries.
- Move raw networking and JSON parsing out of screens.
- Move reusable UI fragments into shared widgets or feature-local widgets.
- Keep runtime configuration centralized and avoid committing secret-like values.
- Keep developer startup commands centralized and consistent across `Makefile` and `tasks.ps1`.
- Keep existing route names, screen behavior, backend contracts, and remote eHospital API contracts stable.
- Make the next LangGraph/backend expansion require changes mostly in backend services and Flutter repositories rather than screen widgets.

**Non-Goals:**

- Rewriting the visual design from scratch.
- Changing backend endpoint contracts.
- Changing the remote eHospital API contract.
- Adding a full state management framework unless the existing code clearly benefits from a lightweight controller/repository split.
- Migrating every low-value static page if doing so would create churn without reducing complexity.
- Solving all existing Flutter lint info such as every deprecated `withOpacity` call unless touched files are already being refactored.

## Decisions

### Decision 1: Use feature-first structure with shared core/data layers

Target structure:

```text
lib/
  config/
  core/
    network/
    widgets/
  data/
    models/
    repositories/
  features/
    auth/
    dashboard/
    health_assistant/
    vitals/
    trends/
    profile/
    settings/
  main.dart
```

Rationale: feature-first organization keeps related screen/controller/widget code close together while `core` and `data` prevent cross-feature duplication. This is more scalable than a single global `screens` directory as the app grows.

Alternative considered: keep `screens/` and only add `widgets/`. This is less disruptive, but it does not solve screen ownership or feature growth.

### Decision 2: Use repositories as the app-facing API boundary

Screens and controllers should call repositories such as `AssistantRepository`, `EHospitalRepository`, and `AuthRepository`. Repositories should call shared HTTP clients or focused API services.

Rationale: the app can change from local mock to backend service to deployed service without forcing each screen to understand URLs, response shapes, or error handling.

Alternative considered: keep static service methods called directly from screens. This is simple, but it keeps business/data details spread across UI code.

### Decision 3: Keep configuration typed and environment-driven

Runtime values such as backend URL, eHospital URL, AI provider, model name, and local testing settings should be accessed through config helpers. Secret-like values should not be hard-coded in tracked Dart source.

Rationale: Flutter apps can be decompiled, so committed tokens or API keys are not a safe storage mechanism. The code should also support local machine, web, emulator, physical phone, and deployed backend modes.

Alternative considered: keep constants in `api_config.dart`. This is convenient for demos but becomes risky and brittle as the app moves toward real data workflows.

### Decision 4: Refactor incrementally around high-impact screens

The first implementation pass should prioritize:

- `health_assistant_screen.dart`
- `vitals_screen.dart`
- `trend_comparison_screen.dart`
- `login_screen.dart`
- dashboard/profile screens if they depend on shared auth/session state

Rationale: these screens currently touch AI, remote APIs, auth/session, or reusable chart/card UI. Refactoring them gives the most benefit and validates the architecture.

Alternative considered: move every file at once. This risks large churn and makes regressions harder to isolate.

### Decision 5: Prefer lightweight controllers before adding a state library

Use `ChangeNotifier`, simple controller classes, or plain state objects where useful. Do not add Riverpod/Bloc/Provider unless implementation shows real need.

Rationale: the current app can be improved significantly with clearer layering before introducing another dependency and pattern.

Alternative considered: adopt Riverpod immediately. Riverpod is a good option, but it should be a deliberate separate change if the project needs app-wide reactive state.

### Decision 6: Move Python backend ownership into `src/backend`

Target backend structure:

```text
src/backend/
  __init__.py
  main.py
  api/
    __init__.py
    assistant.py
    health.py
  core/
    __init__.py
    config.py
    errors.py
  clients/
    __init__.py
    ehospital_client.py
    model_client.py
  schemas/
    __init__.py
    assistant.py
    health.py
  services/
    __init__.py
    assistant_service.py
    patient_context_service.py
    vitals_service.py
    trend_service.py
```

Rationale: FastAPI routers, request/response schemas, remote clients, and orchestration services should not live in one large module. LangGraph can later replace or extend `assistant_service.py` without changing router contracts or Flutter calls.

Alternative considered: keep `src/assistant_backend.py` as the main backend module. This preserves short-term simplicity but keeps orchestration, schemas, routes, and clients tangled together.

### Decision 7: Keep compatibility shims during migration

Existing entry points such as `src.demo2_api:app` or imports from `src.assistant_backend` may be used by scripts/tests. During migration, those files should either re-export the new backend app/router or delegate to `src.backend` until scripts are updated.

Rationale: this reduces breakage while moving code into a cleaner backend package.

Alternative considered: delete old modules immediately. This is cleaner on paper but creates unnecessary risk for existing commands.

### Decision 8: Normalize startup scripts around named workflows

`tasks.ps1` and `Makefile` should expose matching workflows:

- backend API only
- backend API with reload
- Flutter with backend provider
- Flutter web with CORS/dev backend mode
- local Ollama/model checks
- full verification commands

Rationale: startup friction is now part of the architecture problem. If the scripts are unclear, developers will keep bypassing the intended layering.

Alternative considered: document raw commands only. This is useful as fallback, but scripts should be the primary day-to-day interface.

## Risks / Trade-offs

- Screen imports may break during file moves -> Mitigation: use `git mv`, update imports in small batches, and run `flutter analyze` frequently.
- Large screens may still remain large after moving API calls -> Mitigation: extract feature-local widgets/controllers after the data layer is stable.
- Existing UI behavior may drift during decomposition -> Mitigation: keep route names and public widget behavior stable, and verify representative flows manually.
- Backend imports may break during package migration -> Mitigation: add compatibility shims and update scripts/tests incrementally.
- Startup commands may diverge between Windows PowerShell and Makefile -> Mitigation: keep task names and environment variables aligned across both files.
- Secret handling cannot make Flutter client-side keys truly secure -> Mitigation: remove committed secrets and prefer backend-mediated calls for real secret-bearing providers.
- Some analyzer info may remain from legacy code -> Mitigation: prioritize errors and new warnings in touched files; leave broad lint cleanup for a separate change if needed.

## Migration Plan

1. Create shared `core/network`, `core/widgets`, `data/models`, `data/repositories`, and `features` directories.
2. Introduce shared network error and API client helpers.
3. Move backend/eHospital service behavior behind repositories.
4. Move high-impact screens into feature folders and update imports.
5. Extract reusable card/loading/error/metric/chart widgets from high-impact screens.
6. Create or clean `src/backend` package structure.
7. Move FastAPI app/router/schema/client/service logic into `src/backend`.
8. Leave compatibility shims for old backend entry points until scripts/tests reference the new package.
9. Update `tasks.ps1` and `Makefile` to use the new backend entry point and aligned workflow names.
10. Update config documentation, backend docs, and dart define examples.
11. Run Python compile/tests, `flutter pub get`, `flutter analyze`, `flutter test`, and a backend-provider web build.
12. Manually smoke test backend startup, login, health assistant, vitals summary, trend insights, and wearable upload entry points.

Rollback strategy: because the refactor should not change external API contracts, rollback is a source-level revert of moved files and import updates if a regression appears.

## Open Questions

- Should a state management package be introduced later once repositories/controllers are in place?
- Which screens should be considered low priority and left in place for the first implementation pass?
- Should local mock mode become a first-class repository/backend client implementation for demos and offline testing?
- Should the backend immediately include a LangGraph graph module, or only define service boundaries that make the later graph insertion straightforward?
