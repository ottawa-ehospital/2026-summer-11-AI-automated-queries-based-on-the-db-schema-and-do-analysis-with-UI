import '../../../config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../models/urgent_care_models.dart';

class UrgentCareRepository {
  UrgentCareRepository({ApiClient? client})
    : _client = client ?? ApiClient(baseUrl: ApiConfig.backendBaseUrl);

  final ApiClient _client;

  Future<Map<String, dynamic>> health() async {
    final decoded = await _guard(
      () => _client.getJson('/urgent-care/customer/health'),
    );
    return Map<String, dynamic>.from(decoded as Map);
  }

  Future<UrgentCareCheckInResult> checkIn({
    required int? patientId,
    required String name,
    required int age,
    required String gender,
    required String symptoms,
    required String medicalHistory,
  }) async {
    final body = <String, dynamic>{
      if (patientId != null) 'patient_id': patientId,
      'name': name,
      'age': age,
      'gender': gender,
      'symptoms': symptoms,
      'medical_history': medicalHistory,
    };
    final decoded = await _guard(
      () => _client.postJson('/urgent-care/customer/check-in', body),
    );
    return UrgentCareCheckInResult.fromJson(
      Map<String, dynamic>.from(decoded as Map),
    );
  }

  Future<UrgentCarePatientStatus> status(int visitId) async {
    final decoded = await _guard(
      () => _client.getJson('/urgent-care/customer/visits/$visitId/status'),
    );
    final patient = (decoded as Map)['patient'] as Map? ?? {};
    return UrgentCarePatientStatus.fromJson(Map<String, dynamic>.from(patient));
  }

  Future<UrgentCareFeedbackResult> submitFeedback({
    required int visitId,
    required String rating,
    required String message,
    required String conditionUpdate,
  }) async {
    final decoded = await _guard(
      () => _client.postJson('/urgent-care/customer/visits/$visitId/feedback', {
        'rating': rating,
        'message': message,
        'condition_update': conditionUpdate,
      }),
    );
    return UrgentCareFeedbackResult.fromJson(
      Map<String, dynamic>.from(decoded as Map),
    );
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on ApiException catch (error) {
      throw UrgentCareRepositoryException(error.message);
    } catch (error) {
      throw UrgentCareRepositoryException(error.toString());
    }
  }
}

class UrgentCareRepositoryException implements Exception {
  const UrgentCareRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
