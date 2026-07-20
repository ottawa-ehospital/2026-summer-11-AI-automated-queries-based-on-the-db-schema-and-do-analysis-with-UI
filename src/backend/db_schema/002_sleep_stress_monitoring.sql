-- Sleep and stress monitoring remote schema additions.
-- The wearable_vitals columns are nullable so older wearable writes remain valid.

ALTER TABLE wearable_vitals
  ADD COLUMN hrv_sdnn DOUBLE NULL,
  ADD COLUMN resting_heart_rate DOUBLE NULL,
  ADD COLUMN respiratory_rate DOUBLE NULL,
  ADD COLUMN stress_score DOUBLE NULL,
  ADD COLUMN annotation TEXT NULL;

CREATE TABLE IF NOT EXISTS sleep_nights (
  patient_id VARCHAR(64) NOT NULL,
  night DATE NOT NULL,
  deep_minutes DOUBLE NOT NULL DEFAULT 0,
  rem_minutes DOUBLE NOT NULL DEFAULT 0,
  core_minutes DOUBLE NOT NULL DEFAULT 0,
  light_minutes DOUBLE NOT NULL DEFAULT 0,
  awake_minutes DOUBLE NOT NULL DEFAULT 0,
  asleep_minutes DOUBLE NOT NULL DEFAULT 0,
  in_bed_minutes DOUBLE NOT NULL DEFAULT 0,
  spo2_avg DOUBLE NULL,
  spo2_min DOUBLE NULL,
  hr_avg DOUBLE NULL,
  hr_min DOUBLE NULL,
  source VARCHAR(64) NULL DEFAULT 'apple_health',
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (patient_id, night),
  INDEX idx_sleep_nights_patient_night (patient_id, night)
);
