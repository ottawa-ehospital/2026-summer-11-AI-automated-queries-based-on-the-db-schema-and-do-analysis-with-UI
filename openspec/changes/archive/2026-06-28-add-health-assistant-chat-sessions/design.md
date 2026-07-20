## Context

`HealthAssistantScreen` currently keeps messages in an in-memory `_messages` list and sends only the current prompt through `AiService.generate` and `AssistantRepository.chat`. The backend `AssistantChatRequest` accepts only `patient_id` and `message`, so follow-up questions cannot carry prior turns to the model. The UI also exposes a clear action that deletes the current in-memory thread instead of creating a new recoverable conversation.

## Goals / Non-Goals

**Goals:**

- Persist Health Assistant conversations locally by session.
- Open the Health Assistant screen into a fresh blank session by default.
- Let users start a new chat from the app bar without deleting old sessions.
- Let users browse and load previous local Health Assistant sessions.
- Give each saved session a readable title inferred from the first user message.
- Send at most the previous 10 user/assistant messages, in chronological order, with each new assistant request.
- Keep backend chat history optional so current single-message integrations remain compatible.

**Non-Goals:**

- Sync chat history to eHospital or any remote backend.
- Add cross-device session sync or server-side conversation storage.
- Change the wellness safety policy or allow diagnosis/treatment advice.
- Redesign the entire Health Assistant screen beyond the requested session/history controls.

## Decisions

1. Store sessions locally in Flutter using the existing local persistence dependency.
   - Rationale: the request is for local conversation storage, and the app already uses `shared_preferences`.
   - Alternative considered: backend persistence. Rejected because the user asked for local storage and this avoids storing health chat content remotely.

2. Introduce typed Flutter session/message models plus a small local storage repository.
   - Rationale: sessions need IDs, titles/previews, timestamps, and ordered messages; keeping this out of the screen prevents widget-state sprawl.
   - Alternative considered: keep JSON manipulation directly in `HealthAssistantScreen`. Rejected because history loading and session lifecycle would make the screen hard to maintain.

3. Replace the destructive app-bar clear action with a non-destructive new-chat action.
   - Rationale: ChatGPT-like behavior starts a blank session while keeping history available.
   - Alternative considered: keep clear and add a second new button. Rejected because the explicit user request is to replace clear with a new-page/new-chat behavior.

4. Open new Health Assistant screen lifecycles as blank conversations unless the user explicitly loads history.
   - Rationale: this matches the expected new-page/new-chat behavior and avoids surprising users by restoring old health chat content automatically.
   - Alternative considered: restore the most recently active session on screen open. Rejected because history loading should be user-directed.

5. Generate a session title from the first user message.
   - Rationale: users need ChatGPT-like titles to recognize prior conversations quickly.
   - Implementation direction: derive a concise local title by cleaning whitespace, removing trailing punctuation where appropriate, and truncating to a readable length. This avoids an extra model call while still reflecting the conversation topic.
   - Alternative considered: ask the AI model to summarize the first turn. Rejected for this change because it adds latency, cost/provider coupling, and another failure path.

6. Add a history selector reachable from the Health Assistant UI.
   - Rationale: users need a discoverable way to load prior sessions.
   - Implementation direction: a menu, drawer, or bottom sheet can list sessions by inferred title, preview, and updated time; exact widget choice can follow existing app UI patterns during implementation.

7. Send bounded prior context from Flutter and enforce the same bound in backend.
   - Rationale: the client knows the active local session, but the backend must still enforce prompt size and safety boundaries.
   - Bound: include at most 10 prior messages total, not including the new current user message.

## Risks / Trade-offs

- Local chat history can contain sensitive health content -> Keep storage local, avoid remote persistence, and do not log message bodies.
- `shared_preferences` is not ideal for very large histories -> Bound context sent to backend and consider trimming or compact JSON storage during implementation.
- Existing model prompts may become too long -> Backend enforces a maximum of 10 history messages and formats them compactly.
- Concurrent sends could corrupt session order -> Disable send while loading and persist messages after each append.
