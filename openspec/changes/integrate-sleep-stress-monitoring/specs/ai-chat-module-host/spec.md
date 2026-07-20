## ADDED Requirements

### Requirement: Sleep and stress assistant surfaces
The AI chat module host SHALL expose sleep and stress assistant surfaces without removing existing modules.

#### Scenario: Existing assistant modules remain available
- **WHEN** the assistant module picker is displayed after the sleep/stress merge
- **THEN** the health chat, report interpreter, and nutrition monitor modules remain available

#### Scenario: Sleep and stress entry points are discoverable
- **WHEN** sleep or stress analysis features are enabled
- **THEN** users can reach the relevant assistant-backed sleep feedback, sleep chat, or stress analysis surfaces from the appropriate feature context

### Requirement: No teammate fork UI regression
The merge SHALL preserve current DTI-6302 assistant UI behavior instead of replacing it with the older teammate fork screen.

#### Scenario: Module picker preserved
- **WHEN** the merge is complete
- **THEN** the app still uses the current module picker and saved-chat UI patterns
