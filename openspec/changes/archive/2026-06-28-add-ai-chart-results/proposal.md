## Why

AI assistant answers currently return plain text, so queried health data cannot be rendered as charts in Flutter without brittle natural-language parsing. A structured chart result contract lets the backend pass chart-ready data and display intent to Flutter, where reusable chart templates can render the result in the assistant conversation.

## What Changes

- Add a backend AI assistant interface abstraction that supports text and chart result payloads while keeping output contracts stable across different model implementations.
- Extend backend assistant chat responses with an ordered `results` list while keeping the existing `reply` field compatible.
- Define chart payload shape for queried data, display type, series, points, axes, labels, and units.
- Provide an agent-facing backend function that validates and normalizes proposed assistant result payloads before they are returned to Flutter.
- Update the backend LangGraph-ready assistant flow for a minimum single-table chart query path, starting with recent heart-rate data.
- Add Flutter-side parsing expectations for result items so the app can select chart templates by result type/display type.
- Add line and bar chart display templates as the first supported chart result views.

## Capabilities

### New Capabilities
- `ai-chart-results`: Structured assistant result payloads for chart-ready data and Flutter chart rendering.

### Modified Capabilities
- `backend-backed-ai-assistant`: Assistant chat responses include structured result items in addition to the text reply.

## Impact

- Python backend assistant response schemas and orchestration.
- Backend assistant interface boundaries for LangGraph-based workflows backed by different model providers or implementations.
- Backend query/chart result shaping around patient-scoped health data.
- Flutter backend API models, Health Assistant chat message models, and assistant result widgets.
- Tests for backend response contracts and Flutter parsing/rendering behavior.
