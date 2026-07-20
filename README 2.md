# DTI-6302 Debug Runbook

This project has two parts:

- Python FastAPI backend: `src.backend.main:app`
- Flutter app: `src/app`

Most debug runs need two terminals: one for the backend and one for Flutter.

## 1. Check Local Network IP

For iPhone or another physical device, do not use `127.0.0.1` as the backend URL. `127.0.0.1` would point to the phone itself, not your Mac.

On macOS, get the current Wi-Fi LAN IP:

```bash
ipconfig getifaddr en0
```

If that returns empty, list non-loopback addresses:

```bash
ifconfig | awk '/^[a-z0-9]+:/{iface=$1} /inet / && $2 !~ /^127\./ {print iface, $2}'
```

Example result:

```text
10.0.0.173
```

Use that IP in `BACKEND_BASE_URL`, for example `http://10.0.0.173:8080`.

## 2. Check Flutter Devices

List connected devices:

```bash
cd src/app
flutter devices
```

Example iPhone output:

```text
Fmusher0101 (mobile) • 00008130-000414CE3043401C • ios • iOS 26.5
```

The device id is the middle value:

```text
00008130-000414CE3043401C
```

You can also run:

```bash
flutter doctor -v
```

For iPhone debugging, make sure:

- The iPhone is unlocked.
- The iPhone trusts this Mac.
- Xcode is installed and `flutter doctor -v` shows the iOS toolchain as available.
- The iPhone and Mac are on the same Wi-Fi if the app needs the local backend.

## 3. Start Backend for iPhone

For physical iPhone, bind the backend to `0.0.0.0` so other devices on the LAN can reach it.

From the repository root:

```bash
make api-dev API_HOST=0.0.0.0 API_PORT=8080
```

Patient login is proxied through the eHospital React/Node backend. By default
the backend uses the deployed Node service; to use a local checkout instead,
start `E-react-node-backend` on a different port and pass its base URL:

```bash
PORT=8081 npm start
make api-dev API_HOST=0.0.0.0 API_PORT=8080 EHOSPITAL_AUTH_BASE_URL=http://127.0.0.1:8081
```

Health checks from the Mac:

```bash
curl http://127.0.0.1:8080/report-interpreter/health
curl http://<your-mac-lan-ip>:8080/report-interpreter/health
```

Example:

```bash
curl http://10.0.0.173:8080/report-interpreter/health
```

If the LAN IP curl fails but `127.0.0.1` works, check macOS firewall or whether the backend was started with `API_HOST=127.0.0.1` by mistake.

## 4. Run Flutter on iPhone

From the repository root:

```bash
make flutter-run \
  FLUTTER_DEVICE=<device-id-from-flutter-devices> \
  AI_PROVIDER=backend \
  BACKEND_BASE_URL=http://<your-mac-lan-ip>:8080
```

Example:

```bash
make flutter-run \
  FLUTTER_DEVICE=00008130-000414CE3043401C \
  AI_PROVIDER=backend \
  BACKEND_BASE_URL=http://10.0.0.173:8080
```

When iOS asks for Local Network permission, choose Allow.

## 5. Demo Data

The LLM health demo seed script prepares two patient accounts:

| Scenario | Email | Password | Patient ID |
| --- | --- | --- | --- |
| Normal health data | `normal@demo.com` | `123456` | `391` |
| Hypertension with medication and symptoms | `hypertension@demo.com` | `123456` | `393` |

Patient login is handled by the eHospital auth service, which reads patient
credentials from its `patients_registration` login table. The seed script first
logs in or registers each demo patient through
`/api/users/PatientRegistration`, then uses the returned auth patient id when
seeding the health-data service. The current remote auth ids are `391` and
`393`.

Preview the rows without writing:

```bash
python src/datasets/seed_llm_health_scenarios.py --dry-run
```

Insert or refresh the two demo users and their current health data:

```bash
python src/datasets/seed_llm_health_scenarios.py --refresh-recent
```

Without `--refresh-recent`, the script is idempotent and skips recent
measurement rows when either demo patient already has data in the configured
analysis window. It still ensures the reusable context rows for the
hypertension scenario.

## 6. Run Flutter Web Debug

Backend terminal:

```bash
make api-dev API_HOST=127.0.0.1 API_PORT=8080
```

Flutter Chrome terminal:

```bash
make flutter-run AI_PROVIDER=backend CORS=1
```

Or run web-server:

```bash
make flutter-web AI_PROVIDER=backend BACKEND_BASE_URL=http://127.0.0.1:8080
```

## 7. Useful Checks

Install Flutter dependencies:

```bash
make flutter-get
```

Run Flutter analyzer:

```bash
make flutter-analyze
```

Run Flutter tests:

```bash
make flutter-test
```

Run backend report interpreter tests:

```bash
OPENAI_API_KEY=dummy conda run -n langgraph python -m pytest tests/test_report_interpreter_backend.py -q
```

Check OCR/PDF dependencies for the report interpreter:

```bash
make ocr-check
```

## 8. Test Medical Report Interpreter

The extracted medical-report project did not include real sample report files. It only had inline test snippets and model-performance JSON examples. This repo now includes a simple upload fixture:

```text
sample_reports/blood_report_sample.txt
```

### Test in the iPhone App

1. Start the backend:

```bash
make api-dev API_HOST=0.0.0.0 API_PORT=8080
```

2. Run Flutter on iPhone with the Mac LAN IP:

```bash
make flutter-run \
  FLUTTER_DEVICE=<device-id-from-flutter-devices> \
  AI_PROVIDER=backend \
  BACKEND_BASE_URL=http://<your-mac-lan-ip>:8080
```

3. Log in.
4. Open the AI assistant page.
5. Choose `Report Analyze`.
6. Tap the sample/beaker icon to load the bundled `blood_report_sample.txt`, or tap the upload icon to choose a report from iOS Files.
7. For manual uploads, select any `.txt`, `.json`, `.pdf`, `.jpg`, `.jpeg`, `.png`, `.bmp`, `.tif`, or `.tiff` report.
8. Tap the analyze/play icon.
9. After the analysis appears, try a follow-up question such as:

```text
Which values are outside the normal range?
```

For scanned PDFs or images, run `make ocr-check` first. Text and JSON uploads do not need OCR system tools.

### Test Backend Directly

Use this when you want to verify the backend before running the iPhone app:

```bash
curl http://127.0.0.1:8080/report-interpreter/health
```

Upload the sample report:

```bash
curl -X POST http://127.0.0.1:8080/report-interpreter/analyze-file \
  -F "patientId=20" \
  -F "file=@sample_reports/blood_report_sample.txt;type=text/plain"
```

If you are testing from another device on the same Wi-Fi, replace `127.0.0.1` with the Mac LAN IP.

### What Should Work

- Text report upload and analysis.
- Suggested follow-up questions.
- Follow-up chat using the report context.
- Saved-record date/result loading when the logged-in patient has compatible saved records.
- Text-based PDFs if `pypdf` is installed.
- Images and scanned PDFs only when Tesseract and Poppler are installed.

## 9. Test Nutrition Monitor

Nutrition Monitor is integrated as a third AI assistant module beside `Chat` and
`Report Analyze`. The source Android CalorieTrack app is treated as migration
reference material only; it is not run as a separate app inside DTI6302.

### Backend Routes

Nutrition Monitor uses the FastAPI namespace below:

```text
GET  /nutrition-monitor/health
POST /nutrition-monitor/analyze-image
POST /nutrition-monitor/meals
GET  /nutrition-monitor/meals
GET  /nutrition-monitor/summary/daily
GET  /nutrition-monitor/goals
PUT  /nutrition-monitor/goals
```

Meal images are transient analysis inputs. The backend persists structured
nutrition results to `app_nutrition_log` and leaves `image_storage_path` null in
this first version.

### Model Requirement

Food image analysis requires an image-capable configured model/provider. If the
current runtime is text-only, `/nutrition-monitor/health` reports unavailable
image analysis and `POST /nutrition-monitor/analyze-image` returns the
deterministic code `nutrition_image_model_unsupported`. The Flutter module uses
that capability metadata to disable the analyze button and show a visible
unsupported-model message before the user can submit.

### Test in the App

1. Start the backend:

```bash
make api-dev API_HOST=0.0.0.0 API_PORT=8080
```

2. Run Flutter with the backend URL:

```bash
make flutter-run \
  FLUTTER_DEVICE=<device-id-from-flutter-devices> \
  AI_PROVIDER=backend \
  BACKEND_BASE_URL=http://<your-mac-lan-ip>:8080
```

3. Log in.
4. Open the AI assistant page.
5. Choose `Nutrition Monitor`.
6. Pick a meal image from camera, gallery, or Files.
7. Optionally add a hint, then tap `Analyze meal`.
8. Review dish, portion, ingredients, nutrients, risks, warnings, positives, and
   final verdict.
9. Log the meal, then confirm today's progress and meal history refresh.

Daily nutrition goals follow the CalorieTrack local-preference behavior by
default and are stored in patient-scoped Flutter `SharedPreferences`.

### Test Backend Directly

```bash
curl http://127.0.0.1:8080/nutrition-monitor/health
```

Upload a meal image:

```bash
curl -X POST http://127.0.0.1:8080/nutrition-monitor/analyze-image \
  -F "patientId=20" \
  -F "hint=homemade low salt meal" \
  -F "file=@/path/to/meal.jpg;type=image/jpeg"
```

If you are testing from another device on the same Wi-Fi, replace `127.0.0.1`
with the Mac LAN IP.

## 10. Common Network Fixes

## 10. Test Urgent Care

Urgent Care is integrated into the existing DTI6302 backend and mobile app. The
downloaded CareFlow backend is not run as a second service, and the CareFlow
staff web dashboard is not migrated into the patient mobile app.

### Backend Routes

Patient mobile screens use only:

```text
GET  /urgent-care/customer/health
POST /urgent-care/customer/check-in
GET  /urgent-care/customer/visits/{visit_id}/status
POST /urgent-care/customer/visits/{visit_id}/feedback
GET  /urgent-care/customer/patients/{patient_id}/history
```

Backend-only workflow compatibility routes live under:

```text
/urgent-care/workflow/*
```

Do not add mobile staff dashboard screens for those workflow routes.

### Model and Database Requirements

Urgent-care CTAS and feedback analysis use the shared backend model settings:
`AI_MODEL_PROVIDER`, `AI_MODEL_NAME`, and the existing shared model client. The
integration does not use a DeepSeek-specific API path.

Urgent-care persistence uses live eHospital tables:
`patients_registration`, `healthcare_records`, `patient_feedback`, and
`medical_history`. Health checks validate live `/tables` metadata rather than
maintaining a local schema inventory snapshot.

### Clinical Safety Wording

Urgent-care CTAS, risk score, queue assignment, summaries, and recommended
actions are decision support. The mobile app and backend responses should not
present them as a diagnosis, prescription, or treatment order. Patient-facing
copy should direct patients to staff review, and feedback red flags should
prioritize staff reassessment when the model and deterministic safety rules
disagree.

### Test in the App

1. Start the backend:

```bash
make api-dev API_HOST=0.0.0.0 API_PORT=8080
```

2. Run Flutter with the backend URL:

```bash
make flutter-run \
  FLUTTER_DEVICE=<device-id-from-flutter-devices> \
  AI_PROVIDER=backend \
  BACKEND_BASE_URL=http://<your-mac-lan-ip>:8080
```

3. Log in as a patient.
4. Open `Urgent Care` from the dashboard.
5. Submit symptoms and optional medical history.
6. Confirm queue status, manual refresh, and feedback/condition update.

### Test Backend Directly

```bash
curl http://127.0.0.1:8080/urgent-care/health
```

Submit a patient check-in:

```bash
curl -X POST http://127.0.0.1:8080/urgent-care/customer/check-in \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": 391,
    "name": "Normal Demo",
    "age": 35,
    "gender": "Other",
    "symptoms": "Mild sore throat",
    "medical_history": ""
  }'
```

If you are testing from another device on the same Wi-Fi, replace `127.0.0.1`
with the Mac LAN IP.

## 11. Common Network Fixes

If the iPhone cannot reach the backend:

1. Re-run `ipconfig getifaddr en0`; Wi-Fi changes can change the Mac IP.
2. Restart backend with `API_HOST=0.0.0.0`.
3. Use `BACKEND_BASE_URL=http://<mac-lan-ip>:8080`, not `127.0.0.1`.
4. Confirm the phone and Mac are on the same network.
5. Allow Local Network permission on iOS.
6. Allow incoming Python/uvicorn connections in macOS firewall.

If Flutter cannot find the iPhone:

```bash
flutter devices
flutter doctor -v
```

Then unlock the phone, reconnect the cable, trust the Mac, and retry.
