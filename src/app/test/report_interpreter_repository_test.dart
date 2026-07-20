import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:smart_health_app/core/network/api_exception.dart';
import 'package:smart_health_app/features/report_interpreter/data/report_interpreter_repository.dart';
import 'package:smart_health_app/features/report_interpreter/models/report_interpreter_models.dart';

void main() {
  test('fetchDates uses report interpreter namespace and supplied patient id', () async {
    late Uri captured;
    final repository = ReportInterpreterRepository(
      baseUrl: 'https://example.test',
      client: MockClient((request) async {
        captured = request.url;
        return http.Response(jsonEncode(['2026-01-02']), 200);
      }),
    );

    final dates = await repository.fetchDates(
      testType: 'blood',
      patientId: '42',
    );

    expect(dates, ['2026-01-02']);
    expect(captured.path, '/report-interpreter/tests/blood/dates');
    expect(captured.queryParameters['patientId'], '42');
    expect(captured.toString(), isNot(contains('/api/')));
    expect(captured.toString(), isNot(contains('patientId=20')));
  });

  test('sendChat posts JSON to report interpreter chat endpoint', () async {
    late http.Request captured;
    final repository = ReportInterpreterRepository(
      baseUrl: 'https://example.test/',
      client: MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'reply': 'Use the report context.'}), 200);
      }),
    );

    final reply = await repository.sendChat(
      messages: const [
        {'role': 'user', 'content': 'What is high?'},
      ],
      fileContext: 'Hemoglobin 18 g/dL',
    );

    expect(reply, 'Use the report context.');
    expect(captured.url.path, '/report-interpreter/chat');
    expect(captured.headers['Content-Type'], startsWith('application/json'));
    expect(jsonDecode(captured.body), {
      'messages': [
        {'role': 'user', 'content': 'What is high?'},
      ],
      'fileContext': 'Hemoglobin 18 g/dL',
    });
  });

  test('analyzeReport sends multipart file and explicit patient fields', () async {
    http.BaseRequest? capturedRequest;
    String capturedBody = '';
    final repository = ReportInterpreterRepository(
      baseUrl: 'https://example.test',
      client: MockClient.streaming((request, bodyStream) async {
        capturedRequest = request;
        capturedBody = utf8.decode(await bodyStream.toBytes());
        return http.StreamedResponse(
          Stream.value(
            utf8.encode(
              jsonEncode({
                'analysis': 'CBC reviewed.',
                'labValues': [],
                'patientNameNeeded': false,
                'patientNameQuestion': '',
                'savedLabRecordCount': 0,
                'detectedTestType': 'blood',
                'saveErrors': [],
                'fileContext': 'CBC text',
              }),
            ),
          ),
          200,
        );
      }),
    );

    final result = await repository.analyzeReport(
      report: PickedReport(
        name: 'cbc.txt',
        bytes: Uint8List.fromList(utf8.encode('Hemoglobin 18')),
      ),
      previousFileContext: 'previous',
      userQuestion: 'Summarize',
      patientId: '42',
      fromSavedRecord: true,
    );

    expect(result.analysis, 'CBC reviewed.');
    expect(capturedRequest?.method, 'POST');
    expect(capturedRequest?.url.path, '/report-interpreter/analyze-file');
    expect(capturedBody, contains('name="file"'));
    expect(capturedBody, contains('filename="cbc.txt"'));
    expect(capturedBody, contains('name="previousFileContext"'));
    expect(capturedBody, contains('previous'));
    expect(capturedBody, contains('name="userQuestion"'));
    expect(capturedBody, contains('Summarize'));
    expect(capturedBody, contains('name="patientId"'));
    expect(capturedBody, contains('42'));
    expect(capturedBody, contains('name="fromSavedRecord"'));
    expect(capturedBody, contains('true'));
    expect(capturedBody, isNot(contains('/api/')));
  });

  test('error responses are mapped to ApiException details', () async {
    final repository = ReportInterpreterRepository(
      baseUrl: 'https://example.test',
      client: MockClient((request) async {
        return http.Response(jsonEncode({'detail': 'Unsupported file type'}), 415);
      }),
    );

    expect(
      () => repository.sendChat(messages: const []),
      throwsA(
        isA<ApiException>()
            .having((error) => error.message, 'message', 'Unsupported file type')
            .having((error) => error.statusCode, 'statusCode', 415),
      ),
    );
  });
}
