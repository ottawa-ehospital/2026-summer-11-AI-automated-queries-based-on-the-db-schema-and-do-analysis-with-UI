import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  final String baseUrl;
  final http.Client _client;

  ApiClient({required this.baseUrl, http.Client? client})
    : _client = client ?? http.Client();

  Uri uri(String path, {Map<String, String>? queryParameters}) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final baseUri = Uri.parse('$normalizedBase$normalizedPath');
    final mergedQuery = {
      ...baseUri.queryParameters,
      if (queryParameters != null) ...queryParameters,
    };
    return baseUri.replace(
      queryParameters: mergedQuery.isEmpty ? null : mergedQuery,
    );
  }

  Future<dynamic> getJson(
    String path, {
    Map<String, String>? queryParameters,
  }) async {
    final requestUri = uri(path, queryParameters: queryParameters);
    final response = await _send(
      requestUri,
      () => _client.get(
        requestUri,
        headers: const {'Accept': 'application/json'},
      ),
    );
    return _decodeResponse(response);
  }

  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    final requestUri = uri(path);
    final response = await _send(
      requestUri,
      () => _client.post(
        requestUri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    return _decodeResponse(response);
  }

  Future<dynamic> patchJson(String path, Map<String, dynamic> body) async {
    final requestUri = uri(path);
    final response = await _send(
      requestUri,
      () => _client.patch(
        requestUri,
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ),
    );
    return _decodeResponse(response);
  }

  Future<http.Response> _send(
    Uri requestUri,
    Future<http.Response> Function() send,
  ) async {
    try {
      return await send();
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(_connectionMessage(requestUri, error));
    }
  }

  dynamic _decodeResponse(http.Response response) {
    // This is the single HTTP boundary for Flutter API calls: callers receive
    // decoded JSON or a normalized ApiException, never raw http.Response data.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }
    if (response.body.trim().isEmpty) {
      return null;
    }
    try {
      return jsonDecode(response.body);
    } catch (_) {
      throw const ApiException('Server returned invalid JSON.');
    }
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
    } catch (_) {}
    return 'Request failed with status ${response.statusCode}.';
  }

  String _connectionMessage(Uri requestUri, Object error) {
    final buffer = StringBuffer('Unable to reach backend at $requestUri.');
    if (_isLoopbackHost(requestUri.host)) {
      buffer.write(
        ' If this app is running on a physical iPhone, 127.0.0.1/localhost points to the phone, not your Mac. '
        'Start the backend with API_HOST=0.0.0.0 and run Flutter with '
        '--dart-define=BACKEND_BASE_URL=http://<mac-lan-ip>:8080.',
      );
    }
    buffer.write(' Network error: $error');
    return buffer.toString();
  }

  bool _isLoopbackHost(String host) {
    final normalized = host.toLowerCase();
    return normalized == '127.0.0.1' ||
        normalized == 'localhost' ||
        normalized == '::1';
  }
}
