import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/widgets/widgets.dart';
import '../../../l10n/l10n.dart';
import '../../../services/e_hospital_service.dart';
import '../../../services/wearable_sync_service.dart';
import '../../../ui/ui.dart';
import '../models/patient_device.dart';
import '../presentation/device_styles.dart';
import '../widgets/device_info_banner.dart';
import '../widgets/device_section_label.dart';
import '../widgets/patient_device_card.dart';
import '../widgets/simulation_progress_panel.dart';

// Lists patients, shows Apple Watch sync status, and supports demo wearable uploads.
class DeviceConnectionScreen extends StatefulWidget {
  const DeviceConnectionScreen({super.key});

  @override
  State<DeviceConnectionScreen> createState() => _DeviceConnectionScreenState();
}

class _DeviceConnectionScreenState extends State<DeviceConnectionScreen> {
  bool _loading = true;
  String? _errorMsg;
  List<PatientDevice> _patients = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final results = await Future.wait([
        EHospitalService.fetchTable('users'),
        EHospitalService.fetchTable('wearable_vitals'),
      ]);

      final List<dynamic> users = results[0];
      final List<dynamic> vitals = results[1];
      final Map<String, String> latestSync = {};
      final Map<String, int> recordCounts = {};

      for (final vital in vitals) {
        final patientId = (vital['patient_id'] ?? '').toString();
        recordCounts[patientId] = (recordCounts[patientId] ?? 0) + 1;
        final timestamp = (vital['timestamp'] ?? vital['recorded_on'] ?? '')
            .toString();
        if (timestamp.isNotEmpty &&
            (!latestSync.containsKey(patientId) ||
                timestamp.compareTo(latestSync[patientId]!) > 0)) {
          latestSync[patientId] = timestamp;
        }
      }

      final l10n = context.l10n;
      final list =
          users.map((user) {
            final id = (user['user_id'] ?? user['patient_id'] ?? '').toString();
            final username = user['username'] as String? ?? '';
            return PatientDevice(
              patientId: id,
              name: username.isEmpty ? l10n.patientFallbackName(id) : username,
              email: user['email'] as String? ?? '',
              lastSync: latestSync[id],
              recordCount: recordCounts[id] ?? 0,
            );
          }).toList()..sort(
            (a, b) => (int.tryParse(a.patientId) ?? 0).compareTo(
              int.tryParse(b.patientId) ?? 0,
            ),
          );

      if (mounted) {
        setState(() {
          _patients = list;
          _loading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMsg = context.l10n.assistantErrorMessage(error.toString());
        });
      }
    }
  }

  void _simulateForPatient(PatientDevice patient) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _SimulateDialog(patient: patient),
    ).then((_) => _loadPatients());
  }

  String _formatSync(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      final diff = DateTime.now().difference(dt);
      final l10n = context.l10n;
      if (diff.inMinutes < 1) return l10n.justNow;
      if (diff.inHours < 1) return l10n.minutesAgo(diff.inMinutes);
      if (diff.inDays < 1) return l10n.hoursAgo(diff.inHours);
      return l10n.daysAgo(diff.inDays);
    } catch (_) {
      return isoStr;
    }
  }

  Widget _patientCard(PatientDevice patient) {
    final l10n = context.l10n;
    final hasSynced = patient.lastSync != null;
    return PatientDeviceCard(
      patient: patient,
      statusLabel: hasSynced ? l10n.connectedStatus : l10n.noDataStatus,
      metadata: l10n.patientDeviceMeta(patient.patientId, patient.email),
      lastSyncLabel: hasSynced
          ? _formatSync(patient.lastSync!)
          : l10n.neverSynced,
      recordsLabel: patient.recordCount > 0
          ? l10n.recordsCount(patient.recordCount)
          : null,
      simulateLabel: l10n.simulateButton,
      onSimulate: () => _simulateForPatient(patient),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppSliverHeader(
            title: l10n.deviceManagerTitle,
            icon: Icons.watch_outlined,
          ),
          if (_loading)
            SliverStateView.loading()
          else if (_errorMsg != null)
            SliverStateView.error(message: _errorMsg!)
          else
            SliverPadding(
              padding: DeviceStyles.bodyPadding,
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  DeviceInfoBanner(
                    title: l10n.deviceInfoTitle,
                    body: l10n.deviceInfoBody,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DeviceSectionLabel(text: l10n.patientsInDb(_patients.length)),
                  const SizedBox(height: 10),
                  ..._patients.map(_patientCard),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

// The dialog owns upload progress state, while the service boundary remains EHospitalService.
class _SimulateDialog extends StatefulWidget {
  final PatientDevice patient;

  const _SimulateDialog({required this.patient});

  @override
  State<_SimulateDialog> createState() => _SimulateDialogState();
}

class _SimulateDialogState extends State<_SimulateDialog> {
  int _progress = 0;
  bool _done = false;
  String? _error;
  static const int _total = 7;
  final WearableSyncService _wearableSyncService = WearableSyncService();

  @override
  void initState() {
    super.initState();
    _runSimulation();
  }

  Future<void> _runSimulation() async {
    final rng = Random();
    try {
      for (int day = _total - 1; day >= 0; day--) {
        await _wearableSyncService.uploadSimulationSample(
          patientId: widget.patient.patientId,
          heartRate: 58 + rng.nextInt(43),
          steps: 4800 + rng.nextInt(10200),
          calories: 180 + rng.nextInt(421),
          sleep: 5 + rng.nextInt(4),
        );

        if (mounted) setState(() => _progress = _total - day);
        await Future.delayed(const Duration(milliseconds: 350));
      }

      if (mounted) setState(() => _done = true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadii.radius(AppRadii.dialog),
      ),
      title: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: DeviceStyles.simulationIconDecoration,
            child: const Icon(
              Icons.watch_outlined,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            l10n.simulatingDataTitle,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.patientNameLabel(widget.patient.name),
            style: AppTypography.caption.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.appleHealthPipeline,
            style: AppTypography.caption.copyWith(fontSize: 11),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_error != null)
            Text(_error!, style: DeviceStyles.simulationError)
          else
            SimulationProgressPanel(
              done: _done,
              progress: _progress,
              total: _total,
              statusText: _done
                  ? l10n.uploadCompleteMessage(_total)
                  : l10n.uploadingDayMessage(_progress, _total),
            ),
        ],
      ),
      actions: _error != null
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(l10n.closeButton),
              ),
            ]
          : null,
    );
  }
}
