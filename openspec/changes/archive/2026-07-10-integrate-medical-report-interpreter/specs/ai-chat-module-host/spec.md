## ADDED Requirements

### Requirement: AI assistant area hosts multiple modules
The AI assistant area SHALL provide a module host from the existing `/assistant` entry point instead of opening directly into only the current chat conversation.

#### Scenario: Assistant route shows module choice
- **WHEN** a user opens the existing `/assistant` route
- **THEN** Flutter shows the AI module host
- **THEN** Flutter offers separate choices for Chat and Report Interpreter

#### Scenario: Health chat remains default module
- **WHEN** the AI module host opens
- **THEN** the existing Chat module is available as the default module
- **THEN** the Chat module uses the existing health assistant UI and backend assistant API path

#### Scenario: Report interpreter module is selectable
- **WHEN** a user opens the AI module host
- **THEN** Flutter provides a visible module selector for Chat and Report Interpreter
- **THEN** selecting Report Interpreter displays the report interpreter feature without leaving the AI area
- **THEN** the Report Interpreter module uses the report interpreter UI and `/report-interpreter/*` backend API path

#### Scenario: Module selection starts from default
- **WHEN** a user opens the AI module host in a new app session
- **THEN** Flutter starts from the default Chat module
- **THEN** Flutter does not require persisted last-selected-module state

### Requirement: AI module switching preserves module ownership
The AI module host SHALL route each module to its own feature widget and SHALL NOT merge unrelated module state into one chat implementation.

#### Scenario: Health chat state remains isolated
- **WHEN** a user sends messages in Health Chat and then switches to Report Interpreter
- **THEN** Health Chat session behavior, history controls, new-chat controls, and send-message behavior remain owned by the Health Chat module
- **THEN** Health Chat continues using the existing assistant backend API rather than report interpreter APIs

#### Scenario: Report interpreter state remains isolated
- **WHEN** a user analyzes a report in Report Interpreter and then switches to Health Chat
- **THEN** report upload state, report context, suggested questions, and report follow-up messages remain owned by the Report Interpreter module
- **THEN** Report Interpreter continues using report interpreter APIs rather than the existing health chat API

#### Scenario: Modules remain visually separate
- **WHEN** a user switches between Health Chat and Report Interpreter
- **THEN** each module renders as its own distinct experience inside the AI area
- **THEN** the report interpreter behaves like the extracted app embedded as a separate option rather than as extra prompts inside Health Chat

### Requirement: AI module host is responsive
The AI module host SHALL expose module selection on mobile and desktop layouts without overlapping content or causing text overflow.

#### Scenario: Module selector fits mobile layout
- **WHEN** the app runs on a narrow mobile viewport
- **THEN** the module selector remains usable
- **THEN** module labels and actions do not overlap chat or report content
