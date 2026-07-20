class WearableSource {
  static const appleHealth = 'apple_health';
  static const fitbit = 'fitbit';
  static const googleHealth = 'google_health';
  static const manual = 'manual';
  static const simulation = 'simulation';
}

class WearableSample {
  final String patientId;
  final double? heartRate;
  final double? steps;
  final double? calories;
  final double? sleep;
  final DateTime timestamp;
  final DateTime? recordedOn;
  final String source;
  final Map<String, dynamic> sourceMetadata;

  const WearableSample({
    required this.patientId,
    this.heartRate,
    this.steps,
    this.calories,
    this.sleep,
    required this.timestamp,
    this.recordedOn,
    required this.source,
    this.sourceMetadata = const {},
  });

  List<String> get acceptedMetrics => [
    if (heartRate != null) 'heart_rate',
    if (steps != null) 'steps',
    if (calories != null) 'calories',
    if (sleep != null) 'sleep',
  ];

  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    if (heartRate != null) 'heart_rate': heartRate,
    if (steps != null) 'steps': steps,
    if (calories != null) 'calories': calories,
    if (sleep != null) 'sleep': sleep,
    'timestamp': timestamp.toIso8601String(),
    if (recordedOn != null) 'recorded_on': recordedOn!.toIso8601String(),
    'source': source,
    if (sourceMetadata.isNotEmpty) 'source_metadata': sourceMetadata,
  };
}

class WearableIngestionResult {
  final String status;
  final String patientId;
  final List<String> acceptedMetrics;
  final String source;
  final String timestamp;
  final String recordedOn;

  const WearableIngestionResult({
    required this.status,
    required this.patientId,
    required this.acceptedMetrics,
    required this.source,
    required this.timestamp,
    required this.recordedOn,
  });

  factory WearableIngestionResult.fromJson(Map<String, dynamic> json) {
    final rawMetrics = json['accepted_metrics'];
    return WearableIngestionResult(
      status: json['status']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      acceptedMetrics: rawMetrics is List
          ? rawMetrics.map((item) => item.toString()).toList()
          : const [],
      source: json['source']?.toString() ?? '',
      timestamp: json['timestamp']?.toString() ?? '',
      recordedOn: json['recorded_on']?.toString() ?? '',
    );
  }
}

class WearableWorkout {
  final String patientId;
  final String sourceProvider;
  final String sourceWorkoutId;
  final String? sourceBundleId;
  final String? sourceDeviceName;
  final String? sourceDeviceManufacturer;
  final String? sourceDeviceModel;
  final String? sourceDeviceHardwareVersion;
  final String? sourceDeviceSoftwareVersion;
  final String workoutType;
  final String? workoutTypeRaw;
  final int? appleWorkoutActivityType;
  final int? fitbitActivityId;
  final String? fitbitActivityName;
  final DateTime startTime;
  final DateTime endTime;
  final int durationSeconds;
  final int? timezoneOffsetMinutes;
  final double? distanceMeters;
  final double? activeEnergyKcal;
  final double? basalEnergyKcal;
  final double? totalEnergyKcal;
  final int? steps;
  final int? flightsClimbed;
  final double? averageHeartRateBpm;
  final int? maxHeartRateBpm;
  final int? minHeartRateBpm;
  final double? averageSpeedMps;
  final double? maxSpeedMps;
  final double? averageCadenceSpm;
  final double? elevationGainMeters;
  final bool hasRoute;
  final String? routeSourceWorkoutId;
  final String? syncAnchor;
  final String? syncRevision;
  final bool deletedAtSource;
  final Map<String, dynamic> sourceMetadata;
  final Map<String, dynamic> rawPayload;

  const WearableWorkout({
    required this.patientId,
    required this.sourceProvider,
    required this.sourceWorkoutId,
    this.sourceBundleId,
    this.sourceDeviceName,
    this.sourceDeviceManufacturer,
    this.sourceDeviceModel,
    this.sourceDeviceHardwareVersion,
    this.sourceDeviceSoftwareVersion,
    required this.workoutType,
    this.workoutTypeRaw,
    this.appleWorkoutActivityType,
    this.fitbitActivityId,
    this.fitbitActivityName,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
    this.timezoneOffsetMinutes,
    this.distanceMeters,
    this.activeEnergyKcal,
    this.basalEnergyKcal,
    this.totalEnergyKcal,
    this.steps,
    this.flightsClimbed,
    this.averageHeartRateBpm,
    this.maxHeartRateBpm,
    this.minHeartRateBpm,
    this.averageSpeedMps,
    this.maxSpeedMps,
    this.averageCadenceSpm,
    this.elevationGainMeters,
    this.hasRoute = false,
    this.routeSourceWorkoutId,
    this.syncAnchor,
    this.syncRevision,
    this.deletedAtSource = false,
    this.sourceMetadata = const {},
    this.rawPayload = const {},
  });

  Map<String, dynamic> toJson() => {
    'patient_id': patientId,
    'source_provider': sourceProvider,
    'source_workout_id': sourceWorkoutId,
    if (sourceBundleId != null) 'source_bundle_id': sourceBundleId,
    if (sourceDeviceName != null) 'source_device_name': sourceDeviceName,
    if (sourceDeviceManufacturer != null)
      'source_device_manufacturer': sourceDeviceManufacturer,
    if (sourceDeviceModel != null) 'source_device_model': sourceDeviceModel,
    if (sourceDeviceHardwareVersion != null)
      'source_device_hardware_version': sourceDeviceHardwareVersion,
    if (sourceDeviceSoftwareVersion != null)
      'source_device_software_version': sourceDeviceSoftwareVersion,
    'workout_type': workoutType,
    if (workoutTypeRaw != null) 'workout_type_raw': workoutTypeRaw,
    if (appleWorkoutActivityType != null)
      'apple_workout_activity_type': appleWorkoutActivityType,
    if (fitbitActivityId != null) 'fitbit_activity_id': fitbitActivityId,
    if (fitbitActivityName != null) 'fitbit_activity_name': fitbitActivityName,
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'duration_seconds': durationSeconds,
    if (timezoneOffsetMinutes != null)
      'timezone_offset_minutes': timezoneOffsetMinutes,
    if (distanceMeters != null) 'distance_meters': distanceMeters,
    if (activeEnergyKcal != null) 'active_energy_kcal': activeEnergyKcal,
    if (basalEnergyKcal != null) 'basal_energy_kcal': basalEnergyKcal,
    if (totalEnergyKcal != null) 'total_energy_kcal': totalEnergyKcal,
    if (steps != null) 'steps': steps,
    if (flightsClimbed != null) 'flights_climbed': flightsClimbed,
    if (averageHeartRateBpm != null)
      'average_heart_rate_bpm': averageHeartRateBpm,
    if (maxHeartRateBpm != null) 'max_heart_rate_bpm': maxHeartRateBpm,
    if (minHeartRateBpm != null) 'min_heart_rate_bpm': minHeartRateBpm,
    if (averageSpeedMps != null) 'average_speed_mps': averageSpeedMps,
    if (maxSpeedMps != null) 'max_speed_mps': maxSpeedMps,
    if (averageCadenceSpm != null) 'average_cadence_spm': averageCadenceSpm,
    if (elevationGainMeters != null)
      'elevation_gain_meters': elevationGainMeters,
    'has_route': hasRoute,
    if (routeSourceWorkoutId != null)
      'route_source_workout_id': routeSourceWorkoutId,
    if (syncAnchor != null) 'sync_anchor': syncAnchor,
    if (syncRevision != null) 'sync_revision': syncRevision,
    'deleted_at_source': deletedAtSource,
    if (sourceMetadata.isNotEmpty) 'source_metadata': sourceMetadata,
    if (rawPayload.isNotEmpty) 'raw_payload': rawPayload,
  };
}

class WearableWorkoutIngestionResult {
  final String status;
  final String patientId;
  final String sourceProvider;
  final String sourceWorkoutId;
  final String workoutType;
  final String startTime;
  final String endTime;
  final int durationSeconds;

  const WearableWorkoutIngestionResult({
    required this.status,
    required this.patientId,
    required this.sourceProvider,
    required this.sourceWorkoutId,
    required this.workoutType,
    required this.startTime,
    required this.endTime,
    required this.durationSeconds,
  });

  factory WearableWorkoutIngestionResult.fromJson(Map<String, dynamic> json) {
    return WearableWorkoutIngestionResult(
      status: json['status']?.toString() ?? '',
      patientId: json['patient_id']?.toString() ?? '',
      sourceProvider: json['source_provider']?.toString() ?? '',
      sourceWorkoutId: json['source_workout_id']?.toString() ?? '',
      workoutType: json['workout_type']?.toString() ?? '',
      startTime: json['start_time']?.toString() ?? '',
      endTime: json['end_time']?.toString() ?? '',
      durationSeconds: json['duration_seconds'] is num
          ? (json['duration_seconds'] as num).toInt()
          : 0,
    );
  }
}

class WearableWorkoutBatchIngestionResult {
  final String status;
  final int acceptedCount;
  final int ingestedCount;
  final List<WearableWorkoutIngestionResult> workouts;

  const WearableWorkoutBatchIngestionResult({
    required this.status,
    required this.acceptedCount,
    required this.ingestedCount,
    required this.workouts,
  });

  factory WearableWorkoutBatchIngestionResult.fromJson(
    Map<String, dynamic> json,
  ) {
    final rawWorkouts = json['workouts'];
    return WearableWorkoutBatchIngestionResult(
      status: json['status']?.toString() ?? '',
      acceptedCount: json['accepted_count'] is num
          ? (json['accepted_count'] as num).toInt()
          : 0,
      ingestedCount: json['ingested_count'] is num
          ? (json['ingested_count'] as num).toInt()
          : 0,
      workouts: rawWorkouts is List
          ? rawWorkouts
                .whereType<Map<String, dynamic>>()
                .map(WearableWorkoutIngestionResult.fromJson)
                .toList()
          : const [],
    );
  }
}

class WearableSyncResult {
  final bool success;
  final String source;
  final int uploadedCount;
  final String message;
  final List<WearableIngestionResult> ingestions;
  final List<WearableWorkoutIngestionResult> workoutIngestions;

  const WearableSyncResult({
    required this.success,
    required this.source,
    required this.uploadedCount,
    required this.message,
    this.ingestions = const [],
    this.workoutIngestions = const [],
  });

  factory WearableSyncResult.success({
    required String source,
    required List<WearableIngestionResult> ingestions,
    String? message,
  }) {
    return WearableSyncResult(
      success: true,
      source: source,
      uploadedCount: ingestions.length,
      message: message ?? 'Uploaded ${ingestions.length} wearable sample(s).',
      ingestions: ingestions,
    );
  }

  factory WearableSyncResult.workoutsSuccess({
    required String source,
    required List<WearableWorkoutIngestionResult> ingestions,
    String? message,
  }) {
    return WearableSyncResult(
      success: true,
      source: source,
      uploadedCount: ingestions.length,
      message: message ?? 'Uploaded ${ingestions.length} workout(s).',
      workoutIngestions: ingestions,
    );
  }

  factory WearableSyncResult.failure({
    required String source,
    required String message,
  }) {
    return WearableSyncResult(
      success: false,
      source: source,
      uploadedCount: 0,
      message: message,
    );
  }
}

class WearableSourceReadResult {
  final bool success;
  final WearableSample? sample;
  final String source;
  final String? message;

  const WearableSourceReadResult._({
    required this.success,
    required this.source,
    this.sample,
    this.message,
  });

  factory WearableSourceReadResult.success(WearableSample sample) {
    return WearableSourceReadResult._(
      success: true,
      source: sample.source,
      sample: sample,
    );
  }

  factory WearableSourceReadResult.failure({
    required String source,
    required String message,
  }) {
    return WearableSourceReadResult._(
      success: false,
      source: source,
      message: message,
    );
  }
}

class WearableWorkoutReadResult {
  final bool success;
  final List<WearableWorkout> workouts;
  final String source;
  final String? message;

  const WearableWorkoutReadResult._({
    required this.success,
    required this.source,
    this.workouts = const [],
    this.message,
  });

  factory WearableWorkoutReadResult.success({
    required String source,
    required List<WearableWorkout> workouts,
  }) {
    return WearableWorkoutReadResult._(
      success: true,
      source: source,
      workouts: workouts,
    );
  }

  factory WearableWorkoutReadResult.failure({
    required String source,
    required String message,
  }) {
    return WearableWorkoutReadResult._(
      success: false,
      source: source,
      message: message,
    );
  }
}
