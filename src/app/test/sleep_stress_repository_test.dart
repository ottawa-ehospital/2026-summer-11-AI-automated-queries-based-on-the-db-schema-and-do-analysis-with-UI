import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_app/core/network/api_client.dart';
import 'package:smart_health_app/data/repositories/assistant_repository.dart';
import 'package:smart_health_app/data/repositories/ehospital_repository.dart';
import 'package:smart_health_app/data/repositories/sleep_repository.dart';
import 'package:smart_health_app/features/sleep/models/night_sleep.dart';

void main() {
  test('SleepRepository syncs sleep nights through backend endpoint', () async {
    late http.Request captured;
    final repository = SleepRepository(
      client: ApiClient(
        baseUrl: 'https://backend.test',
        client: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode({'saved': 1}), 200);
        }),
      ),
    );

    final saved = await repository.syncNights(
      patientId: '20',
      nights: [
        NightSleep(
          night: '2026-07-17',
          deepMinutes: 80,
          remMinutes: 90,
          coreMinutes: 220,
          lightMinutes: 120,
          awakeMinutes: 20,
          asleepMinutes: 510,
          inBedMinutes: 540,
          spo2Avg: 97,
          spo2Min: 93,
          hrAvg: 58,
          hrMin: 48,
        ),
      ],
    );

    expect(saved, 1);
    expect(captured.method, 'POST');
    expect(captured.url.path, '/sleep/nights');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['patient_id'], '20');
    expect(body['forward_to_ehospital'], isTrue);
    final nights = body['nights'] as List<dynamic>;
    expect(nights.single['night'], '2026-07-17');
    expect(nights.single['deep_minutes'], 80);
    expect(nights.single['source'], 'apple_health');
  });

  test('EHospitalRepository sends stress snapshot through backend', () async {
    late http.Request captured;
    final repository = EHospitalRepository(
      backendClient: ApiClient(
        baseUrl: 'https://backend.test',
        client: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode({'status': 'ok'}), 200);
        }),
      ),
    );

    await repository.sendStressSnapshot(
      patientId: '20',
      hrvSdnn: 25,
      restingHeartRate: 80,
      respiratoryRate: 18,
      heartRate: 88,
      timestamp: '2026-07-18T10:00:00Z',
    );

    expect(captured.method, 'POST');
    expect(captured.url.path, '/vitals/stress-snapshot');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['patient_id'], '20');
    expect(body['hrv_sdnn'], 25);
    expect(body['resting_heart_rate'], 80);
    expect(body['respiratory_rate'], 18);
    expect(body['heart_rate'], 88);
    expect(body['timestamp'], '2026-07-18T10:00:00Z');
  });

  test(
    'EHospitalRepository updates stress annotation through backend',
    () async {
      late http.Request captured;
      final repository = EHospitalRepository(
        backendClient: ApiClient(
          baseUrl: 'https://backend.test',
          client: MockClient((request) async {
            captured = request;
            return http.Response(jsonEncode({'status': 'updated'}), 200);
          }),
        ),
      );

      await repository.updateStressAnnotation(
        vitalId: 99,
        annotation: 'presentation day',
      );

      expect(captured.method, 'PATCH');
      expect(captured.url.path, '/vitals/99/annotation');
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['annotation'], 'presentation day');
    },
  );

  test('SleepRepository requests sleep feedback and follow-up chat', () async {
    final captured = <http.Request>[];
    final repository = SleepRepository(
      client: ApiClient(
        baseUrl: 'https://backend.test',
        client: MockClient((request) async {
          captured.add(request);
          if (request.url.path == '/sleep/feedback') {
            return http.Response(
              jsonEncode({'feedback': 'Keep sleep consistent.'}),
              200,
            );
          }
          return http.Response(
            jsonEncode({'reply': 'Try a calm wind-down.'}),
            200,
          );
        }),
      ),
    );

    final feedback = await repository.requestFeedback(patientId: '20');
    final reply = await repository.chatAboutSleep(
      patientId: '20',
      message: 'Why was REM low?',
      history: const [
        {'role': 'assistant', 'content': 'REM was lower than usual.'},
      ],
    );

    expect(feedback, 'Keep sleep consistent.');
    expect(reply, 'Try a calm wind-down.');
    expect(captured.first.url.path, '/sleep/feedback');
    expect(jsonDecode(captured.first.body)['patient_id'], '20');
    expect(captured.last.url.path, '/sleep/chat');
    final chatBody = jsonDecode(captured.last.body) as Map<String, dynamic>;
    expect(chatBody['message'], 'Why was REM low?');
    expect(chatBody['history'], isA<List<dynamic>>());
  });

  test(
    'AssistantRepository requests stress analysis through backend',
    () async {
      SharedPreferences.setMockInitialValues({});
      late http.Request captured;
      final repository = AssistantRepository(
        client: ApiClient(
          baseUrl: 'https://backend.test',
          client: MockClient((request) async {
            captured = request;
            return http.Response(
              jsonEncode({'analysis': 'Stress looks manageable.'}),
              200,
            );
          }),
        ),
      );

      final analysis = await repository.stressAnalysis(patientId: '20');

      expect(analysis, 'Stress looks manageable.');
      expect(captured.method, 'POST');
      expect(captured.url.path, '/assistant/stress-analysis');
      expect(jsonDecode(captured.body)['patient_id'], '20');
    },
  );
}
