import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'e_hospital_service.dart';
import '../config/api_config.dart';

class FitbitService {
  static String get clientId     => ApiConfig.fitbitClientId;
  static String get clientSecret => ApiConfig.fitbitClientSecret;
  static const String authUrl = 'https://www.fitbit.com/oauth2/authorize';
  static const String tokenUrl = 'https://api.fitbit.com/oauth2/token';
  static String get hospitalApi =>
      '${EHospitalService.baseUrl}/table/vitals_history';

  static const _kAccess = 'fitbit_access_token';
  static const _kRefresh = 'fitbit_refresh_token';
  static const _kExpiresAt = 'fitbit_expires_at';

  static String get redirectUri {
    if (kIsWeb) {
      return 'http://localhost:8080/';
    } else {
      return 'smarthealth://callback';
    }
  }

  // ------------------------------------------------------------
  // OK Fetch Latest Fitbit Vitals (REAL DATA)
  // ------------------------------------------------------------
  static Future<Map<String, dynamic>> getLatestVitals() async {
    try {
      final token = await _getValidAccessToken();
      if (token == null) throw 'No valid Fitbit token. Please reconnect Fitbit.';

      final heartSeries = await _getHeartRateSeries(token);
      final dailySummary = await _getDailySummary(token);
      final sleepData = await _getSleepToday(token);

      int latestHR = 0;
      double avgHR = 0;

      if (heartSeries.isNotEmpty) {
        latestHR = heartSeries.last["value"] ?? 0;
        avgHR = heartSeries
                .map((e) => e["value"] as int)
                .reduce((a, b) => a + b) /
            heartSeries.length;
      }

      final result = {
        "heart_rate": latestHR,
        "avg_heart_rate": avgHR.round(),
        "steps": dailySummary["steps"] ?? 0,
        "calories": dailySummary["calories"] ?? 0,
        "sleep": sleepData["minutesAsleep"] ?? 0,
        "timestamp": DateTime.now().toIso8601String(),
      };

      debugPrint(" Fitbit Vitals -> $result");
      return result;
    } catch (e) {
      debugPrint(" Fitbit getLatestVitals error: $e");
      return {};
    }
  }

  // ------------------------------------------------------------
  // Fitbit Connect Flow (OAuth)
  // ------------------------------------------------------------
  static Future<void> connectFitbit(BuildContext context) async {
    try {
      ApiConfig.requireFitbitConfig();
      final encodedRedirect = Uri.encodeComponent(redirectUri);
      final authUri = Uri.parse(
        '$authUrl?response_type=code'
        '&client_id=$clientId'
        '&redirect_uri=$encodedRedirect'
        '&scope=activity%20heartrate%20sleep%20profile',
      );

      if (!await canLaunchUrl(authUri)) {
        throw 'Could not launch Fitbit authorization URL';
      }

      await launchUrl(authUri, mode: LaunchMode.externalApplication);

      if (kIsWeb) return;

      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
      await for (HttpRequest req in server) {
        final code = req.uri.queryParameters['code'];
        if (code != null) {
          req.response
            ..statusCode = 200
            ..headers.contentType = ContentType.html
            ..write("<h2> Fitbit connected successfully! You can close this tab.</h2>");
          await req.response.close();
          await server.close();

          final ok = await _exchangeCodeForToken(code);
          if (!ok) throw 'Failed to get access token';

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text(" Fitbit Connected Successfully")),
            );
          }

          break;
        } else {
          req.response
            ..statusCode = 400
            ..write("<h2>鉂?Fitbit connection failed.</h2>");
          await req.response.close();
        }
      }
    } catch (e) {
      debugPrint('Fitbit connect error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  static Future<bool> _exchangeCodeForToken(String code) async {
    final res = await http.post(
      Uri.parse(tokenUrl),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'client_id': clientId,
        'grant_type': 'authorization_code',
        'redirect_uri': redirectUri,
        'code': code,
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _saveTokens(
        access: data['access_token'],
        refresh: data['refresh_token'],
        expiresInSec: data['expires_in'],
      );
      return true;
    }
    debugPrint('Token exchange failed: ${res.statusCode} ${res.body}');
    return false;
  }

  static Future<void> _saveTokens({
    required String access,
    required String refresh,
    required int expiresInSec,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final expiresAt = DateTime.now()
        .add(Duration(seconds: expiresInSec - 60))
        .millisecondsSinceEpoch ~/ 1000;
    await prefs.setString(_kAccess, access);
    await prefs.setString(_kRefresh, refresh);
    await prefs.setInt(_kExpiresAt, expiresAt);
  }

  static Future<String?> _getValidAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final access = prefs.getString(_kAccess);
    final refresh = prefs.getString(_kRefresh);
    final expiresAt = prefs.getInt(_kExpiresAt) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    if (access != null && now < expiresAt) return access;
    if (refresh == null) return null;

    final res = await http.post(
      Uri.parse(tokenUrl),
      headers: {
        'Authorization': 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refresh,
      },
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      await _saveTokens(
        access: data['access_token'],
        refresh: data['refresh_token'] ?? refresh,
        expiresInSec: data['expires_in'],
      );
      return data['access_token'];
    } else {
      debugPrint('Token refresh failed: ${res.statusCode} ${res.body}');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> _getHeartRateSeries(String accessToken) async {
    final url = Uri.parse('https://api.fitbit.com/1/user/-/activities/heart/date/today/1d/1min.json');
    final r = await http.get(url, headers: {'Authorization': 'Bearer $accessToken'});
    if (r.statusCode != 200) throw 'HR fetch failed: ${r.statusCode}';
    final json = jsonDecode(r.body);
    final series = (json['activities-heart-intraday']?['dataset'] as List? ?? [])
        .map((e) => {"time": e['time'], "value": e['value']})
        .cast<Map<String, dynamic>>()
        .toList();
    return series;
  }

  static Future<Map<String, dynamic>> _getDailySummary(String accessToken) async {
    final today = DateTime.now().toIso8601String().split('T').first;
    final url = Uri.parse('https://api.fitbit.com/1/user/-/activities/date/$today.json');
    final r = await http.get(url, headers: {'Authorization': 'Bearer $accessToken'});
    if (r.statusCode != 200) throw 'Daily summary failed: ${r.statusCode}';
    final j = jsonDecode(r.body);
    final summary = j['summary'] ?? {};
    return {"steps": summary['steps'] ?? 0, "calories": summary['caloriesOut'] ?? 0};
  }

  static Future<Map<String, dynamic>> _getSleepToday(String accessToken) async {
    final url = Uri.parse('https://api.fitbit.com/1.2/user/-/sleep/date/today.json');
    final r = await http.get(url, headers: {'Authorization': 'Bearer $accessToken'});
    if (r.statusCode != 200) throw 'Sleep fetch failed: ${r.statusCode}';
    final j = jsonDecode(r.body);
    final sleeps = (j['sleep'] as List? ?? []);
    if (sleeps.isEmpty) return {};
    final main = sleeps.firstWhere(
      (e) => (e['isMainSleep'] ?? false) == true,
      orElse: () => sleeps.first,
    );
    return {
      "minutesAsleep": main['minutesAsleep'] ?? 0,
      "efficiency": main['efficiency'] ?? 0,
    };
  }
}
