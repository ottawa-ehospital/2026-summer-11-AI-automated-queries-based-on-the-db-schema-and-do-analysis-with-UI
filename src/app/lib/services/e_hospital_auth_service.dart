import '../data/repositories/auth_repository.dart';
import '../data/models/ehospital_models.dart';

// Compatibility facade for the login screen; AuthRepository owns the backend
// auth call and local session persistence.
class EHospitalAuthService {
  static final AuthRepository _repository = AuthRepository();
  static const supportedIdentities = AuthRepository.supportedIdentities;

  static Future<AuthLoginResult> loginWithEmail(
    String email,
    String password, {
    String selectedOption = 'Patient',
  }) {
    return _repository.loginWithEmail(
      email,
      password,
      selectedOption: selectedOption,
    );
  }

  static Future<int?> getLoggedInPatientId() {
    return _repository.getLoggedInPatientId();
  }
}
