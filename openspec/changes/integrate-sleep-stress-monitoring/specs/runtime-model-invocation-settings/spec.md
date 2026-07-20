## ADDED Requirements

### Requirement: New assistant calls preserve runtime model settings
New sleep and stress assistant-backed calls SHALL not remove or bypass the current runtime model invocation settings contract.

#### Scenario: Stress analysis uses current model configuration
- **WHEN** stress analysis invokes an AI model
- **THEN** it uses the existing backend model configuration path or accepts compatible runtime model invocation settings

#### Scenario: General assistant model settings remain intact
- **WHEN** sleep and stress features are merged
- **THEN** existing general assistant chat, vitals summary, trend insights, and health alert calls still support current model invocation settings
