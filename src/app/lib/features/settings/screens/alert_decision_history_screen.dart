import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/widgets/widgets.dart';
import '../../../data/models/health_alert_models.dart';
import '../../../data/repositories/alert_decision_store.dart';
import '../../../services/health_alert_debug_scenario_runner.dart';
import '../../../ui/ui.dart';
import '../presentation/settings_styles.dart';

class AlertDecisionHistoryScreen extends StatefulWidget {
  final AlertDecisionStore? store;
  final HealthAlertDebugScenarioRunner? debugScenarioRunner;
  final bool debugToolsEnabled;

  const AlertDecisionHistoryScreen({
    super.key,
    this.store,
    this.debugScenarioRunner,
    this.debugToolsEnabled = kDebugMode,
  });

  @override
  State<AlertDecisionHistoryScreen> createState() =>
      _AlertDecisionHistoryScreenState();
}

class _AlertDecisionHistoryScreenState
    extends State<AlertDecisionHistoryScreen> {
  late final AlertDecisionStore _store;
  late final HealthAlertDebugScenarioRunner _debugRunner;
  List<AlertDecisionRecord> _records = [];
  String? _patientId;
  bool _loading = true;
  bool _runningDebugScenario = false;

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? AlertDecisionStore();
    _debugRunner =
        widget.debugScenarioRunner ?? HealthAlertDebugScenarioRunner();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final patientId = prefs.get('patient_id')?.toString();
    final records = patientId == null
        ? <AlertDecisionRecord>[]
        : await _store.load(patientId);
    if (!mounted) return;
    setState(() {
      _patientId = patientId;
      _records = records;
      _loading = false;
    });
  }

  Future<void> _clear() async {
    final patientId = _patientId;
    if (patientId == null) return;
    await _store.clear(patientId);
    if (!mounted) return;
    setState(() => _records = []);
  }

  Future<void> _showDebugScenarioPicker() async {
    if (_runningDebugScenario) return;
    final scenario = await showModalBottomSheet<HealthAlertDebugScenario>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.health_and_safety_outlined),
                title: const Text('Debug data received'),
                subtitle: const Text('Simulate valid Apple Health sync data.'),
                onTap: () =>
                    Navigator.pop(context, HealthAlertDebugScenario.normalSync),
              ),
              ListTile(
                leading: const Icon(Icons.monitor_heart_outlined),
                title: const Text('Falling blood pressure'),
                subtitle: const Text('Run analysis with medication context.'),
                onTap: () => Navigator.pop(
                  context,
                  HealthAlertDebugScenario.fallingBloodPressure,
                ),
              ),
            ],
          ),
        );
      },
    );
    if (scenario == null) return;
    await _runDebugScenario(scenario);
  }

  Future<void> _runDebugScenario(HealthAlertDebugScenario scenario) async {
    final patientId = _patientId;
    if (patientId == null || patientId.trim().isEmpty) {
      _showSnackBar('Patient context is required before running analysis.');
      return;
    }
    _showSnackBar(_triggerMessage(scenario));
    setState(() => _runningDebugScenario = true);
    try {
      final result = await _debugRunner.run(scenario, patientId: patientId);
      await _load();
      if (!mounted) return;
      _showSnackBar(result.message);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Debug alert analysis failed: $error');
    } finally {
      if (mounted) {
        setState(() => _runningDebugScenario = false);
      }
    }
  }

  String _triggerMessage(HealthAlertDebugScenario scenario) {
    return switch (scenario) {
      HealthAlertDebugScenario.normalSync =>
        'Debug Apple Health sync analysis triggered.',
      HealthAlertDebugScenario.fallingBloodPressure =>
        'Debug blood-pressure analysis triggered.',
    };
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatTime(DateTime value) {
    final dt = value.toLocal();
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} $hour:$minute $ampm';
  }

  Color _statusColor(AlertDecisionRecord record) {
    if (record.notificationDispatched) return Colors.green.shade700;
    if (record.decision.notify) return Colors.orange.shade700;
    if (record.decision.status == 'invalid_event') return AppColors.danger;
    return AppColors.textMuted;
  }

  @override
  Widget build(BuildContext context) {
    final canShowDebugTools = widget.debugToolsEnabled && !_loading;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(
            title: 'Alert decision history',
            icon: Icons.notifications_active_outlined,
          ),
          if (_loading)
            SliverStateView.loading()
          else if (_records.isEmpty)
            SliverStateView.empty(
              icon: Icons.notifications_none_outlined,
              title: 'No alert decisions yet',
              subtitle:
                  'HealthKit alert analysis and test notification decisions will appear here for debugging.',
            )
          else
            SliverPadding(
              padding: SettingsStyles.sliverPadding,
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _AlertDecisionCard(
                    record: _records[index],
                    color: _statusColor(_records[index]),
                    formatTime: _formatTime,
                  ),
                  childCount: _records.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: (!canShowDebugTools && _records.isEmpty)
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (canShowDebugTools) ...[
                  FloatingActionButton.extended(
                    heroTag: 'test-alert-analyse',
                    tooltip: 'Test Alert Analyse',
                    onPressed: _runningDebugScenario
                        ? null
                        : _showDebugScenarioPicker,
                    icon: _runningDebugScenario
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.science_outlined),
                    label: const Text('Test Alert Analyse'),
                  ),
                  if (_records.isNotEmpty) const SizedBox(height: 12),
                ],
                if (_records.isNotEmpty)
                  FloatingActionButton(
                    heroTag: 'clear-alert-history',
                    tooltip: 'Clear history',
                    backgroundColor: AppColors.danger,
                    onPressed: _clear,
                    child: const Icon(
                      Icons.delete_sweep_outlined,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
    );
  }
}

class _AlertDecisionCard extends StatelessWidget {
  final AlertDecisionRecord record;
  final Color color;
  final String Function(DateTime value) formatTime;

  const _AlertDecisionCard({
    required this.record,
    required this.color,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    final decision = record.decision;
    final title = decision.title ?? decision.reason;
    final subtitle = decision.body ?? decision.reason;
    return Container(
      margin: SettingsStyles.tileMargin,
      decoration: SettingsStyles.tileDecoration(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        title: Text(
          title,
          style: AppTypography.body.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(subtitle, style: AppTypography.caption),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _chip(decision.notify ? 'notify' : 'suppressed', color),
                  _chip(decision.severity, color),
                  _chip(decision.eventType, color),
                  _chip(decision.isTestSource ? 'test' : 'production', color),
                  _chip(
                    record.notificationDispatched ? 'sent' : 'not sent',
                    color,
                  ),
                ],
              ),
              if (decision.evidenceSummary.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  decision.evidenceSummary.take(3).join(' | '),
                  style: AppTypography.caption.copyWith(fontSize: 11),
                ),
              ],
              if (record.dispatchFailure != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Dispatch issue: ${record.dispatchFailure}',
                  style: AppTypography.caption.copyWith(
                    color: AppColors.danger,
                    fontSize: 11,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Text(
                '${formatTime(record.storedAt)} · ${decision.eventSourceId}',
                style: AppTypography.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadii.radius(AppRadii.sm),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
