class EHospitalUser {
  final int? patientId;
  final String email;
  final String username;
  final String selectedOption;
  final Map<String, dynamic> raw;

  const EHospitalUser({
    required this.patientId,
    required this.email,
    required this.username,
    required this.selectedOption,
    required this.raw,
  });

  factory EHospitalUser.fromJson(Map<String, dynamic> json) {
    final selectedOption = json['selectedOption']?.toString() ?? 'Patient';
    final rawId = selectedOption == 'Patient'
        ? json['patient_id'] ?? json['user_id'] ?? json['id']
        : json['patient_id'];
    final email = json['email'] ?? json['EmailId'] ?? json['Email_Id'];
    final username =
        json['username'] ??
        json['name'] ??
        [json['FName'], json['MName'], json['LName']]
            .where(
              (value) => value != null && value.toString().trim().isNotEmpty,
            )
            .join(' ');
    return EHospitalUser(
      patientId: rawId == null ? null : int.tryParse(rawId.toString()),
      email: email?.toString() ?? '',
      username: username.toString(),
      selectedOption: selectedOption,
      raw: json,
    );
  }
}

class AuthLoginResult {
  final bool authenticated;
  final bool hasPatientSession;

  const AuthLoginResult({
    required this.authenticated,
    required this.hasPatientSession,
  });

  static const rejected = AuthLoginResult(
    authenticated: false,
    hasPatientSession: false,
  );
}
