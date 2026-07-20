## Database Compatibility Check

Checked against live eHospital database API:

```text
https://aetab8pjmb.us-east-1.awsapprunner.com
```

Date checked: 2026-07-17

## Result

The remote database is usable for the CareFlow urgent-care workflow.

The local `src/backend/ehospital_schema_inventory.json` in DTI6302 is stale for these tables: it does not list `healthcare_records`, and it shows an older `patient_feedback` shape. Urgent-care implementation should not maintain or depend on that local inventory; it should use live `/tables` metadata when schema validation is needed.

## Required Tables

### `patients_registration`

Live primary key:

- `patient_id`

Live fields needed by urgent care:

- `patient_id`
- `name`
- `dob`
- `gender`
- `contact_info`
- `phone_number`
- `OHIP_code`
- `private_insurance_name`
- `private_insurance_id`
- `weight_kg`
- `height_cm`
- `family_doctor_id`

Compatibility: OK.

### `healthcare_records`

Live primary key:

- `record_id`

Live fields:

- `record_id`
- `patient_id`
- `symptoms`
- `ctas_urgency_level`
- `risk_score`
- `queue_name`
- `status`
- `clinical_summary`
- `recommended_action`
- `check_in_time`
- `consultation_started_at`
- `completed_at`

Compatibility: OK. This matches the core CareFlow `patient_to_healthcare_record()` payload.

### `patient_feedback`

Live primary key:

- `feedback_id`

Live fields:

- `feedback_id`
- `feedback_message`
- `created_time`
- `rating`
- `record_id`
- `condition_update`
- `alert_required`
- `alert_reason`

Compatibility: OK. This matches the CareFlow feedback payload.

Note: the checked-in inventory currently shows the older fields `id`, `patient_id`, `treatment`, `feedback`, `datetime`, `is_severe`, and `feedback_type`; urgent-care implementation must rely on live metadata instead of the local inventory.

### `medical_history`

Live primary key:

- `history_id`

Live fields:

- `history_id`
- `patient_id`
- `diagnosed_by`
- `condition`
- `status`
- `severity`
- `diagnosis_date`
- `notes`
- `treatment_given`
- `followup_required`
- `last_updated`

Compatibility: OK.

## Read Query Check

The live `/sql/select` endpoint works for urgent-care queries:

- `SELECT * FROM healthcare_records WHERE patient_id = :patient_id ORDER BY check_in_time DESC LIMIT :limit`
- `SELECT * FROM patient_feedback WHERE record_id = :record_id ORDER BY created_time DESC LIMIT :limit`

Both returned successful responses.

## Implementation Guidance

- Use live `/tables` metadata in `/urgent-care/health` or runtime schema checks instead of trusting or refreshing the stale checked-in inventory.
- Add/update an eHospital client helper for `PUT /table/:name/:id`, because staff `notify`, `start`, and `complete` actions need to update `healthcare_records`.
- Do not create new tables for the first implementation; the required remote tables already exist.
- Keep a clear error if a different deployment is configured and does not expose the same urgent-care table shape.
