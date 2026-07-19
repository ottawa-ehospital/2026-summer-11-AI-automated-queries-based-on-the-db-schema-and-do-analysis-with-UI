import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../../core/network/api_client.dart';
import '../models/wearable_models.dart';
import 'wearable_ingestion_repository.dart';

class EHospitalRepository {
  final ApiClient _client;
  final ApiClient _backendClient;
  final WearableIngestionClient _wearableIngestionClient;

  EHospitalRepository({
    ApiClient? client,
    ApiClient? backendClient,
    WearableIngestionClient? wearableIngestionClient,
  }) : _client = client ?? ApiClient(baseUrl: ApiConfig.ehospitalBaseUrl),
       _backendClient =
           backendClient ?? ApiClient(baseUrl: ApiConfig.backendBaseUrl),
       _wearableIngestionClient =
           wearableIngestionClient ?? WearableIngestionRepository();

  Future<String?> getCurrentPatientId() async {
    final prefs = await SharedPreferences.getInstance();
    final Object? rawId = prefs.get('patient_id');
    return rawId?.toString();
  }

  Future<void> sendWearableVitals({
    String? patientId,
    required int heartRate,
    required int steps,
    required int calories,
    required int sleep,
  }) async {
    final id = patientId ?? await getCurrentPatientId() ?? 'unknown_user';
    // Legacy callers still enter here, but wearable writes are now
    // backend-mediated so ingestion validation and future alert hooks run.
    await _wearableIngestionClient.ingest(
      WearableSample(
        patientId: id,
        heartRate: heartRate.toDouble(),
        steps: steps.toDouble(),
        calories: calories.toDouble(),
        sleep: sleep.toDouble(),
        timestamp: DateTime.now(),
        source: WearableSource.manual,
      ),
    );
  }

  Future<List<dynamic>> fetchVitals() {
    return fetchTable('wearable_vitals');
  }

  Future<void> sendStressSnapshot({
    String? patientId,
    double? hrvSdnn,
    double? restingHeartRate,
    double? respiratoryRate,
    double? heartRate,
    String? timestamp,
  }) async {
    final id = patientId ?? await getCurrentPatientId() ?? 'unknown_user';
    await _backendClient.postJson('/vitals/stress-snapshot', {
      'patient_id': id,
      if (hrvSdnn != null) 'hrv_sdnn': hrvSdnn,
      if (restingHeartRate != null) 'resting_heart_rate': restingHeartRate,
      if (respiratoryRate != null) 'respiratory_rate': respiratoryRate,
      if (heartRate != null) 'heart_rate': heartRate,
      'timestamp': timestamp ?? DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateStressAnnotation({
    required Object vitalId,
    required String annotation,
  }) async {
    await _backendClient.patchJson('/vitals/$vitalId/annotation', {
      'annotation': annotation,
    });
  }

  Future<List<dynamic>> fetchTable(String table, {String? patientId}) async {
    // eHospital deployments have returned both {"data": [...]} and raw arrays;
    // normalize both shapes here so feature screens can consume rows only.
    final decoded = await _client.getJson(
      '/table/$table',
      queryParameters: patientId == null ? null : {'patient_id': patientId},
    );
    final rows = decoded is Map<String, dynamic> && decoded['data'] is List
        ? decoded['data'] as List<dynamic>
        : decoded is List
        ? decoded
        : <dynamic>[];
    if (patientId == null) return rows;
    return rows
        .where(
          (item) => item is Map && item['patient_id']?.toString() == patientId,
        )
        .toList();
  }
}
