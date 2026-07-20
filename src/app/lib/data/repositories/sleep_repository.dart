import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_exception.dart';
import '../../features/sleep/models/night_sleep.dart';

class SleepRepository {
  final ApiClient _client;

  SleepRepository({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.backendBaseUrl);

  static const _lastSyncKey = 'sleep_last_auto_sync_date';

  Future<int> syncNights({
    required String patientId,
    required List<NightSleep> nights,
  }) async {
    final decoded = await _client.postJson('/sleep/nights', {
      'patient_id': patientId,
      'nights': nights
          .map(
            (n) => {
              'night': n.night,
              'deep_minutes': n.deepMinutes,
              'rem_minutes': n.remMinutes,
              'core_minutes': n.coreMinutes,
              'light_minutes': n.lightMinutes,
              'awake_minutes': n.awakeMinutes,
              'asleep_minutes': n.asleepMinutes,
              'in_bed_minutes': n.inBedMinutes,
              'spo2_avg': n.spo2Avg,
              'spo2_min': n.spo2Min,
              'hr_avg': n.hrAvg,
              'hr_min': n.hrMin,
              'source': n.source,
            },
          )
          .toList(),
      'forward_to_ehospital': true,
    });
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Backend returned an unexpected response.');
    }
    return int.tryParse(decoded['saved']?.toString() ?? '') ?? nights.length;
  }

  /// Sync automatically at most once per calendar day. Safe to call on every
  /// screen open; it no-ops if it already ran today. Returns the number of
  /// nights synced, or null if it was skipped.
  Future<int?> autoSyncOncePerDay({
    required String patientId,
    required List<NightSleep> nights,
  }) async {
    if (nights.isEmpty) return null;
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final patientKey = '${_lastSyncKey}_$patientId';
    if (prefs.getString(patientKey) == todayKey) {
      return null; // already synced today
    }
    final saved = await syncNights(patientId: patientId, nights: nights);
    await prefs.setString(patientKey, todayKey);
    return saved;
  }

  Future<String> requestFeedback({required String patientId}) async {
    final decoded = await _client.postJson('/sleep/feedback', {
      'patient_id': patientId,
      'days': 7,
    });
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Backend returned an unexpected response.');
    }
    return decoded['feedback']?.toString() ?? 'No feedback available';
  }

  /// Follow-up chat about the sleep feedback. [history] is the prior
  /// conversation as a list of {'role': 'user'|'assistant', 'content': ...}.
  Future<String> chatAboutSleep({
    required String patientId,
    required String message,
    required List<Map<String, String>> history,
  }) async {
    final decoded = await _client.postJson('/sleep/chat', {
      'patient_id': patientId,
      'message': message,
      'history': history,
      'days': 7,
    });
    if (decoded is! Map<String, dynamic>) {
      throw const ApiException('Backend returned an unexpected response.');
    }
    return decoded['reply']?.toString() ?? '';
  }
}
