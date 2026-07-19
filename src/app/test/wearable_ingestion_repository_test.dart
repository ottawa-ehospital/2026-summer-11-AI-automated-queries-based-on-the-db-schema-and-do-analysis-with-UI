import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_health_app/core/network/api_client.dart';
import 'package:smart_health_app/core/network/api_exception.dart';
import 'package:smart_health_app/data/models/wearable_models.dart';
import 'package:smart_health_app/data/repositories/wearable_ingestion_repository.dart';

void main() {
  test('WearableWorkout serializes Apple-style workout payload', () {
    final workout = WearableWorkout(
      patientId: '20',
      sourceProvider: WearableSource.appleHealth,
      sourceWorkoutId: 'HK-1',
      sourceBundleId: 'com.apple.Health',
      sourceDeviceName: 'Apple Watch',
      workoutType: 'running',
      workoutTypeRaw: 'RUNNING',
      appleWorkoutActivityType: 37,
      startTime: DateTime.parse('2026-06-20T10:00:00Z'),
      endTime: DateTime.parse('2026-06-20T10:30:00Z'),
      durationSeconds: 1800,
      distanceMeters: 5000,
      activeEnergyKcal: 320,
      averageHeartRateBpm: 142,
      sourceMetadata: const {'recording_method': 'automatic'},
      rawPayload: const {'uuid': 'HK-1'},
    );

    final json = workout.toJson();

    expect(json['patient_id'], '20');
    expect(json['source_provider'], 'apple_health');
    expect(json['source_workout_id'], 'HK-1');
    expect(json['source_bundle_id'], 'com.apple.Health');
    expect(json['workout_type'], 'running');
    expect(json['workout_type_raw'], 'RUNNING');
    expect(json['apple_workout_activity_type'], 37);
    expect(json['duration_seconds'], 1800);
    expect(json['distance_meters'], 5000);
    expect(json['active_energy_kcal'], 320);
    expect(json['average_heart_rate_bpm'], 142);
    expect(json['source_metadata'], {'recording_method': 'automatic'});
    expect(json['raw_payload'], {'uuid': 'HK-1'});
  });

  test('WearableWorkout serializes Fitbit-compatible workout payload', () {
    final workout = WearableWorkout(
      patientId: '20',
      sourceProvider: WearableSource.fitbit,
      sourceWorkoutId: 'fitbit-activity-1',
      workoutType: 'cycling',
      fitbitActivityId: 90013,
      fitbitActivityName: 'Outdoor Bike',
      startTime: DateTime.parse('2026-06-20T10:00:00Z'),
      endTime: DateTime.parse('2026-06-20T11:00:00Z'),
      durationSeconds: 3600,
      distanceMeters: 22000,
      totalEnergyKcal: 650,
    );

    final json = workout.toJson();

    expect(json['source_provider'], 'fitbit');
    expect(json['source_workout_id'], 'fitbit-activity-1');
    expect(json['fitbit_activity_id'], 90013);
    expect(json['fitbit_activity_name'], 'Outdoor Bike');
    expect(json['workout_type'], 'cycling');
    expect(json['distance_meters'], 22000);
    expect(json['total_energy_kcal'], 650);
  });

  test('ingest posts wearable sample to backend ingestion endpoint', () async {
    late http.Request captured;
    final repository = WearableIngestionRepository(
      client: ApiClient(
        baseUrl: 'https://backend.test',
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'status': 'ingested',
              'patient_id': '20',
              'accepted_metrics': ['heart_rate', 'steps'],
              'source': 'google_health',
              'timestamp': '2026-06-20T10:30:00+00:00',
              'recorded_on': '2026-06-20T10:30:00+00:00',
            }),
            200,
          );
        }),
      ),
    );

    final result = await repository.ingest(
      WearableSample(
        patientId: '20',
        heartRate: 82,
        steps: 6400,
        timestamp: DateTime.parse('2026-06-20T10:30:00Z'),
        source: WearableSource.googleHealth,
      ),
    );

    expect(captured.url.path, '/wearables/ingest');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['patient_id'], '20');
    expect(body['heart_rate'], 82);
    expect(body['steps'], 6400);
    expect(body['source'], 'google_health');
    expect(body['timestamp'], contains('2026-06-20T10:30:00'));
    expect(result.status, 'ingested');
    expect(result.acceptedMetrics, ['heart_rate', 'steps']);
    expect(result.source, 'google_health');
  });

  test('ingestWorkout posts single workout to backend endpoint', () async {
    late http.Request captured;
    final repository = WearableIngestionRepository(
      client: ApiClient(
        baseUrl: 'https://backend.test',
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'status': 'ingested',
              'patient_id': '20',
              'source_provider': 'apple_health',
              'source_workout_id': 'HK-1',
              'workout_type': 'running',
              'start_time': '2026-06-20T10:00:00+00:00',
              'end_time': '2026-06-20T10:30:00+00:00',
              'duration_seconds': 1800,
            }),
            200,
          );
        }),
      ),
    );

    final result = await repository.ingestWorkout(_testWorkout());

    expect(captured.url.path, '/wearables/workouts/ingest');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['patient_id'], '20');
    expect(body['source_provider'], 'apple_health');
    expect(body['source_workout_id'], 'HK-1');
    expect(body['workout_type'], 'running');
    expect(body['duration_seconds'], 1800);
    expect(result.status, 'ingested');
    expect(result.sourceWorkoutId, 'HK-1');
    expect(result.durationSeconds, 1800);
  });

  test('ingestWorkoutBatch posts workouts to backend batch endpoint', () async {
    late http.Request captured;
    final repository = WearableIngestionRepository(
      client: ApiClient(
        baseUrl: 'https://backend.test',
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'status': 'ingested',
              'accepted_count': 1,
              'ingested_count': 1,
              'workouts': [
                {
                  'status': 'ingested',
                  'patient_id': '20',
                  'source_provider': 'apple_health',
                  'source_workout_id': 'HK-1',
                  'workout_type': 'running',
                  'start_time': '2026-06-20T10:00:00+00:00',
                  'end_time': '2026-06-20T10:30:00+00:00',
                  'duration_seconds': 1800,
                },
              ],
            }),
            200,
          );
        }),
      ),
    );

    final result = await repository.ingestWorkoutBatch([_testWorkout()]);

    expect(captured.url.path, '/wearables/workouts/batch-ingest');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['workouts'], isA<List>());
    expect((body['workouts'] as List).single['source_workout_id'], 'HK-1');
    expect(result.acceptedCount, 1);
    expect(result.ingestedCount, 1);
    expect(result.workouts.single.sourceWorkoutId, 'HK-1');
  });

  test('ingest maps backend errors to ApiException', () async {
    final repository = WearableIngestionRepository(
      client: ApiClient(
        baseUrl: 'https://backend.test',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': 'invalid wearable sample'}),
            422,
          ),
        ),
      ),
    );

    expect(
      () => repository.ingest(
        WearableSample(
          patientId: '20',
          steps: 10,
          timestamp: DateTime.parse('2026-06-20T10:30:00Z'),
          source: WearableSource.manual,
        ),
      ),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('invalid wearable sample'),
        ),
      ),
    );
  });

  test('ingestWorkout maps backend errors to ApiException', () async {
    final repository = WearableIngestionRepository(
      client: ApiClient(
        baseUrl: 'https://backend.test',
        client: MockClient(
          (_) async =>
              http.Response(jsonEncode({'detail': 'invalid workout'}), 422),
        ),
      ),
    );

    expect(
      () => repository.ingestWorkout(_testWorkout()),
      throwsA(
        isA<ApiException>().having(
          (error) => error.message,
          'message',
          contains('invalid workout'),
        ),
      ),
    );
  });
}

WearableWorkout _testWorkout() {
  return WearableWorkout(
    patientId: '20',
    sourceProvider: WearableSource.appleHealth,
    sourceWorkoutId: 'HK-1',
    workoutType: 'running',
    startTime: DateTime.parse('2026-06-20T10:00:00Z'),
    endTime: DateTime.parse('2026-06-20T10:30:00Z'),
    durationSeconds: 1800,
    distanceMeters: 5000,
  );
}
