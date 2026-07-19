import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_app/data/models/wearable_models.dart';
import 'package:smart_health_app/data/repositories/ehospital_repository.dart';
import 'package:smart_health_app/data/repositories/wearable_ingestion_repository.dart';
import 'package:smart_health_app/features/goals/data/training_records_repository.dart';
import 'package:smart_health_app/features/goals/models/training_record.dart';
import 'package:smart_health_app/features/goals/screens/health_goals_screen.dart';
import 'package:smart_health_app/l10n/generated/app_localizations.dart';
import 'package:smart_health_app/services/wearable_sync_service.dart';
import 'package:smart_health_app/ui/app_theme.dart';

void main() {
  testWidgets('Health Goals shows records on a separate tab', (tester) async {
    SharedPreferences.setMockInitialValues({'patient_id': 20});
    final trainingRepository = _FakeTrainingRecordsRepository([
      [_record('HK-1', workoutType: 'running')],
    ]);

    await _pumpScreen(tester, trainingRepository: trainingRepository);

    expect(find.text('Daily Steps'), findsOneWidget);
    expect(find.text('Running'), findsNothing);

    await tester.tap(find.text('Training Records'));
    await tester.pumpAndSettle();

    expect(find.text('Daily Steps'), findsNothing);
    expect(find.text('Running'), findsOneWidget);
    expect(find.textContaining('Source: Apple Health'), findsOneWidget);
  });

  testWidgets('Training Records tab shows empty and error states', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'patient_id': 20});
    final trainingRepository = _FakeTrainingRecordsRepository([
      <TrainingRecord>[],
      Exception('offline'),
    ]);

    await _pumpScreen(tester, trainingRepository: trainingRepository);
    await tester.tap(find.text('Training Records'));
    await tester.pumpAndSettle();

    expect(find.text('No synced training records available.'), findsOneWidget);

    await tester.tap(find.byTooltip('Refresh training records'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Could not load training records.'),
      findsOneWidget,
    );
  });

  testWidgets('Training Records refresh shows loading then new rows', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'patient_id': 20});
    final refreshCompleter = Completer<List<TrainingRecord>>();
    final trainingRepository = _FakeTrainingRecordsRepository([
      <TrainingRecord>[],
      refreshCompleter.future,
    ]);

    await _pumpScreen(tester, trainingRepository: trainingRepository);
    await tester.tap(find.text('Training Records'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Refresh training records'));
    await tester.pump();

    expect(find.text('Loading training records...'), findsOneWidget);

    refreshCompleter.complete([_record('HK-2', workoutType: 'cycling')]);
    await tester.pumpAndSettle();

    expect(find.text('Cycling'), findsOneWidget);
  });

  testWidgets('Training Records sync failure is shown without hiding refresh', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'patient_id': 20});
    final trainingRepository = _FakeTrainingRecordsRepository([
      <TrainingRecord>[],
    ]);
    final syncService = _FakeWearableSyncService(
      WearableSyncResult.failure(
        source: 'platform',
        message: 'Workout sync is not available on this platform.',
      ),
    );

    await _pumpScreen(
      tester,
      trainingRepository: trainingRepository,
      wearableSyncService: syncService,
    );
    await tester.tap(find.text('Training Records'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Sync platform workouts'));
    await tester.pumpAndSettle();

    expect(
      find.text('Workout sync is not available on this platform.'),
      findsOneWidget,
    );
    expect(find.byTooltip('Refresh training records'), findsOneWidget);
  });
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required _FakeTrainingRecordsRepository trainingRepository,
  WearableSyncService? wearableSyncService,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: buildAppTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: HealthGoalsScreen(
          ehospitalRepository: _FakeEHospitalRepository(),
          trainingRecordsRepository: trainingRepository,
          wearableSyncService: wearableSyncService,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

TrainingRecord _record(String sourceWorkoutId, {required String workoutType}) {
  return TrainingRecord(
    patientId: '20',
    sourceProvider: 'apple_health',
    sourceWorkoutId: sourceWorkoutId,
    workoutType: workoutType,
    startTime: DateTime.parse('2026-07-12T10:00:00Z'),
    endTime: DateTime.parse('2026-07-12T10:45:00Z'),
    durationSeconds: 2700,
    distanceMeters: 8000,
    activeEnergyKcal: 520,
    steps: 9000,
  );
}

class _FakeEHospitalRepository extends EHospitalRepository {
  @override
  Future<List<dynamic>> fetchTable(String table, {String? patientId}) async {
    if (table == 'wearable_vitals') {
      return [
        {
          'patient_id': patientId,
          'timestamp': '2026-07-12T10:00:00Z',
          'steps': 5000,
          'sleep': 7.5,
          'calories': 300,
        },
      ];
    }
    return const [];
  }
}

class _FakeTrainingRecordsRepository extends TrainingRecordsRepository {
  _FakeTrainingRecordsRepository(this.responses);

  final List<Object> responses;
  int calls = 0;

  @override
  Future<List<TrainingRecord>> fetchTrainingRecords({
    required String patientId,
    int limit = 30,
  }) async {
    final index = calls < responses.length ? calls : responses.length - 1;
    calls += 1;
    final response = responses[index];
    if (response is Future<List<TrainingRecord>>) return response;
    if (response is Exception) throw response;
    return response as List<TrainingRecord>;
  }
}

class _FakeWearableSyncService extends WearableSyncService {
  _FakeWearableSyncService(this.result)
    : super(ingestionClient: _FakeIngestionClient());

  final WearableSyncResult result;

  @override
  Future<WearableSyncResult> syncPlatformWorkouts({
    required String patientId,
  }) async {
    return result;
  }
}

class _FakeIngestionClient implements WearableIngestionClient {
  @override
  Future<WearableIngestionResult> ingest(WearableSample sample) async {
    throw UnimplementedError();
  }

  @override
  Future<WearableWorkoutIngestionResult> ingestWorkout(
    WearableWorkout workout,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<WearableWorkoutBatchIngestionResult> ingestWorkoutBatch(
    List<WearableWorkout> workouts,
  ) async {
    throw UnimplementedError();
  }
}
