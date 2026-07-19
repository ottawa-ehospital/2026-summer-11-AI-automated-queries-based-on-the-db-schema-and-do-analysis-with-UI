## ADDED Requirements

### Requirement: Vertical AI Module Picker
The Health Assistant entry screen SHALL present available AI assistant modules in a vertically scrollable picker where one module is visually focused as the current selection, and the picker SHALL be driven by module definitions rather than hardcoded two-option layout.

#### Scenario: User opens assistant entry screen
- **WHEN** the user navigates to `/assistant`
- **THEN** the screen displays the available AI assistant modules in a vertical picker rather than static stacked cards
- **AND** at least the Health Chat and Report Analyze modules are available

#### Scenario: Picker has focused selection
- **WHEN** the picker is visible
- **THEN** one module is treated as selected
- **AND** the selected module is visually emphasized relative to non-selected modules
- **AND** adjacent non-selected modules remain partially or fully visible to communicate vertical browsing

#### Scenario: User scrolls between modules
- **WHEN** the user scrolls the picker vertically to another module
- **THEN** the selected module updates to the newly focused module
- **AND** the module detail and launch action reflect the newly selected module

#### Scenario: Additional module definitions are provided
- **WHEN** the picker receives more than two AI module definitions
- **THEN** it renders the additional modules in the same vertical selection interaction
- **AND** it does not require new bespoke layout code for each added module

### Requirement: AI Module Launch
The Health Assistant entry screen SHALL let the user launch the selected AI module without changing the existing module workflows.

#### Scenario: User launches Health Chat
- **WHEN** Health Chat is selected and the user activates the launch action or taps the focused Health Chat item
- **THEN** the app opens the existing Health Chat module
- **AND** existing chat session behavior remains available

#### Scenario: User launches Report Analyze
- **WHEN** Report Analyze is selected and the user activates the launch action or taps the focused Report Analyze item
- **THEN** the app opens the existing Report Interpreter module
- **AND** existing report upload and analysis behavior remains available

#### Scenario: Future module launch behavior is supplied
- **WHEN** a future AI module definition includes a launch callback or destination builder
- **THEN** the picker can launch that module through the same selected-module activation path used by existing modules
- **AND** adding that module does not require duplicating the picker item widget

### Requirement: Picker Mobile Usability
The AI module picker SHALL remain usable and readable on mobile viewports.

#### Scenario: Small screen layout
- **WHEN** the assistant entry screen renders on a small mobile viewport
- **THEN** picker item labels, descriptions, icons, and launch controls do not overlap
- **AND** the selected module and launch action remain reachable without horizontal scrolling

#### Scenario: Accessibility semantics
- **WHEN** assistive technology inspects the picker
- **THEN** each module exposes a meaningful label and activation target
- **AND** the selected module state is communicated through semantics or equivalent accessible text
