## 1. Session Data Model And Storage

- [x] 1.1 Add typed Flutter models for assistant chat messages and chat sessions, including title metadata and JSON serialization.
- [x] 1.2 Add a local Health Assistant session store backed by existing local persistence.
- [x] 1.3 Add local title inference from the first user message, with cleanup and readable truncation.
- [x] 1.4 Persist session metadata and ordered messages after user and assistant message updates.

## 2. Health Assistant UI

- [x] 2.1 Start `HealthAssistantScreen` with a blank new session on each new page lifecycle.
- [x] 2.2 Replace the app-bar clear action with a new-chat action that creates a blank session without deleting existing sessions.
- [x] 2.3 Add a history selector UI for listing saved sessions by inferred title, preview or timestamp, and loading the selected session.
- [x] 2.4 Ensure empty/loading/error states still render correctly for new and loaded sessions.

## 3. Conversation Context Request Flow

- [x] 3.1 Extend Flutter assistant repository/request code to accept optional message history.
- [x] 3.2 Send at most the most recent 10 prior messages from the active session with each new prompt.
- [x] 3.3 Ensure the current prompt is sent as `message` and is not duplicated in the history payload.

## 4. Backend Assistant History Support

- [x] 4.1 Extend backend assistant chat schemas to accept optional prior conversation messages.
- [x] 4.2 Update assistant service prompt construction to include bounded chronological history.
- [x] 4.3 Preserve backwards compatibility for requests that omit history.

## 5. Verification

- [x] 5.1 Add or update backend tests for chat requests with omitted, short, and over-limit history.
- [x] 5.2 Add or update Flutter tests for session serialization/storage and bounded history selection.
- [x] 5.3 Run relevant Python backend tests and Flutter analyzer/tests for the touched areas.
