import '../config/api_config.dart';
import '../data/repositories/ehospital_repository.dart';

// Compatibility facade for legacy screens. EHospitalRepository owns endpoint
// paths and response normalization for new code.
class EHospitalService {
  static const String baseUrl = ApiConfig.ehospitalBaseUrl;
  static final EHospitalRepository _repository = EHospitalRepository();

  static Future<String?> getCurrentPatientId() {
    return _repository.getCurrentPatientId();
  }

  static Future<void> sendWearableVitals({
    String? patientId,
    required int heartRate,
    required int steps,
    required int calories,
    required int sleep,
  }) {
    return _repository.sendWearableVitals(
      patientId: patientId,
      heartRate: heartRate,
      steps: steps,
      calories: calories,
      sleep: sleep,
    );
  }

  static Future<void> sendStressSnapshot({
    String? patientId,
    double? hrvSdnn,
    double? restingHeartRate,
    double? respiratoryRate,
    double? heartRate,
    String? timestamp,
  }) {
    return _repository.sendStressSnapshot(
      patientId: patientId,
      hrvSdnn: hrvSdnn,
      restingHeartRate: restingHeartRate,
      respiratoryRate: respiratoryRate,
      heartRate: heartRate,
      timestamp: timestamp,
    );
  }

  static Future<void> updateStressAnnotation({
    required Object vitalId,
    required String annotation,
  }) {
    return _repository.updateStressAnnotation(
      vitalId: vitalId,
      annotation: annotation,
    );
  }

  static Future<List<dynamic>> fetchVitals() {
    return _repository.fetchVitals();
  }

  static Future<List<dynamic>> fetchTable(String table, {String? patientId}) {
    return _repository.fetchTable(table, patientId: patientId);
  }
}
