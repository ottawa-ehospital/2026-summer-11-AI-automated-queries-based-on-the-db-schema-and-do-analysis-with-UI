## ADDED Requirements

### Requirement: Stress signal upload
The Flutter app SHALL derive hourly stress signal snapshots from wearable data and upload them to the backend.

#### Scenario: Upload hourly stress bucket
- **WHEN** HealthKit data contains HRV SDNN, resting heart rate, respiratory rate, or heart-rate samples for an hour
- **THEN** the app uploads one stress snapshot for that hour with the signed-in patient id and timestamp

### Requirement: Stress tab in vitals
The Flutter vitals screen SHALL include a stress metric tab without removing existing metric tabs.

#### Scenario: Display stress metric
- **WHEN** remote wearable vitals include stress score values
- **THEN** the vitals screen displays a stress tab and plots stress scores alongside existing steps, calories, heart-rate, and sleep tabs

### Requirement: Stress annotation UI
The Flutter app SHALL allow users to annotate stress chart points and persist those annotations remotely.

#### Scenario: Add stress annotation
- **WHEN** the user taps an annotatable stress chart point and saves a note
- **THEN** the app sends the annotation to the backend and marks the point as annotated after success

### Requirement: Stress trend and analysis
The Flutter app SHALL display stress trend context and request AI stress analysis.

#### Scenario: Generate stress analysis
- **WHEN** the user requests stress analysis from the stress tab
- **THEN** the app calls the backend stress analysis endpoint and displays the returned wellness analysis with loading and error states

#### Scenario: Show seven-day stress trend
- **WHEN** stress scores exist across recent days
- **THEN** the app summarizes daily average stress trend for the user
