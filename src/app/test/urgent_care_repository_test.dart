import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_health_app/core/network/api_client.dart';
import 'package:smart_health_app/features/urgent_care/urgent_care.dart';

void main() {
  test('checkIn posts to customer urgent-care endpoint', () async {
    late http.Request captured;
    final repository = UrgentCareRepository(
      client: ApiClient(
        baseUrl: 'https://example.test',
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'message': 'Check-in complete.',
              'patient': _statusJson(),
              'analysis': {'ctas_level': 3},
            }),
            200,
          );
        }),
      ),
    );

    final result = await repository.checkIn(
      patientId: 42,
      name: 'Jane Doe',
      age: 40,
      gender: 'Female',
      symptoms: 'Chest tightness',
      medicalHistory: 'Hypertension',
    );

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(captured.url.path, '/urgent-care/customer/check-in');
    expect(captured.url.path, isNot(contains('/workflow')));
    expect(body['patient_id'], 42);
    expect(body['symptoms'], 'Chest tightness');
    expect(result.patient.localPatientId, 1001);
  });

  test('status reads customer visit status endpoint', () async {
    late http.Request captured;
    final repository = UrgentCareRepository(
      client: ApiClient(
        baseUrl: 'https://example.test/',
        client: MockClient((request) async {
          captured = request;
          return http.Response(jsonEncode({'patient': _statusJson()}), 200);
        }),
      ),
    );

    final status = await repository.status(1001);

    expect(captured.method, 'GET');
    expect(captured.url.path, '/urgent-care/customer/visits/1001/status');
    expect(status.status, 'Waiting');
  });

  test('submitFeedback posts patient update without staff route', () async {
    late http.Request captured;
    final repository = UrgentCareRepository(
      client: ApiClient(
        baseUrl: 'https://example.test',
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'message': 'Staff review has been flagged.',
              'alert_agent': {'alert_required': true},
              'feedback': {},
              'database': {},
            }),
            200,
          );
        }),
      ),
    );

    final result = await repository.submitFeedback(
      visitId: 1001,
      rating: 'Unsure',
      message: 'The wait feels long',
      conditionUpdate: 'Getting worse',
    );

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(captured.url.path, '/urgent-care/customer/visits/1001/feedback');
    expect(captured.url.path, isNot(contains('/staff')));
    expect(captured.url.path, isNot(contains('/workflow')));
    expect(body['condition_update'], 'Getting worse');
    expect(result.alertRequired, isTrue);
  });
}

Map<String, dynamic> _statusJson() => {
      'local_patient_id': 1001,
      'patient_id': 42,
      'queue_number': 2,
      'status': 'Waiting',
      'patients_ahead': 1,
      'estimated_wait_range': '10-25 minutes',
      'notified': false,
      'checked_in_at': '2026-07-17T10:00:00',
      'server_time': '2026-07-17T10:01:00',
      'submitted_information': {
        'symptoms': 'Chest tightness',
        'ctas_urgency_level': 3,
        'risk_score': 6,
        'queue_name': 'Normal Queue',
      },
    };
