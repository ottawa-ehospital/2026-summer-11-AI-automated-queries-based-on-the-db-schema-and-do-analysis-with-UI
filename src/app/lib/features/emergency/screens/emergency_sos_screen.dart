import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';
import '../presentation/emergency_styles.dart';
import '../widgets/emergency_call_button.dart';
import '../widgets/emergency_edit_dialog.dart';
import '../widgets/emergency_info_card.dart';
import '../widgets/emergency_warning_banner.dart';

class EmergencySosScreen extends StatefulWidget {
  const EmergencySosScreen({super.key});

  @override
  State<EmergencySosScreen> createState() => _EmergencySosScreenState();
}

class _EmergencySosScreenState extends State<EmergencySosScreen> {
  String _bloodType = '';
  String _allergies = '';
  String _contactName = '';
  String _contactPhone = '';
  int? _patientId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.get('patient_id');
    _patientId = int.tryParse(rawId?.toString() ?? '');

    setState(() {
      _bloodType = prefs.getString('emergency_blood_type_$_patientId') ?? '';
      _allergies = prefs.getString('emergency_allergies_$_patientId') ?? '';
      _contactName = prefs.getString('emergency_contact_name_$_patientId') ?? '';
      _contactPhone = prefs.getString('emergency_contact_phone_$_patientId') ?? '';
    });
  }

  Future<void> _save() async {
    if (_patientId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('emergency_blood_type_$_patientId', _bloodType);
    await prefs.setString('emergency_allergies_$_patientId', _allergies);
    await prefs.setString('emergency_contact_name_$_patientId', _contactName);
    await prefs.setString('emergency_contact_phone_$_patientId', _contactPhone);
  }

  Future<void> _editField(String title, String current, IconData icon, ValueChanged<String> onSave) async {
    final value = await showDialog<String>(
      context: context,
      builder: (context) => EmergencyEditDialog(
        l10n: context.l10n,
        title: title,
        currentValue: current,
        icon: icon,
      ),
    );

    if (value == null) return;
    onSave(value);
    await _save();
  }

  Future<void> _callEmergency() async {
    final uri = Uri.parse('tel:911');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.cannotLaunchPhoneDialer)),
    );
  }

  Widget _sectionLabel(String label) => Text(label, style: EmergencyStyles.sectionLabel);

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(
            title: l10n.emergencySosTitle,
            icon: Icons.emergency_outlined,
            gradient: EmergencyStyles.headerGradient,
            backgroundColor: Colors.red.shade700,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: AppSpacing.page,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  EmergencyWarningBanner(message: l10n.emergencyUpdateWarning),
                  const SizedBox(height: AppSpacing.xxl),
                  _sectionLabel(l10n.medicalInformationTitle),
                  const SizedBox(height: AppSpacing.md),
                  EmergencyInfoCard(
                    icon: Icons.bloodtype_outlined,
                    label: l10n.bloodTypeLabel,
                    value: _bloodType,
                    emptyLabel: l10n.tapToSet,
                    onEdit: () => _editField(
                      l10n.bloodTypeLabel,
                      _bloodType,
                      Icons.bloodtype_outlined,
                      (value) => setState(() => _bloodType = value),
                    ),
                  ),
                  EmergencyInfoCard(
                    icon: Icons.warning_amber_outlined,
                    label: l10n.allergiesLabel,
                    value: _allergies,
                    emptyLabel: l10n.tapToSet,
                    onEdit: () => _editField(
                      l10n.allergiesLabel,
                      _allergies,
                      Icons.warning_amber_outlined,
                      (value) => setState(() => _allergies = value),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _sectionLabel(l10n.emergencyContactTitle),
                  const SizedBox(height: AppSpacing.md),
                  EmergencyInfoCard(
                    icon: Icons.person_outlined,
                    label: l10n.contactNameLabel,
                    value: _contactName,
                    emptyLabel: l10n.tapToSet,
                    onEdit: () => _editField(
                      l10n.contactNameLabel,
                      _contactName,
                      Icons.person_outlined,
                      (value) => setState(() => _contactName = value),
                    ),
                  ),
                  EmergencyInfoCard(
                    icon: Icons.phone_outlined,
                    label: l10n.contactPhoneLabel,
                    value: _contactPhone,
                    emptyLabel: l10n.tapToSet,
                    onEdit: () => _editField(
                      l10n.contactPhoneLabel,
                      _contactPhone,
                      Icons.phone_outlined,
                      (value) => setState(() => _contactPhone = value),
                    ),
                  ),
                  const SizedBox(height: 32),
                  EmergencyCallButton(
                    label: l10n.callEmergencyButton,
                    onPressed: _callEmergency,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
