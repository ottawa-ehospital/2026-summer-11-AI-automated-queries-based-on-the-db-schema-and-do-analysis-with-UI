# health-assistant-chat-sessions Specification

## Purpose
TBD - created by archiving change add-health-assistant-chat-sessions. Update Purpose after archive.
## Requirements
### Requirement: Local Chat Session Persistence
The Health Assistant SHALL persist conversations locally as separate chat sessions with stable session IDs, timestamps, and ordered messages.

#### Scenario: Message is persisted in active session
- **WHEN** a user sends a Health Assistant message and receives a response
- **THEN** both the user message and assistant response are saved to the active local session in order

#### Scenario: New screen opens blank by default
- **WHEN** the user opens the Health Assistant screen through a new page lifecycle
- **THEN** the screen starts with a blank local session unless the user explicitly loads a previous session from history

### Requirement: New Chat Action
The Health Assistant app bar SHALL replace the destructive clear-chat action with a new-chat action that starts a blank session without deleting previous sessions.

#### Scenario: User starts a new chat
- **WHEN** the user activates the new-chat action
- **THEN** the screen shows an empty conversation bound to a new local session

#### Scenario: Previous session remains available
- **WHEN** the user starts a new chat after having an existing conversation
- **THEN** the previous conversation remains available through chat history

### Requirement: History Selection
The Health Assistant SHALL provide a UI control for selecting and loading previous local chat sessions.

#### Scenario: Session title is inferred from first user message
- **WHEN** a new session receives its first user message
- **THEN** the session is saved with a concise readable title derived from that first message

#### Scenario: User opens history
- **WHEN** the user opens the Health Assistant history selector
- **THEN** saved sessions are listed with the inferred title, a preview or timestamp, and enough metadata to distinguish them

#### Scenario: User loads previous session
- **WHEN** the user selects a previous session
- **THEN** the Health Assistant screen displays that session's messages and subsequent sends append to that session

### Requirement: Bounded Conversation Context
Each Health Assistant request SHALL send at most the previous 10 user/assistant messages from the active session to the assistant backend as conversation context.

#### Scenario: Short conversation sends all prior messages
- **WHEN** the active session has fewer than or equal to 10 prior messages before the new prompt
- **THEN** all prior messages are included in chronological order in the assistant request history

#### Scenario: Long conversation sends latest prior messages only
- **WHEN** the active session has more than 10 prior messages before the new prompt
- **THEN** only the most recent 10 prior messages are included in chronological order in the assistant request history

#### Scenario: Current prompt is not duplicated in history
- **WHEN** the user sends a new prompt
- **THEN** the current prompt is sent as the request message and is not also duplicated in the history array

### Requirement: Backend Chat History Support
The assistant backend SHALL accept optional prior conversation messages and include them in the model prompt while preserving existing safety restrictions.

#### Scenario: Request includes history
- **WHEN** `/assistant/chat` receives a request with prior user/assistant messages
- **THEN** the backend includes the bounded chronological history in the prompt sent to the configured model

#### Scenario: Request omits history
- **WHEN** `/assistant/chat` receives a request without history
- **THEN** the backend continues to process the single-message prompt successfully

#### Scenario: Backend enforces history bound
- **WHEN** `/assistant/chat` receives more than 10 history messages
- **THEN** the backend uses at most the most recent 10 messages when constructing the model prompt

