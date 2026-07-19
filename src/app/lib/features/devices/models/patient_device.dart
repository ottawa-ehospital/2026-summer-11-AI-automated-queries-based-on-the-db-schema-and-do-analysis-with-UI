class PatientDevice {
  final String patientId;
  final String name;
  final String email;
  final String? lastSync;
  final int recordCount;

  const PatientDevice({
    required this.patientId,
    required this.name,
    required this.email,
    required this.lastSync,
    required this.recordCount,
  });
}
