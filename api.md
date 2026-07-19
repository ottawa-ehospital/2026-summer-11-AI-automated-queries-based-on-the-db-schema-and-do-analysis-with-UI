# Smart Health API Reference

Last verified against the deployed server on 2026-06-03.

Remote eHospital base URL:

```text
https://aetab8pjmb.us-east-1.awsapprunner.com
```

Local Python backend default URL:

```text
http://127.0.0.1:8000
```

## Quick Findings

- The deployed eHospital service is healthy and currently exposes 69 database tables.
- All 69 tables can be introspected through `GET /tables`.
- All 69 tables can be read through `GET /table/{table}` and `POST /sql/select`.
- The largest useful app-facing tables are `wearable_vitals` 197 rows, `patient_feedback` 176 rows, `appointments` 150 rows, `prescription_form` 127 rows, and `requisition_form` 122 rows.
- Empty tables observed: `billing_services`, `incidents`, `schema_migrations`.
- `GET /table/{table}?patient_id=1` does not filter server-side. Use `POST /sql/select` with a `WHERE patient_id = :patient_id` clause, or filter client-side.
- No authentication requirement was observed on the documented eHospital endpoints.
- The service supports write endpoints in the generic table API. Treat them as real database writes.

## Which Data Can Be Retrieved?

Patient-scoped clinical/app data is available from tables containing `patient_id`, including:

- Profile and demographics: `patients_registration`
- Wearables and vitals: `wearable_vitals`, `vitals_history`, `ecg`
- Diagnostics and risk analyses: `ai_diagnostics`, `diabetes_analysis`, `heart_disease_analysis`, `stroke_prediction`, `lung_cancer_analysis`, `alzheimer`, `tumor`, `breast_cancer_details`
- Clinical records: `diagnosis`, `medical_history`, `family_history`, `surgical_history`, `lab_tests`, `bloodtests`, `eye_test`
- Care operations: `appointments`, `prescription`, `prescription_form`, `requisition_form`, `billing_records`, `insurance_claims`
- Messaging and feedback: `message_pat_to_doctor`, `message_doctor_to_pat`, `message_pat_to_clinicalstaff`, `message_clinicalstaff_to_pat`, `patient_message_hub`, `patient_feedback`
- Preferences and outcomes: `patient_preference`, `patients_outcome_measure`
- Nutrition: `app_nutrition_log`

Non-patient reference/admin data is also available, including doctors, labs, pharmacies, medicines, services catalog, staff, trials, clinics, hospital service history, users, password reset records, and audit logs.

Sensitive fields are present in the schema, such as `password_hash`, `token`, `OHIP_code`, private insurance fields, messages, addresses, and clinical notes. Avoid logging or displaying them unless the feature explicitly requires it.

## Remote eHospital API

### `GET /`

Health check plus detected table names.

```http
GET https://aetab8pjmb.us-east-1.awsapprunner.com/
```

Response shape:

```json
{
  "message": "MySQL Database service is running",
  "status": "healthy",
  "timestamp": "2026-06-03T07:01:12.528Z",
  "tables": ["users", "patients_registration", "wearable_vitals"]
}
```

### `GET /tables`

Returns schema metadata for every detected table.

```http
GET https://aetab8pjmb.us-east-1.awsapprunner.com/tables
```

Response shape:

```json
{
  "count": 69,
  "tables": [
    {
      "name": "wearable_vitals",
      "qualifiedName": "wearable_vitals",
      "modelName": "WearableVitals",
      "primaryKeys": ["vital_id"],
      "attributes": [
        "vital_id",
        "patient_id",
        "heart_rate",
        "steps",
        "calories",
        "sleep",
        "timestamp",
        "recorded_on"
      ]
    }
  ]
}
```

### `POST /sql/select`

Runs one read-only SQL query. The query must begin with `SELECT` or `WITH`. Use named `replacements` for user-provided values.

This is the preferred endpoint for patient-scoped reads because `GET /table/{table}` does not server-filter by query parameters.

```http
POST https://aetab8pjmb.us-east-1.awsapprunner.com/sql/select
Content-Type: application/json

{
  "sql": "SELECT vital_id, patient_id, heart_rate, steps, calories, sleep, timestamp, recorded_on FROM wearable_vitals WHERE patient_id = :patient_id ORDER BY timestamp DESC LIMIT 20",
  "replacements": {
    "patient_id": "1"
  }
}
```

Response shape:

```json
{
  "count": 3,
  "data": [
    {
      "vital_id": 206,
      "patient_id": 1,
      "heart_rate": 83,
      "steps": 5110,
      "calories": 475,
      "sleep": "7.00",
      "timestamp": "2026-04-30T03:30:41.000Z",
      "recorded_on": "2026-04-30T10:30:42.000Z"
    }
  ]
}
```

Useful query patterns:

```sql
SELECT COUNT(*) AS count FROM wearable_vitals;

SELECT *
FROM patients_registration
WHERE patient_id = :patient_id
LIMIT 1;

SELECT *
FROM lab_tests
WHERE patient_id = :patient_id
ORDER BY test_date DESC
LIMIT 20;

SELECT *
FROM prescription_form
WHERE patient_id = :patient_id
ORDER BY date_prescribed DESC
LIMIT 20;
```

### `GET /table/{table}`

Returns all rows from a table.

```http
GET https://aetab8pjmb.us-east-1.awsapprunner.com/table/wearable_vitals
```

Response shape:

```json
{
  "table": "wearable_vitals",
  "count": 197,
  "data": [
    {
      "vital_id": 206,
      "patient_id": 1,
      "heart_rate": 83,
      "steps": 5110,
      "calories": 475,
      "sleep": "7.00",
      "timestamp": "2026-04-30T03:30:41.000Z",
      "recorded_on": "2026-04-30T10:30:42.000Z"
    }
  ]
}
```

Important behavior:

- `GET /table/wearable_vitals?patient_id=1` returned all 197 rows during verification.
- Use `/sql/select` for server-side filtering.
- There is no observed pagination parameter. Large tables should be read with `/sql/select LIMIT ...`.

### `GET /table/{table}/{id}`

Fetches one row by the table primary key. This works for single-column primary keys.

```http
GET https://aetab8pjmb.us-east-1.awsapprunner.com/table/patients_registration/1
```

Response shape:

```json
{
  "patient_id": 1,
  "name": "Larry Gonzalez",
  "dob": "1932-03-06",
  "gender": "Male",
  "contact_info": "...",
  "family_doctor_id": 1
}
```

### `POST /table/{table}`

Creates a row. Payload keys must match table column names.

```http
POST https://aetab8pjmb.us-east-1.awsapprunner.com/table/wearable_vitals
Content-Type: application/json

{
  "patient_id": 1,
  "heart_rate": 72,
  "steps": 6500,
  "calories": 320,
  "sleep": 7,
  "timestamp": "2026-06-03T12:00:00.000Z"
}
```

Response shape:

```json
{
  "message": "Record created successfully",
  "data": {
    "vital_id": 207,
    "patient_id": 1,
    "heart_rate": 72
  }
}
```

### `PUT /table/{table}/{id}`

Updates one row by primary key.

```http
PUT https://aetab8pjmb.us-east-1.awsapprunner.com/table/wearable_vitals/207
Content-Type: application/json

{
  "heart_rate": 74
}
```

### `DELETE /table/{table}/{id}`

Deletes one row by primary key.

```http
DELETE https://aetab8pjmb.us-east-1.awsapprunner.com/table/wearable_vitals/207
```

### Error Responses

Observed/documented patterns:

- `400`: invalid table name, invalid payload, unsupported primary key shape, invalid SQL, non-read SQL, or multiple SQL statements
- `404`: table or row not found
- `500`: internal database/query error

FastAPI-style wrappers in this project may also return:

- `502`: local backend failed to fetch from remote eHospital service

## Remote Table Inventory

Rows are live counts from the deployed server at verification time.

| Table | Rows | Primary key | Scope key | Fields |
| --- | ---: | --- | --- | --- |
| ai_diagnostics | 26 | record_id | patient_id | `record_id, patient_id, disease_type, prediction, confidence_score, created_at` |
| allergy_reaction | 20 | reaction_id | - | `reaction_id, allergy_record_id, reaction_description, reaction_date` |
| allergy_records | 23 | record_id | patient_id | `record_id, patient_id, allergen, severity, recorded_on` |
| alzheimer | 21 | record_id | patient_id | `record_id, patient_id, memory_loss_score, risk_level, diagnosis_date` |
| app_nutrition_log | 10 | log_id | patient_id | `log_id, patient_id, logged_at, image_storage_path, identified_foods, estimated_portions, calories, protein_g, fat_g, carbohydrates_g, sodium_mg, sugar_g, insight_risk, insight_warning, insight_positive, ingredients_list` |
| appointments | 150 | appointment_id | patient_id | `appointment_id, patient_id, doctor_id, datetime, status` |
| audit_log | 20 | log_id | user_id | `log_id, user_id, action, table_name, record_id, timestamp` |
| billing_records | 22 | billing_id | patient_id | `billing_id, patient_id, appointment_id, amount, billing_date, status, bill_type` |
| billing_services | 0 | billing_id, service_code | - | `billing_id, service_code` |
| bloodtests | 21 | bloodtest_id | patient_id | `bloodtest_id, patient_id, test_name, result_value, unit, normal_range, test_date` |
| breast_cancer_details | 20 | case_id | patient_id | `case_id, patient_id, tumor_size, diagnosis_stage` |
| chat_table | 20 | chat_id | patient_id | `chat_id, patient_id, started_at, ended_at` |
| chatbot_conversation | 21 | conversation_id | - | `conversation_id, chat_id, message, response, timestamp` |
| chatbot_patients | 20 | chat_id | patient_id | `chat_id, patient_id, session_id, start_time` |
| clinic_help | 20 | ticket_id | clinic_id | `ticket_id, clinic_id, issue_description, submitted_by` |
| clinic_recordauthorized | 20 | record_id | clinic_id | `record_id, clinic_id, authorized_by, authorized_on` |
| clinic_servicehistory | 10 | clinic_id | clinic_id | `clinic_id, clinic_name, location, active` |
| clinical_staff_message_hub | 20 | hub_id | staff_id | `hub_id, staff_id, summary` |
| clinical_staff_registration | 20 | staff_id | staff_id | `staff_id, name, role, email, clinic_id` |
| clinical_staff_tasks | 20 | task_id | - | `task_id, assigned_to, task_description, status, deadline` |
| clinical_trials | 20 | trial_id | - | `trial_id, title, status, start_date, end_date` |
| clinicaltrials_patients | 20 | entry_id | patient_id | `entry_id, trial_id, patient_id, enrolled_on` |
| diabetes_analysis | 20 | diabetes_id | patient_id | `diabetes_id, patient_id, glucose_level, insulin, prediction` |
| diagnosis | 40 | diagnosis_id | patient_id | `diagnosis_id, patient_id, doctor_id, diagnosis_code, diagnosis_description, diagnosis_date` |
| doctor_tasks | 20 | task_id | doctor_id | `task_id, doctor_id, description, status, due_date` |
| doctor_to_patient_message | 20 | message_id | patient_id | `message_id, doctor_id, patient_id, message, sent_at` |
| doctors_help | 20 | ticket_id | doctor_id | `ticket_id, doctor_id, issue, submitted_on` |
| doctors_registration | 20 | doctor_id | doctor_id | `doctor_id, name, specialty, clinic_id, license_number, email, phone_number, address, hospital_name` |
| ecg | 20 | ecg_id | patient_id | `ecg_id, patient_id, ecg_result, recorded_on, comments` |
| eye_test | 20 | eye_test_id | patient_id | `eye_test_id, patient_id, test_type, result, vision_metric, vision_score, test_date, comments` |
| family_history | 20 | history_id | patient_id | `history_id, patient_id, relation, condition, notes` |
| heart_disease_analysis | 21 | analysis_id | patient_id | `analysis_id, patient_id, cholesterol, resting_bp, age, sex, risk_score, prediction, analyzed_on, model_version, comments` |
| hospital_admin | 16 | admin_id | - | `admin_id, name, email, role, hospital_id, created_on, status, last_login, auth_level, password_hash` |
| hospital_recordauthorized | 20 | record_id | patient_id | `record_id, hospital_id, patient_id, authorized_by, reason, access_level, expires_on, status, authorized_on` |
| hospital_servicehistory | 20 | service_id | - | `service_id, hospital_id, description, service_type, logged_by, status, priority, resolved_on, date_logged` |
| incidents | 0 | incident_id | user_id | `incident_id, user_id, incident_file, incident_punishment, created_at` |
| insurance_claims | 20 | claim_id | patient_id | `claim_id, patient_id, billing_id, insurance_provider, claim_amount, approved_amount, claim_status, submitted_on, processed_on, payment_status, reference_number, notes` |
| lab_registration | 31 | lab_id | lab_id | `lab_id, name, email, phone_number, address, license_no, status, registered_on` |
| lab_tests | 20 | lab_test_id | patient_id | `lab_test_id, patient_id, ordered_by, test_type, lab_location, status, sample_type, result, comments, test_date, uploaded_on` |
| lung_cancer_analysis | 20 | analysis_id | patient_id | `analysis_id, patient_id, analysis_date, run_by, model_version, status, followup_needed, stage, probability, comments` |
| medical_history | 20 | history_id | patient_id | `history_id, patient_id, diagnosed_by, condition, status, severity, diagnosis_date, notes, treatment_given, followup_required, last_updated` |
| medicines | 20 | medicine_id | - | `medicine_id, name, description, dosage_form, strength, manufacturer, price, created_on, is_available` |
| message_clinicalstaff_to_pat | 20 | message_id | patient_id | `message_id, sender_id, patient_id, message, sent_at, status, is_urgent, delivered_at, reply_to` |
| message_doctor_to_pat | 20 | message_id | patient_id | `message_id, doctor_id, patient_id, message, sent_at, status, is_urgent, delivered_at, reply_to, attachment_url` |
| message_pat_to_clinicalstaff | 20 | message_id | patient_id | `message_id, patient_id, receiver_id, message, sent_at, status, is_urgent, delivered_at, reply_to` |
| message_pat_to_doctor | 22 | message_id | patient_id | `message_id, patient_id, doctor_id, message, sent_at, status, is_urgent, delivered_at, reply_to, attachment_url` |
| password_resets | 20 | reset_id | user_id | `reset_id, user_id, requested_at, token, expires_at, used, used_at` |
| patient_feedback | 176 | id | patient_id | `id, patient_id, treatment, feedback, datetime, is_severe, feedback_type` |
| patient_message_hub | 20 | hub_id | patient_id | `hub_id, patient_id, summary, last_updated, message_count, status` |
| patient_preference | 57 | preference_id | patient_id | `preference_id, patient_id, preference_type, pharmacy_id, lab_id, notes` |
| patients_outcome_category | 5 | category_id | - | `category_id, name, description, created_on, status` |
| patients_outcome_domain | 5 | domain_id | - | `domain_id, category_id, name, description` |
| patients_outcome_measure | 10 | measure_id | patient_id | `measure_id, patient_id, domain_id, type_id, score, assessment_date, notes` |
| patients_outcome_measure_detail | 20 | detail_id | - | `detail_id, measure_id, attribute_name, value` |
| patients_outcome_measure_type | 5 | type_id | - | `type_id, name, description` |
| patients_registration | 20 | patient_id | patient_id | `patient_id, name, dob, gender, contact_info, phone_number, OHIP_code, private_insurance_name, private_insurance_id, weight_kg, height_cm, family_doctor_id` |
| pharmaceutical_company | 10 | company_id | - | `company_id, name, contact_email, phone_number, address, country, status, created_on` |
| pharmacy_registration | 40 | pharmacy_id | pharmacy_id | `pharmacy_id, name, email, phone_number, address, license_no, status, registered_on` |
| prescription | 12 | prescription_id | patient_id | `prescription_id, patient_id, doctor_id, medicine_name, dosage, start_date, end_date, notes, issued_on, status` |
| prescription_form | 127 | prescription_id | patient_id | `prescription_id, patient_id, prescriber_id, medication_name, medication_strength, medication_form, dosage_instructions, quantity, refills_allowed, date_prescribed, expiry_date, status, notes, pharmacy_id` |
| requisition_form | 122 | requisition_id | patient_id | `requisition_id, patient_id, lab_id, department, test_type, test_code, clinical_info, date_requested, priority, status, result_date, notes` |
| schema_migrations | 0 | filename | - | `filename, checksum, applied_at` |
| services_catalog | 3 | service_code | - | `service_code, service_name, service_price, description, created_on` |
| stroke_prediction | 10 | prediction_id | patient_id | `prediction_id, patient_id, risk_score, predicted_on, model_version, comments` |
| surgical_history | 10 | surgery_id | patient_id | `surgery_id, patient_id, surgery_type, surgery_date, surgeon_name, hospital_name, recovery_status, notes` |
| tumor | 10 | tumor_id | patient_id | `tumor_id, patient_id, tumor_type, location, size_cm, diagnosed_on, status, notes` |
| users | 11 | user_id | user_id | `user_id, username, email, password_hash, role, created_on, status` |
| vitals_history | 35 | vital_id | patient_id | `vital_id, patient_id, blood_pressure, heart_rate, temperature, respiratory_rate, recorded_on, notes` |
| wearable_vitals | 197 | vital_id | patient_id | `vital_id, patient_id, heart_rate, steps, calories, sleep, timestamp, recorded_on` |

## Local Python Backend API

Run locally:

```bash
make api
```

The local backend is a FastAPI app in `src/backend/main.py`. It exposes an authentication proxy plus assistant endpoints backed by the remote eHospital API and the configured model provider.

### Authentication Endpoint

#### `POST /login`

Request:

```json
{
  "email": "patient@example.com",
  "password": "secret",
  "selectedOption": "Patient"
}
```

This proxies the React/Node eHospital backend `POST /api/users/login` endpoint
at the configured `EHOSPITAL_AUTH_BASE_URL`.
On success, the response preserves the returned user fields and also normalizes
`patient_id`, `user_id`, `email`, and `username` for the Flutter session. The
backend strips sensitive login fields before returning the payload.
Local JSON `username/password` login is not supported by the runtime `/login`
endpoint.

### Assistant endpoints

These use remote eHospital data through `EHOSPITAL_BASE_URL`, then call the configured model provider.

#### `GET /assistant/patients/{patient_id}/context`

Builds one patient context document from the remote tables:

- `users`
- `wearable_vitals`
- `vitals_history`
- `ecg`
- `diabetes_analysis`
- `heart_disease_analysis`
- `stroke_prediction`
- `lab_tests`
- `diagnosis`

Response shape:

```json
{
  "patient_id": 1,
  "patient": {},
  "latest_wearable": [],
  "latest_vitals_history": {},
  "latest_ecg": {},
  "latest_diabetes_analysis": {},
  "latest_heart_disease_analysis": {},
  "latest_stroke_prediction": {},
  "recent_lab_tests": [],
  "recent_diagnosis": []
}
```

Important implementation note: the current context builder searches `users` by `patient_id` or `id`, but the remote `users` table exposes `user_id`, not `patient_id`. As written, `/assistant/patients/{patient_id}/context` may return `404 Unknown patient_id` unless the remote user rows happen to include one of those keys.

#### `POST /assistant/chat`

Request:

```json
{
  "patient_id": 1,
  "message": "Summarize my latest wearable data."
}
```

Response:

```json
{
  "reply": "..."
}
```

Validation:

- Empty or whitespace-only `message` returns `400`.
- Unknown patient context returns `404`.
- Remote eHospital fetch failures return `502`.

#### `POST /assistant/vitals-summary`

Request:

```json
{
  "patient_id": 1,
  "metric": "Steps",
  "latest": 5110,
  "average": 8300,
  "peak": 14519,
  "zero_count": 0,
  "total_count": 7,
  "unit": "steps",
  "healthy_range": "5000-15000",
  "clinical_note": "Optional note"
}
```

Response:

```json
{
  "summary": "..."
}
```

#### `POST /assistant/trend-insights`

Request:

```json
{
  "patient_id": 1,
  "steps": {
    "last_week": 7000,
    "this_week": 8500
  },
  "calories": {
    "last_week": 300,
    "this_week": 350
  },
  "heart_rate": {
    "last_week": 72,
    "this_week": 74
  },
  "sleep": {
    "last_week": 6.5,
    "this_week": 7.1
  }
}
```

Response:

```json
{
  "insights": {
    "Steps": "...",
    "Active Calories": "...",
    "Heart Rate": "...",
    "Sleep": "..."
  }
}
```

## Flutter Integration Notes

The Flutter app defaults are in `src/app/lib/config/api_config.dart`:

- `EHOSPITAL_BASE_URL`: `https://aetab8pjmb.us-east-1.awsapprunner.com`
- `BACKEND_BASE_URL`: `http://127.0.0.1:8000`

`EHospitalRepository.fetchTable(table, patientId: ...)` currently calls remote `GET /table/{table}` and filters `patient_id` on the client. This works for small tables but pulls the full table. For production-like usage, prefer a backend/repository method that calls `POST /sql/select` with `WHERE patient_id = :patient_id` and `LIMIT`.

`EHospitalRepository.sendWearableVitals(...)` writes to:

```text
POST /table/wearable_vitals
```

with this shape:

```json
{
  "patient_id": "1",
  "heart_rate": 72,
  "steps": 6500,
  "calories": 320,
  "sleep": 7,
  "timestamp": "2026-06-03T12:00:00.000"
}
```

## Recommended App Queries

### Latest patient profile

```json
{
  "sql": "SELECT patient_id, name, dob, gender, contact_info, phone_number, weight_kg, height_cm, family_doctor_id FROM patients_registration WHERE patient_id = :patient_id LIMIT 1",
  "replacements": {
    "patient_id": "1"
  }
}
```

### Latest wearable vitals

```json
{
  "sql": "SELECT vital_id, patient_id, heart_rate, steps, calories, sleep, timestamp, recorded_on FROM wearable_vitals WHERE patient_id = :patient_id ORDER BY timestamp DESC LIMIT 30",
  "replacements": {
    "patient_id": "1"
  }
}
```

### Latest clinical vitals

```json
{
  "sql": "SELECT vital_id, patient_id, blood_pressure, heart_rate, temperature, respiratory_rate, recorded_on, notes FROM vitals_history WHERE patient_id = :patient_id ORDER BY recorded_on DESC LIMIT 20",
  "replacements": {
    "patient_id": "1"
  }
}
```

### Recent lab tests

```json
{
  "sql": "SELECT lab_test_id, patient_id, ordered_by, test_type, lab_location, status, sample_type, result, comments, test_date, uploaded_on FROM lab_tests WHERE patient_id = :patient_id ORDER BY test_date DESC LIMIT 20",
  "replacements": {
    "patient_id": "1"
  }
}
```

### Recent prescriptions

```json
{
  "sql": "SELECT prescription_id, patient_id, prescriber_id, medication_name, medication_strength, medication_form, dosage_instructions, quantity, refills_allowed, date_prescribed, expiry_date, status, notes, pharmacy_id FROM prescription_form WHERE patient_id = :patient_id ORDER BY date_prescribed DESC LIMIT 20",
  "replacements": {
    "patient_id": "1"
  }
}
```

### Recent appointments

```json
{
  "sql": "SELECT appointment_id, patient_id, doctor_id, datetime, status FROM appointments WHERE patient_id = :patient_id ORDER BY datetime DESC LIMIT 20",
  "replacements": {
    "patient_id": "1"
  }
}
```
