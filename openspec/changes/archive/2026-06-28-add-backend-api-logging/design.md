## Context

The Python backend is created in `src/backend/main.py` and currently wires CORS plus routers, but it does not emit application-level startup confirmation or request lifecycle logs. Uvicorn may print process-level startup messages, but those do not show the configured backend/provider settings or whether requests are reaching specific API paths.

## Goals / Non-Goals

**Goals:**
- Emit a concise startup log after FastAPI app startup completes.
- Emit a concise log for each HTTP request handled by the backend.
- Keep logs free of request bodies, response bodies, credentials, and patient data.
- Keep router contracts and service orchestration unchanged.

**Non-Goals:**
- Add distributed tracing, metrics exporters, or a new observability dependency.
- Change the Flutter API layer or backend endpoint response schemas.
- Log AI prompts, model responses, SQL text, or patient context payloads.

## Decisions

1. Use Python's standard `logging` module.

   Rationale: the project already has a small backend and does not need an external logging package. Standard logging integrates naturally with Uvicorn output.

   Alternative considered: add a structured logging dependency. That would be heavier than needed for this developer feedback problem.

2. Add request logging as FastAPI HTTP middleware.

   Rationale: middleware captures every routed API uniformly, including assistant, demo, and query-tool endpoints, without duplicating logging in each router.

   Alternative considered: decorate each endpoint. That would be noisy and easy to forget when adding new routes.

3. Log request metadata only.

   Rationale: method, path, status, and elapsed time are enough to confirm execution while avoiding accidental exposure of health data or secrets.

   Alternative considered: log query strings and bodies. Query strings can contain identifiers and request bodies can contain patient data, so they stay out of default logs.

## Risks / Trade-offs

- Request logs can add console noise during tests and development -> Keep the format compact and at INFO level.
- Middleware must preserve error behavior -> Re-raise exceptions after logging failed requests.
- Uvicorn logging configuration varies by environment -> Configure the app logger only when no handlers exist, so it remains compatible with existing process logging.
