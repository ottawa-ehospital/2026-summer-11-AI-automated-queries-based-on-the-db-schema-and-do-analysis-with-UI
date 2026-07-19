import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

import '../data/models/wearable_models.dart';
import '../data/repositories/ehospital_repository.dart';
import '../data/repositories/wearable_ingestion_repository.dart';

abstract class WearablePlatformSyncService {
  String get source;

  Future<WearableSourceReadResult> readLatestSample({
    required String patientId,
  });
}

abstract class WearablePlatformWorkoutSyncService {
  String get source;

  Future<WearableWorkoutReadResult> readRecentWorkouts({
    required String patientId,
  });
}

class WearableSyncService {
  final WearableIngestionClient _ingestionClient;
  final WearablePlatformSyncService _appleHealthSyncService;
  final WearablePlatformSyncService _googleHealthSyncService;
  final WearablePlatformWorkoutSyncService _appleWorkoutSyncService;
  final WearablePlatformWorkoutSyncService _googleWorkoutSyncService;

  WearableSyncService({
    WearableIngestionClient? ingestionClient,
    WearablePlatformSyncService? appleHealthSyncService,
    WearablePlatformSyncService? googleHealthSyncService,
    WearablePlatformWorkoutSyncService? appleWorkoutSyncService,
    WearablePlatformWorkoutSyncService? googleWorkoutSyncService,
  }) : _ingestionClient = ingestionClient ?? WearableIngestionRepository(),
       _appleHealthSyncService =
           appleHealthSyncService ?? AppleHealthSyncService(),
       _googleHealthSyncService =
           googleHealthSyncService ?? GoogleHealthSyncService(),
       _appleWorkoutSyncService =
           appleWorkoutSyncService ?? AppleHealthSyncService(),
       _googleWorkoutSyncService =
           googleWorkoutSyncService ?? GoogleHealthSyncService();

  Future<WearableSyncResult> uploadManual({
    required String patientId,
    required int heartRate,
    required int steps,
    required int calories,
    required int sleep,
    DateTime? timestamp,
  }) {
    return uploadSample(
      WearableSample(
        patientId: patientId,
        heartRate: heartRate.toDouble(),
        steps: steps.toDouble(),
        calories: calories.toDouble(),
        sleep: sleep.toDouble(),
        timestamp: timestamp ?? DateTime.now(),
        source: WearableSource.manual,
      ),
    );
  }

  Future<WearableSyncResult> uploadSimulationSample({
    required String patientId,
    required int heartRate,
    required int steps,
    required int calories,
    required int sleep,
    DateTime? timestamp,
  }) {
    return uploadSample(
      WearableSample(
        patientId: patientId,
        heartRate: heartRate.toDouble(),
        steps: steps.toDouble(),
        calories: calories.toDouble(),
        sleep: sleep.toDouble(),
        timestamp: timestamp ?? DateTime.now(),
        source: WearableSource.simulation,
      ),
    );
  }

  Future<WearableSyncResult> syncPlatformHealth({required String patientId}) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return syncFromAppleHealth(patientId: patientId);
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return syncFromGoogleHealth(patientId: patientId);
    }
    return Future.value(
      WearableSyncResult.failure(
        source: 'platform',
        message: 'Health sync is not available on this platform.',
      ),
    );
  }

  Future<WearableSyncResult> syncFromAppleHealth({required String patientId}) {
    return _syncFromPlatform(
      patientId: patientId,
      service: _appleHealthSyncService,
    );
  }

  Future<int> syncRecentStressFromAppleHealth({
    required String patientId,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return 0;
    return _uploadHourlyStressBuckets(health: Health(), patientId: patientId);
  }

  Future<WearableSyncResult> syncFromGoogleHealth({required String patientId}) {
    return _syncFromPlatform(
      patientId: patientId,
      service: _googleHealthSyncService,
    );
  }

  Future<WearableSyncResult> uploadSample(WearableSample sample) async {
    final ingestion = await _ingestionClient.ingest(sample);
    return WearableSyncResult.success(
      source: sample.source,
      ingestions: [ingestion],
    );
  }

  Future<WearableSyncResult> uploadWorkout(WearableWorkout workout) async {
    final ingestion = await _ingestionClient.ingestWorkout(workout);
    return WearableSyncResult.workoutsSuccess(
      source: workout.sourceProvider,
      ingestions: [ingestion],
    );
  }

  Future<WearableSyncResult> uploadWorkouts(
    List<WearableWorkout> workouts, {
    String? source,
  }) async {
    if (workouts.isEmpty) {
      return WearableSyncResult.failure(
        source: source ?? 'workout',
        message: 'No workout data available.',
      );
    }
    final ingestion = await _ingestionClient.ingestWorkoutBatch(workouts);
    return WearableSyncResult.workoutsSuccess(
      source: source ?? workouts.first.sourceProvider,
      ingestions: ingestion.workouts,
      message: 'Uploaded ${ingestion.acceptedCount} workout(s).',
    );
  }

  Future<WearableSyncResult> uploadSimulationWorkout({
    required String patientId,
    required String workoutType,
    required DateTime startTime,
    required DateTime endTime,
    double? distanceMeters,
    double? activeEnergyKcal,
    int? steps,
  }) {
    final duration = endTime.difference(startTime).inSeconds;
    return uploadWorkout(
      WearableWorkout(
        patientId: patientId,
        sourceProvider: WearableSource.simulation,
        sourceWorkoutId:
            'simulation-${patientId}-${startTime.toUtc().toIso8601String()}',
        workoutType: workoutType,
        workoutTypeRaw: workoutType,
        startTime: startTime,
        endTime: endTime,
        durationSeconds: duration < 0 ? 0 : duration,
        distanceMeters: distanceMeters,
        activeEnergyKcal: activeEnergyKcal,
        totalEnergyKcal: activeEnergyKcal,
        steps: steps,
        sourceMetadata: const {'source': 'fixture'},
      ),
    );
  }

  Future<WearableSyncResult> syncPlatformWorkouts({required String patientId}) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return syncWorkoutsFromAppleHealth(patientId: patientId);
    }
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return syncWorkoutsFromGoogleHealth(patientId: patientId);
    }
    return Future.value(
      WearableSyncResult.failure(
        source: 'platform',
        message: 'Workout sync is not available on this platform.',
      ),
    );
  }

  Future<WearableSyncResult> syncWorkoutsFromAppleHealth({
    required String patientId,
  }) {
    return _syncWorkoutsFromPlatform(
      patientId: patientId,
      service: _appleWorkoutSyncService,
    );
  }

  Future<WearableSyncResult> syncWorkoutsFromGoogleHealth({
    required String patientId,
  }) {
    return _syncWorkoutsFromPlatform(
      patientId: patientId,
      service: _googleWorkoutSyncService,
    );
  }

  Future<WearableSyncResult> _syncFromPlatform({
    required String patientId,
    required WearablePlatformSyncService service,
  }) async {
    final read = await service.readLatestSample(patientId: patientId);
    if (!read.success || read.sample == null) {
      return WearableSyncResult.failure(
        source: read.source,
        message: read.message ?? 'No wearable data available.',
      );
    }
    return uploadSample(read.sample!);
  }

  Future<WearableSyncResult> _syncWorkoutsFromPlatform({
    required String patientId,
    required WearablePlatformWorkoutSyncService service,
  }) async {
    final read = await service.readRecentWorkouts(patientId: patientId);
    if (!read.success || read.workouts.isEmpty) {
      return WearableSyncResult.failure(
        source: read.source,
        message: read.message ?? 'No workout data available.',
      );
    }
    return uploadWorkouts(read.workouts, source: read.source);
  }
}

class AppleHealthSyncService
    implements WearablePlatformSyncService, WearablePlatformWorkoutSyncService {
  final Health _health;

  AppleHealthSyncService({Health? health}) : _health = health ?? Health();

  @override
  String get source => WearableSource.appleHealth;

  @override
  Future<WearableSourceReadResult> readLatestSample({
    required String patientId,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return WearableSourceReadResult.failure(
        source: source,
        message: 'Apple Health is only available on iOS devices.',
      );
    }
    return _readHealthSample(
      health: _health,
      patientId: patientId,
      source: source,
      unavailableMessage: 'No Apple Health data found in the last 24 hours.',
    );
  }

  @override
  Future<WearableWorkoutReadResult> readRecentWorkouts({
    required String patientId,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return WearableWorkoutReadResult.failure(
        source: source,
        message: 'Apple Health workout sync is only available on iOS devices.',
      );
    }
    return _readHealthWorkouts(
      health: _health,
      patientId: patientId,
      source: source,
      unavailableMessage: 'No Apple Health workouts found in the last 90 days.',
    );
  }
}

class GoogleHealthSyncService
    implements WearablePlatformSyncService, WearablePlatformWorkoutSyncService {
  final Health _health;

  GoogleHealthSyncService({Health? health}) : _health = health ?? Health();

  @override
  String get source => WearableSource.googleHealth;

  @override
  Future<WearableSourceReadResult> readLatestSample({
    required String patientId,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return WearableSourceReadResult.failure(
        source: source,
        message: 'Google Health sync is only available on Android devices.',
      );
    }
    return _readHealthSample(
      health: _health,
      patientId: patientId,
      source: source,
      unavailableMessage:
          'No Google Health / Health Connect data found in the last 24 hours.',
    );
  }

  @override
  Future<WearableWorkoutReadResult> readRecentWorkouts({
    required String patientId,
  }) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return WearableWorkoutReadResult.failure(
        source: source,
        message:
            'Google Health workout sync is only available on Android devices.',
      );
    }
    return _readHealthWorkouts(
      health: _health,
      patientId: patientId,
      source: source,
      unavailableMessage:
          'No Google Health / Health Connect workouts found in the last 90 days.',
    );
  }
}

Future<WearableSourceReadResult> _readHealthSample({
  required Health health,
  required String patientId,
  required String source,
  required String unavailableMessage,
}) async {
  await health.configure();

  const types = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.SLEEP_ASLEEP,
  ];
  final permissions = types.map((_) => HealthDataAccess.READ).toList();
  final granted = await health.requestAuthorization(
    types,
    permissions: permissions,
  );
  if (!granted) {
    return WearableSourceReadResult.failure(
      source: source,
      message: 'Health permission was denied.',
    );
  }

  final now = DateTime.now();
  final since = now.subtract(const Duration(hours: 24));
  final dataPoints = await health.getHealthDataFromTypes(
    startTime: since,
    endTime: now,
    types: types,
  );
  final unique = health.removeDuplicates(dataPoints);

  int steps = 0;
  double totalHeartRate = 0;
  int heartRateCount = 0;
  double calories = 0;
  double sleepMinutes = 0;

  for (final point in unique) {
    final value = point.value;
    if (value is! NumericHealthValue) continue;
    switch (point.type) {
      case HealthDataType.STEPS:
        steps += value.numericValue.round();
        break;
      case HealthDataType.HEART_RATE:
        totalHeartRate += value.numericValue;
        heartRateCount++;
        break;
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        calories += value.numericValue;
        break;
      case HealthDataType.SLEEP_ASLEEP:
        sleepMinutes += value.numericValue;
        break;
      default:
        break;
    }
  }

  final averageHeartRate = heartRateCount > 0
      ? (totalHeartRate / heartRateCount).round()
      : 0;
  final sleepHours = sleepMinutes / 60;
  if (steps == 0 && averageHeartRate == 0 && calories == 0 && sleepHours == 0) {
    return WearableSourceReadResult.failure(
      source: source,
      message: unavailableMessage,
    );
  }

  return WearableSourceReadResult.success(
    WearableSample(
      patientId: patientId,
      heartRate: averageHeartRate > 0 ? averageHeartRate.toDouble() : null,
      steps: steps > 0 ? steps.toDouble() : null,
      calories: calories > 0 ? calories.roundToDouble() : null,
      sleep: sleepHours > 0
          ? double.parse(sleepHours.toStringAsFixed(2))
          : null,
      timestamp: now,
      source: source,
    ),
  );
}

class _StressBucket {
  final DateTime hour;
  final List<double> hrvSdnn = [];
  final List<double> restingHeartRate = [];
  final List<double> respiratoryRate = [];
  final List<double> heartRate = [];

  _StressBucket(this.hour);

  double? avg(List<double> values) {
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a + b) / values.length;
  }
}

Future<int> _uploadHourlyStressBuckets({
  required Health health,
  required String patientId,
}) async {
  await health.configure();
  const types = [
    HealthDataType.HEART_RATE_VARIABILITY_SDNN,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.RESPIRATORY_RATE,
    HealthDataType.HEART_RATE,
  ];
  final permissions = types.map((_) => HealthDataAccess.READ).toList();
  final granted = await health.requestAuthorization(
    types,
    permissions: permissions,
  );
  if (!granted) return 0;

  final now = DateTime.now();
  final since = now.subtract(const Duration(hours: 24));
  final points = health.removeDuplicates(
    await health.getHealthDataFromTypes(
      startTime: since,
      endTime: now,
      types: types,
    ),
  );
  final buckets = <DateTime, _StressBucket>{};
  for (final point in points) {
    final value = point.value;
    if (value is! NumericHealthValue) continue;
    final local = point.dateFrom.toLocal();
    final hour = DateTime(local.year, local.month, local.day, local.hour);
    final bucket = buckets.putIfAbsent(hour, () => _StressBucket(hour));
    switch (point.type) {
      case HealthDataType.HEART_RATE_VARIABILITY_SDNN:
        bucket.hrvSdnn.add(value.numericValue.toDouble());
        break;
      case HealthDataType.RESTING_HEART_RATE:
        bucket.restingHeartRate.add(value.numericValue.toDouble());
        break;
      case HealthDataType.RESPIRATORY_RATE:
        bucket.respiratoryRate.add(value.numericValue.toDouble());
        break;
      case HealthDataType.HEART_RATE:
        bucket.heartRate.add(value.numericValue.toDouble());
        break;
      default:
        break;
    }
  }

  var uploaded = 0;
  final repo = EHospitalRepository();
  final sorted = buckets.values.toList()
    ..sort((a, b) => a.hour.compareTo(b.hour));
  for (final bucket in sorted) {
    final hrv = bucket.avg(bucket.hrvSdnn);
    final resting = bucket.avg(bucket.restingHeartRate);
    final respiratory = bucket.avg(bucket.respiratoryRate);
    if (hrv == null && resting == null && respiratory == null) continue;
    await repo.sendStressSnapshot(
      patientId: patientId,
      hrvSdnn: hrv,
      restingHeartRate: resting,
      respiratoryRate: respiratory,
      heartRate: bucket.avg(bucket.heartRate),
      timestamp: bucket.hour.toUtc().toIso8601String(),
    );
    uploaded++;
  }
  return uploaded;
}

Future<WearableWorkoutReadResult> _readHealthWorkouts({
  required Health health,
  required String patientId,
  required String source,
  required String unavailableMessage,
}) async {
  await health.configure();

  const types = [HealthDataType.WORKOUT];
  const permissions = [HealthDataAccess.READ];
  final granted = await health.requestAuthorization(
    types,
    permissions: permissions,
  );
  if (!granted) {
    return WearableWorkoutReadResult.failure(
      source: source,
      message: 'Health workout permission was denied.',
    );
  }

  final now = DateTime.now();
  final since = now.subtract(const Duration(days: 90));
  final dataPoints = await health.getHealthDataFromTypes(
    startTime: since,
    endTime: now,
    types: types,
  );
  final unique = health.removeDuplicates(dataPoints);
  final workouts = unique
      .where((point) => point.type == HealthDataType.WORKOUT)
      .map((point) => _workoutFromHealthPoint(point, patientId, source))
      .whereType<WearableWorkout>()
      .toList();

  if (workouts.isEmpty) {
    return WearableWorkoutReadResult.failure(
      source: source,
      message: unavailableMessage,
    );
  }

  return WearableWorkoutReadResult.success(source: source, workouts: workouts);
}

WearableWorkout? _workoutFromHealthPoint(
  HealthDataPoint point,
  String patientId,
  String source,
) {
  final value = point.value;
  if (value is! WorkoutHealthValue) return null;
  final duration = point.dateTo.difference(point.dateFrom).inSeconds;
  final rawType = value.workoutActivityType.name;
  final metadata = <String, dynamic>{
    'source_platform': point.sourcePlatform.name,
    'source_id': point.sourceId,
    'source_name': point.sourceName,
    'source_device_id': point.sourceDeviceId,
    'recording_method': point.recordingMethod.name,
    if (value.totalEnergyBurnedUnit != null)
      'total_energy_burned_unit': value.totalEnergyBurnedUnit!.name,
    if (value.totalDistanceUnit != null)
      'total_distance_unit': value.totalDistanceUnit!.name,
    if (value.totalStepsUnit != null)
      'total_steps_unit': value.totalStepsUnit!.name,
    if (point.metadata != null) 'metadata': point.metadata,
  };
  return WearableWorkout(
    patientId: patientId,
    sourceProvider: source,
    sourceWorkoutId: point.uuid,
    sourceBundleId: point.sourceId,
    sourceDeviceName: point.sourceName,
    sourceDeviceModel: point.deviceModel,
    workoutType: _normalizeWorkoutType(rawType),
    workoutTypeRaw: rawType,
    startTime: point.dateFrom,
    endTime: point.dateTo,
    durationSeconds: duration < 0 ? 0 : duration,
    distanceMeters: _distanceMeters(
      value.totalDistance,
      value.totalDistanceUnit,
    ),
    activeEnergyKcal: _energyKcal(
      value.totalEnergyBurned,
      value.totalEnergyBurnedUnit,
    ),
    totalEnergyKcal: _energyKcal(
      value.totalEnergyBurned,
      value.totalEnergyBurnedUnit,
    ),
    steps: value.totalSteps,
    sourceMetadata: metadata,
    rawPayload: point.toJson(),
  );
}

double? _distanceMeters(int? value, HealthDataUnit? unit) {
  if (value == null) return null;
  switch (unit) {
    case HealthDataUnit.METER:
    case null:
      return value.toDouble();
    case HealthDataUnit.CENTIMETER:
      return value / 100;
    default:
      return value.toDouble();
  }
}

double? _energyKcal(int? value, HealthDataUnit? unit) {
  if (value == null) return null;
  return value.toDouble();
}

String _normalizeWorkoutType(String rawType) {
  switch (rawType) {
    case 'RUNNING':
    case 'RUNNING_TREADMILL':
      return 'running';
    case 'BIKING':
    case 'BIKING_STATIONARY':
      return 'cycling';
    case 'WALKING':
    case 'WALKING_TREADMILL':
      return 'walking';
    case 'SWIMMING':
    case 'SWIMMING_OPEN_WATER':
    case 'SWIMMING_POOL':
      return 'swimming';
    default:
      return rawType.toLowerCase();
  }
}
