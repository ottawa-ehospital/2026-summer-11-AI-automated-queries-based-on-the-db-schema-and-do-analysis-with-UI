## ADDED Requirements

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
