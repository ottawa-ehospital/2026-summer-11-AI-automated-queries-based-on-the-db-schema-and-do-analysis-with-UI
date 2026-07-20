# AI Chart Results

## Purpose

Structured assistant result payloads for backend-validated chart-ready data and Flutter chart rendering.
## Requirements
### Requirement: Backend Assistant Interface Contract
The backend SHALL expose assistant orchestration through an interface that constrains every implementation to the same structured assistant response contract.

#### Scenario: LangGraph implementation returns structured response
- **WHEN** the backend assistant uses a LangGraph-based implementation
- **THEN** it returns an assistant response with `reply` and validated `results` items that match the shared contract

#### Scenario: Model implementation is swapped
- **WHEN** the backend assistant implementation changes model provider or graph internals
- **THEN** the FastAPI assistant endpoint and Flutter response parsing contract remain unchanged

#### Scenario: Provider-specific output is normalized
- **WHEN** a model provider returns provider-specific text or tool output
- **THEN** the assistant implementation normalizes it through the shared result models and validator before composing the response

### Requirement: Structured Assistant Results
Assistant chat responses SHALL include a structured ordered result list that Flutter can render without parsing natural-language prose.

#### Scenario: Text result is returned
- **WHEN** the backend answers an assistant chat request with text only
- **THEN** the response includes a `results` list containing a text result with the assistant reply content

#### Scenario: Chart result is returned
- **WHEN** the backend answers an assistant chat request with chart-ready data
- **THEN** the response includes a chart result with a supported `displayType`, title, axes metadata, series, and points

#### Scenario: Legacy reply remains available
- **WHEN** Flutter or another caller receives an assistant chat response
- **THEN** the top-level `reply` field remains populated with the assistant's text summary

### Requirement: Backend Chart Payload Validation
The backend SHALL only return chart result payloads that conform to the supported assistant chart schema.

#### Scenario: Supported chart display type
- **WHEN** the backend creates a chart result for a line or bar chart
- **THEN** the result declares the matching `displayType` and includes chart data normalized for Flutter rendering

#### Scenario: Empty chart data
- **WHEN** a user asks for a chart but no usable data points are available
- **THEN** the backend returns a text result explaining that no chartable data is available instead of returning an empty chart

### Requirement: Agent Output Format Validation
The backend SHALL provide an agent-facing function that validates and normalizes proposed assistant result payloads before they can be returned to Flutter.

#### Scenario: Agent proposes valid chart result
- **WHEN** an agent proposes a chart result with supported type, display type, axes metadata, series, and numeric points
- **THEN** the validation function returns a valid normalized payload suitable for the assistant response

#### Scenario: Agent proposes invalid chart result
- **WHEN** an agent proposes a chart result with an unsupported display type, missing series, or non-numeric point values
- **THEN** the validation function returns validation errors and the backend does not return that chart payload to Flutter

#### Scenario: Validator is documented for agent use
- **WHEN** a developer inspects the backend validation function
- **THEN** its docstring or adjacent documentation explains the accepted assistant result format and that it is the required gate before response composition

### Requirement: LangGraph MVP Single-Table Chart Flow
The backend SHALL support a minimum LangGraph-compatible flow that converts simple wearable metric questions into single-table chart results.

#### Scenario: Recent heart rate chart request
- **WHEN** a logged-in user asks "How has my recent heart rate been?"
- **THEN** the backend graph maps the request to a patient-scoped `wearable_vitals` query for `timestamp` and `heart_rate`
- **THEN** the backend returns a line chart result for recent heart-rate points after validating the result payload

#### Scenario: MVP avoids complex analysis
- **WHEN** the backend graph handles the minimum chart flow
- **THEN** it does not perform multi-table joins, diagnosis, or complex trend analysis before returning the chart result

### Requirement: Flutter Chart Result Rendering
Flutter SHALL render assistant chart results using predefined templates selected by the result display type.

#### Scenario: Line chart result
- **WHEN** a chat message contains a chart result with `displayType` set to `line`
- **THEN** Flutter renders the result with the line chart template inside the assistant message

#### Scenario: Bar chart result
- **WHEN** a chat message contains a chart result with `displayType` set to `bar`
- **THEN** Flutter renders the result with the bar chart template inside the assistant message

#### Scenario: Unsupported chart result warning
- **WHEN** a chat message contains a chart result with an unsupported `displayType`
- **THEN** Flutter emits a warning and does not render that chart item
- **THEN** Flutter preserves the assistant text reply

### Requirement: Structured Markdown Report Results
Assistant chat responses SHALL support structured Markdown report results with explicit freshness metadata.

#### Scenario: Report result is returned
- **WHEN** the backend returns a generated health-data report
- **THEN** the response includes a report result with `type`, `format`, `title`, `content`, `generatedAt`, `expiresAt`, and `freshnessReason`
- **THEN** the top-level `reply` remains populated with a concise summary for backwards compatibility

#### Scenario: Report content uses Markdown
- **WHEN** the backend returns a report result
- **THEN** the report declares `format` as `markdown`
- **THEN** the report content is suitable for frontend Markdown rendering without requiring natural-language parsing

#### Scenario: Report payload is invalid
- **WHEN** an agent or workflow proposes a report result missing required Markdown content or freshness metadata
- **THEN** the backend validator rejects the payload and does not return it to Flutter as a structured report

### Requirement: Report Expiration Metadata
Report results SHALL contain enough metadata for Flutter to determine whether a displayed report is stale without calling the backend.

#### Scenario: Report is still fresh
- **WHEN** Flutter renders a report result before `expiresAt`
- **THEN** Flutter displays the report normally

#### Scenario: Report has expired
- **WHEN** Flutter renders a report result after `expiresAt`
- **THEN** Flutter displays a clear stale or expired report notice
- **THEN** the notice explains that the user's health data or short-term condition may have changed since the report was generated

#### Scenario: Expired report content remains visible
- **WHEN** Flutter marks a report as expired
- **THEN** Flutter preserves the report content for user reference
- **THEN** Flutter visually distinguishes the report from fresh reports

### Requirement: Flutter Markdown Report Rendering
Flutter SHALL render assistant report results using a controlled Markdown renderer instead of displaying raw Markdown as plain text.

#### Scenario: Markdown report contains supported formatting
- **WHEN** a report result contains supported Markdown elements such as headings, paragraphs, emphasis, and lists
- **THEN** Flutter renders those elements in the assistant message

#### Scenario: Markdown report contains unsupported or unsafe markup
- **WHEN** a report result contains unsupported Markdown or raw HTML
- **THEN** Flutter ignores, sanitizes, or safely degrades that markup
- **THEN** Flutter does not execute embedded scripts or unsafe content

#### Scenario: Unknown result type is received
- **WHEN** Flutter receives an assistant result type it does not support
- **THEN** Flutter preserves the assistant text reply and does not crash

### Requirement: Query analysis can drive chart result generation
The backend SHALL support chart result generation from validated query results and structured analysis, not only fixed single-metric chart mappings.

#### Scenario: Analysis recommends a line chart
- **WHEN** query analysis identifies time-series numeric data suitable for a line chart
- **THEN** the backend generates a chart result with `displayType` set to `line`
- **THEN** the chart series points are derived from validated query rows

#### Scenario: Analysis recommends a bar chart
- **WHEN** query analysis identifies categorical or bucketed numeric data suitable for a bar chart
- **THEN** the backend generates a chart result with `displayType` set to `bar`
- **THEN** the chart series points are derived from validated query rows or validated aggregate analysis

#### Scenario: Analysis recommends unsupported chart type
- **WHEN** model analysis recommends a chart type that Flutter does not support
- **THEN** the backend rejects that chart payload or degrades to a supported text/report result
- **THEN** the backend does not return an unsupported chart display type

### Requirement: Chart outputs include source and freshness context
Chart results generated by the query/report workflow SHALL include enough surrounding response context for users to understand where the chart came from and when it may become stale.

#### Scenario: Chart accompanies report
- **WHEN** the workflow returns a chart as part of an analysis report
- **THEN** the response also includes text or report content summarizing the source data and freshness window

#### Scenario: Chart has no usable points
- **WHEN** selected query rows cannot be converted into numeric chart points
- **THEN** the backend returns a text or report explanation instead of an empty chart result

