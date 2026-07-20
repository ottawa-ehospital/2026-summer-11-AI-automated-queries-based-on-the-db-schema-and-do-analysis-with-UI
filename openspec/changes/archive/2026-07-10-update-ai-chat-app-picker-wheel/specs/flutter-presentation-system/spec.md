## ADDED Requirements

### Requirement: Interactive Feature Selectors Use Presentation Resources
Feature-level interactive selectors SHALL use shared presentation tokens, localizable user-facing text, and feature-local widgets or styles when selector behavior is specific to one feature.

#### Scenario: AI assistant picker uses presentation resources
- **WHEN** the AI assistant module picker is implemented
- **THEN** picker labels, descriptions, headings, and action text are sourced from l10n-compatible resources or the documented l10n facade
- **AND** picker spacing, color, typography, radii, and motion-related visual treatment compose existing app tokens or Health Assistant feature-local presentation resources

#### Scenario: Selector implementation remains feature-local
- **WHEN** the AI assistant module picker requires custom layout, selection, or styling code
- **THEN** that code is placed in Health Assistant feature-local widgets or presentation files unless it is generic enough for shared core widgets
- **AND** the feature-local picker UI does not call backend APIs, repositories, AI services, Fitbit, eHospital, or provider SDKs directly
