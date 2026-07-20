## ADDED Requirements

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
