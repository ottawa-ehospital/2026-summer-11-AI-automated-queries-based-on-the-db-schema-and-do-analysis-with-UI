# flutter-reusable-ui-components Specification

## Purpose
TBD - created by archiving change refactor-flutter-architecture. Update Purpose after archive.
## Requirements
### Requirement: Shared UI primitives exist for repeated patterns
The Flutter app SHALL provide reusable UI primitives for common card, section header, loading, empty, error, metric, and chart container patterns.

#### Scenario: A feature displays loading data
- **WHEN** a feature needs to show a loading, empty, or error state
- **THEN** it can use a shared widget rather than implementing a custom state block in the screen

### Requirement: Feature-local widgets are extracted from large screens
Large feature screens SHALL extract repeated or complex visual sections into feature-local widgets when those sections are not broadly reusable.

#### Scenario: Vitals screen contains chart and AI summary sections
- **WHEN** the Vitals screen is refactored
- **THEN** chart, metric summary, and AI insight sections are extracted into shared or feature-local widgets

### Requirement: Shared components preserve app visual style
Reusable widgets SHALL preserve the existing app color, spacing, typography, and interaction style unless a visual change is explicitly requested.

#### Scenario: Dashboard card is replaced by a shared component
- **WHEN** a dashboard card uses a shared card widget
- **THEN** it remains visually consistent with the previous app style

### Requirement: UI components avoid embedded data fetching
Reusable and feature-local presentation widgets SHALL NOT perform remote API calls directly.

#### Scenario: Chart widget renders vitals data
- **WHEN** a chart widget receives data from a feature screen or controller
- **THEN** it renders the data without fetching remote tables itself

