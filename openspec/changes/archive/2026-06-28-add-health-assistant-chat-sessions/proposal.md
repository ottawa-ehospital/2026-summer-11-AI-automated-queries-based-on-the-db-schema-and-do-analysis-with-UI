## Why

The current Health Assistant treats each prompt as a standalone request and stores messages only in the active widget state. Users need ChatGPT-like sessions that start fresh by default while keeping prior chats available from history, and the agent needs recent conversation context to answer follow-up questions coherently.

## What Changes

- Add local persistent Health Assistant chat sessions with session metadata and message history.
- Replace the current top-right clear-chat action with a new-chat action that starts a fresh session without deleting history.
- Add a history selector so users can load previous Health Assistant sessions.
- Extend assistant request models and repository calls to include up to the most recent 10 prior user/assistant messages when sending a new prompt.
- Update the backend assistant chat contract so the model prompt includes bounded conversation history while preserving the existing wellness safety boundary.
- Keep message context bounded and chronological to avoid oversized prompts.

## Capabilities

### New Capabilities

- `health-assistant-chat-sessions`: Persistent local chat sessions, history selection, new-session UX, and bounded assistant conversation context.

### Modified Capabilities

- None.

## Impact

- Affected Flutter code: Health Assistant screen/widgets/models, assistant repository/model request shape, localization strings, and local storage usage.
- Affected backend code: assistant chat request schema, assistant route/service prompt construction, and backend tests.
- Existing single-message assistant clients should remain compatible by treating history as optional.
