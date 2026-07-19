import 'package:flutter_test/flutter_test.dart';
import 'package:smart_health_app/data/models/wearable_models.dart';
import 'package:smart_health_app/data/repositories/ehospital_repository.dart';
import 'package:smart_health_app/data/repositories/wearable_ingestion_repository.dart';
import 'package:smart_health_app/services/wearable_sync_service.dart';

void main() {
  test('manual upload routes through backend ingestion client', () async {
    final ingestion = _FakeIngestionClient();
    final service = WearableSyncService(ingestionClient: ingestion);

    final result = await service.uploadManual(
      patientId: '20',
      heartRate: 80,
      steps: 6000,
      calories: 300,
      sleep: 7,
    );

    expect(result.success, isTrue);
    expect(result.source, WearableSource.manual);
    expect(ingestion.samples.single.source, WearableSource.manual);
    expect(ingestion.samples.single.patientId, '20');
  });

  test('simulation upload routes through backend ingestion client', () async {
    final ingestion = _FakeIngestionClient();
    final service = WearableSyncService(ingestionClient: ingestion);

    final result = await service.uploadSimulationSample(
      patientId: '20',
      heartRate: 72,
      steps: 5000,
      calories: 250,
      sleep: 6,
    );

    expect(result.success, isTrue);
    expect(result.source, WearableSource.simulation);
    expect(ingestion.samples.single.source, WearableSource.simulation);
  });

  test(
    'Apple platform sync reads from AppleHealthSyncService then ingests',
    () async {
      final ingestion = _FakeIngestionClient();
      final apple = _FakePlatformSyncService(
        source: WearableSource.appleHealth,
        sample: WearableSample(
          patientId: '20',
          heartRate: 78,
          timestamp: DateTime.parse('2026-06-20T10:30:00Z'),
          source: WearableSource.appleHealth,
        ),
      );
      final service = WearableSyncService(
        ingestionClient: ingestion,
        appleHealthSyncService: apple,
      );

      final result = await service.syncFromAppleHealth(patientId: '20');

      expect(result.success, isTrue);
      expect(apple.readCount, 1);
      expect(ingestion.samples.single.source, WearableSource.appleHealth);
    },
  );

  test(
    'Google platform sync reads from GoogleHealthSyncService then ingests',
    () async {
      final ingestion = _FakeIngestionClient();
      final google = _FakePlatformSyncService(
        source: WearableSource.googleHealth,
        sample: WearableSample(
          patientId: '20',
          steps: 4000,
          timestamp: DateTime.parse('2026-06-20T10:30:00Z'),
          source: WearableSource.googleHealth,
        ),
      );
      final service = WearableSyncService(
        ingestionClient: ingestion,
        googleHealthSyncService: google,
      );

      final result = await service.syncFromGoogleHealth(patientId: '20');

      expect(result.success, isTrue);
      expect(google.readCount, 1);
      expect(ingestion.samples.single.source, WearableSource.googleHealth);
    },
  );

  test('platform source failure does not call backend ingestion', () async {
    final ingestion = _FakeIngestionClient();
    final apple = _FakePlatformSyncService.failure(
      source: WearableSource.appleHealth,
      message: 'permission denied',
    );
    final service = WearableSyncService(
      ingestionClient: ingestion,
      appleHealthSyncService: apple,
    );

    final result = await service.syncFromAppleHealth(patientId: '20');

    expect(result.success, isFalse);
    expect(result.message, 'permission denied');
    expect(ingestion.samples, isEmpty);
  });

  test(
    'fixture workout upload routes through backend ingestion client',
    () async {
      final ingestion = _FakeIngestionClient();
      final service = WearableSyncService(ingestionClient: ingestion);

      final result = await service.uploadWorkout(_testWorkout());

      expect(result.success, isTrue);
      expect(result.source, WearableSource.appleHealth);
      expect(result.uploadedCount, 1);
      expect(ingestion.workouts.single.sourceWorkoutId, 'HK-1');
    },
  );

  test(
    'simulation workout helper creates uploadable fixture workout',
    () async {
      final ingestion = _FakeIngestionClient();
      final service = WearableSyncService(ingestionClient: ingestion);

      final result = await service.uploadSimulationWorkout(
        patientId: '20',
        workoutType: 'running',
        startTime: DateTime.parse('2026-06-20T10:00:00Z'),
        endTime: DateTime.parse('2026-06-20T10:45:00Z'),
        distanceMeters: 8000,
        activeEnergyKcal: 520,
        steps: 9000,
      );

      expect(result.success, isTrue);
      final workout = ingestion.workouts.single;
      expect(workout.sourceProvider, WearableSource.simulation);
      expect(workout.sourceWorkoutId, contains('simulation-20-'));
      expect(workout.durationSeconds, 2700);
      expect(workout.distanceMeters, 8000);
      expect(workout.activeEnergyKcal, 520);
      expect(workout.sourceMetadata['source'], 'fixture');
    },
  );

  test(
    'batch workout upload routes through backend ingestion client',
    () async {
      final ingestion = _FakeIngestionClient();
      final service = WearableSyncService(ingestionClient: ingestion);

      final result = await service.uploadWorkouts([
        _testWorkout(),
        _testWorkout(sourceWorkoutId: 'HK-2'),
      ]);

      expect(result.success, isTrue);
      expect(result.uploadedCount, 2);
      expect(ingestion.workoutBatches.single.length, 2);
    },
  );

  test(
    'Apple workout sync reads platform workouts then ingests batch',
    () async {
      final ingestion = _FakeIngestionClient();
      final appleWorkouts = _FakeWorkoutSyncService(
        source: WearableSource.appleHealth,
        workouts: [_testWorkout()],
      );
      final service = WearableSyncService(
        ingestionClient: ingestion,
        appleWorkoutSyncService: appleWorkouts,
      );

      final result = await service.syncWorkoutsFromAppleHealth(patientId: '20');

      expect(result.success, isTrue);
      expect(appleWorkouts.readCount, 1);
      expect(ingestion.workoutBatches.single.single.sourceWorkoutId, 'HK-1');
    },
  );

  test(
    'workout platform source failure does not call backend ingestion',
    () async {
      final ingestion = _FakeIngestionClient();
      final appleWorkouts = _FakeWorkoutSyncService.failure(
        source: WearableSource.appleHealth,
        message: 'workout permission denied',
      );
      final service = WearableSyncService(
        ingestionClient: ingestion,
        appleWorkoutSyncService: appleWorkouts,
      );

      final result = await service.syncWorkoutsFromAppleHealth(patientId: '20');

      expect(result.success, isFalse);
      expect(result.message, 'workout permission denied');
      expect(ingestion.workoutBatches, isEmpty);
      expect(ingestion.workouts, isEmpty);
    },
  );

  test(
    'legacy eHospital wearable upload delegates to ingestion client',
    () async {
      final ingestion = _FakeIngestionClient();
      final repository = EHospitalRepository(
        wearableIngestionClient: ingestion,
      );

      await repository.sendWearableVitals(
        patientId: '20',
        heartRate: 72,
        steps: 4500,
        calories: 220,
        sleep: 7,
      );

      expect(ingestion.samples.single.patientId, '20');
      expect(ingestion.samples.single.source, WearableSource.manual);
    },
  );
}

class _FakeIngestionClient implements WearableIngestionClient {
  final samples = <WearableSample>[];
  final workouts = <WearableWorkout>[];
  final workoutBatches = <List<WearableWorkout>>[];

  @override
  Future<WearableIngestionResult> ingest(WearableSample sample) async {
    samples.add(sample);
    return WearableIngestionResult(
      status: 'ingested',
      patientId: sample.patientId,
      acceptedMetrics: sample.acceptedMetrics,
      source: sample.source,
      timestamp: sample.timestamp.toIso8601String(),
      recordedOn: (sample.recordedOn ?? sample.timestamp).toIso8601String(),
    );
  }

  @override
  Future<WearableWorkoutIngestionResult> ingestWorkout(
    WearableWorkout workout,
  ) async {
    workouts.add(workout);
    return _workoutIngestionResult(workout);
  }

  @override
  Future<WearableWorkoutBatchIngestionResult> ingestWorkoutBatch(
    List<WearableWorkout> workouts,
  ) async {
    workoutBatches.add(workouts);
    return WearableWorkoutBatchIngestionResult(
      status: 'ingested',
      acceptedCount: workouts.length,
      ingestedCount: workouts.length,
      workouts: workouts.map(_workoutIngestionResult).toList(),
    );
  }
}

class _FakePlatformSyncService implements WearablePlatformSyncService {
  _FakePlatformSyncService({
    required this.source,
    required WearableSample sample,
  }) : _sample = sample,
       _message = null;

  _FakePlatformSyncService.failure({
    required this.source,
    required String message,
  }) : _sample = null,
       _message = message;

  @override
  final String source;

  final WearableSample? _sample;
  final String? _message;
  int readCount = 0;

  @override
  Future<WearableSourceReadResult> readLatestSample({
    required String patientId,
  }) async {
    readCount++;
    final sample = _sample;
    if (sample == null) {
      return WearableSourceReadResult.failure(
        source: source,
        message: _message ?? 'unavailable',
      );
    }
    return WearableSourceReadResult.success(sample);
  }
}

class _FakeWorkoutSyncService implements WearablePlatformWorkoutSyncService {
  _FakeWorkoutSyncService({
    required this.source,
    required List<WearableWorkout> workouts,
  }) : _workouts = workouts,
       _message = null;

  _FakeWorkoutSyncService.failure({
    required this.source,
    required String message,
  }) : _workouts = const [],
       _message = message;

  @override
  final String source;

  final List<WearableWorkout> _workouts;
  final String? _message;
  int readCount = 0;

  @override
  Future<WearableWorkoutReadResult> readRecentWorkouts({
    required String patientId,
  }) async {
    readCount++;
    final message = _message;
    if (message != null) {
      return WearableWorkoutReadResult.failure(
        source: source,
        message: message,
      );
    }
    return WearableWorkoutReadResult.success(
      source: source,
      workouts: _workouts,
    );
  }
}

WearableWorkout _testWorkout({String sourceWorkoutId = 'HK-1'}) {
  return WearableWorkout(
    patientId: '20',
    sourceProvider: WearableSource.appleHealth,
    sourceWorkoutId: sourceWorkoutId,
    workoutType: 'running',
    startTime: DateTime.parse('2026-06-20T10:00:00Z'),
    endTime: DateTime.parse('2026-06-20T10:30:00Z'),
    durationSeconds: 1800,
    distanceMeters: 5000,
  );
}

WearableWorkoutIngestionResult _workoutIngestionResult(
  WearableWorkout workout,
) {
  return WearableWorkoutIngestionResult(
    status: 'ingested',
    patientId: workout.patientId,
    sourceProvider: workout.sourceProvider,
    sourceWorkoutId: workout.sourceWorkoutId,
    workoutType: workout.workoutType,
    startTime: workout.startTime.toIso8601String(),
    endTime: workout.endTime.toIso8601String(),
    durationSeconds: workout.durationSeconds,
  );
}
