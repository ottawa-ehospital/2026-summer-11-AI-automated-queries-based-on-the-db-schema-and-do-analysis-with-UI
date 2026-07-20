## ADDED Requirements

### Requirement: Bounded assistant history for contextual replies
The assistant chat flow SHALL send bounded prior conversation turns to backend assistant calls while preserving saved chat sessions.

#### Scenario: General assistant contextual reply
- **WHEN** the user sends a general assistant message from an existing chat session
- **THEN** the app includes recent prior user and assistant turns in the backend request

#### Scenario: Saved sessions unaffected
- **WHEN** bounded request history is sent to the backend
- **THEN** the full local saved chat session behavior remains unchanged

### Requirement: Sleep chat history isolation
Sleep-specific follow-up chat SHALL maintain its own bounded sleep chat context without corrupting general assistant chat sessions.

#### Scenario: Sleep follow-up does not overwrite general chat
- **WHEN** the user asks a sleep follow-up question
- **THEN** the app sends sleep-specific history to the sleep chat API and does not replace the current general assistant session
