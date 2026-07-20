import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../services/e_hospital_service.dart';
import '../presentation/profile_styles.dart';
import '../widgets/profile_header.dart';
import '../widgets/profile_info_row.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  Map<String, dynamic>? _user;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final l10n = context.l10n;
    final rawId = prefs.get('patient_id');
    if (rawId == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = l10n.profileNotLoggedIn;
        });
      }
      return;
    }
    final patientId = int.tryParse(rawId.toString());
    if (patientId == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = l10n.profileInvalidPatientId;
        });
      }
      return;
    }

    try {
      final data = await EHospitalService.fetchTable('users');
      final record = data.firstWhere((e) {
        final id = e["user_id"] ?? e["patient_id"];
        if (id == null) return false;
        return id is int
            ? id == patientId
            : id.toString() == patientId.toString();
      }, orElse: () => null);
      if (mounted) {
        setState(() {
          _user = record != null ? Map<String, dynamic>.from(record) : null;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = l10n.profileNetworkError(e.toString());
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final username = _user?["username"] as String?;
    final email = _user?["email"] as String?;
    final role = _user?["role"] as String?;
    final status = _user?["status"] as String?;
    final createdOn = _user?["created_on"] as String?;
    final userId =
        _user?["user_id"]?.toString() ?? _user?["patient_id"]?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileScreenTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => Navigator.pushNamed(context, "/settings"),
          ),
        ],
      ),
      body: _loading
          ? const LoadingStateView()
          : _errorMsg != null
          ? ErrorStateView(message: _errorMsg!)
          : _user == null
          ? EmptyStateView(message: l10n.profileNotFound)
          : SingleChildScrollView(
              child: Column(
                children: [
                  ProfileHeader(
                    username: username,
                    email: email,
                    role: role,
                    status: status,
                  ),
                  Padding(
                    padding: ProfileStyles.infoPadding,
                    child: Column(
                      children: [
                        ProfileInfoRow(
                          icon: Icons.badge_outlined,
                          label: l10n.patientIdLabel,
                          value: userId,
                        ),
                        ProfileInfoRow(
                          icon: Icons.person_outline,
                          label: l10n.usernameLabel,
                          value: username,
                        ),
                        ProfileInfoRow(
                          icon: Icons.email_outlined,
                          label: l10n.emailLabel,
                          value: email,
                        ),
                        ProfileInfoRow(
                          icon: Icons.verified_user_outlined,
                          label: l10n.roleLabel,
                          value: role,
                        ),
                        ProfileInfoRow(
                          icon: Icons.circle_outlined,
                          label: l10n.statusLabel,
                          value: status,
                        ),
                        ProfileInfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: l10n.memberSinceLabel,
                          value: createdOn,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
