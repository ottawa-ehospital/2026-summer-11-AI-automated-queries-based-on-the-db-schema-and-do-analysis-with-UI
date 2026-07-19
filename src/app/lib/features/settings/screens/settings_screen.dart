import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../../core/widgets/widgets.dart';
import '../../../data/models/model_invocation_settings.dart';
import '../../../data/repositories/model_invocation_settings_store.dart';
import '../../../l10n/l10n.dart';
import '../../../ui/ui.dart';
import '../presentation/settings_styles.dart';
import '../widgets/data_sources_dialog.dart';
import '../widgets/settings_section_header.dart';
import '../widgets/settings_tile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  String _email = "";
  int? _patientId;
  ModelInvocationSettings? _modelInvocationSettings;
  final FlutterLocalNotificationsPlugin _notifPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _load();
    _initNotifications();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final rawId = prefs.get("patient_id");
    final modelSettings = await ModelInvocationSettingsStore().loadEffective();
    _patientId = int.tryParse(rawId?.toString() ?? '');
    if (mounted) {
      setState(() {
        _notificationsEnabled = prefs.getBool("notifications_enabled_$_patientId") ?? false;
        _email = prefs.getString("patient_email") ?? "";
        _modelInvocationSettings = modelSettings;
      });
    }
  }

  Future<void> _initNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _notifPlugin.initialize(settings);
  }

  Future<void> _toggleNotifications(bool val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool("notifications_enabled_$_patientId", val);
    setState(() => _notificationsEnabled = val);

    if (val) {
      await _scheduleDaily9am();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.notificationsEnabledMessage)),
        );
      }
    } else {
      await _notifPlugin.cancelAll();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.notificationsDisabledMessage)),
        );
      }
    }
  }

  Future<void> _scheduleDaily9am() async {
    const androidDetails = AndroidNotificationDetails(
      'health_reminder',
      'Daily Health Reminder',
      channelDescription: 'Reminds you to check your health metrics',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _notifPlugin.show(
      0,
      'Health Check Reminder',
      'Time to review your health metrics for the day!',
      details,
    );
  }

  Future<void> _logout(BuildContext context) async {
    final l10n = context.l10n;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.radius(AppRadii.dialog)),
        title: Text(l10n.logoutTitle),
        content: Text(l10n.logoutConfirmBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancelButton)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.logoutTitle, style: const TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
    }
  }

  void _showDataSourcesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const DataSourcesDialog(),
    );
  }

  Future<void> _openModelInvocationSettings() async {
    final changed = await Navigator.pushNamed(context, "/settings/model-invocation");
    if (changed == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(title: l10n.settingsTitle, icon: Icons.settings_outlined),
          SliverPadding(
            padding: SettingsStyles.sliverPadding,
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SettingsSectionHeader(title: l10n.accountSection),
                  SettingsTile(
                    icon: Icons.person_outlined,
                    title: l10n.profileTitle,
                    subtitle: _email.isNotEmpty ? _email : null,
                    onTap: () => Navigator.pushNamed(context, "/profile"),
                  ),
                  SettingsSectionHeader(title: l10n.notificationsSection),
                  SettingsTile(
                    icon: Icons.notifications_outlined,
                    title: l10n.dailyHealthRemindersTitle,
                    subtitle: l10n.dailyHealthRemindersSubtitle,
                    trailing: Switch(
                      value: _notificationsEnabled,
                      onChanged: _toggleNotifications,
                      activeThumbColor: AppColors.primary,
                    ),
                  ),
                  SettingsSectionHeader(title: l10n.emergencySection),
                  SettingsTile(
                    icon: Icons.emergency_outlined,
                    title: l10n.emergencySosCardTitle,
                    subtitle: l10n.emergencySosCardSubtitle,
                    iconColor: Colors.red.shade600,
                    onTap: () => Navigator.pushNamed(context, "/emergency"),
                  ),
                  SettingsSectionHeader(title: l10n.aboutSection),
                  SettingsTile(
                    icon: Icons.info_outline,
                    title: l10n.appVersionTitle,
                    subtitle: l10n.appVersionValue,
                    trailing: const SizedBox.shrink(),
                  ),
                  SettingsTile(
                    icon: Icons.health_and_safety_outlined,
                    title: l10n.appTitle,
                    subtitle: l10n.smartHealthAppSubtitle,
                    trailing: const SizedBox.shrink(),
                  ),
                  SettingsSectionHeader(title: l10n.dataSourcesTitle),
                  SettingsTile(
                    icon: Icons.local_hospital_outlined,
                    title: l10n.clinicalWearableDataTitle,
                    subtitle: l10n.clinicalWearableDataSubtitle,
                    onTap: () => _showDataSourcesDialog(context),
                  ),
                  SettingsTile(
                    icon: Icons.psychology_outlined,
                    title: l10n.aiHealthResponsesTitle,
                    subtitle: l10n.aiHealthResponsesSubtitle,
                    onTap: () => _showDataSourcesDialog(context),
                  ),
                  SettingsTile(
                    icon: Icons.tune_outlined,
                    title: 'Model invocation',
                    subtitle: _modelInvocationSettings?.summary ?? 'Backend defaults',
                    onTap: _openModelInvocationSettings,
                  ),
                  SettingsTile(
                    icon: Icons.notifications_active_outlined,
                    title: 'Alert decision history',
                    subtitle: 'Debug HealthKit alert analysis and notification records',
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/settings/alert-decisions',
                    ),
                  ),
                  SettingsTile(
                    icon: Icons.monitor_heart_outlined,
                    title: l10n.vitalsReferenceRangesTitle,
                    subtitle: l10n.vitalsReferenceRangesSubtitle,
                    onTap: () => _showDataSourcesDialog(context),
                  ),
                  SettingsSectionHeader(title: l10n.dangerZoneSection),
                  SettingsTile(
                    icon: Icons.logout,
                    title: l10n.logoutTitle,
                    subtitle: l10n.logoutSubtitle,
                    iconColor: Colors.red.shade700,
                    backgroundColor: Colors.red.shade50,
                    borderColor: Colors.red.shade200,
                    trailing: Icon(Icons.chevron_right, color: Colors.red.shade300),
                    onTap: () => _logout(context),
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
