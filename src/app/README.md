# Smart Health App

A Flutter app for patient health monitoring, Apple Health wearable sync, eHospital clinical records, and backend-backed AI assistance.

## Features

- Email login against the eHospital users table.
- Patient session stored with `SharedPreferences`.
- Apple Health / Apple Watch vitals sync.
- eHospital clinical records and wearable vitals dashboards.
- AI assistant area backed by the unified Python FastAPI backend, with separate Chat and Report Interpreter modules.
- Medical report interpreter for uploaded text, JSON, PDF, image, scanned-report OCR, saved-record review, and report follow-up questions.
- Local Ollama testing and optional Gemini configuration.
- Medication, symptoms, goals, BMI, emergency, profile, and trend screens.

## Flutter Architecture

```text
lib/
  config/
    api_config.dart
  core/
    network/
      api_client.dart
      api_exception.dart
    widgets/
      app_card.dart
      metric_tile.dart
      section_header.dart
      state_views.dart
  data/
    models/
    repositories/
  features/
    auth/
    dashboard/
    devices/
    emergency/
    goals/
    health_assistant/
    report_interpreter/
    insights/
    medications/
    profile/
    settings/
    symptoms/
    tools/
    trends/
    vitals/
  services/
    thin compatibility wrappers around repositories
  ui/
    app_theme.dart
```

Screens belong in `features/<feature>/screens`. Shared API and parsing logic belongs in `data/repositories` and `core/network`. Shared visual primitives belong in `core/widgets`.

## Backend Architecture

Backend code lives outside the Flutter app:

```text
src/backend/
  main.py                 canonical FastAPI app entry point
  api/                    FastAPI routers
  clients/                eHospital and model-provider clients
  core/                   backend settings and shared helpers
  schemas/                Pydantic request/response models
  services/               assistant and patient-context orchestration
```

Use `src.backend.main:app` for new backend commands. Older compatibility shims may still exist for previous imports.

The report interpreter backend is integrated into this same FastAPI app under `/report-interpreter/*`; do not run the extracted standalone report-interpreter backend separately after integration. The existing health chat continues to use `/assistant/*`.

## Running

Install Flutter dependencies:

```powershell
flutter pub get
```

Start the Python backend from the repository root:

```powershell
.\tasks.ps1 ai-backend-dev
```

Canonical raw backend command:

```powershell
conda run -n langgraph uvicorn src.backend.main:app --reload --host 127.0.0.1 --port 8000
```

Start Flutter in backend AI mode:

```powershell
.\tasks.ps1 flutter-run-cors-backend
```

Equivalent raw Flutter flags:

```powershell
flutter run `
  --dart-define=AI_PROVIDER=backend `
  --dart-define=BACKEND_BASE_URL=http://127.0.0.1:8000
```

Open the existing AI assistant entry point (`/assistant`) to choose between:

- `Chat`: the current health assistant UI and `/assistant/chat` backend.
- `Report Analyze`: the migrated report upload/saved-record/report-follow-up UI and `/report-interpreter/*` backend.

Backend URL examples:

- Local desktop/web: `http://127.0.0.1:8000`
- Android emulator: `http://10.0.2.2:8000`
- Physical phone: `http://<your-computer-lan-ip>:8000`
- Production-like testing: deployed HTTPS backend URL

For an iPhone on the same Wi-Fi as the development Mac, bind the backend to all local interfaces and pass the Mac LAN IP to Flutter:

```bash
# Terminal 1, repository root
make api-dev API_HOST=0.0.0.0 API_PORT=8080
```

```bash
# Terminal 2, repository root
make flutter-run \
  FLUTTER_DEVICE=00008130-000414CE3043401C \
  AI_PROVIDER=backend \
  BACKEND_BASE_URL=http://10.0.0.173:8080
```

If the Wi-Fi network changes, refresh the Mac LAN IP with `ipconfig getifaddr en0` and update `BACKEND_BASE_URL`.

## Configuration

Do not commit real API keys or OAuth secrets. `lib/config/api_config.dart` reads runtime values from `--dart-define`.

Supported keys are documented in `dart_defines.example.json`, including:

- `AI_PROVIDER`
- `BACKEND_BASE_URL`
- `EHOSPITAL_BASE_URL`
- `OLLAMA_BASE_URL`
- `OLLAMA_MODEL`
- `GEMINI_API_KEY`
- `GEMINI_MODEL`
- `FITBIT_CLIENT_ID`
- `FITBIT_CLIENT_SECRET`

Flutter client-side values are not secure secret storage. Production secret-bearing calls should be mediated by a backend service.

## Report Interpreter OCR

Text and JSON reports work with the normal backend dependencies. Text-based PDFs require the `pypdf` Python package. Image reports and scanned PDFs require the OCR stack:

- Python packages: `python-multipart`, `pypdf`, `pdf2image`, `pillow`, `pytesseract`
- System tools: Tesseract OCR and Poppler (`pdfinfo`/`pdftoppm`)

The Python packages are included in the repository `environment.yml`. Update the local backend environment from the repository root:

```bash
conda env update -n langgraph -f environment.yml
```

Install the system tools separately:

```bash
# macOS
brew install tesseract poppler
```

```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install -y tesseract-ocr poppler-utils
```

```powershell
# Windows with Chocolatey
choco install tesseract poppler
```

Local development can run without Tesseract/Poppler for text, JSON, and text-based PDF work; scanned PDFs and images will return a clear degraded error if OCR tools are missing. Production-like demo or deployment environments must install or explicitly verify these tools so the original scanned-report/image functionality is preserved.

Run one of these checks from the repository root:

```powershell
.\tasks.ps1 ocr-check
```

```bash
make ocr-check
```

## Apple Health

HealthKit does not work in the simulator. Use a physical iPhone paired with an Apple Watch, enable HealthKit capability in Xcode, and keep the deployment target at iOS 14.0 or newer.

## eHospital Tables

The app reads remote tables such as:

- `users`
- `wearable_vitals`
- `vitals_history`
- `ecg`
- `lab_tests`
- `diabetes_analysis`
- `heart_disease_analysis`
- `stroke_prediction`
- `diagnosis`
