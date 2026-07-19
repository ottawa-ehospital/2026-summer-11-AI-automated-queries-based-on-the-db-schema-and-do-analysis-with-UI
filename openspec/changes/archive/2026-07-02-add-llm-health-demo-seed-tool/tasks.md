## 1. OpenSpec Planning

- [x] 1.1 Create proposal for a standalone LLM health demo seed tool.
- [x] 1.2 Add design decisions for fixed-email patients, idempotent recent windows, refresh mode, and symptom placement in `vitals_history.notes`.
- [x] 1.3 Add specs for fixed patient creation, three scenario seeding, idempotency, refresh mode, and structured output.

## 2. Seed Script

- [x] 2.1 Add a script under `src/datasets` that creates or reuses fixed demo users and matching patient registrations.
- [x] 2.2 Seed normal, hypertension-with-medication, and sleep-deprivation scenarios using existing eHospital tables.
- [x] 2.3 Store symptom evidence in `vitals_history.notes`.
- [x] 2.4 Skip recent scenario measurements by default when data exists in the configured recent window.
- [x] 2.5 Add `--refresh-recent`, `--dry-run`, `--window-hours`, and `--base-url` options.
- [x] 2.6 Print structured JSON containing the final email-to-patient-id mapping.

## 3. Tests and Verification

- [x] 3.1 Add unit tests for fixed patient identity creation.
- [x] 3.2 Add unit tests for recent-window duplicate detection.
- [x] 3.3 Add unit tests proving medication context and symptom notes are seeded correctly.
- [x] 3.4 Run targeted tests and OpenSpec validation.
