## ADDED Requirements

### Requirement: Nutrition monitor backend namespace
The backend SHALL expose Nutrition Monitor endpoints under a dedicated `/nutrition-monitor` namespace and SHALL NOT introduce CalorieTrack's standalone Android client networking model into Flutter.

#### Scenario: Health endpoint is available
- **WHEN** a client requests `GET /nutrition-monitor/health`
- **THEN** the backend returns a successful health response for the Nutrition Monitor module
- **AND** existing assistant and report interpreter endpoints remain registered

#### Scenario: Standalone source API patterns are not exposed
- **WHEN** the Nutrition Monitor integration is implemented
- **THEN** Flutter calls DTI6302 backend endpoints rather than direct OpenAI URLs
- **AND** Flutter does not write directly to eHospital `/table/*` endpoints for nutrition monitor persistence

### Requirement: Food image analysis API
The backend SHALL provide a patient-scoped food image analysis endpoint that accepts an image and optional user hint, checks image-model capability, assembles EHR context, invokes the configured model path, validates structured results, and returns normalized nutrition analysis.

#### Scenario: Analyze food image
- **WHEN** an authenticated patient submits a food image with an optional hint
- **THEN** the backend includes the active patient id in the analysis workflow
- **AND** the backend retrieves relevant patient registration, allergies, diagnosed conditions, recent vitals, and recent blood tests through existing eHospital client helpers
- **AND** the backend returns dish name, portion size, ingredients, calories, protein, fat, carbs, sodium, sugar, risks, warnings, positives, and final verdict

#### Scenario: Patient context is unavailable
- **WHEN** no active patient id is available for image analysis
- **THEN** the backend rejects the request with a clear patient-context-required error
- **AND** the backend does not fall back to a hard-coded demo patient id

#### Scenario: Non-food image is detected
- **WHEN** image analysis determines the image does not contain food
- **THEN** the backend returns a non-food result or validation error that prevents meal logging
- **AND** the response tells Flutter to prompt the user to try another image

#### Scenario: Configured model does not support image input
- **WHEN** the configured model/provider cannot process image input
- **THEN** the backend reports image analysis as unavailable through health or capability metadata
- **AND** analysis requests fail with a clear unsupported-model error rather than attempting text-only processing

#### Scenario: Unsupported model is guarded before work starts
- **WHEN** a client calls `POST /nutrition-monitor/analyze-image` while image analysis is unavailable
- **THEN** the backend checks model capability before loading EHR context
- **AND** the backend does not invoke the model provider
- **AND** the backend returns a deterministic non-retryable error code such as `nutrition_image_model_unsupported`
- **AND** the backend does not log uploaded image contents

#### Scenario: Capability metadata includes reason
- **WHEN** Flutter or another client checks Nutrition Monitor capability metadata
- **THEN** the backend response includes whether image input is supported
- **AND** the response includes the configured provider/model identity and a short reason when image input is unavailable

### Requirement: Meal logging API
The backend SHALL log analyzed meals to `app_nutrition_log` only after a successful food analysis and SHALL scope all writes to the active patient id.

#### Scenario: Log analyzed meal
- **WHEN** Flutter submits a confirmed nutrition analysis for logging
- **THEN** the backend writes a row to `app_nutrition_log` with patient id, dish/ingredients, portion estimate, nutrients, and insight fields
- **AND** the backend returns the created or accepted meal record

#### Scenario: Reject invalid meal log
- **WHEN** Flutter attempts to log a missing, invalid, or non-food analysis
- **THEN** the backend rejects the request
- **AND** no `app_nutrition_log` row is written

### Requirement: Nutrition history and summaries
The backend SHALL provide patient-scoped meal history and daily summary data derived from `app_nutrition_log`.

#### Scenario: Load meal history
- **WHEN** Flutter requests meal history for the active patient
- **THEN** the backend returns only meals for that patient
- **AND** the backend supports enough date information for recent-history filtering in the Flutter UI

#### Scenario: Load daily summary
- **WHEN** Flutter requests today's nutrition summary
- **THEN** the backend returns totals for calories, protein, carbs, fat, sodium, and sugar for the active patient
- **AND** the totals are calculated from logged meals for the requested day

### Requirement: Nutrition goal API contract
The backend SHALL define an API contract for retrieving and saving patient-scoped nutrition goals when server-side goal persistence is available, while allowing Flutter to use patient-scoped local storage when no suitable remote table exists.

#### Scenario: Load nutrition goals
- **WHEN** Flutter requests nutrition goals for the active patient
- **THEN** the backend returns patient-specific goals when persisted values exist
- **AND** the backend returns safe defaults or a not-configured state when no goals exist

#### Scenario: Save nutrition goals
- **WHEN** Flutter saves calorie and macro goals
- **THEN** the backend persists the goals for the active patient when a supported storage target exists
- **AND** the backend rejects goals containing invalid negative values

#### Scenario: No remote goal table exists
- **WHEN** implementation cannot find a supported remote or eHospital table for nutrition goals
- **THEN** the backend does not require a new table before shipping the feature
- **AND** Flutter stores goals in patient-scoped local storage as the source Android app did
