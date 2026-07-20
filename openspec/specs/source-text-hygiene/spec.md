# Source Text Hygiene

## Purpose

Text hygiene requirements for migrated source files, especially readable UTF-8 comments, developer text, and visible UI copy.

## Requirements

### Requirement: Migrated source text is readable
Migrated Flutter source files SHALL NOT contain known mojibake markers in comments or developer-facing text after cleanup.

#### Scenario: Mojibake scan passes
- **WHEN** the cleanup validation scans migrated Flutter source for known corrupted text markers
- **THEN** it reports no matches for the configured mojibake patterns in cleaned files

#### Scenario: Corrupted comments are removed or repaired
- **WHEN** a legacy comment contains unreadable mojibake
- **THEN** the comment is either replaced with concise readable text or removed if it does not add useful context

### Requirement: Dart files remain UTF-8 encoded
Affected Dart source files MUST remain readable by the Dart analyzer as UTF-8 source after text cleanup.

#### Scenario: Analyzer reads cleaned files
- **WHEN** `flutter analyze` is run after cleanup
- **THEN** analyzer MUST NOT report encoding-related parse errors or missing URI errors caused by invalid source encoding

### Requirement: Visible user text is preserved unless corrupted
Cleanup SHALL preserve existing visible app copy unless the text is corrupted, misleading due to the refactor, or part of developer-only diagnostics.

#### Scenario: Valid UI copy remains stable
- **WHEN** a visible string is already readable and behaviorally accurate
- **THEN** the cleanup leaves that string unchanged

#### Scenario: Corrupted UI copy is repaired
- **WHEN** a visible string contains mojibake or replacement characters
- **THEN** the cleanup replaces it with readable text that preserves the surrounding UI intent

### Requirement: API boundary comments are useful and concise
API-facing Flutter and backend code SHALL include concise comments where they clarify non-obvious contracts, response normalization, or service boundaries introduced by the refactor.

#### Scenario: Repository boundary is documented
- **WHEN** a repository or API client normalizes external response shapes
- **THEN** a concise comment explains the boundary or invariant being preserved

#### Scenario: Backend route boundary is documented
- **WHEN** a backend router delegates to a service or compatibility shim for architectural reasons
- **THEN** a concise comment explains the boundary without duplicating the code

#### Scenario: Obvious code remains uncommented
- **WHEN** a line only performs an obvious assignment, import, or direct return
- **THEN** the cleanup does not add a redundant comment for that line
