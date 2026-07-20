-- Common workout schema for Apple HealthKit-first wearable sync.
-- The format preserves HealthKit workout identity/metadata while allowing
-- Fitbit, Google Health Connect, manual, and simulated workouts to map into
-- the same table.

CREATE TABLE IF NOT EXISTS `wearable_workouts` (
  `workout_id` bigint NOT NULL AUTO_INCREMENT,
  `patient_id` int NOT NULL,

  -- Source identity. For Apple Health this should be the HKWorkout UUID.
  -- For Fitbit this can be activity logId / tcxLink id / provider record id.
  `source_provider` enum('apple_health','fitbit','google_health','manual','simulation') NOT NULL,
  `source_workout_id` varchar(191) NOT NULL,
  `source_bundle_id` varchar(255) DEFAULT NULL,
  `source_device_name` varchar(255) DEFAULT NULL,
  `source_device_manufacturer` varchar(255) DEFAULT NULL,
  `source_device_model` varchar(255) DEFAULT NULL,
  `source_device_hardware_version` varchar(255) DEFAULT NULL,
  `source_device_software_version` varchar(255) DEFAULT NULL,

  -- Workout classification. Keep the Apple raw activity code/name for lossless
  -- HealthKit round-tripping, and normalize into a cross-provider category for
  -- AI queries and reporting.
  `workout_type` varchar(64) NOT NULL,
  `workout_type_raw` varchar(128) DEFAULT NULL,
  `apple_workout_activity_type` int DEFAULT NULL,
  `fitbit_activity_id` int DEFAULT NULL,
  `fitbit_activity_name` varchar(255) DEFAULT NULL,

  -- Time window. HealthKit workouts are interval records; Fitbit activity logs
  -- can be represented the same way.
  `start_time` datetime(6) NOT NULL,
  `end_time` datetime(6) NOT NULL,
  `duration_seconds` int NOT NULL,
  `timezone_offset_minutes` smallint DEFAULT NULL,

  -- Summary metrics. Units are normalized for common analytics.
  `distance_meters` decimal(12,3) DEFAULT NULL,
  `active_energy_kcal` decimal(10,3) DEFAULT NULL,
  `basal_energy_kcal` decimal(10,3) DEFAULT NULL,
  `total_energy_kcal` decimal(10,3) DEFAULT NULL,
  `steps` int DEFAULT NULL,
  `flights_climbed` int DEFAULT NULL,
  `average_heart_rate_bpm` decimal(6,2) DEFAULT NULL,
  `max_heart_rate_bpm` smallint DEFAULT NULL,
  `min_heart_rate_bpm` smallint DEFAULT NULL,
  `average_speed_mps` decimal(8,3) DEFAULT NULL,
  `max_speed_mps` decimal(8,3) DEFAULT NULL,
  `average_cadence_spm` decimal(8,3) DEFAULT NULL,
  `elevation_gain_meters` decimal(10,3) DEFAULT NULL,

  -- Route availability and privacy boundary. Store route points in a separate
  -- table if needed; this table only records whether route data exists.
  `has_route` tinyint(1) NOT NULL DEFAULT 0,
  `route_source_workout_id` varchar(191) DEFAULT NULL,

  -- Sync bookkeeping. Anchors/cursors are provider-specific and should be kept
  -- opaque so Apple/Fitbit implementations can evolve independently.
  `sync_anchor` varchar(512) DEFAULT NULL,
  `sync_revision` varchar(191) DEFAULT NULL,
  `deleted_at_source` tinyint(1) NOT NULL DEFAULT 0,
  `first_synced_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `last_synced_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

  -- Lossless provider payloads for fields not yet normalized. Avoid storing
  -- raw route coordinates here unless the user explicitly consents.
  `source_metadata` json DEFAULT NULL,
  `raw_payload` json DEFAULT NULL,

  PRIMARY KEY (`workout_id`),
  UNIQUE KEY `uq_wearable_workouts_source` (`source_provider`, `source_workout_id`),
  KEY `idx_wearable_workouts_patient_start` (`patient_id`, `start_time`),
  KEY `idx_wearable_workouts_patient_type_start` (`patient_id`, `workout_type`, `start_time`),
  KEY `idx_wearable_workouts_patient_provider` (`patient_id`, `source_provider`),
  CONSTRAINT `wearable_workouts_ibfk_patient`
    FOREIGN KEY (`patient_id`) REFERENCES `patients_registration` (`patient_id`),
  CONSTRAINT `ck_wearable_workouts_time_order`
    CHECK (`end_time` >= `start_time`),
  CONSTRAINT `ck_wearable_workouts_duration`
    CHECK (`duration_seconds` >= 0),
  CONSTRAINT `ck_wearable_workouts_distance`
    CHECK (`distance_meters` IS NULL OR `distance_meters` >= 0),
  CONSTRAINT `ck_wearable_workouts_energy`
    CHECK (`active_energy_kcal` IS NULL OR `active_energy_kcal` >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE IF NOT EXISTS `wearable_workout_segments` (
  `segment_id` bigint NOT NULL AUTO_INCREMENT,
  `workout_id` bigint NOT NULL,
  `segment_type` enum('lap','split','interval','heart_rate_zone','fitbit_zone','other') NOT NULL,
  `segment_index` int NOT NULL DEFAULT 0,
  `start_time` datetime(6) DEFAULT NULL,
  `end_time` datetime(6) DEFAULT NULL,
  `duration_seconds` int DEFAULT NULL,
  `distance_meters` decimal(12,3) DEFAULT NULL,
  `active_energy_kcal` decimal(10,3) DEFAULT NULL,
  `average_heart_rate_bpm` decimal(6,2) DEFAULT NULL,
  `max_heart_rate_bpm` smallint DEFAULT NULL,
  `zone_name` varchar(64) DEFAULT NULL,
  `zone_min_bpm` smallint DEFAULT NULL,
  `zone_max_bpm` smallint DEFAULT NULL,
  `source_metadata` json DEFAULT NULL,

  PRIMARY KEY (`segment_id`),
  KEY `idx_workout_segments_workout` (`workout_id`, `segment_type`, `segment_index`),
  CONSTRAINT `wearable_workout_segments_ibfk_workout`
    FOREIGN KEY (`workout_id`) REFERENCES `wearable_workouts` (`workout_id`)
    ON DELETE CASCADE,
  CONSTRAINT `ck_workout_segments_time_order`
    CHECK (`end_time` IS NULL OR `start_time` IS NULL OR `end_time` >= `start_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
