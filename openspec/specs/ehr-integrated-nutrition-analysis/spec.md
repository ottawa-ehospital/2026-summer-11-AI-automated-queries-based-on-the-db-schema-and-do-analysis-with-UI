# ehr-integrated-nutrition-analysis Specification

## Purpose
TBD - created by archiving change integrate-calorie-track-nutrition-monitor. Update Purpose after archive.
## Requirements
### Requirement: EHR-aware food interpretation
Nutrition analysis SHALL use the patient's EHR context to personalize food safety insights while keeping responses explanatory and non-diagnostic.

#### Scenario: EHR context is assembled
- **WHEN** the backend analyzes a food image for a patient
- **THEN** it includes available allergies, diagnosed conditions, recent vitals, recent blood tests, height, and weight in the analysis context
- **AND** missing EHR fields are represented as unavailable rather than fabricated

#### Scenario: Conditions influence warnings
- **WHEN** a nutrient value may conflict with a known patient condition or recent test value
- **THEN** the analysis includes a warning explaining the relevant concern
- **AND** the warning remains advisory rather than diagnostic

### Requirement: Exact allergy safety checks
Nutrition analysis SHALL protect allergy behavior with deterministic exact matching rules where possible.

#### Scenario: Exact allergen match
- **WHEN** a detected food ingredient exactly matches a patient allergy term case-insensitively
- **THEN** the analysis includes a high-risk allergy insight
- **AND** the final verdict treats the meal as not recommended

#### Scenario: Related but non-exact allergen names
- **WHEN** a detected ingredient is related to but does not exactly match an allergy term
- **THEN** deterministic allergy matching does not create a high-risk exact-match allergy insight
- **AND** the model may still provide a separate caution only if clearly labeled as non-exact advisory guidance

### Requirement: Nutrition response structure
Nutrition analysis SHALL normalize model output into a stable structure before returning it to Flutter.

#### Scenario: Structured result is valid
- **WHEN** model output contains valid food analysis data
- **THEN** the backend returns dish name, portion size, ingredient list, nutrient totals, risks, warnings, positives, and final verdict in typed response fields
- **AND** Flutter does not need to parse raw model prose to render the result

#### Scenario: Structured result is invalid
- **WHEN** model output is missing required fields or cannot be parsed
- **THEN** the backend returns a controlled analysis failure
- **AND** the backend does not log a meal record from the invalid output

### Requirement: Final verdict scoring
Nutrition analysis SHALL compute a final verdict from risks, warnings, and positives using deterministic scoring compatible with the CalorieTrack behavior.

#### Scenario: High risk overrides positives
- **WHEN** one or more high-risk allergy insights are present
- **THEN** the final verdict is `not_recommended` or equivalent
- **AND** positive nutrition facts do not override the high-risk verdict

#### Scenario: Warnings without high risk
- **WHEN** warnings are present and high-risk allergy insights are absent
- **THEN** the final verdict indicates moderation or caution

#### Scenario: No risks or warnings
- **WHEN** no risks or warnings are present
- **THEN** the analysis includes at least one neutral or positive insight
- **AND** the final verdict indicates neutral or recommended based on positive evidence

### Requirement: Image and privacy handling
Nutrition analysis SHALL treat uploaded food images as transient analysis inputs and SHALL persist only structured nutrition results unless image persistence is explicitly added by a future requirement.

#### Scenario: Analyze transient image
- **WHEN** a user submits a food image for analysis
- **THEN** the backend processes the image for model input
- **AND** persisted meal logs contain structured nutrition results rather than raw image bytes
- **AND** `image_storage_path` remains null unless a future secure image storage requirement is added

