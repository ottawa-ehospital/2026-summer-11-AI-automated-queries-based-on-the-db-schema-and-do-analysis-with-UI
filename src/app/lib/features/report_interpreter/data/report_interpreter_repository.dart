import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../../../config/api_config.dart';
import '../../../core/network/api_exception.dart';
import '../models/report_interpreter_models.dart';

class ReportInterpreterRepository {
  ReportInterpreterRepository({String? baseUrl, http.Client? client})
    : baseUrl = baseUrl ?? ApiConfig.backendBaseUrl,
      _client = client ?? http.Client();

  final String baseUrl;
  final http.Client _client;

  void close() {
    _client.close();
  }

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse(
      '$normalizedBase$normalizedPath',
    ).replace(queryParameters: queryParameters);
  }

  Future<List<PatientOption>> fetchPatients() async {
    final response = await _client.get(_uri('/report-interpreter/patients'));
    if (response.statusCode != 200) return [];
    return (jsonDecode(response.body) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(PatientOption.fromJson)
        .where((patient) => patient.id.isNotEmpty)
        .toList();
  }

  Future<List<TestType>> fetchTestTypes() async {
    final response = await _client.get(_uri('/report-interpreter/test-types'));
    if (response.statusCode != 200) return [];
    return (jsonDecode(response.body) as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(TestType.fromJson)
        .where((type) => type.id.isNotEmpty)
        .toList();
  }

  Future<List<String>> fetchDates({
    required String testType,
    required String patientId,
  }) async {
    final response = await _client.get(
      _uri(
        '/report-interpreter/tests/$testType/dates',
        queryParameters: {'patientId': patientId},
      ),
    );
    if (response.statusCode != 200) return [];
    return (jsonDecode(response.body) as List<dynamic>)
        .map((item) => item.toString())
        .toList();
  }

  Future<String> sendChat({
    required List<Map<String, String>> messages,
    String? fileContext,
  }) async {
    final response = await _client.post(
      _uri('/report-interpreter/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'messages': messages, 'fileContext': fileContext}),
    );
    _throwIfError(response, fallback: 'Chat request failed');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['reply']?.toString() ?? 'No response from model.';
  }

  Future<AssignPatientResult> assignPendingReportToPatient({
    required String name,
    required List<LabValueVisual> labValues,
    String? reportDate,
    String? detectedTestType,
  }) async {
    final response = await _client.post(
      _uri('/report-interpreter/reports/assign-patient'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'labValues': labValues.map((value) => value.toJson()).toList(),
        'reportDate': reportDate,
        'detectedTestType': detectedTestType,
      }),
    );
    _throwIfError(response, fallback: 'Could not save patient records');
    return AssignPatientResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AnalyzeReportResult> analyzeReport({
    required PickedReport report,
    String? previousFileContext,
    String? userQuestion,
    String? patientId,
    bool fromSavedRecord = false,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      _uri('/report-interpreter/analyze-file'),
    );
    if (report.hasPath) {
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          report.path!,
          filename: report.name,
        ),
      );
    } else if (report.bytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          report.bytes!,
          filename: report.name,
        ),
      );
    } else {
      throw const ApiException('Report file is not available.');
    }
    if (previousFileContext != null) {
      request.fields['previousFileContext'] = previousFileContext;
    }
    if (userQuestion != null && userQuestion.trim().isNotEmpty) {
      request.fields['userQuestion'] = userQuestion.trim();
    }
    if (patientId != null) {
      request.fields['patientId'] = patientId;
    }
    if (fromSavedRecord) {
      request.fields['fromSavedRecord'] = 'true';
    }

    final response = await http.Response.fromStream(
      await _client.send(request),
    );
    _throwIfError(response, fallback: 'File analysis failed');
    return AnalyzeReportResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<PickedReport> fetchSavedRecord({
    required String type,
    required String date,
    required String patientId,
  }) async {
    final response = await _client.get(
      _uri(
        '/report-interpreter/tests/$type/$date',
        queryParameters: {'patientId': patientId},
      ),
    );
    _throwIfError(response, fallback: 'No saved record found');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final text = data['formattedText']?.toString() ?? '';
    return PickedReport(
      name: '$type-$date.txt',
      bytes: Uint8List.fromList(utf8.encode(text)),
    );
  }

  Future<List<String>> suggestQuestions({
    required String latestResponse,
    String? fileContext,
    int? patientId,
  }) async {
    final response = await _client.post(
      _uri('/report-interpreter/suggest-questions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'latestResponse': latestResponse,
        'fileContext': fileContext,
        'patientId': patientId,
      }),
    );
    if (response.statusCode >= 400) return [];
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return (data['questions'] as List<dynamic>? ?? [])
        .map((question) => question.toString())
        .toList();
  }

  void _throwIfError(http.Response response, {required String fallback}) {
    if (response.statusCode < 400) return;
    var message = fallback;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        message = decoded['detail'].toString();
      }
    } catch (_) {
      if (response.body.trim().isNotEmpty) {
        message = response.body.trim();
      }
    }
    throw ApiException(message, statusCode: response.statusCode);
  }
}
