import 'package:flutter/material.dart';

import '../../../ui/ui.dart';
import '../models/patient_device.dart';
import '../presentation/device_styles.dart';
import 'device_status_chip.dart';

class PatientDeviceCard extends StatelessWidget {
  final PatientDevice patient;
  final String statusLabel;
  final String metadata;
  final String lastSyncLabel;
  final String? recordsLabel;
  final String simulateLabel;
  final VoidCallback onSimulate;

  const PatientDeviceCard({
    super.key,
    required this.patient,
    required this.statusLabel,
    required this.metadata,
    required this.lastSyncLabel,
    required this.recordsLabel,
    required this.simulateLabel,
    required this.onSimulate,
  });

  @override
  Widget build(BuildContext context) {
    final hasSynced = patient.lastSync != null;
    final statusColor = hasSynced ? Colors.green : Colors.orange;

    return Container(
      margin: DeviceStyles.patientCardMargin,
      padding: DeviceStyles.patientCardPadding,
      decoration: DeviceStyles.patientCardDecoration,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: DeviceStyles.statusIconDecoration(statusColor),
            child: Icon(Icons.watch_outlined, color: statusColor, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(patient.name, style: DeviceStyles.patientName)),
                    DeviceStatusChip(label: statusLabel, color: statusColor),
                  ],
                ),
                const SizedBox(height: 2),
                Text(metadata, style: DeviceStyles.patientMeta),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.history, size: 12, color: AppColors.textMuted),
                    const SizedBox(width: AppSpacing.xs),
                    Text(lastSyncLabel, style: DeviceStyles.patientMeta),
                    if (recordsLabel != null) ...[
                      const SizedBox(width: 10),
                      const Icon(Icons.storage_outlined, size: 12, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Text(recordsLabel!, style: DeviceStyles.recordCount),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton(
            onPressed: onSimulate,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: AppRadii.radius(AppSpacing.md)),
              elevation: 0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.watch_outlined, color: Colors.white, size: 16),
                const SizedBox(height: 2),
                Text(simulateLabel, style: DeviceStyles.simulateButton),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
