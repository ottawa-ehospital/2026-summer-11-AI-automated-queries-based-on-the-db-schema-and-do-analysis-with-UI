import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_health_app/core/network/api_client.dart';
import 'package:smart_health_app/data/repositories/auth_repository.dart';

void main() {
  test('loginWithEmail posts credentials to 6302 login endpoint', () async {
    SharedPreferences.setMockInitialValues({});
    late http.Request captured;
    final repository = AuthRepository(
      client: ApiClient(
        baseUrl: 'https://backend.test',
        client: MockClient((request) async {
          captured = request;
          return http.Response(
            jsonEncode({
              'id': 20,
              'EmailId': 'patient@example.com',
              'FName': 'Ava',
              'LName': 'Chen',
              'patient_id': 20,
              'email': 'patient@example.com',
              'username': 'Ava Chen',
            }),
            200,
          );
        }),
      ),
    );

    final result = await repository.loginWithEmail(
      'patient@example.com',
      'secret',
      selectedOption: 'Patient',
    );

    expect(result.authenticated, isTrue);
    expect(result.hasPatientSession, isTrue);
    expect(captured.url.path, '/login');
    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body, {
      'email': 'patient@example.com',
      'password': 'secret',
      'selectedOption': 'Patient',
    });

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('patient_id'), 20);
    expect(prefs.getString('patient_email'), 'patient@example.com');
    expect(prefs.getString('patient_username'), 'Ava Chen');
    expect(prefs.getString('patient_identity'), 'Patient');
  });

  test(
    'loginWithEmail preserves non-patient identity without patient id',
    () async {
      SharedPreferences.setMockInitialValues({'patient_id': 99});
      late http.Request captured;
      final repository = AuthRepository(
        client: ApiClient(
          baseUrl: 'https://backend.test',
          client: MockClient((request) async {
            captured = request;
            return http.Response(
              jsonEncode({
                'id': 7,
                'email': 'admin@example.com',
                'full_name': 'Admin Person',
                'selectedOption': 'Admin',
                'username': 'Admin Person',
              }),
              200,
            );
          }),
        ),
      );

      final result = await repository.loginWithEmail(
        'admin@example.com',
        'secret',
        selectedOption: 'Admin',
      );

      expect(result.authenticated, isTrue);
      expect(result.hasPatientSession, isFalse);
      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['selectedOption'], 'Admin');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('patient_id'), isNull);
      expect(prefs.getString('patient_email'), 'admin@example.com');
      expect(prefs.getString('patient_username'), 'Admin Person');
      expect(prefs.getString('patient_identity'), 'Admin');
    },
  );

  test('loginWithEmail returns false for rejected credentials', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = AuthRepository(
      client: ApiClient(
        baseUrl: 'https://backend.test',
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({'detail': 'Invalid email or password'}),
            401,
          ),
        ),
      ),
    );

    final result = await repository.loginWithEmail(
      'patient@example.com',
      'bad',
    );

    expect(result.authenticated, isFalse);
    expect(result.hasPatientSession, isFalse);
  });
}
