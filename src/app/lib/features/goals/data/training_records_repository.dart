import '../../../data/repositories/ehospital_repository.dart';
import '../models/training_record.dart';

class TrainingRecordsRepository {
  final EHospitalRepository _ehospitalRepository;

  TrainingRecordsRepository({EHospitalRepository? ehospitalRepository})
    : _ehospitalRepository = ehospitalRepository ?? EHospitalRepository();

  Future<List<TrainingRecord>> fetchTrainingRecords({
    required String patientId,
    int limit = 30,
  }) async {
    final rows = await _ehospitalRepository.fetchTable(
      'wearable_workouts',
      patientId: patientId,
    );
    final records = rows
        .whereType<Map>()
        .map((row) => TrainingRecord.fromJson(row.cast<String, dynamic>()))
        .toList();
    return TrainingRecord.sortDedupeAndLimit(records, limit: limit);
  }
}
