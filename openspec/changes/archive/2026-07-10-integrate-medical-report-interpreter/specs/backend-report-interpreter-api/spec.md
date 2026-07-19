## ADDED Requirements

### Requirement: Backend exposes isolated report interpreter API
The backend SHALL expose medical report interpreter endpoints under a dedicated `/report-interpreter` namespace in the existing FastAPI app.

#### Scenario: Report interpreter health endpoint
- **WHEN** a client requests `GET /report-interpreter/health`
- **THEN** the existing FastAPI app returns a successful report-interpreter health response
- **THEN** existing assistant, query-tools, wearable, and demo routes remain registered

#### Scenario: Extracted generic API paths are not introduced
- **WHEN** the report interpreter backend is integrated
- **THEN** the imported extracted-app routes are not mounted as generic `/api/*` routes
- **THEN** report interpreter clients use `/report-interpreter/*` endpoint paths

### Requirement: Backend analyzes uploaded medical reports
The backend SHALL accept supported uploaded report files, extract text, invoke the configured model path for interpretation, and return a structured report analysis response.

#### Scenario: Text report upload succeeds
- **WHEN** a client uploads a supported text or JSON medical report with an active patient id
- **THEN** the backend extracts report text
- **THEN** the backend returns analysis text, report context, detected report metadata, parsed lab-value visuals when available, and patient-scoped save details

#### Scenario: Unsupported report type is rejected
- **WHEN** a client uploads an unsupported file type
- **THEN** the backend returns a validation error before invoking a model
- **THEN** the backend does not attempt to save parsed report values

#### Scenario: Optional persistence fails
- **WHEN** report analysis succeeds but eHospital persistence fails
- **THEN** the backend returns the analysis response with save error details
- **THEN** the whole analysis request is not failed solely because optional persistence failed

### Requirement: Backend extracts report text with OCR fallback
The backend SHALL support text extraction from text, JSON, text-based PDF, image, and scanned PDF inputs, preserving the extracted app's original OCR-dependent report-reading capabilities when OCR tools are installed.

#### Scenario: Text-based PDF extraction
- **WHEN** a client uploads a text-based PDF
- **THEN** the backend extracts embedded PDF text without requiring OCR tools

#### Scenario: OCR tools are unavailable
- **WHEN** a scanned PDF or image requires OCR and OCR tools are unavailable
- **THEN** the backend returns a clear degraded extraction error
- **THEN** the error message identifies that OCR support requires external tools such as Tesseract or Poppler

#### Scenario: OCR tools are installed
- **WHEN** a scanned PDF or image report is uploaded in an environment with OCR tools installed
- **THEN** the backend extracts report text through OCR
- **THEN** the backend continues the normal report analysis flow

#### Scenario: Production-like workflow preserves OCR
- **WHEN** the app is prepared for a production-like run
- **THEN** OCR dependencies are installed or explicitly verified
- **THEN** scanned-PDF and image report support is not silently dropped during integration

### Requirement: Backend supports report follow-up chat
The backend SHALL provide report-context-aware chat and suggested question endpoints for report interpreter sessions.

#### Scenario: Follow-up chat uses report context
- **WHEN** a client sends report interpreter chat messages with file context
- **THEN** the backend includes the report context in the model prompt
- **THEN** the backend returns a report-specific assistant reply

#### Scenario: Suggested questions fallback
- **WHEN** the model returns invalid suggested-question JSON or cannot be reached
- **THEN** the backend returns deterministic fallback follow-up questions

### Requirement: Backend supports patient-scoped saved records
The backend SHALL expose report-interpreter endpoints for patient lookup, patient assignment, available test types, saved test dates, and saved record text.

#### Scenario: Saved record dates are patient scoped
- **WHEN** a client requests saved record dates for a test type and patient id
- **THEN** the backend queries only records for that patient id
- **THEN** the response contains dates for the requested test type

#### Scenario: Hard-coded demo patient is not used
- **WHEN** a request includes an explicit patient id
- **THEN** the backend uses that patient id for saved record and persistence operations
- **THEN** the backend does not fall back to the extracted app's demo patient id
