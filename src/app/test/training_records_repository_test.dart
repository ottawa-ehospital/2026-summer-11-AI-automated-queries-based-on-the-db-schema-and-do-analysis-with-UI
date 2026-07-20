import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_health_app/core/network/api_client.dart';
import 'package:smart_health_app/data/repositories/ehospital_repository.dart';
import 'package:smart_health_app/features/goals/data/training_records_repository.dart';
import 'package:smart_health_app/features/goals/models/training_record.dart';

void main() {
  test('parses workout rows defensively', () {
    final record = TrainingRecord.fromJson({
      'patient_id': 20,
      'workout_type': 'outdoor_running',
      'source_provider': 'apple_health',
      'source_workout_id': 'HK-1',
      'start_time': '2026-07-12T10:00:00Z',
      'end_time': '2026-07-12T10:45:00Z',
      'distance_meters': '8000.5',
      'active_energy_kcal': '520',
      'steps': '9200',
    });

    expect(record.patientId, '20');
    expect(record.displayType, 'Outdoor Running');
    expect(record.durationSeconds, 2700);
    expect(record.distanceMeters, 8000.5);
    expect(record.activeEnergyKcal, 520);
    expect(record.steps, 9200);
    expect(record.stableKey, 'apple_health::HK-1');
  });

  test('malformed optional fields do not break parsing', () {
    final record = TrainingRecord.fromJson({
      'workout_type': '',
      'start_time': 'not-a-date',
      'duration_seconds': 'also-bad',
      'distance_meters': 'far',
      'steps': null,
    });

    expect(record.workoutType, 'workout');
    expect(record.startTime, isNull);
    expect(record.durationSeconds, 0);
    expect(record.distanceMeters, isNull);
    expect(record.steps, isNull);
  });

  test('fetches patient-scoped training records through table API', () async {
    late Uri requestedUri;
    final repository = TrainingRecordsRepository(
      ehospitalRepository: EHospitalRepository(
        client: ApiClient(
          baseUrl: 'https://ehospital.test',
          client: MockClient((request) async {
            requestedUri = request.url;
            return http.Response(
              jsonEncode({
                'data': [
                  _row('HK-older', '2026-07-10T09:00:00Z'),
                  _row('HK-newer', '2026-07-12T09:00:00Z'),
                  _row('HK-newer', '2026-07-12T09:00:00Z'),
                  _row(
                    'HK-other-patient',
                    '2026-07-13T09:00:00Z',
                    patientId: 99,
                  ),
                ],
              }),
              200,
            );
          }),
        ),
      ),
    );

    final records = await repository.fetchTrainingRecords(
      patientId: '20',
      limit: 10,
    );

    expect(requestedUri.path, '/table/wearable_workouts');
    expect(requestedUri.queryParameters['patient_id'], '20');
    expect(records.map((record) => record.sourceWorkoutId), [
      'HK-newer',
      'HK-older',
    ]);
  });

  test('normalizes raw list responses and applies limit', () async {
    final repository = TrainingRecordsRepository(
      ehospitalRepository: EHospitalRepository(
        client: ApiClient(
          baseUrl: 'https://ehospital.test',
          client: MockClient((request) async {
            return http.Response(
              jsonEncode([
                _row('HK-1', '2026-07-12T09:00:00Z'),
                _row('HK-2', '2026-07-11T09:00:00Z'),
              ]),
              200,
            );
          }),
        ),
      ),
    );

    final records = await repository.fetchTrainingRecords(
      patientId: '20',
      limit: 1,
    );

    expect(records, hasLength(1));
    expect(records.single.sourceWorkoutId, 'HK-1');
  });
}

Map<String, dynamic> _row(
  String sourceWorkoutId,
  String startTime, {
  int patientId = 20,
}) {
  return {
    'patient_id': patientId,
    'source_provider': 'apple_health',
    'source_workout_id': sourceWorkoutId,
    'workout_type': 'running',
    'start_time': startTime,
    'end_time': '2026-07-12T09:45:00Z',
    'duration_seconds': 2700,
    'distance_meters': 8000,
    'active_energy_kcal': 520,
    'steps': 9000,
  };
}
