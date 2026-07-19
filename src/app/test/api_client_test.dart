import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_health_app/core/network/api_client.dart';
import 'package:smart_health_app/core/network/api_exception.dart';

void main() {
  test('getJson does not send Content-Type header', () async {
    late http.Request captured;
    final client = ApiClient(
      baseUrl: 'https://example.test',
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'data': []}), 200);
      }),
    );

    await client.getJson('/table/users');

    expect(captured.headers['Accept'], 'application/json');
    expect(captured.headers.containsKey('Content-Type'), isFalse);
  });

  test('network failures include loopback iPhone guidance', () async {
    final client = ApiClient(
      baseUrl: 'http://127.0.0.1:8080',
      client: MockClient((_) async => throw Exception('connection refused')),
    );

    expect(
      () => client.getJson('/assistant/chat'),
      throwsA(
        isA<ApiException>()
            .having(
              (error) => error.message,
              'message',
              contains('http://127.0.0.1:8080/assistant/chat'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('physical iPhone'),
            )
            .having(
              (error) => error.message,
              'message',
              contains('BACKEND_BASE_URL=http://<mac-lan-ip>:8080'),
            ),
      ),
    );
  });
}
